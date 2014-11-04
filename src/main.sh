set_halcyon_vars () {
	if ! (( ${HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED:-0} )); then
		export HALCYON_INTERNAL_VARS_SET_ONCE_AND_INHERITED=1

		export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon-cache}"
		export HALCYON_INSTALL_DIR="${HALCYON_INSTALL_DIR:-}"
		export HALCYON_RECURSIVE="${HALCYON_RECURSIVE:-0}"
		export HALCYON_TARGET="${HALCYON_TARGET:-slug}"
		export HALCYON_ONLY_DEPLOY_ENV="${HALCYON_ONLY_DEPLOY_ENV:-0}"
		export HALCYON_NO_COPY_LOCAL_SOURCE="${HALCYON_NO_COPY_LOCAL_SOURCE:-0}"
		export HALCYON_NO_BUILD_DEPENDENCIES="${HALCYON_NO_BUILD_DEPENDENCIES:-0}"
		export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
		export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"
		export HALCYON_NO_DELETE="${HALCYON_NO_DELETE:-0}"

		export HALCYON_GHC_VERSION="${HALCYON_GHC_VERSION:-}"
		export HALCYON_GHC_MAGIC_HASH="${HALCYON_GHC_MAGIC_HASH:-}"

		export HALCYON_CABAL_VERSION="${HALCYON_CABAL_VERSION:-}"
		export HALCYON_CABAL_MAGIC_HASH="${HALCYON_CABAL_MAGIC_HASH:-}"
		export HALCYON_CABAL_REPO="${HALCYON_CABAL_REPO:-}"

		export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
		export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
		export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
		export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"
		export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"
		export HALCYON_NO_CACHE="${HALCYON_NO_CACHE:-0}"
		export HALCYON_NO_PUBLIC_STORAGE="${HALCYON_NO_PUBLIC_STORAGE:-0}"
	fi

	if ! (( ${HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET:-0} )); then
		export HALCYON_INTERNAL_VARS_INHERITED_ONCE_AND_RESET=1

		export HALCYON_CONSTRAINTS_DIR="${HALCYON_CONSTRAINTS_DIR:-}"
		export HALCYON_FORCE_RESTORE_ALL="${HALCYON_FORCE_RESTORE_ALL:-0}"
		export HALCYON_NO_ANNOUNCE_DEPLOY="${HALCYON_NO_ANNOUNCE_DEPLOY:-0}"

		export HALCYON_GHC_PRE_BUILD_HOOK="${HALCYON_GHC_PRE_BUILD_HOOK:-}"
		export HALCYON_GHC_POST_BUILD_HOOK="${HALCYON_GHC_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_BUILD_GHC="${HALCYON_FORCE_BUILD_GHC:-0}"

		export HALCYON_CABAL_PRE_BUILD_HOOK="${HALCYON_CABAL_PRE_BUILD_HOOK:-}"
		export HALCYON_CABAL_POST_BUILD_HOOK="${HALCYON_CABAL_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_BUILD_CABAL="${HALCYON_FORCE_BUILD_CABAL:-0}"
		export HALCYON_FORCE_UPDATE_CABAL="${HALCYON_FORCE_UPDATE_CABAL:-0}"

		export HALCYON_SANDBOX_EXTRA_LIBS="${HALCYON_SANDBOX_EXTRA_LIBS:-}"
		export HALCYON_SANDBOX_EXTRA_APPS="${HALCYON_SANDBOX_EXTRA_APPS:-}"
		export HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR="${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR:-}"
		export HALCYON_SANDBOX_PRE_BUILD_HOOK="${HALCYON_SANDBOX_PRE_BUILD_HOOK:-}"
		export HALCYON_SANDBOX_POST_BUILD_HOOK="${HALCYON_SANDBOX_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_BUILD_SANDBOX="${HALCYON_FORCE_BUILD_SANDBOX:-0}"

		export HALCYON_APP_EXTRA_CONFIGURE_FLAGS="${HALCYON_APP_EXTRA_CONFIGURE_FLAGS:-}"
		export HALCYON_APP_PRE_BUILD_HOOK="${HALCYON_APP_PRE_BUILD_HOOK:-}"
		export HALCYON_APP_POST_BUILD_HOOK="${HALCYON_APP_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_BUILD_APP="${HALCYON_FORCE_BUILD_APP:-0}"

		export HALCYON_SLUG_EXTRA_APPS="${HALCYON_SLUG_EXTRA_APPS:-}"
		export HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR="${HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR:-}"
		export HALCYON_SLUG_PRE_BUILD_HOOK="${HALCYON_SLUG_PRE_BUILD_HOOK:-}"
		export HALCYON_SLUG_POST_BUILD_HOOK="${HALCYON_SLUG_POST_BUILD_HOOK:-}"
		export HALCYON_FORCE_BUILD_SLUG="${HALCYON_FORCE_BUILD_SLUG:-0}"
	else
		export HALCYON_CONSTRAINTS_DIR=''
		export HALCYON_FORCE_RESTORE_ALL=0
		export HALCYON_NO_ANNOUNCE_DEPLOY=0

		export HALCYON_GHC_PRE_BUILD_HOOK=''
		export HALCYON_GHC_POST_BUILD_HOOK=''
		export HALCYON_FORCE_BUILD_GHC=0

		export HALCYON_CABAL_PRE_BUILD_HOOK=''
		export HALCYON_CABAL_POST_BUILD_HOOK=''
		export HALCYON_FORCE_BUILD_CABAL=0
		export HALCYON_FORCE_UPDATE_CABAL=0

		export HALCYON_SANDBOX_EXTRA_LIBS=''
		export HALCYON_SANDBOX_EXTRA_APPS=''
		export HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR=''
		export HALCYON_SANDBOX_PRE_BUILD_HOOK=''
		export HALCYON_SANDBOX_POST_BUILD_HOOK=''
		export HALCYON_FORCE_BUILD_SANDBOX=0

		export HALCYON_APP_EXTRA_CONFIGURE_FLAGS=''
		export HALCYON_APP_PRE_BUILD_HOOK=''
		export HALCYON_APP_POST_BUILD_HOOK=''
		export HALCYON_FORCE_BUILD_APP=0

		export HALCYON_SLUG_EXTRA_APPS=''
		export HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR=''
		export HALCYON_SLUG_PRE_BUILD_HOOK=''
		export HALCYON_SLUG_POST_BUILD_HOOK=''
		export HALCYON_FORCE_BUILD_SLUG=0
	fi
}


