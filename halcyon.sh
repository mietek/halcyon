export HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

if ! [ -d "${HALCYON_TOP_DIR}/lib/bashmenot" ]; then
	echo '   *** ERROR: Cannot source bashmenot' >&2
	exit 1
fi

source "${HALCYON_TOP_DIR}/lib/bashmenot/bashmenot.sh"
source "${HALCYON_TOP_DIR}/src/deploy.sh"
source "${HALCYON_TOP_DIR}/src/cache.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/constraints.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/app.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"


function set_default_vars () {
	export HALCYON_DIR="${HALCYON_DIR:-/app/.halcyon}"

	export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
	export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
	export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
	export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"
	export HALCYON_PUBLIC="${HALCYON_PUBLIC:-0}"

	export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon/cache}"
	export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"

	export HALCYON_FORCE_BUILD_ALL="${HALCYON_FORCE_BUILD_ALL:-0}"
	export HALCYON_FORCE_GHC_VERSION="${HALCYON_FORCE_GHC_VERSION:-}"
	export HALCYON_FORCE_BUILD_GHC="${HALCYON_FORCE_BUILD_GHC:-0}"
	export HALCYON_FORCE_CABAL_VERSION="${HALCYON_FORCE_CABAL_VERSION:-}"
	export HALCYON_FORCE_BUILD_CABAL="${HALCYON_FORCE_BUILD_CABAL:-0}"
	export HALCYON_FORCE_UPDATE_CABAL="${HALCYON_FORCE_UPDATE_CABAL:-0}"
	export HALCYON_FORCE_BUILD_SANDBOX="${HALCYON_FORCE_BUILD_SANDBOX:-0}"
	export HALCYON_FORCE_SANDBOX_FLAGS="${HALCYON_FORCE_SANDBOX_FLAGS:-}"
	export HALCYON_FORCE_BUILD_APP="${HALCYON_FORCE_BUILD_APP:-0}"
	export HALCYON_FORCE_APP_FLAGS="${HALCYON_FORCE_APP_FLAGS:-}"
	export HALCYON_FORCE_APP_INSTALL_DIR="${HALCYON_FORCE_APP_INSTALL_DIR:-}"

	export HALCYON_NO_BUILD="${HALCYON_NO_BUILD:-0}"
	export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
	export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"

	export HALCYON_NO_WARN_CONSTRAINTS="${HALCYON_NO_WARN_CONSTRAINTS:-0}"

	export HALCYON_NO_PREPARE_CACHE="${HALCYON_NO_PREPARE_CACHE:-0}"
	export HALCYON_NO_GHC="${HALCYON_NO_GHC:-0}"
	export HALCYON_NO_CABAL="${HALCYON_NO_CABAL:-0}"
	export HALCYON_NO_SANDBOX="${HALCYON_NO_SANDBOX:-0}"
	export HALCYON_NO_APP="${HALCYON_NO_APP:-0}"
	export HALCYON_NO_CLEAN_CACHE="${HALCYON_NO_CLEAN_CACHE:-0}"

	export HALCYON_PROTECT_SANDBOX="${HALCYON_PROTECT_SANDBOX:-0}"
	export HALCYON_INTO_SANDBOX="${HALCYON_INTO_SANDBOX:-0}"

	export HALCYON_QUIET="${HALCYON_QUIET:-0}"

	if ! (( ${HALCYON_INTERNAL_NO_SET_ENV:-0} )); then
		export HALCYON_INTERNAL_NO_SET_ENV=1

		export PATH="${HALCYON_DIR}/ghc/bin:${PATH}"
		export PATH="${HALCYON_DIR}/cabal/bin:${PATH}"
		export PATH="${HALCYON_DIR}/sandbox/bin:${PATH}"
		export PATH="${HALCYON_DIR}/app/bin:${PATH}"
		export PATH="${HALCYON_TOP_DIR}/bin:${PATH}"

		export LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LIBRARY_PATH:-}"
		export LD_LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LD_LIBRARY_PATH:-}"

		export LANG="${LANG:-en_US.UTF-8}"
	fi
}


function log_deploy_space () {
	if ! (( ${HALCYON_INTERNAL_DEPLOY_SPACE:-0} )); then
		export HALCYON_INTERNAL_DEPLOY_SPACE=1
	else
		log
		log_delimiter
		log
	fi
}


function reset_deploy_space () {
	unset HALCYON_INTERNAL_DEPLOY_SPACE
}


