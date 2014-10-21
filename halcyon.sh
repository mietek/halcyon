export HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

if ! [ -d "${HALCYON_TOP_DIR}/lib/bashmenot" ]; then
	echo '   *** ERROR: Cannot source bashmenot' >&2
	exit 1
fi

source "${HALCYON_TOP_DIR}/lib/bashmenot/bashmenot.sh"
source "${HALCYON_TOP_DIR}/src/paths.sh"
source "${HALCYON_TOP_DIR}/src/vars.sh"
source "${HALCYON_TOP_DIR}/src/deploy.sh"
source "${HALCYON_TOP_DIR}/src/cache.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/app.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"


function halcyon_deploy () {
	local -a args
	while (( $# )); do
		case "$1" in
	# Paths:
		'--halcyon-dir')
			shift
			expect_args halcyon_dir -- "$@"
			export HALCYON_DIR="${halcyon_dir}";;
		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;
		'--cache-dir')
			shift
			expect_args cache_dir -- "$@"
			export HALCYON_CACHE_DIR="${cache_dir}";;
		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;

	# Vars set once and inherited:
		'--aws-access-key-id')
			shift
			expect_args aws_access_key_id -- "$@"
			export HALCYON_AWS_ACCESS_KEY_ID="${aws_access_key_id}";;
		'--aws-access-key-id='*)
			export HALCYON_AWS_ACCESS_KEY_ID="${1#*=}";;
		'--aws-secret-access-key')
			shift
			expect_args aws_secret_access_key -- "$@"
			export HALCYON_AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}";;
		'--aws-secret-access-key='*)
			export HALCYON_AWS_SECRET_ACCESS_KEY="${1#*=}";;
		'--s3-bucket')
			shift
			expect_args s3_bucket -- "$@"
			export HALCYON_S3_BUCKET="${s3_bucket}";;
		'--s3-bucket='*)
			export HALCYON_S3_BUCKET="${1#*=}";;
		'--s3-acl')
			shift
			expect_args s3_acl -- "$@"
			export HALCYON_S3_ACL="${s3_acl}";;
		'--s3-acl='*)
			export HALCYON_S3_ACL="${1#*=}";;

		'--public')
			export HALCYON_PUBLIC=1;;

		'--recursive')
			export HALCYON_RECURSIVE=1;;
		'--tool')
			export HALCYON_TOOL=1;;

		'--no-build')
			export HALCYON_NO_BUILD=1;;
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;

		'--no-install-ghc')
			export HALCYON_NO_INSTALL_GHC=1;;
		'--no-install-cabal')
			export HALCYON_NO_INSTALL_CABAL=1;;
		'--no-install-sandbox')
			export HALCYON_NO_INSTALL_SANDBOX=1;;
		'--no-install-app')
			export HALCYON_NO_INSTALL_APP=1;;

		'--no-prepare-cache')
			export HALCYON_NO_PREPARE_CACHE=1;;
		'--no-clean-cache')
			export HALCYON_NO_CLEAN_CACHE=1;;

		'--no-warn-implicit')
			export HALCYON_NO_WARN_IMPLICIT=1;;

	# Vars inherited once and reset:
		'--ghc-version')
			shift
			expect_args ghc_version -- "$@"
			export HALCYON_GHC_VERSION="${ghc_version}";;
		'--ghc-version='*)
			export HALCYON_GHC_VERSION="${1#*=}";;

		'--cabal-version')
			shift
			expect_args cabal_version -- "$@"
			export HALCYON_CABAL_VERSION="${cabal_version}";;
		'--cabal-version='*)
			export HALCYON_CABAL_VERSION="${1#*=}";;
		'--cabal-remote-repo')
			shift
			expect_args remote_repo -- "$@"
			export HALCYON_CABAL_REMOTE_REPO="${remote_repo}";;
		'--cabal-remote-repo='*)
			export HALCYON_CABAL_REMOTE_REPO="${1#*=}";;

		'--buildtime-deps')
			shift
			expect_args buildtime_deps -- "$@"
			export HALCYON_BUILDTIME_DEPS="${buildtime_deps}";;
		'--buildtime-deps='*)
			export HALCYON_BUILDTIME_DEPS="${1#*=}";;
		'--runtime-deps')
			shift
			expect_args runtime_deps -- "$@"
			export HALCYON_RUNTIME_DEPS="${runtime_deps}";;
		'--runtime-deps='*)
			export HALCYON_RUNTIME_DEPS="${1#*=}";;

		'--build-ghc')
			export HALCYON_BUILD_GHC=1;;
		'--build-cabal')
			export HALCYON_BUILD_CABAL=1;;
		'--build-sandbox')
			export HALCYON_BUILD_SANDBOX=1;;
		'--build-app')
			export HALCYON_BUILD_APP=1;;

		'--update-cabal')
			export HALCYON_UPDATE_CABAL=1;;

		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;

		'-'*)
			die "Unexpected option: $1";;

		*)
			args+=( "$1" )
		esac
		shift
	done

	if ! (( ${#args[@]} )); then
		if ! deploy_local_app '.'; then
			return 1
		fi
	elif (( ${#args[@]} == 1 )); then
		if ! deploy_app "${args[0]}"; then
			return 1
		fi
	else
		local index
		index=0
		for arg in "${args[@]}"; do
			index=$(( index + 1 ))
			if (( index == 1 )); then
				if ! HALCYON_NO_CLEAN_CACHE=1 \
					deploy_app "${arg}"
				then
					return 1
				fi
			else
				log
				log
				log_delimiter
				log
				if (( index == ${#args[@]} )); then
					if ! HALCYON_NO_PREPARE_CACHE=1    \
						HALCYON_NO_INSTALL_GHC=1   \
						HALCYON_NO_INSTALL_CABAL=1 \
						deploy_app "${arg}"
					then
						return 1
					fi
				else
					if ! HALCYON_NO_PREPARE_CACHE=1    \
						HALCYON_NO_INSTALL_GHC=1   \
						HALCYON_NO_INSTALL_CABAL=1 \
						HALCYON_NO_CLEAN_CACHE=1   \
						deploy_app "${arg}"
					then
						return 1
					fi
				fi
			fi
		done
	fi
}