halcyon_main () {
	local cmd
	local -a args
	cmd=''

	while (( $# )); do
		case "$1" in
		# Paths:
		'--halcyon-dir')
			shift
			expect_args halcyon_dir -- "$@"
			export HALCYON_DIR="${halcyon_dir}";;
		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;

		# Vars set once and inherited:
		'--cache-dir')
			shift
			expect_args cache_dir -- "$@"
			export HALCYON_CACHE_DIR="${cache_dir}";;
		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;
		'--install-dir')
			shift
			expect_args install_dir -- "$@"
			export HALCYON_INSTALL_DIR="${install_dir}";;
		'--install-dir='*)
			export HALCYON_INSTALL_DIR="${1#*=}";;
		'--recursive')
			export HALCYON_RECURSIVE=1;;
		'--target')
			shift
			expect_args target -- "$@"
			export HALCYON_TARGET="${target}";;
		'--target='*)
			export HALCYON_TARGET="${1#*=}";;
		'--only-deploy-env')
			export HALCYON_ONLY_DEPLOY_ENV=1;;
		'--no-copy-local-source')
			export HALCYON_NO_COPY_LOCAL_SOURCE=1;;
		'--no-build-dependencies')
			export HALCYON_NO_BUILD_DEPENDENCIES=1;;
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;
		'--no-delete')
			export HALCYON_NO_DELETE=1;;

		'--ghc-version')
			shift
			expect_args ghc_version -- "$@"
			export HALCYON_GHC_VERSION="${ghc_version}";;
		'--ghc-version='*)
			export HALCYON_GHC_VERSION="${1#*=}";;
		'--ghc-magic-hash')
			shift
			expect_args ghc_magic_hash -- "$@"
			export HALCYON_GHC_MAGIC_HASH="${ghc_magic_hash}";;
		'--ghc-magic-hash='*)
			export HALCYON_GHC_MAGIC_HASH="${1#*=}";;

		'--cabal-version')
			shift
			expect_args cabal_version -- "$@"
			export HALCYON_CABAL_VERSION="${cabal_version}";;
		'--cabal-version='*)
			export HALCYON_CABAL_VERSION="${1#*=}";;
		'--cabal-magic-hash')
			shift
			expect_args cabal_magic_hash -- "$@"
			export HALCYON_CABAL_MAGIC_HASH="${cabal_magic_hash}";;
		'--cabal-magic-hash='*)
			export HALCYON_CABAL_MAGIC_HASH="${1#*=}";;
		'--cabal-repo')
			shift
			expect_args cabal_repo -- "$@"
			export HALCYON_CABAL_REPO="${cabal_repo}";;
		'--cabal-repo='*)
			export HALCYON_CABAL_REPO="${1#*=}";;

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
		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;
		'--no-cache')
			export HALCYON_NO_CACHE=1;;
		'--no-public-storage')
			export HALCYON_NO_PUBLIC_STORAGE=1;;

		# Vars inherited once and reset:
		'--constraints-dir')
			shift
			expect_args constraints_dir -- "$@"
			export HALCYON_CONSTRAINTS_DIR="${constraints_dir}";;
		'--constraints-dir='*)
			export HALCYON_CONSTRAINTS_DIR="${1#*=}";;
		'--force-restore-all')
			export HALCYON_FORCE_RESTORE_ALL=1;;
		'--no-announce-deploy')
			export HALCYON_NO_ANNOUNCE_DEPLOY=1;;

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
		'--force-build-ghc')
			export HALCYON_FORCE_BUILD_GHC=1;;

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
		'--force-build-cabal')
			export HALCYON_FORCE_BUILD_CABAL=1;;
		'--force-update-cabal')
			export HALCYON_FORCE_UPDATE_CABAL=1;;

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
		'--force-build-sandbox')
			export HALCYON_FORCE_BUILD_SANDBOX=1;;

		'--app-extra-configure-flags')
			shift
			expect_args app_extra_configure_flags -- "$@"
			export HALCYON_APP_EXTRA_CONFIGURE_FLAGS="${app_extra_configure_flags}";;
		'--app-extra-configure-flags='*)
			export HALCYON_APP_EXTRA_CONFIGURE_FLAGS="${1#*=}";;
		'--app-pre-build-hook')
			shift
			expect_args app_pre_build_hook -- "$@"
			export HALCYON_APP_PRE_BUILD_HOOK="${app_pre_build_hook}";;
		'--app-pre-build-hook='*)
			export HALCYON_APP_PRE_BUILD_HOOK="${1#*=}";;
		'--app-post-build-hook')
			shift
			expect_args app_post_build_hook -- "$@"
			export HALCYON_APP_POST_BUILD_HOOK="${app_post_build_hook}";;
		'--app-post-build-hook='*)
			export HALCYON_APP_POST_BUILD_HOOK="${1#*=}";;
		'--force-build-app')
			export HALCYON_FORCE_BUILD_APP=1;;

		'--slug-extra-apps')
			shift
			expect_args slug_extra_apps -- "$@"
			export HALCYON_SLUG_EXTRA_APPS="${slug_extra_apps}";;
		'--slug-extra-apps='*)
			export HALCYON_SLUG_EXTRA_APPS="${1#*=}";;
		'--slug-extra-apps-constraints-dir')
			shift
			expect_args slug_extra_apps_constraints_dir -- "$@"
			export HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR="${slug_extra_apps_constraints_dir}";;
		'--slug-extra-apps-constraints-dir='*)
			export HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR="${1#*=}";;
		'--slug-pre-build-hook')
			shift
			expect_args slug_pre_build_hook -- "$@"
			export HALCYON_SLUG_PRE_BUILD_HOOK="${slug_pre_build_hook}";;
		'--slug-pre-build-hook='*)
			export HALCYON_SLUG_PRE_BUILD_HOOK="${1#*=}";;
		'--slug-post-build-hook')
			shift
			expect_args slug_post_build_hook -- "$@"
			export HALCYON_SLUG_POST_BUILD_HOOK="${slug_post_build_hook}";;
		'--slug-post-build-hook='*)
			export HALCYON_SLUG_POST_BUILD_HOOK="${1#*=}";;
		'--force-build-slug')
			export HALCYON_FORCE_BUILD_SLUG=1;;

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

	if [[ "${HALCYON_TARGET}" != 'sandbox' && "${HALCYON_TARGET}" != 'slug' ]]; then
		die "Unexpected target: ${HALCYON_TARGET}"
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
	'show-paths')
		cat "${HALCYON_TOP_DIR}/src/paths.sh" || die
		;;
	'show-app-label')
		HALCYON_INTERNAL_ONLY_SHOW_APP_LABEL=1 \
			halcyon_deploy "${args[@]:-}" || return 1
		;;
	'show-constraints')
		HALCYON_INTERNAL_ONLY_SHOW_CONSTRAINTS=1 \
			halcyon_deploy "${args[@]:-}" || return 1
		;;
	'show-tag')
		HALCYON_INTERNAL_ONLY_SHOW_TAG=1 \
			halcyon_deploy "${args[@]:-}" || return 1
		;;
	*)
		log_error "Unexpected command: ${cmd} ${args[*]:-}"
		help_usage
		die
	esac
}
