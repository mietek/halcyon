function detect_app_package () {
	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	local package_file
	package_file=$(
		find_spaceless_recursively "${source_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	) || return 1

	cat "${source_dir}/${package_file}"
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

	echo "${app_name}-${app_label}"
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


function deploy_sandbox_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	log 'Deploying sandbox extra apps'

	local sandbox_apps
	sandbox_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) ) || die
	if ! ( deploy --recursive --target='sandbox' "${sandbox_apps[@]}" ) |& quote; then
		log_warning 'Cannot deploy sandbox extra apps'
		return 1
	fi
}


function deploy_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	log 'Deploying extra apps'

	local extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/extra-apps" ) ) || die
	if ! ( deploy --recursive "${extra_apps[@]}" ) |& quote; then
		log_warning 'Cannot deploy extra apps'
		return 1
	fi
}


function deploy_layers () {
	expect_vars HALCYON_DIR HALCYON_RECURSIVE HALCYON_ONLY_ENV HALCYON_NO_PREPARE_CACHE HALCYON_NO_CLEAN_CACHE

	local tag constraints source_dir
	expect_args tag constraints source_dir -- "$@"

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache || die
	fi

	if ! (( HALCYON_RECURSIVE )); then
		log
		deploy_ghc_layer "${tag}" "${source_dir}" || return 1
		log
		deploy_cabal_layer "${tag}" "${source_dir}" || return 1
	else
		if ! validate_ghc_layer "${tag}" >'/dev/null' ||
			! validate_updated_cabal_layer "${tag}" >'/dev/null'
		then
			die 'Cannot reuse environment'
		fi
	fi

	if ! (( HALCYON_ONLY_ENV )); then
		if ! (( HALCYON_RECURSIVE )); then
			rm -rf "${HALCYON_DIR}/sandbox" "${HALCYON_DIR}/app" "${HALCYON_DIR}/slug" || die
		fi

		if restore_slug "${tag}"; then
			install_slug || die
			return 0
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
		deploy_sandbox_layer "${tag}" "${constraints}" "${source_dir}" || return 1
		log
		deploy_app_layer "${tag}" "${source_dir}" || return 1

		if [ -f "${source_dir}/.halcyon-magic/extra-apps" ]; then
			log
			deploy_extra_apps "${source_dir}" || return 1
		fi

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
		build_slug || die
		archive_slug || die
		install_slug || die
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

	HALCYON_ONLY_ENV=1 \
		deploy_layers "${env_tag}" '' '/dev/null' || return 1
}


function deploy_app () {
	expect_vars HALCYON_NO_WARN_IMPLICIT

	local env_tag app_label source_dir
	expect_args env_tag app_label source_dir -- "$@"
	expect_existing "${source_dir}"

	log 'Deploying app:                           ' "${app_label}"

	if [ -n "${HALCYON_SANDBOX_EXTRA_APPS:+_}" ]; then
		mkdir -p "${source_dir}/.halcyon-magic" || die
		echo "${HALCYON_SANDBOX_EXTRA_APPS}" >"${source_dir}/.halcyon-magic/sandbox-extra-apps" || die
	fi
	if [ -n "${HALCYON_EXTRA_APPS:+_}" ]; then
		mkdir -p "${source_dir}/.halcyon-magic" || die
		echo "${HALCYON_EXTRA_APPS}" >"${source_dir}/.halcyon-magic/extra-apps" || die
	fi

	local constraints warn_constraints
	if [ -f "${source_dir}/cabal.config" ]; then
		if ! constraints=$( detect_constraints "${app_label}" "${source_dir}" ); then
			die 'Cannot determine explicit constraints'
		fi
		warn_constraints=0
	else
		if ! constraints=$( freeze_implicit_constraints "${app_label}" "${source_dir}" ); then
			die 'Cannot determine implicit constraints'
		fi
		warn_constraints=1
	fi

	local tag
	tag=$( determine_full_tag "${env_tag}" "${app_label}" "${constraints}" "${source_dir}" ) || die
	describe_full_tag "${tag}" || die

	if [ -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]; then
		local sandbox_apps
		sandbox_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) )
		log_indent 'Sandbox extra apps:                      ' "${sandbox_apps[*]:-}"
	fi
	if [ -f "${source_dir}/.halcyon-magic/extra-apps" ]; then
		local extra_apps
		extra_apps=( $( <"${source_dir}/.halcyon-magic/extra-apps" ) )
		log_indent 'Extra apps:                              ' "${extra_apps[*]:-}"
	fi

	describe_storage || die

	if ! (( HALCYON_RECURSIVE )) &&
		! (( HALCYON_NO_WARN_IMPLICIT )) &&
		(( warn_constraints ))
	then
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

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die
	copy_entire_contents "${local_dir}" "${source_dir}" || die

	local app_label
	if ! app_label=$( detect_app_label "${source_dir}" ); then
		die 'Cannot detect app label'
	fi
	if ! deploy_app "${env_tag}" "${app_label}" "${source_dir}"; then
		die 'Cannot deploy app'
	fi

	rm -rf "${source_dir}" || die
}


function deploy_cloned_app () {
	local env_tag url
	expect_args env_tag url -- "$@"

	log 'Cloning app'

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die
	if ! git clone --depth=1 --quiet "${url}" "${source_dir}"; then
		die 'Cannot clone app'
	fi

	local app_label
	if ! app_label=$( detect_app_label "${source_dir}" ); then
		die 'Cannot detect app label'
	fi
	if ! deploy_app "${env_tag}" "${app_label}" "${source_dir}"; then
		die 'Cannot deploy app'
	fi

	rm -rf "${source_dir}" || die
}


function deploy_unpacked_app () {
	expect_vars HALCYON_DIR HALCYON_NO_PREPARE_CACHE

	local env_tag thing
	expect_args env_tag thing -- "$@"

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
			die 'Cannot reuse environment'
		fi
	fi

	log 'Unpacking app'

	local unpack_dir source_dir
	unpack_dir=$( get_tmp_dir 'halcyon.unpack' ) || die
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die

	mkdir -p "${unpack_dir}" || die

	local app_label
	if ! app_label=$(
		cabal_do "${unpack_dir}" unpack "${thing}" 2>'/dev/null' |
		filter_last |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		die 'Cannot unpack app'
	fi

	if ! (( HALCYON_NO_WARN_IMPLICIT )) &&
		[ "${thing}" != "${app_label}" ]
	then
		log_warning "Using newest available version of ${app_label%-*}"
		log_warning 'Expected app label with explicit version'
	fi

	mv "${unpack_dir}/${app_label}" "${source_dir}" || die
	rm -rf "${unpack_dir}" || die

	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		HALCYON_NO_WARN_IMPLICIT=1                  \
		deploy_app "${env_tag}" "${app_label}" "${source_dir}"
	then
		die 'Cannot deploy app'
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
