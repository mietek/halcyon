function set_halcyon_vars () {
	set_halcyon_paths

	if ! (( ${HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED:-0} )); then
		export HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED=1

		export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
		export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
		export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
		export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"

		export HALCYON_RECURSIVE="${HALCYON_RECURSIVE:-0}"
		export HALCYON_TARGET="${HALCYON_TARGET:-slug}"
		export HALCYON_SLUG_DIR="${HALCYON_SLUG_DIR:-}"

		export HALCYON_ONLY_BUILD_APP="${HALCYON_ONLY_BUILD_APP:-0}"
		export HALCYON_NO_DOWNLOAD_PUBLIC="${HALCYON_NO_DOWNLOAD_PUBLIC:-0}"
		export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
		export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"
	fi

	if ! (( ${HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET:-0} )); then
		export HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET=1

		export HALCYON_GHC_VERSION="${HALCYON_GHC_VERSION:-}"
		export HALCYON_FORCE_BUILD_GHC="${HALCYON_FORCE_BUILD_GHC:-0}"

		export HALCYON_CABAL_VERSION="${HALCYON_CABAL_VERSION:-}"
		export HALCYON_CABAL_REMOTE_REPO="${HALCYON_CABAL_REMOTE_REPO:-}"
		export HALCYON_UPDATE_CABAL="${HALCYON_UPDATE_CABAL:-0}"
		export HALCYON_FORCE_BUILD_CABAL="${HALCYON_FORCE_BUILD_CABAL:-0}"

		export HALCYON_ONLY_DEPLOY_ENV="${HALCYON_ONLY_DEPLOY_ENV:-0}"

		export HALCYON_SANDBOX_EXTRA_APPS="${HALCYON_SANDBOX_EXTRA_APPS:-}"
		export HALCYON_FORCE_BUILD_SANDBOX="${HALCYON_FORCE_BUILD_SANDBOX:-0}"

		export HALCYON_FORCE_BUILD_APP="${HALCYON_FORCE_BUILD_APP:-0}"

		export HALCYON_SLUG_EXTRA_APPS="${HALCYON_SLUG_EXTRA_APPS:-}"
		export HALCYON_NO_RESTORE_SLUG="${HALCYON_NO_RESTORE_SLUG:-0}"
		export HALCYON_NO_ARCHIVE_SLUG="${HALCYON_NO_ARCHIVE_SLUG:-0}"

		export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"
		export HALCYON_NO_PREPARE_CACHE="${HALCYON_NO_PREPARE_CACHE:-0}"
		export HALCYON_NO_CLEAN_CACHE="${HALCYON_NO_CLEAN_CACHE:-0}"

		export HALCYON_NO_WARN_IMPLICIT="${HALCYON_NO_WARN_IMPLICIT:-0}"
	else
		export HALCYON_GHC_VERSION=
		export HALCYON_FORCE_BUILD_GHC=0

		export HALCYON_CABAL_VERSION=
		export HALCYON_CABAL_REMOTE_REPO=
		export HALCYON_UPDATE_CABAL=0
		export HALCYON_FORCE_BUILD_CABAL=0

		export HALCYON_ONLY_DEPLOY_ENV=0

		export HALCYON_SANDBOX_EXTRA_APPS=
		export HALCYON_FORCE_BUILD_SANDBOX=0

		export HALCYON_FORCE_BUILD_APP=0

		export HALCYON_SLUG_EXTRA_APPS=
		export HALCYON_NO_RESTORE_SLUG=0
		export HALCYON_NO_ARCHIVE_SLUG=0

		export HALCYON_PURGE_CACHE=0
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

		'--recursive')
			export HALCYON_RECURSIVE=1;;
		'--target')
			shift
			expect_args target -- "$@"
			export HALCYON_TARGET="${target}";;
		'--target='*)
			export HALCYON_TARGET="${1#*=}";;
		'--slug-dir')
			shift
			expect_args slug_dir -- "$@"
			export HALCYON_SLUG_DIR="${slug_dir}";;
		'--slug-dir='*)
			export HALCYON_SLUG_DIR="${1#*=}";;

		'--only-build-app')
			export HALCYON_ONLY_BUILD_APP=1;;
		'--no-download-public')
			export HALCYON_NO_DOWNLOAD_PUBLIC=1;;
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
		'--force-build-ghc')
			export HALCYON_FORCE_BUILD_GHC=1;;

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
		'--update-cabal')
			export HALCYON_UPDATE_CABAL=1;;
		'--cabal-update')
			export HALCYON_UPDATE_CABAL=1;;
		'--force-build-cabal')
			export HALCYON_FORCE_BUILD_CABAL=1;;

		'--only-deploy-env')
			export HALCYON_ONLY_DEPLOY_ENV=1;;

		'--sandbox-extra-apps')
			shift
			expect_args sandbox_extra_apps -- "$@"
			export HALCYON_SANDBOX_EXTRA_APPS="${sandbox_extra_apps}";;
		'--sandbox-extra-apps='*)
			export HALCYON_SANDBOX_EXTRA_APPS="${1#*=}";;
		'--extra-sandbox-apps')
			shift
			expect_args sandbox_extra_apps -- "$@"
			export HALCYON_SANDBOX_EXTRA_APPS="${sandbox_extra_apps}";;
		'--extra-sandbox-apps='*)
			export HALCYON_SANDBOX_EXTRA_APPS="${1#*=}";;
		'--force-build-sandbox')
			export HALCYON_FORCE_BUILD_SANDBOX=1;;

		'--force-build-app')
			export HALCYON_FORCE_BUILD_APP=1;;

		'--slug-extra-apps')
			shift
			expect_args slug_extra_apps -- "$@"
			export HALCYON_SLUG_EXTRA_APPS="${slug_extra_apps}";;
		'--slug-extra-apps='*)
			export HALCYON_SLUG_EXTRA_APPS="${1#*=}";;
		'--extra-slug-apps')
			shift
			expect_args slug_extra_apps -- "$@"
			export HALCYON_SLUG_EXTRA_APPS="${slug_extra_apps}";;
		'--extra-slug-apps='*)
			export HALCYON_SLUG_EXTRA_APPS="${1#*=}";;
		'--no-restore-slug')
			export HALCYON_NO_RESTORE_SLUG=1;;
		'--no-archive-slug')
			export HALCYON_NO_ARCHIVE_SLUG=1;;

		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;
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
