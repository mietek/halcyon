function set_halcyon_vars () {
	set_halcyon_paths

	if ! (( ${HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED:-0} )); then
		export HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED=1

		export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
		export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
		export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
		export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"

		export HALCYON_PUBLIC="${HALCYON_PUBLIC:-0}"

		export HALCYON_RECURSIVE="${HALCYON_RECURSIVE:-0}"
		export HALCYON_TARGET_SANDBOX="${HALCYON_TARGET_SANDBOX:-0}"

		export HALCYON_NO_BUILD="${HALCYON_NO_BUILD:-0}"
		export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
		export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"
	fi

	if ! (( ${HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET:-0} )); then
		export HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET=1

		export HALCYON_GHC_VERSION="${HALCYON_GHC_VERSION:-}"

		export HALCYON_CABAL_VERSION="${HALCYON_CABAL_VERSION:-}"
		export HALCYON_CABAL_REMOTE_REPO="${HALCYON_CABAL_REMOTE_REPO:-}"

		export HALCYON_SANDBOX_APPS="${HALCYON_SANDBOX_APPS:-}"
		export HALCYON_EXTRA_APPS="${HALCYON_EXTRA_APPS:-}"

		export HALCYON_FORCE_GHC="${HALCYON_FORCE_GHC:-0}"
		export HALCYON_FORCE_CABAL="${HALCYON_FORCE_CABAL:-0}"
		export HALCYON_FORCE_SANDBOX="${HALCYON_FORCE_SANDBOX:-0}"
		export HALCYON_FORCE_APP="${HALCYON_FORCE_APP:-0}"

		export HALCYON_UPDATE_CABAL="${HALCYON_UPDATE_CABAL:-0}"

		export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"

		export HALCYON_NO_GHC="${HALCYON_NO_GHC:-0}"
		export HALCYON_NO_CABAL="${HALCYON_NO_CABAL:-0}"
		export HALCYON_NO_SANDBOX_OR_APP="${HALCYON_NO_SANDBOX_OR_APP:-0}"
		export HALCYON_NO_APP="${HALCYON_NO_APP:-0}"

		export HALCYON_NO_PREPARE_CACHE="${HALCYON_NO_PREPARE_CACHE:-0}"
		export HALCYON_NO_CLEAN_CACHE="${HALCYON_NO_CLEAN_CACHE:-0}"

		export HALCYON_NO_WARN_IMPLICIT="${HALCYON_NO_WARN_IMPLICIT:-0}"
	else
		export HALCYON_GHC_VERSION=

		export HALCYON_CABAL_VERSION=
		export HALCYON_CABAL_REMOTE_REPO=

		export HALCYON_SANDBOX_APPS=
		export HALCYON_EXTRA_APPS=

		export HALCYON_FORCE_GHC=0
		export HALCYON_FORCE_CABAL=0
		export HALCYON_FORCE_SANDBOX=0
		export HALCYON_FORCE_APP=0

		export HALCYON_UPDATE_CABAL=0

		export HALCYON_PURGE_CACHE=0

		export HALCYON_NO_GHC=0
		export HALCYON_NO_CABAL=0
		export HALCYON_NO_SANDBOX_OR_APP=0
		export HALCYON_NO_APP=0

		export HALCYON_NO_PREPARE_CACHE=0
		export HALCYON_NO_CLEAN_CACHE=0

		export HALCYON_NO_WARN_IMPLICIT=0
	fi
}


function handle_command_line () {
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
		'--tmp-cache-dir')
			shift
			expect_args tmp_cache_dir -- "$@"
			export HALCYON_TMP_CACHE_DIR="${tmp_cache_dir}";;
		'--tmp-cache-dir='*)
			export HALCYON_TMP_CACHE_DIR="${1#*=}";;
		'--tmp-slug-dir')
			shift
			expect_args tmp_slug_dir -- "$@"
			export HALCYON_TMP_SLUG_DIR="${tmp_slug_dir}";;
		'--tmp-cache-dir='*)
			export HALCYON_TMP_SLUG_DIR="${1#*=}";;

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
		'--target-sandbox')
			export HALCYON_TARGET_SANDBOX=1;;

		'--no-build')
			export HALCYON_NO_BUILD=1;;
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;

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

		'--sandbox-apps')
			shift
			expect_args sandbox_apps -- "$@"
			export HALCYON_SANDBOX_APPS="${sandbox_apps}";;
		'--sandbox-apps='*)
			export HALCYON_SANDBOX_APPS="${1#*=}";;
		'--extra-apps')
			shift
			expect_args extra_apps -- "$@"
			export HALCYON_EXTRA_APPS="${extra_apps}";;
		'--extra-apps='*)
			export HALCYON_EXTRA_APPS="${1#*=}";;

		'--force-ghc')
			export HALCYON_FORCE_GHC=1;;
		'--force-cabal')
			export HALCYON_FORCE_CABAL=1;;
		'--force-sandbox')
			export HALCYON_FORCE_SANDBOX=1;;
		'--force-app')
			export HALCYON_FORCE_APP=1;;

		'--update-cabal')
			export HALCYON_UPDATE_CABAL=1;;

		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;

		'--no-ghc')
			export HALCYON_NO_GHC=1;;
		'--no-cabal')
			export HALCYON_NO_CABAL=1;;
		'--no-sandbox-or-app')
			export HALCYON_NO_SANDBOX_OR_APP=1;;
		'--no-app')
			export HALCYON_NO_APP=1;;

		'--no-prepare-cache')
			export HALCYON_NO_PREPARE_CACHE=1;;
		'--no-clean-cache')
			export HALCYON_NO_CLEAN_CACHE=1;;

		'--no-warn-implicit')
			export HALCYON_NO_WARN_IMPLICIT=1;;

		'-'*)
			die "Unexpected option: $1";;

		*)
			HALCYON_INTERNAL_ARGS+=( "$1" )
		esac
		shift
	done
}
