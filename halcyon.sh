export HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

if ! [ -d "${HALCYON_TOP_DIR}/lib/bashmenot" ]; then
	echo '   *** ERROR: Cannot source bashmenot' >&2
	exit 1
fi

source "${HALCYON_TOP_DIR}/lib/bashmenot/bashmenot.sh"
source "${HALCYON_TOP_DIR}/src/deploy.sh"
source "${HALCYON_TOP_DIR}/src/detect.sh"
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


function format_fake_base_package () {
	local base_version
	expect_args base_version -- "$@"

	cat <<-EOF
		name:           halcyon-fake-base
		version:        ${base_version}
		build-type:     Simple
		cabal-version:  >= 1.2

		executable halcyon-fake-base
		  build-depends:  base == ${base_version}
EOF
}


function deploy_local_app () {
	local local_dir
	expect_args local_dir -- "$@"

	log 'Deploying local app'

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die
	copy_entire_contents "${local_dir}" "${source_dir}" || die

	local app_name app_version
	if ! app_name=$( detect_app_name "${source_dir}" ) ||
		! app_version=$( detect_app_version "${source_dir}" )
	then
		log_error 'Cannot detect app label'
		return 1
	fi

	if ! deploy_app "${app_name}-${app_version}" "${source_dir}"; then
		log_error 'Cannot deploy local app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_cloned_app () {
	local url
	expect_args url -- "$@"

	log 'Deploying cloned app'

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die
	if ! git clone --depth=1 --quiet "${url}" "${source_dir}"; then
		log_error 'Cannot locate cloned app'
		return 1
	fi

	local app_name app_version
	if ! app_name=$( detect_app_name "${source_dir}" ) ||
		! app_version=$( detect_app_version "${source_dir}" )
	then
		log_error 'Cannot detect app label'
		return 1
	fi

	if ! deploy_app "${app_name}-${app_version}" "${source_dir}"; then
		log_error 'Cannot deploy cloned app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_base_package () {
	expect_vars HALCYON_DIR HALCYON_NO_PREPARE_CACHE

	local thing
	expect_args thing -- "$@"

	local no_prepare_cache
	no_prepare_cache="${HALCYON_NO_PREPARE_CACHE}"
	if ! [ -f "${HALCYON_DIR}/ghc/.halcyon-tag" ] ||
		! [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ]
	then
		log 'Deploying default environment'

		if ! HALCYON_ONLY_ENV=1   \
			HALCYON_NO_CLEAN_CACHE=1   \
			HALCYON_NO_WARN_IMPLICIT=1 \
				deploy_app '' '/dev/null'
		then
			log_error 'Cannot deploy default environment'
			return 1
		fi
		log
		no_prepare_cache=1
	fi

	log 'Deploying base package'

	local base_version
	if [ "${thing}" = 'base' ]; then
		if ! base_version=$( ghc_detect_base_package_version ); then
			log_error 'Cannot detect base package version'
			return 1
		fi
		if ! (( HALCYON_NO_WARN_IMPLICIT )); then
			log_warning 'Using implicit base package version'
			log_warning 'Expected app label with explicit version'
		fi
	else
		base_version="${thing#base-}"
	fi

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die

	mkdir -p "${source_dir}" || die
	format_fake_base_package "${base_version}" >"${source_dir}/halcyon-fake-base.cabal" || die

	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		HALCYON_ONLY_ENV=1                          \
		HALCYON_NO_WARN_IMPLICIT=1                  \
			deploy_app "base-${base_version}" "${source_dir}"
	then
		log_error 'Cannot deploy base package'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_published_app () {
	expect_vars HALCYON_DIR HALCYON_NO_PREPARE_CACHE

	local thing
	expect_args thing -- "$@"

	local no_prepare_cache
	no_prepare_cache="${HALCYON_NO_PREPARE_CACHE}"
	if ! [ -f "${HALCYON_DIR}/ghc/.halcyon-tag" ] ||
		! [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ]
	then
		log 'Deploying default environment'

		if ! HALCYON_ONLY_ENV=1            \
			HALCYON_NO_CLEAN_CACHE=1   \
			HALCYON_NO_WARN_IMPLICIT=1 \
				deploy_app '' '/dev/null'
		then
			log_error 'Cannot deploy default environment'
			return 1
		fi
		log
		no_prepare_cache=1
	fi

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die

	log 'Deploying published app'

	mkdir -p "${source_dir}" || die

	local app_label
	if ! app_label=$(
		cabal_do "${source_dir}" unpack "${thing}" 2>'/dev/null' |
		filter_last |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		log_error 'Cannot locate published app'
		return 1
	fi

	local app_name app_version
	app_name="${app_label%-*}"
	app_version="${app_label##*-}"
	if [ "${thing}" = "${app_name}" ] && ! (( HALCYON_NO_WARN_IMPLICIT )); then
		log_warning "Using newest available version of ${app_name}"
		log_warning 'Expected app label with explicit version'
	fi

	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		HALCYON_NO_WARN_IMPLICIT=1                  \
		deploy_app "${app_label}" "${source_dir}/${app_label}"
	then
		log_error 'Cannot deploy published app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_thing () {
	local thing
	expect_args thing -- "$@"

	case "${thing}" in
	'base');&
	'base-'[0-9]*)
		deploy_base_package "${thing}" || return 1
		;;
	'https://'*);&
	'ssh://'*);&
	'git@'*);&
	'file://'*);&
	'http://'*);&
	'git://'*)
		deploy_cloned_app "${thing}" || return 1
		;;
	*)
		if [ -d "${thing}" ]; then
			deploy_local_app "${thing%/}" || return 1
		else
			deploy_published_app "${thing}" || return 1
		fi
	esac
}


function halcyon_deploy () {
	export -a HALCYON_INTERNAL_ARGS
	handle_command_line "$@" || die

	if [ -z "${HALCYON_INTERNAL_ARGS[@]:+_}" ]; then
		deploy_local_app '.' || return 1
	elif (( ${#HALCYON_INTERNAL_ARGS[@]} == 1 )); then
		deploy_thing "${HALCYON_INTERNAL_ARGS[0]}" || return 1
	else
		local index
		index=0
		for thing in "${HALCYON_INTERNAL_ARGS[@]}"; do
			index=$(( index + 1 ))
			if (( index == 1 )); then
				HALCYON_NO_CLEAN_CACHE=1 \
					deploy_thing "${thing}" || return 1
			else
				log
				log
				if (( index == ${#HALCYON_INTERNAL_ARGS[@]} )); then
					HALCYON_NO_PREPARE_CACHE=1 \
						deploy_thing "${thing}" || return 1
				else
					HALCYON_NO_PREPARE_CACHE=1 \
					HALCYON_NO_CLEAN_CACHE=1   \
						deploy_thing "${thing}" || return 1
				fi
			fi
		done
	fi
}
