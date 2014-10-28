function detect_app_package () {
	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	local package_file
	package_file=$(
		find "${source_dir}" -maxdepth 1 -type f -name '*.cabal' |
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

	local cache_dir slug_dir
	cache_dir=$( get_tmp_dir 'halcyon-cache' ) || die
	slug_dir=$( get_tmp_dir 'halcyon-slug' ) || die

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache "${cache_dir}" || die
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
			if restore_slug "${tag}" "${slug_dir}"; then
				log
				apply_slug "${tag}" "${slug_dir}" || die
				return 0
			fi
		fi

		local saved_sandbox saved_app
		saved_sandbox=
		saved_app=
		if (( HALCYON_RECURSIVE )); then
			if [ -d "${HALCYON_DIR}/sandbox" ]; then
				saved_sandbox=$( get_tmp_dir 'halcyon-saved-sandbox' ) || die
				mv "${HALCYON_DIR}/sandbox" "${saved_sandbox}" || die
			fi
			if [ -d "${HALCYON_DIR}/app" ]; then
				saved_app=$( get_tmp_dir 'halcyon-saved-app' ) || die
				mv "${HALCYON_DIR}/app" "${saved_app}" || die
			fi
		fi

		log
		install_sandbox_layer "${tag}" "${constraints}" "${source_dir}" || return 1
		log
		install_app_layer "${tag}" "${source_dir}" || return 1
		log
		build_slug "${tag}" "${source_dir}" "${slug_dir}" || return 1
		archive_slug "${slug_dir}" || die

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
		apply_slug "${tag}" "${slug_dir}" || die
	fi

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache "${cache_dir}" || die
	fi

	rm -rf "${cache_dir}" "${slug_dir}" || die
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
			if ! HALCYON_NO_CLEAN_CACHE=1   \
				deploy_env "${env_tag}"
			then
				log_warning 'Cannot deploy environment'
				return 1
			fi
			log
			no_prepare_cache=1
		else
			die 'Cannot use existing environment'
		fi
	fi

	echo "${no_prepare_cache}"
}


function deploy_sandbox_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"
	if ! [ -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]; then
		return 0
	fi

	log 'Deploying sandbox extra apps'

	local -a extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) ) || die

	local extra_app
	for extra_app in "${extra_apps[@]}"; do
		local constraints_file
		constraints_file="${source_dir}/.halcyon-magic/sandbox-extra-apps-constraints/${extra_app}.cabal.config"

		if ! (
			deploy  --recursive                              \
				--target='sandbox'                       \
				--constraints-file="${constraints_file}" \
				"${extra_app}" |& quote
		); then
			log_warning 'Failed to deploy sandbox extra apps'
			return 1
		fi
	done
}


function deploy_slug_extra_apps () {
	local source_dir slug_dir
	expect_args source_dir slug_dir -- "$@"
	if ! [ -f "${source_dir}/.halcyon-magic/slug-extra-apps" ]; then
		return 0
	fi

	log 'Deploying slug extra apps'

	local -a extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/slug-extra-apps" ) ) || die

	local extra_app
	for extra_app in "${extra_apps[@]}"; do
		local constraints_file
		constraints_file="${source_dir}/.halcyon-magic/slug-extra-apps-constraints/${extra_app}.cabal.config"

		if ! (
			deploy  --recursive                              \
				--constraints-file="${constraints_file}" \
				--slug-dir="${slug_dir}"                 \
				"${extra_app}" |& quote
		); then
			log_warning 'Failed to deploy slug extra apps'
			return 1
		fi
	done
}


function unpack_app () {
	local thing must_error work_dir
	expect_args thing must_error work_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'halcyon-unpack-stderr' ) || die

	mkdir -p "${work_dir}" || die

	local app_label
	if ! app_label=$(
		cabal_do "${work_dir}" unpack "${thing}" 2>"${stderr}" |
		filter_matching '^Unpacking to ' |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		quote <"${stderr}" || die
		die 'Failed to unpack app'
	fi
	if [ "${app_label}" != "${thing}" ]; then
		if (( must_error )); then
			log_error "Cannot use implicit version of ${thing}"
			die 'Expected app label with explicit version'
		fi
		log_warning "Using implicit version of ${thing}"
		log_warning 'Expected app label with explicit version'
	fi

	rm -rf "${stderr}" || die

	echo "${app_label}"
}


function prepare_sandbox_extra_apps () {
	expect_vars HALCYON_RECURSIVE

	local source_dir
	expect_args source_dir -- "$@"

	local -a extra_apps
	extra_apps=()

	local must_error
	must_error="${HALCYON_RECURSIVE}"
	if [ -n "${HALCYON_SANDBOX_EXTRA_APPS:+_}" ]; then
		extra_apps=( ${HALCYON_SANDBOX_EXTRA_APPS} )
	elif [ -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]; then
		extra_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) ) || die
		must_error=1
	fi
	if [ -z "${extra_apps[@]:+_}" ]; then
		return 0
	fi

	local constraints_dir work_dir
	constraints_dir="${source_dir}/.halcyon-magic/sandbox-extra-apps-constraints"
	work_dir=$( get_tmp_dir 'halcyon-sandbox-extra-apps' ) || die

	mkdir -p "${source_dir}/.halcyon-magic" || die
	if [ -n "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR:+_}" ]; then
		rm -rf "${constraints_dir}" || die
		tar_copy "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS_DIR}" "${constraints_dir}" || die
	fi

	local -a app_labels
	app_labels=()

	local extra_app
	for extra_app in "${extra_apps[@]}"; do
		local app_label constraints_file
		app_label=$( unpack_app "${extra_app}" "${must_error}" "${work_dir}" ) || die
		constraints_file="${constraints_dir}/${app_label}.cabal.config"

		if ! [ -f "${constraints_file}" ]; then
			if (( must_error )); then
				log_error "Cannot use implicit constraints for ${app_label}"
				die "Expected ${constraints_file##${source_dir}/} with explicit constraints"
			fi
			log_warning "Using implicit constraints for ${app_label}"
			log_warning "Expected ${constraints_file##${source_dir}/} with explicit constraints"
		fi

		app_labels+=( "${app_label}" )
	done

	( IFS=$'\n' && echo "${app_labels[*]:-}" >"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) || die

	rm -rf "${work_dir}" || die
}


