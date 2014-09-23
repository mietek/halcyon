#!/usr/bin/env bash


set -o nounset
set -o pipefail

declare self_dir
self_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )
source "${self_dir}/lib/curl.sh"
source "${self_dir}/lib/expect.sh"
source "${self_dir}/lib/log.sh"
source "${self_dir}/lib/s3.sh"
source "${self_dir}/lib/tar.sh"
source "${self_dir}/lib/tools.sh"
source "${self_dir}/build.sh"
source "${self_dir}/cabal.sh"
source "${self_dir}/cache.sh"
source "${self_dir}/constraints.sh"
source "${self_dir}/ghc.sh"
source "${self_dir}/package.sh"
source "${self_dir}/sandbox.sh"
source "${self_dir}/transfer.sh"




function set_default_vars () {
	! (( ${HALCYON_DEFAULTS_SET:-0} )) || return 0
	export HALCYON_DEFAULTS_SET=1

	export HALCYON_DIR="${HALCYON_DIR:-/app/.halcyon}"
	export HALCYON_CONFIG_DIR="${HALCYON_CONFIG_DIR:-${HALCYON_DIR}/config}"
	export HALCYON_INSTALL_DIR="${HALCYON_INSTALL_DIR:-${HALCYON_DIR}/install}"
	export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon/cache}"

	export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"
	export HALCYON_FORCE_FAIL_INSTALL="${HALCYON_FORCE_FAIL_INSTALL:-0}"
	export HALCYON_DEPENDENCIES_ONLY="${HALCYON_DEPENDENCIES_ONLY:-0}"
	export HALCYON_PREPARED_ONLY="${HALCYON_PREPARED_ONLY:-0}"
	export HALCYON_FORCE_GHC_VERSION="${HALCYON_FORCE_GHC_VERSION:-}"
	export HALCYON_NO_CUT_GHC="${HALCYON_NO_CUT_GHC:-0}"
	export HALCYON_FORCE_CABAL_VERSION="${HALCYON_FORCE_CABAL_VERSION:-}"
	export HALCYON_FORCE_CABAL_UPDATE="${HALCYON_FORCE_CABAL_UPDATE:-0}"

	export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
	export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
	export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
	export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"

	export HALCYON_ONE_SHOT="${HALCYON_ONE_SHOT:-0}"
	export HALCYON_DRY_RUN="${HALCYON_DRY_RUN:-0}"
	export HALCYON_SILENT="${HALCYON_SILENT:-0}"

	export PATH="${HALCYON_DIR}/ghc/bin:${PATH}"
	export PATH="${HALCYON_DIR}/cabal/bin:${PATH}"
	export PATH="${HALCYON_DIR}/sandbox/bin:${PATH}"
	export PATH="${HALCYON_INSTALL_DIR}/bin:${PATH}"
	export LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LD_LIBRARY_PATH:-}"

	export LANG="${LANG:-en_US.UTF-8}"
}


set_default_vars




function set_config_vars () {
	expect_vars HALCYON_CONFIG_DIR

	log 'Setting config vars'

	local ignored_pattern secret_pattern
	ignored_pattern='GIT_DIR|PATH|LIBRARY_PATH|LD_LIBRARY_PATH|LD_PRELOAD'
	secret_pattern='HALCYON_AWS_SECRET_ACCESS_KEY|DATABASE_URL|.*_POSTGRESQL_.*_URL'

	local var
	for var in $(
		find_spaceless "${HALCYON_CONFIG_DIR}" -maxdepth 1 |
		sed "s:^${HALCYON_CONFIG_DIR}/::" |
		sort_naturally |
		filter_not_matching "^(${ignored_pattern})$"
	); do
		local value
		value=$( match_exactly_one <"${HALCYON_CONFIG_DIR}/${var}" ) || die
		if filter_matching "^(${secret_pattern})$" <<<"${var}" |
			match_exactly_one >'/dev/null'
		then
			log_indent "${var} (secret)"
		else
			log_indent "${var}=${value}"
		fi
		export "${var}=${value}" || die
	done
}