function halcyon_deploy () {
	local -a args
	while (( $# )); do
		case "$1" in
		'--halcyon-dir')
			shift
			expect_args halcyon_dir -- "$@"
			export HALCYON_DIR="${halcyon_dir}";;
		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;

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

		'--cache-dir')
			shift
			expect_args cache_dir -- "$@"
			export HALCYON_CACHE_DIR="${cache_dir}";;
		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;
		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;

		'--force-build-all')
			export HALCYON_FORCE_BUILD_ALL=1;;
		'--force-ghc-version')
			shift
			expect_args force_ghc_version -- "$@"
			export HALCYON_FORCE_GHC_VERSION="${force_ghc_version}";;
		'--force-ghc-version='*)
			export HALCYON_FORCE_GHC_VERSION="${1#*=}";;
		'--force-build-ghc')
			export HALCYON_FORCE_BUILD_GHC=1;;
		'--force-cabal-version')
			shift
			expect_args force_cabal_version -- "$@"
			export HALCYON_FORCE_CABAL_VERSION="${force_cabal_version}";;
		'--force-cabal-version='*)
			export HALCYON_FORCE_CABAL_VERSION="${1#*=}";;
		'--force-build-cabal')
			export HALCYON_FORCE_BUILD_CABAL=1;;
		'--force-update-cabal')
			export HALCYON_FORCE_UPDATE_CABAL=1;;
		'--force-build-sandbox')
			export HALCYON_FORCE_BUILD_SANDBOX=1;;
		'--force-sandbox-flags')
			shift
			expect_args force_sandbox_flags -- "$@"
			export HALCYON_FORCE_SANDBOX_FLAGS="${force_sandbox_flags}";;
		'--force-sandbox-flags='*)
			export HALCYON_FORCE_SANDBOX_FLAGS="${1#*=}";;
		'--force-build-app')
			export HALCYON_FORCE_BUILD_APP=1;;
		'--force-app-flags')
			shift
			expect_args force_app_flags -- "$@"
			export HALCYON_FORCE_APP_FLAGS="${force_app_flags}";;
		'--force-app-flags='*)
			export HALCYON_FORCE_APP_FLAGS="${1#*=}";;
		'--force-app-install-dir')
			shift
			expect_args force_app_install_dir -- "$@"
			export HALCYON_FORCE_APP_INSTALL_DIR="${force_app_install_dir}";;
		'--force-app-install-dir='*)
			export HALCYON_FORCE_APP_INSTALL_DIR="${1#*=}";;

		'--no-build')
			export HALCYON_NO_BUILD=1;;
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;

		'--no-warn-constraints')
			export HALCYON_NO_WARN_CONSTRAINTS=1;;

		'--no-prepare-cache')
			export HALCYON_NO_PREPARE_CACHE=1;;
		'--no-ghc')
			export HALCYON_NO_GHC=1;;
		'--no-cabal')
			export HALCYON_NO_CABAL=1;;
		'--no-sandbox')
			export HALCYON_NO_SANDBOX=1;;
		'--no-app')
			export HALCYON_NO_APP=1;;
		'--no-clean-cache')
			export HALCYON_NO_CLEAN_CACHE=1;;

		'--protect-sandbox')
			export HALCYON_PROTECT_SANDBOX=1;;
		'--into-sandbox')
			export HALCYON_FORCE_APP_INSTALL_DIR="${HALCYON_DIR}/sandbox";;

		'--recursive')
			export HALCYON_NO_WARN_CONSTRAINTS=1
			export HALCYON_NO_PREPARE_CACHE=1
			export HALCYON_NO_GHC=1
			export HALCYON_NO_CABAL=1
			export HALCYON_PROTECT_SANDBOX=1
			export HALCYON_NO_CLEAN_CACHE=1
			;;

		'--quiet')
			export HALCYON_QUIET=1;;

		'-'*)
			die "Unexpected option: $1";;

		*)
			args+=( "$1" )
		esac
		shift
	done

	if ! (( ${#args[@]} )); then
		deploy_local_app '.' || return 1
	elif (( ${#args[@]} == 1 )); then
		deploy_some_app "${args[0]}" || return 1
	else
		local index
		index=0
		for arg in "${args[@]}"; do
			log_deploy_space
			if ! (( index )); then
				HALCYON_NO_CLEAN_CACHE=1 \
					deploy_some_app "${arg}" || return 1
			elif (( index == ${#args[@]} - 1 )); then
				HALCYON_NO_PREPARE_CACHE=1 HALCYON_NO_GHC=1 HALCYON_NO_CABAL=1 \
					deploy_some_app "${arg}" || return 1
			else
				HALCYON_NO_PREPARE_CACHE=1 HALCYON_NO_GHC=1 HALCYON_NO_CABAL=1 HALCYON_NO_CLEAN_CACHE=1 \
					deploy_some_app "${arg}" || return 1
			fi
			index=$(( index + 1 ))
		done
	fi
}
