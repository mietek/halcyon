function detect_app_package () {
	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	local package_file
	package_file=$(
		find "${source_dir}" -type f -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	) || return 1

	cat "${package_file}"
}


function detect_app_name () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_name
	app_name=$(
		detect_app_package "${source_dir}" |
		awk '/^ *[Nn]ame:/ { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	echo "${app_name}"
}


function detect_app_version () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_version
	app_version=$(
		detect_app_package "${source_dir}" |
		awk '/^ *[Vv]ersion:/ { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	echo "${app_version}"
}


function detect_app_label () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_name app_version
	app_name=$( detect_app_name "${source_dir}" ) || return 1
	app_version=$( detect_app_version "${source_dir}" ) || return 1

	echo "${app_name}-${app_version}"
}


function detect_app_executable () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_executable
	app_executable=$(
		detect_app_package "${source_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	echo "${app_executable}"
}


function deploy_layers () {
	expect_vars HALCYON_DIR HALCYON_RECURSIVE HALCYON_ONLY_DEPLOY_ENV HALCYON_NO_RESTORE_SLUG HALCYON_NO_PREPARE_CACHE HALCYON_NO_CLEAN_CACHE

	local tag constraints source_dir
	expect_args tag constraints source_dir -- "$@"

	local target
	target=$( get_tag_target "${tag}" ) || die

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache || die
	fi

	if ! (( HALCYON_RECURSIVE )); then
		log
		install_ghc_layer "${tag}" "${source_dir}" || return 1
		log
		install_cabal_layer "${tag}" "${source_dir}" || return 1
	else
		if ! validate_ghc_layer "${tag}" >'/dev/null' ||
			! validate_updated_cabal_layer "${tag}" >'/dev/null'
		then
			die 'Cannot use existing environment'
		fi
	fi

	if ! (( HALCYON_ONLY_DEPLOY_ENV )); then
		if ! (( HALCYON_RECURSIVE )); then
			rm -rf "${HALCYON_DIR}/sandbox" "${HALCYON_DIR}/app" "${HALCYON_DIR}/slug" || die
		fi

		if ! (( HALCYON_NO_RESTORE_SLUG )); then
			log
			if restore_slug "${tag}"; then
				if ! (( HALCYON_RECURSIVE )) || [ "${target}" = 'sandbox' ]; then
					apply_slug "${tag}" || die
					return 0
				fi
			fi
		fi

		local saved_sandbox saved_app
		saved_sandbox=
		saved_app=
		if (( HALCYON_RECURSIVE )); then
			if [ -d "${HALCYON_DIR}/sandbox" ]; then
				saved_sandbox=$( get_tmp_dir 'halcyon.saved-sandbox' ) || die
				mv "${HALCYON_DIR}/sandbox" "${saved_sandbox}" || die
			fi
			if [ -d "${HALCYON_DIR}/app" ]; then
				saved_app=$( get_tmp_dir 'halcyon.saved-app' ) || die
				mv "${HALCYON_DIR}/app" "${saved_app}" || die
			fi
		fi

		log
		install_sandbox_layer "${tag}" "${constraints}" "${source_dir}" || return 1
		log
		install_app_layer "${tag}" "${source_dir}" || return 1

		if (( HALCYON_RECURSIVE )); then
			if [ -n "${saved_sandbox}" ]; then
				rm -rf "${HALCYON_DIR}/sandbox" || die
				mv "${saved_sandbox}" "${HALCYON_DIR}/sandbox" || die
			fi
			if [ -n "${saved_app}" ]; then
				rm -rf "${HALCYON_DIR}/app" || die
				mv "${saved_app}" "${HALCYON_DIR}/app" || die
			fi
		fi

		log
		prepare_slug "${tag}" || die
		archive_slug || die
		if ! (( HALCYON_RECURSIVE )) || [ "${target}" = 'sandbox' ]; then
			apply_slug "${tag}" || die
		fi
	fi

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache || die
	fi
}


function deploy_env () {
	log 'Deploying environment'

	local env_tag
	expect_args env_tag -- "$@"

	describe_env_tag "${env_tag}" || die
	describe_storage || die

	HALCYON_ONLY_DEPLOY_ENV=1 \
		deploy_layers "${env_tag}" '' '/dev/null' || return 1
}


function prepare_env () {
	expect_vars HALCYON_RECURSIVE HALCYON_NO_PREPARE_CACHE

	local env_tag
	expect_args env_tag -- "$@"

	local no_prepare_cache
	no_prepare_cache="${HALCYON_NO_PREPARE_CACHE}"

	if ! validate_ghc_layer "${env_tag}" >'/dev/null' ||
		! validate_updated_cabal_layer "${env_tag}" >'/dev/null'
	then
		if ! (( HALCYON_RECURSIVE )); then
			if ! HALCYON_NO_CLEAN_CACHE=1      \
				HALCYON_NO_WARN_IMPLICIT=1 \
				deploy_env "${env_tag}"
			then
				die 'Cannot deploy environment'
			fi
			log
			no_prepare_cache=1
		else
			die 'Cannot use existing environment'
		fi
	fi

	echo "${no_prepare_cache}"
}