function halcyon_install () {
	expect_vars HALCYON_CONFIG_DIR HALCYON_FORCE_FAIL_INSTALL HALCYON_DEPENDENCIES_ONLY

	while (( $# )); do
		case "$1" in
		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;
		'--config-dir='*)
			export HALCYON_CONFIG_DIR="${1#*=}";;
		'--install-dir='*)
			export HALCYON_INSTALL_DIR="${1#*=}";;
		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;

		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;
		'--force-fail-install')
			export HALCYON_FORCE_FAIL_INSTALL=1;;
		'--dependencies-only');&
		'--dep-only');&
		'--only-dependencies');&
		'--only-dep')
			export HALCYON_DEPENDENCIES_ONLY=1;;
		'--prepared-only');&
		'--prep-only');&
		'--only-prepared');&
		'--only-prep')
			export HALCYON_PREPARED_ONLY=1;;
		'--force-ghc-version='*)
			export HALCYON_FORCE_GHC_VERSION="${1#*=}";;
		'--no-cut-ghc')
			export HALCYON_NO_CUT_GHC=1;;
		'--force-cabal-version='*)
			export HALCYON_FORCE_CABAL_VERSION="${1#*=}";;
		'--force-cabal-update')
			export HALCYON_FORCE_CABAL_UPDATE=1;;

		'--aws-access-key-id='*)
			export HALCYON_AWS_ACCESS_KEY_ID="${1#*=}";;
		'--aws-secret-access-key='*)
			export HALCYON_AWS_SECRET_ACCESS_KEY="${1#*=}";;
		'--s3-bucket='*)
			export HALCYON_S3_BUCKET="${1#*=}";;
		'--s3-acl='*)
			export HALCYON_S3_ACL="${1#*=}";;

		'--one-shot')
			export HALCYON_ONE_SHOT=1;;
		'--dry-run')
			export HALCYON_DRY_RUN=1;;
		'--silent')
			export HALCYON_SILENT=1;;

		'-'*)
			die "Unexpected option: $1";;
		*)
			break
		esac
		shift
	done

	local build_dir app_label
	if ! (( $# )); then
		build_dir='.'
		app_label=$( detect_app_label "${build_dir}" ) || die
	elif [ -d "$1" ]; then
		build_dir="$1"
		app_label=$( detect_app_label "${build_dir}" ) || die
	else
		export HALCYON_FAKE_BUILD=1
		app_label="$1"
		build_dir=''
	fi

	log "Installing ${app_label}"
	log

	if [ -d "${HALCYON_CONFIG_DIR}" ]; then
		set_config_vars || die
		log
	fi

	if (( ${HALCYON_FORCE_FAIL_INSTALL} )); then
		return 1
	fi

	prepare_cache || die
	log

	install_ghc "${build_dir}" || return 1
	log

	if (( ${HALCYON_FAKE_BUILD:-0} )); then
		build_dir=$( fake_build_dir "${app_label}" ) || die
	fi

	install_cabal || return 1
	log

	install_sandbox "${build_dir}" || return 1
	log

	if (( ${HALCYON_FAKE_BUILD:-0} )); then
		rm -rf "${build_dir}" || die
	elif ! (( ${HALCYON_DEPENDENCIES_ONLY} )); then
		local build_tag
		build_tag=$( infer_build_tag "${build_dir}" ) || die
		if ! restore_build "${build_dir}" "${build_tag}"; then
			configure_build "${build_dir}" || die
		fi
		build "${build_dir}" "${build_tag}" || die
		cache_build "${build_dir}" "${build_tag}" || die
		log
	fi

	clean_cache "${build_dir}" || die
	log

	log "Installed ${app_label}"
}




function log_add_config_help () {
	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log_file_indent <<-EOF
		To use explicit constraints, add cabal.config:
		$ cat >cabal.config <<EOF
EOF
	echo_constraints <<<"${sandbox_constraints}" >&2 || die
	echo 'EOF' >&2
}
