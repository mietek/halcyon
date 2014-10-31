export HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

if ! [ -d "${HALCYON_TOP_DIR}/lib/bashmenot" ]; then
	echo '   *** ERROR: Cannot source bashmenot' >&2
	exit 1
fi

source "${HALCYON_TOP_DIR}/lib/bashmenot/bashmenot.sh"
source "${HALCYON_TOP_DIR}/src/deploy.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/constraints.sh"
source "${HALCYON_TOP_DIR}/src/app.sh"
source "${HALCYON_TOP_DIR}/src/slug.sh"
source "${HALCYON_TOP_DIR}/src/tag.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/paths.sh"
source "${HALCYON_TOP_DIR}/src/vars.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"


function halcyon_deploy () {
	expect_vars HALCYON_TARGET HALCYON_DEPLOY_ONLY_ENV

	export -a HALCYON_INTERNAL_ARGS
	handle_command_line "$@" || die

	if [ "${HALCYON_TARGET}" != 'sandbox' ] && [ "${HALCYON_TARGET}" != 'slug' ]; then
		die "Unexpected target: ${HALCYON_TARGET}"
	fi

	local cache_dir
	cache_dir=$( get_tmp_dir 'halcyon-cache' ) || die

	prepare_cache "${cache_dir}" || die

	if (( HALCYON_DEPLOY_ONLY_ENV )); then
		deploy_env '/dev/null' || return 1
	elif [ -z "${HALCYON_INTERNAL_ARGS[@]:+_}" ]; then
		if ! detect_app_label '.' >'/dev/null'; then
			HALCYON_DEPLOY_ONLY_ENV=1 deploy_env '/dev/null' || return 1
		else
			deploy_local_app '.' || return 1
		fi
	else
		local app_oid index
		index=0
		for app_oid in "${HALCYON_INTERNAL_ARGS[@]}"; do
			index=$(( index + 1 ))
			if (( index > 1 )); then
				log
				log
			fi

			deploy_app_oid "${app_oid}" || return 1
		done
	fi

	clean_cache "${cache_dir}" || die

	rm -rf "${cache_dir}" || die
}