function deploy_extra_apps () {
	local target source_dir
	expect_args target source_dir -- "$@"

	if [ "${target}" != 'sandbox' ] && [ "${target}" != 'slug' ]; then
		die "Unexpected target: ${target}"
	fi
	if ! [ -f "${source_dir}/.halcyon-magic/${target}-extra-apps" ]; then
		return 0
	fi

	log 'Deploying extra apps'

	local -a extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/${target}-extra-apps" ) ) || die
	if ! ( deploy --recursive --target="${target}" "${extra_apps[@]}" |& quote ); then
		log_warning 'Cannot deploy extra apps'
		return 1
	fi
}


function prepare_extra_apps () {
	local target source_dir
	expect_args target source_dir -- "$@"

	local -a extra_apps
	case "${target}" in
	'sandbox')
		if [ -z "${HALCYON_SANDBOX_EXTRA_APPS:+_}" ]; then
			return 0
		fi
		extra_apps=( ${HALCYON_SANDBOX_EXTRA_APPS} )
		;;
	'slug')
		if [ -z "${HALCYON_SLUG_EXTRA_APPS:+_}" ]; then
			return 0
		fi
		extra_apps=( ${HALCYON_SLUG_EXTRA_APPS} )
		;;
	*)
		die "Unexpected target: ${target}"
	esac

	local work_dir
	work_dir=$( get_tmp_dir 'halcyon.extra-apps' ) || die

	local -a app_labels
	local extra_app
	for extra_app in "${extra_apps[@]}"; do
		local app_label
		app_label=$( cabal_unpack_app "${extra_app}" "${work_dir}" ) || die

		app_labels+=( "${app_label}" )
	done

	mkdir -p "${source_dir}/.halcyon-magic" || die
	( IFS=$'\n' && echo "${app_labels[*]:-}" >"${source_dir}/.halcyon-magic/${target}-extra-apps" ) || die

	rm -rf "${work_dir}" || die
}


function deploy_app () {
	expect_vars HALCYON_NO_WARN_IMPLICIT

	local env_tag app_label source_dir
	expect_args env_tag app_label source_dir -- "$@"
	expect_existing "${source_dir}"

	log 'Deploying app:                           ' "${app_label}"

	local constraints warn_implicit
	if [ -f "${source_dir}/cabal.config" ]; then
		constraints=$( detect_constraints "${app_label}" "${source_dir}" ) || die
		warn_implicit=0
	else
		constraints=$( cabal_freeze_implicit_constraints "${app_label}" "${source_dir}" ) || die
		warn_implicit=1
	fi

	prepare_extra_apps 'sandbox' "${source_dir}"
	prepare_extra_apps 'slug' "${source_dir}"

	local tag
	tag=$( create_full_tag "${env_tag}" "${app_label}" "${constraints}" "${source_dir}" ) || die
	describe_full_tag "${tag}" "${source_dir}" || die
	describe_storage || die

	if ! (( HALCYON_NO_WARN_IMPLICIT )) && (( warn_implicit )); then
		log_warning 'Using implicit constraints'
		log_warning 'Expected cabal.config with explicit constraints'
		log
		help_add_explicit_constraints "${constraints}"
		log
	fi

	deploy_layers "${tag}" "${constraints}" "${source_dir}" || return 1
}


function deploy_local_app () {
	local env_tag local_dir
	expect_args env_tag local_dir -- "$@"

	local no_prepare_cache
	no_prepare_cache=$( prepare_env "${env_tag}" ) || die

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.copied-source' ) || die
	copy_app_source "${local_dir}" "${source_dir}" || die

	local app_label
	if ! app_label=$( detect_app_label "${source_dir}" ); then
		die 'Cannot detect app label'
	fi
	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		deploy_app "${env_tag}" "${app_label}" "${source_dir}"
	then
		log_warning 'Cannot deploy app'
		return 1
	fi
}


function deploy_cloned_app () {
	local env_tag url
	expect_args env_tag url -- "$@"

	local no_prepare_cache
	no_prepare_cache=$( prepare_env "${env_tag}" ) || die

	log 'Cloning app'

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.cloned-source' ) || die
	if ! git clone --depth=1 --quiet "${url}" "${source_dir}"; then
		die 'Cannot clone app'
	fi

	local app_label
	if ! app_label=$( detect_app_label "${source_dir}" ); then
		die 'Cannot detect app label'
	fi

	log
	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		deploy_app "${env_tag}" "${app_label}" "${source_dir}"
	then
		log_warning 'Cannot deploy app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_unpacked_app () {
	local env_tag thing
	expect_args env_tag thing -- "$@"

	local no_prepare_cache
	no_prepare_cache=$( prepare_env "${env_tag}" ) || die

	log 'Unpacking app'

	local source_dir app_label
	source_dir=$( get_tmp_dir 'halcyon.unpacked-source' ) || die
	app_label=$( cabal_unpack_app "${thing}" "${source_dir}" ) || die

	log
	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		HALCYON_NO_WARN_IMPLICIT=1                  \
		deploy_app "${env_tag}" "${app_label}" "${source_dir}"
	then
		log_warning 'Cannot deploy app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_thing () {
	local env_tag thing
	expect_args env_tag thing -- "$@"

	case "${thing}" in
	'https://'*);&
	'ssh://'*);&
	'git@'*);&
	'file://'*);&
	'http://'*);&
	'git://'*)
		deploy_cloned_app "${env_tag}" "${thing}" || return 1
		;;
	*)
		if [ -d "${thing}" ]; then
			deploy_local_app "${env_tag}" "${thing%/}" || return 1
		else
			deploy_unpacked_app "${env_tag}" "${thing}" || return 1
		fi
	esac
}