function prepare_slug_extra_apps () {
	expect_vars HALCYON_RECURSIVE

	local source_dir
	expect_args source_dir -- "$@"

	local -a extra_apps
	extra_apps=()

	local must_error
	must_error="${HALCYON_RECURSIVE}"
	if [ -n "${HALCYON_SLUG_EXTRA_APPS:+_}" ]; then
		extra_apps=( ${HALCYON_SLUG_EXTRA_APPS} )
	elif [ -f "${source_dir}/.halcyon-magic/slug-extra-apps" ]; then
		extra_apps=( $( <"${source_dir}/.halcyon-magic/slug-extra-apps" ) ) || die
		must_error=1
	fi
	if [ -z "${extra_apps[@]:+_}" ]; then
		return 0
	fi

	local constraints_dir work_dir
	constraints_dir="${source_dir}/.halcyon-magic/slug-extra-apps-constraints"
	work_dir=$( get_tmp_dir 'halcyon-slug-extra-apps' ) || die

	mkdir -p "${source_dir}/.halcyon-magic" || die
	if [ -n "${HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR:+_}" ]; then
		rm -rf "${constraints_dir}" || die
		tar_copy "${HALCYON_SLUG_EXTRA_APPS_CONSTRAINTS_DIR}" "${constraints_dir}" || die
	fi

	local -a app_labels
	app_labels=()

	local extra_app
	for extra_app in "${extra_apps[@]}"; do
		local app_label constraints_file
		app_label=$( unpack_app "${extra_app}" "${must_error}" "${work_dir}" ) || die
		constraints_file="${constraints_dir}/${app_label}.cabal.config"

		if ! [ -f "${constraints_file}" ]; then
			if (( must_error )); then
				log_error "Cannot use implicit constraints for ${app_label}"
				die "Expected ${constraints_file##${source_dir}/} with explicit constraints"
			fi
			log_warning "Using implicit constraints for ${app_label}"
			log_warning "Expected ${constraints_file##${source_dir}/} with explicit constraints"
		fi

		app_labels+=( "${app_label}" )
	done

	( IFS=$'\n' && echo "${app_labels[*]:-}" >"${source_dir}/.halcyon-magic/slug-extra-apps" ) || die

	rm -rf "${work_dir}" || die
}


function deploy_app () {
	expect_vars HALCYON_RECURSIVE

	local env_tag app_label source_dir
	expect_args env_tag app_label source_dir -- "$@"
	expect_existing "${source_dir}"

	log 'Deploying app:                           ' "${app_label}"

	if [ -n "${HALCYON_CONSTRAINTS_FILE:+_}" ] && [ -f "${HALCYON_CONSTRAINTS_FILE}" ]; then
		cp -p "${HALCYON_CONSTRAINTS_FILE}" "${source_dir}/cabal.config" || die
	fi

	local constraints warn_implicit
	warn_implicit=0
	if [ -f "${source_dir}/cabal.config" ]; then
		constraints=$( detect_constraints "${app_label}" "${source_dir}" ) || die
	else
		constraints=$( freeze_implicit_constraints "${app_label}" "${source_dir}" ) || die
		warn_implicit=1
	fi

	prepare_sandbox_extra_apps "${source_dir}"
	prepare_slug_extra_apps "${source_dir}"

	local tag
	tag=$( create_full_tag "${env_tag}" "${app_label}" "${constraints}" "${source_dir}" ) || die
	describe_full_tag "${tag}" "${source_dir}" || die
	describe_storage || die

	if (( warn_implicit )); then
		if (( HALCYON_RECURSIVE )); then
			log_error 'Cannot use implicit constraints'
			log_error 'Expected cabal.config with explicit constraints'
			log
			help_add_explicit_constraints "${constraints}"
			die
		fi
		log_warning 'Using implicit constraints'
		log_warning 'Expected cabal.config with explicit constraints'
		log
		help_add_explicit_constraints "${constraints}"
	fi

	deploy_layers "${tag}" "${constraints}" "${source_dir}" || return 1
}


function deploy_local_app () {
	local env_tag local_dir
	expect_args env_tag local_dir -- "$@"

	local no_prepare_cache
	no_prepare_cache=$( prepare_env "${env_tag}" ) || return 1

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon-copied-source' ) || die
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
	no_prepare_cache=$( prepare_env "${env_tag}" ) || return 1

	log 'Cloning app'

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon-cloned-source' ) || die
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
	expect_vars HALCYON_RECURSIVE

	local env_tag thing
	expect_args env_tag thing -- "$@"

	local must_error no_prepare_cache
	must_error="${HALCYON_RECURSIVE}"
	no_prepare_cache=$( prepare_env "${env_tag}" ) || return 1

	log 'Unpacking app'

	local work_dir app_label
	work_dir=$( get_tmp_dir 'halcyon-unpacked-source' ) || die
	app_label=$( unpack_app "${thing}" "${must_error}" "${work_dir}" ) || die

	log
	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		deploy_app "${env_tag}" "${app_label}" "${work_dir}/${app_label}"
	then
		log_warning 'Cannot deploy app'
		return 1
	fi

	rm -rf "${work_dir}" || die
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
