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
source "${HALCYON_TOP_DIR}/src/cache.sh"
source "${HALCYON_TOP_DIR}/src/paths.sh"
source "${HALCYON_TOP_DIR}/src/vars.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"


function halcyon_deploy () {
	expect_vars HALCYON_TARGET HALCYON_ONLY_ENV

	export -a HALCYON_INTERNAL_ARGS
	handle_command_line "$@" || die

	if [ "${HALCYON_TARGET}" != 'sandbox' ] &&
		[ "${HALCYON_TARGET}" != 'slug' ]
	then
		die "Unexpected target: ${HALCYON_TARGET}"
	fi

	local env_tag
	env_tag=$( create_env_tag ) || die

	if (( HALCYON_ONLY_ENV )); then
		deploy_env "${env_tag}" || return 1
	elif [ -z "${HALCYON_INTERNAL_ARGS[@]:+_}" ]; then
		if ! detect_app_label '.'; then
			deploy_env "${env_tag}" || return 1
		else
			deploy_local_app "${env_tag}" '.' || return 1
		fi
	elif (( ${#HALCYON_INTERNAL_ARGS[@]} == 1 )); then
		deploy_thing "${env_tag}" "${HALCYON_INTERNAL_ARGS[0]}" || return 1
	else
		local index
		index=0
		for thing in "${HALCYON_INTERNAL_ARGS[@]}"; do
			index=$(( index + 1 ))
			if (( index == 1 )); then
				HALCYON_NO_CLEAN_CACHE=1 \
					deploy_thing "${env_tag}" "${thing}" || return 1
			else
				log
				log
				if (( index == ${#HALCYON_INTERNAL_ARGS[@]} )); then
					HALCYON_NO_PREPARE_CACHE=1 \
						deploy_thing "${env_tag}" "${thing}" || return 1
				else
					HALCYON_NO_PREPARE_CACHE=1 \
					HALCYON_NO_CLEAN_CACHE=1   \
						deploy_thing "${env_tag}" "${thing}" || return 1
				fi
			fi
		done
	fi
}
