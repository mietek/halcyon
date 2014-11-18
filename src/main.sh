set_halcyon_vars () {
	# NOTE: Recursive vars are set once and inherited.

	if ! (( ${HALCYON_INTERNAL_RECURSIVE_VARS:-0} )); then
		export HALCYON_INTERNAL_RECURSIVE_VARS=1

		# NOTE: HALCYON_APP_DIR is set in paths.sh.

		export HALCYON_ROOT_DIR="${HALCYON_ROOT_DIR:-/}"
		export HALCYON_TARGET="${HALCYON_TARGET:-}"
		export HALCYON_NO_APP="${HALCYON_NO_APP:-0}"
		export HALCYON_NO_BUILD_DEPENDENCIES="${HALCYON_NO_BUILD_DEPENDENCIES:-0}"
		export HALCYON_NO_BUILD_ANY="${HALCYON_NO_BUILD_ANY:-0}"
		export HALCYON_NO_ARCHIVE_ANY="${HALCYON_NO_ARCHIVE_ANY:-0}"
		export HALCYON_NO_UPLOAD_ANY="${HALCYON_NO_UPLOAD_ANY:-0}"
		export HALCYON_NO_DELETE_ANY="${HALCYON_NO_DELETE_ANY:-0}"

		export HALCYON_PUBLIC_STORAGE_URL="${HALCYON_PUBLIC_STORAGE_URL:-https://s3.halcyon.sh}"
		export HALCYON_NO_PUBLIC_STORAGE="${HALCYON_NO_PUBLIC_STORAGE:-0}"

		export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
		export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
		export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
		export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"
		export HALCYON_S3_HOST="${HALCYON_S3_HOST:-s3.amazonaws.com}"
		export HALCYON_NO_PRIVATE_STORAGE="${HALCYON_NO_PRIVATE_STORAGE:-0}"

		export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon-cache}"
		export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"
		export HALCYON_NO_CLEAN_CACHE="${HALCYON_NO_CLEAN_CACHE:-0}"

		export HALCYON_GHC_VERSION="${HALCYON_GHC_VERSION:-7.8.3}"

		# NOTE: Cabal does not support HTTPS repository URLs.
		# https://github.com/haskell/cabal/issues/936

		export HALCYON_CABAL_VERSION="${HALCYON_CABAL_VERSION:-1.20.0.3}"
		export HALCYON_CABAL_REPO="${HALCYON_CABAL_REPO:-Hackage:http://hackage.haskell.org/packages/archive}"

		export HALCYON_INTERNAL_RECURSIVE="${HALCYON_INTERNAL_RECURSIVE:-0}"
		export HALCYON_INTERNAL_NONLOCAL_SOURCE="${HALCYON_INTERNAL_NONLOCAL_SOURCE:-0}"
		export HALCYON_INTERNAL_ONLY_LABEL="${HALCYON_INTERNAL_ONLY_LABEL:-0}"
		export HALCYON_INTERNAL_ONLY_CONSTRAINTS="${HALCYON_INTERNAL_ONLY_CONSTRAINTS:-0}"
		export HALCYON_INTERNAL_ONLY_TAG="${HALCYON_INTERNAL_ONLY_TAG:-0}"
		export HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE="${HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE:-0}"
		export HALCYON_INTERNAL_NO_PURGE_APP_DIR="${HALCYON_INTERNAL_NO_PURGE_APP_DIR:-0}"
		export HALCYON_INTERNAL_GHC_MAGIC_HASH="${HALCYON_INTERNAL_GHC_MAGIC_HASH:-}"
		export HALCYON_INTERNAL_CABAL_MAGIC_HASH="${HALCYON_INTERNAL_CABAL_MAGIC_HASH:-}"
	fi

	# NOTE: Non-recursive vars are inherited once, then reset to default.

	if ! (( ${HALCYON_INTERNAL_NONRECURSIVE_VARS:-0} )); then
		export HALCYON_INTERNAL_NONRECURSIVE_VARS=1

		export HALCYON_CONSTRAINTS_FILE="${HALCYON_CONSTRAINTS_FILE:-}"
		export HALCYON_CONSTRAINTS_DIR="${HALCYON_CONSTRAINTS_DIR:-}"
		export HALCYON_CUSTOM_PREFIX="${HALCYON_CUSTOM_PREFIX:-}"
		export HALCYON_EXTRA_CONFIGURE_FLAGS="${HALCYON_EXTRA_CONFIGURE_FLAGS:-}"
		export HALCYON_EXTRA_APPS="${HALCYON_EXTRA_APPS:-}"
		export HALCYON_EXTRA_APPS_CONSTRAINTS_DIR="${HALCYON_EXTRA_APPS_CONSTRAINTS_DIR:-}"
		export HALCYON_PRE_BUILD_HOOK="${HALCYON_PRE_BUILD_HOOK:-}"
		export HALCYON_POST_BUILD_HOOK="${HALCYON_POST_BUILD_HOOK:-}"
		export HALCYON_PRE_INSTALL_HOOK="${HALCYON_PRE_INSTALL_HOOK:-}"
		export HALCYON_POST_INSTALL_HOOK="${HALCYON_POST_INSTALL_HOOK:-}"
		export HALCYON_INCLUDE_SOURCE="${HALCYON_INCLUDE_SOURCE:-0}"
		export HALCYON_INCLUDE_BUILD="${HALCYON_INCLUDE_BUILD:-0}"
		export HALCYON_INCLUDE_ALL="${HALCYON_INCLUDE_ALL:-0}"
		export HALCYON_FORCE_CONFIGURE="${HALCYON_FORCE_CONFIGURE:-0}"
		export HALCYON_FORCE_CLEAN_REBUILD="${HALCYON_FORCE_CLEAN_REBUILD:-0}"

		export HALCYON_GHC_PRE_BUILD_HOOK="${HALCYON_GHC_PRE_BUILD_HOOK:-}"
		export HALCYON_GHC_POST_BUILD_HOOK="${HALCYON_GHC_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_CLEAN_REBUILD_GHC="${HALCYON_FORCE_CLEAN_REBUILD_GHC:-0}"

		export HALCYON_CABAL_PRE_BUILD_HOOK="${HALCYON_CABAL_PRE_BUILD_HOOK:-}"
		export HALCYON_CABAL_POST_BUILD_HOOK="${HALCYON_CABAL_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_CLEAN_REBUILD_CABAL="${HALCYON_FORCE_CLEAN_REBUILD_CABAL:-0}"
		export HALCYON_FORCE_UPDATE_CABAL="${HALCYON_FORCE_UPDATE_CABAL:-0}"

		export HALCYON_SANDBOX_SOURCES="${HALCYON_SANDBOX_SOURCES:-}"
		export HALCYON_SANDBOX_EXTRA_LIBS="${HALCYON_SANDBOX_EXTRA_LIBS:-}"
		export HALCYON_SANDBOX_EXTRA_APPS="${HALCYON_SANDBOX_EXTRA_APPS:-}"
		export HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR="${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR:-}"
		export HALCYON_SANDBOX_PRE_BUILD_HOOK="${HALCYON_SANDBOX_PRE_BUILD_HOOK:-}"
		export HALCYON_SANDBOX_POST_BUILD_HOOK="${HALCYON_SANDBOX_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_CLEAN_REBUILD_SANDBOX="${HALCYON_FORCE_CLEAN_REBUILD_SANDBOX:-0}"

		export HALCYON_INTERNAL_FORCE_RESTORE_ALL="${HALCYON_INTERNAL_FORCE_RESTORE_ALL:-0}"
		export HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY="${HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY:-0}"
	else
		export HALCYON_CONSTRAINTS_FILE=''
		export HALCYON_CONSTRAINTS_DIR=''
		export HALCYON_CUSTOM_PREFIX=''
		export HALCYON_EXTRA_CONFIGURE_FLAGS=''
		export HALCYON_EXTRA_APPS=''
		export HALCYON_EXTRA_APPS_CONSTRAINTS_DIR=''
		export HALCYON_PRE_BUILD_HOOK=''
		export HALCYON_POST_BUILD_HOOK=''
		export HALCYON_PRE_INSTALL_HOOK=''
		export HALCYON_POST_INSTALL_HOOK=''
		export HALCYON_INCLUDE_SOURCE=0
		export HALCYON_INCLUDE_BUILD=0
		export HALCYON_INCLUDE_ALL=0
		export HALCYON_FORCE_CONFIGURE=0
		export HALCYON_FORCE_CLEAN_REBUILD=0

		export HALCYON_GHC_PRE_BUILD_HOOK=''
		export HALCYON_GHC_POST_BUILD_HOOK=''
		export HALCYON_FORCE_CLEAN_REBUILD_GHC=0

		export HALCYON_CABAL_PRE_BUILD_HOOK=''
		export HALCYON_CABAL_POST_BUILD_HOOK=''
		export HALCYON_FORCE_CLEAN_REBUILD_CABAL=0
		export HALCYON_FORCE_UPDATE_CABAL=0

		export HALCYON_SANDBOX_SOURCES=''
		export HALCYON_SANDBOX_EXTRA_LIBS=''
		export HALCYON_SANDBOX_EXTRA_APPS=''
		export HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR=''
		export HALCYON_SANDBOX_PRE_BUILD_HOOK=''
		export HALCYON_SANDBOX_POST_BUILD_HOOK=''
		export HALCYON_FORCE_CLEAN_REBUILD_SANDBOX=0

		export HALCYON_INTERNAL_FORCE_RESTORE_ALL=0
		export HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY=0
	fi
}


halcyon_main () {
	local cmd
	local -a args
	cmd=''

	while (( $# )); do
		case "$1" in
	# Options:
		'--app-dir')
			shift
			expect_args app_dir -- "$@"
			export HALCYON_APP_DIR="${app_dir}";;
		'--app-dir='*)
			export HALCYON_APP_DIR="${1#*=}";;
		'--root-dir')
			shift
			expect_args root_dir -- "$@"
			export HALCYON_ROOT_DIR="${root_dir}";;
		'--root-dir='*)
			export HALCYON_ROOT_DIR="${1#*=}";;
		'--target')
			shift
			expect_args target -- "$@"
			export HALCYON_TARGET="${target}";;
		'--target='*)
			export HALCYON_TARGET="${1#*=}";;
		'--no-app')
			export HALCYON_NO_APP=1;;
		'--no-build-dependencies')
			export HALCYON_NO_BUILD_DEPENDENCIES=1;;
		'--no-build-any')
			export HALCYON_NO_BUILD_ANY=1;;
		'--no-archive-any')
			export HALCYON_NO_ARCHIVE_ANY=1;;
		'--no-upload-any')
			export HALCYON_NO_UPLOAD_ANY=1;;
		'--no-delete-any')
			export HALCYON_NO_DELETE_ANY=1;;

	# Public storage options:
		'--public-storage-url')
			shift
			expect_args public_storage_url -- "$@"
			export HALCYON_PUBLIC_STORAGE_URL="${public_storage_url}";;
		'--public-storage-url='*)
			export HALCYON_PUBLIC_STORAGE_URL="${1#*=}";;
		'--no-public-storage')
			export HALCYON_NO_PUBLIC_STORAGE=1;;

	# Private storage options:
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
		'--s3-host')
			shift
			expect_args s3_host -- "$@"
			export HALCYON_S3_HOST="${s3_host}";;
		'--s3-host='*)
			export HALCYON_S3_HOST="${1#*=}";;
		'--no-private-storage')
			export HALCYON_NO_PRIVATE_STORAGE=1;;

	# Cache options:
		'--cache-dir')
			shift
			expect_args cache_dir -- "$@"
			export HALCYON_CACHE_DIR="${cache_dir}";;
		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;
		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;
		'--no-clean-cache')
			export HALCYON_NO_CLEAN_CACHE=1;;

	# GHC layer options:
		'--ghc-version')
			shift
			expect_args ghc_version -- "$@"
			export HALCYON_GHC_VERSION="${ghc_version}";;
		'--ghc-version='*)
			export HALCYON_GHC_VERSION="${1#*=}";;

	# Cabal layer options:
		'--cabal-version')
			shift
			expect_args cabal_version -- "$@"
			export HALCYON_CABAL_VERSION="${cabal_version}";;
		'--cabal-version='*)
			export HALCYON_CABAL_VERSION="${1#*=}";;
		'--cabal-repo')
			shift
			expect_args cabal_repo -- "$@"
			export HALCYON_CABAL_REPO="${cabal_repo}";;
		'--cabal-repo='*)
			export HALCYON_CABAL_REPO="${1#*=}";;

	# Non-recursive options:
		'--constraints-file')
			shift
			expect_args constraints_file -- "$@"
			export HALCYON_CONSTRAINTS_FILE="${constraints_file}";;
		'--constraints-file='*)
			export HALCYON_CONSTRAINTS_FILE="${1#*=}";;
		'--constraints-dir')
			shift
			expect_args constraints_dir -- "$@"
			export HALCYON_CONSTRAINTS_DIR="${constraints_dir}";;
		'--constraints-dir='*)
			export HALCYON_CONSTRAINTS_DIR="${1#*=}";;
		'--custom-prefix')
			shift
			expect_args custom_prefix -- "$@"
			export HALCYON_CUSTOM_PREFIX="${custom_prefix}";;
		'--custom-prefix='*)
			export HALCYON_CUSTOM_PREFIX="${1#*=}";;
		'--extra-configure-flags')
			shift
			expect_args extra_configure_flags -- "$@"
			export HALCYON_EXTRA_CONFIGURE_FLAGS="${extra_configure_flags}";;
		'--extra-configure-flags='*)
			export HALCYON_EXTRA_CONFIGURE_FLAGS="${1#*=}";;
		'--extra-apps')
			shift
			expect_args extra_apps -- "$@"
			export HALCYON_EXTRA_APPS="${extra_apps}";;
		'--extra-apps='*)
			export HALCYON_EXTRA_APPS="${1#*=}";;
		'--extra-apps-constraints-dir')
			shift
			expect_args extra_apps_constraints_dir -- "$@"
			export HALCYON_EXTRA_APPS_CONSTRAINTS_DIR="${extra_apps_constraints_dir}";;
		'--extra-apps-constraints-dir='*)
			export HALCYON_EXTRA_APPS_CONSTRAINTS_DIR="${1#*=}";;
		'--pre-build-hook')
			shift
			expect_args pre_build_hook -- "$@"
			export HALCYON_PRE_BUILD_HOOK="${pre_build_hook}";;
		'--pre-build-hook='*)
			export HALCYON_PRE_BUILD_HOOK="${1#*=}";;
		'--post-build-hook')
			shift
			expect_args post_build_hook -- "$@"
			export HALCYON_POST_BUILD_HOOK="${post_build_hook}";;
		'--post-build-hook='*)
			export HALCYON_POST_BUILD_HOOK="${1#*=}";;
		'--pre-install-hook')
			shift
			expect_args pre_install_hook -- "$@"
			export HALCYON_PRE_INSTALL_HOOK="${pre_install_hook}";;
		'--pre-install-hook='*)
			export HALCYON_PRE_INSTALL_HOOK="${1#*=}";;
		'--post-install-hook')
			shift
			expect_args post_install_hook -- "$@"
			export HALCYON_POST_INSTALL_HOOK="${post_install_hook}";;
		'--post-install-hook='*)
			export HALCYON_POST_INSTALL_HOOK="${1#*=}";;
		'--include-source')
			export HALCYON_INCLUDE_SOURCE=1;;
		'--include-build')
			export HALCYON_INCLUDE_BUILD=1;;
		'--include-all')
			export HALCYON_INCLUDE_ALL=1;;
		'--force-configure')
			export HALCYON_FORCE_CONFIGURE=1;;
		'--force-clean-rebuild')
			export HALCYON_FORCE_CLEAN_REBUILD=1;;

	# Non-recursive GHC layer options:
		'--ghc-pre-build-hook')
			shift
			expect_args ghc_pre_build_hook -- "$@"
			export HALCYON_GHC_PRE_BUILD_HOOK="${ghc_pre_build_hook}";;
		'--ghc-pre-build-hook='*)
			export HALCYON_GHC_PRE_BUILD_HOOK="${1#*=}";;
		'--ghc-post-build-hook')
			shift
			expect_args ghc_post_build_hook -- "$@"
			export HALCYON_GHC_POST_BUILD_HOOK="${ghc_post_build_hook}";;
		'--ghc-post-build-hook='*)
			export HALCYON_GHC_POST_BUILD_HOOK="${1#*=}";;
		'--force-clean-rebuild-ghc')
			export HALCYON_FORCE_CLEAN_REBUILD_GHC=1;;

	# Non-recursive Cabal layer options:
		'--cabal-pre-build-hook')
			shift
			expect_args cabal_pre_build_hook -- "$@"
			export HALCYON_CABAL_PRE_BUILD_HOOK="${cabal_pre_build_hook}";;
		'--cabal-pre-build-hook='*)
			export HALCYON_CABAL_PRE_BUILD_HOOK="${1#*=}";;
		'--cabal-post-build-hook')
			shift
			expect_args cabal_post_build_hook -- "$@"
			export HALCYON_CABAL_POST_BUILD_HOOK="${cabal_post_build_hook}";;
		'--cabal-post-build-hook='*)
			export HALCYON_CABAL_POST_BUILD_HOOK="${1#*=}";;
		'--force-clean-rebuild-cabal')
			export HALCYON_FORCE_CLEAN_REBUILD_CABAL=1;;
		'--force-update-cabal')
			export HALCYON_FORCE_UPDATE_CABAL=1;;

	# Non-recursive sandbox layer options:
		'--sandbox-sources')
			shift
			expect_args sandbox_sources -- "$@"
			export HALCYON_SANDBOX_SOURCES="${sandbox_sources}";;
		'--sandbox-sources='*)
			export HALCYON_SANDBOX_SOURCES="${1#*=}";;
		'--sandbox-extra-libs')
			shift
			expect_args sandbox_extra_libs -- "$@"
			export HALCYON_SANDBOX_EXTRA_LIBS="${sandbox_extra_libs}";;
		'--sandbox-extra-libs='*)
			export HALCYON_SANDBOX_EXTRA_LIBS="${1#*=}";;
		'--sandbox-extra-apps')
			shift
			expect_args sandbox_extra_apps -- "$@"
			export HALCYON_SANDBOX_EXTRA_APPS="${sandbox_extra_apps}";;
		'--sandbox-extra-apps='*)
			export HALCYON_SANDBOX_EXTRA_APPS="${1#*=}";;
		'--sandbox-extra-apps-constraints-dir')
			shift
			expect_args sandbox_extra_apps_constraints_dir -- "$@"
			export HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR="${sandbox_extra_apps_constraints_dir}";;
		'--sandbox-extra-apps-constraints-dir='*)
			export HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR="${1#*=}";;
		'--sandbox-pre-build-hook')
			shift
			expect_args sandbox_pre_build_hook -- "$@"
			export HALCYON_SANDBOX_PRE_BUILD_HOOK="${sandbox_pre_build_hook}";;
		'--sandbox-pre-build-hook='*)
			export HALCYON_SANDBOX_PRE_BUILD_HOOK="${1#*=}";;
		'--sandbox-post-build-hook')
			shift
			expect_args sandbox_post_build_hook -- "$@"
			export HALCYON_SANDBOX_POST_BUILD_HOOK="${sandbox_post_build_hook}";;
		'--sandbox-post-build-hook='*)
			export HALCYON_SANDBOX_POST_BUILD_HOOK="${1#*=}";;
		'--force-clean-rebuild-sandbox')
			export HALCYON_FORCE_CLEAN_REBUILD_SANDBOX=1;;

		'--')
			shift
			while (( $# )); do
				if [[ -z "${cmd}" ]]; then
					cmd="$1"
				else
					args+=( "$1" )
				fi
				shift
			done
			;;
		'-'*)
			log_error "Unexpected option: $1"
			help_usage
			die
			;;
		*)
			if [[ -z "${cmd}" ]]; then
				cmd="$1"
			else
				args+=( "$1" )
			fi
		esac
		shift
	done

	case "${HALCYON_TARGET}" in
	'');&
	'sandbox');&
	'custom')
		true;;
	*)
		die "Unexpected target: ${HALCYON_TARGET}"
	esac

	# NOTE: HALCYON_CACHE_DIR must not be /tmp, as the cache
	# cleaning functionality will get confused.

	if [[ "${HALCYON_CACHE_DIR}" == '/tmp' ]]; then
		export HALCYON_CACHE_DIR='/tmp/halcyon-cache'
	fi

	if [[ -n "${HALCYON_CABAL_REPO}" ]]; then
		local repo_name
		repo_name="${HALCYON_CABAL_REPO%%:*}"
		if [[ -z "${repo_name}" ]]; then
			log_error "Unexpected Cabal repo: ${HALCYON_CABAL_REPO}"
			die "Expected Cabal repo: RepoName:${HALCYON_CABAL_REPO}"
		fi
	fi

	if [[ -n "${HALCYON_CUSTOM_PREFIX}" ]]; then
		export HALCYON_TARGET='custom'
	fi

	if [[ -z "${cmd}" ]]; then
		log_error 'Expected command'
		help_usage
		die
	fi

	case "${cmd}" in
	'deploy')
		halcyon_deploy "${args[@]:-}" || return 1
		;;
	'label')
		HALCYON_INTERNAL_ONLY_LABEL=1 \
			halcyon_deploy "${args[@]:-}" || return 1
		;;
	'constraints')
		HALCYON_INTERNAL_ONLY_CONSTRAINTS=1 \
			halcyon_deploy "${args[@]:-}" || return 1
		;;
	'tag')
		HALCYON_INTERNAL_ONLY_TAG=1 \
			halcyon_deploy "${args[@]:-}" || return 1
		;;
	'paths')
		echo -e "export HALCYON_TOP_DIR='${HALCYON_TOP_DIR}'\n"

		cat "${HALCYON_TOP_DIR}/src/paths.sh" || die
		;;
	*)
		log_error "Unexpected command: ${cmd} ${args[*]:-}"
		help_usage
		die
	esac
}
