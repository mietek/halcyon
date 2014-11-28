detect_package () {
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


detect_label () {
	local source_dir
	expect_args source_dir -- "$@"

	local package
	package=$( detect_package "${source_dir}" ) || return 1

	local name
	name=$(
		awk '/^ *[Nn]ame:/ { print $2 }' <<<"${package}" |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	local version
	version=$(
		awk '/^ *[Vv]ersion:/ { print $2 }' <<<"${package}" |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	echo "${name}-${version}"
}


detect_executable () {
	local source_dir
	expect_args source_dir -- "$@"

	local executable
	executable=$(
		detect_package "${source_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		tr -d '\r' |
		match_at_least_one |
		filter_first
	) || return 1

	echo "${executable}"
}


determine_ghc_version () {
	expect_vars HALCYON_GHC_VERSION

	local constraints
	expect_args constraints -- "$@"

	local ghc_version
	if [[ -n "${constraints}" ]]; then
		ghc_version=$( map_constraints_to_ghc_version "${constraints}" ) || die
	else
		ghc_version="${HALCYON_GHC_VERSION}"
	fi

	echo "${ghc_version}"
}


determine_ghc_magic_hash () {
	local source_dir
	expect_args source_dir -- "$@"

	local ghc_magic_hash
	if [[ -n "${HALCYON_INTERNAL_GHC_MAGIC_HASH:+_}" ]]; then
		ghc_magic_hash="${HALCYON_INTERNAL_GHC_MAGIC_HASH}"
	else
		ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || die
	fi

	echo "${ghc_magic_hash}"
}


determine_cabal_magic_hash () {
	local source_dir
	expect_args source_dir -- "$@"

	local cabal_magic_hash
	if [[ -n "${HALCYON_INTERNAL_CABAL_MAGIC_HASH:+_}" ]]; then
		cabal_magic_hash="${HALCYON_INTERNAL_CABAL_MAGIC_HASH}"
	else
		cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || die
	fi

	echo "${cabal_magic_hash}"
}


describe_extra () {
	local extra_label extra_file
	expect_args extra_label extra_file -- "$@"

	if [[ ! -f "${extra_file}" ]]; then
		return 0
	fi

	local -a extra_lines
	extra_lines=( $( <"${extra_file}" ) ) || die
	if [[ -z "${extra_lines[@]:+_}" ]]; then
		return 0
	fi

	local only_first extra_line
	only_first="${extra_label}"
	for extra_line in "${extra_lines[@]}"; do
		log_indent_label "${only_first}" "${extra_line}"
		only_first=''
	done
}


hash_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	# NOTE: The version number of Cabal and the contents of its package
	# database could conceivably be treated as dependencies.

	hash_tree "${source_dir}/.halcyon-magic" -not -path './cabal*' || die
}


copy_source_dir_over () {
	local source_dir dst_dir
	expect_args source_dir dst_dir -- "$@"

	copy_dir_over "${source_dir}" "${dst_dir}" \
		--exclude '.git' \
		--exclude '.gitmodules' \
		--exclude '.ghc' \
		--exclude '.cabal' \
		--exclude '.cabal-sandbox' \
		--exclude 'cabal.sandbox.config' || die
}


announce_deploy () {
	expect_vars HALCYON_NO_APP \
		HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY

	local tag
	expect_args tag -- "$@"

	if (( HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY )); then
		return 0
	fi

	if (( HALCYON_NO_APP )); then
		log_label 'Environment deployed'
		return 0
	fi

	local label
	label=$( get_tag_label "${tag}" ) || die

	log
	log_label 'App deployed:' "${label}"
}


do_deploy_env () {
	expect_vars HALCYON_INTERNAL_RECURSIVE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if ! validate_ghc_layer "${tag}" >'/dev/null' ||
			! validate_updated_cabal_layer "${tag}" >'/dev/null'
		then
			die 'Cannot use existing environment'
		fi
		return 0
	fi

	install_ghc_layer "${tag}" "${source_dir}" || return 1
	recache_ghc_package_db "${tag}" || die
	log

	install_cabal_layer "${tag}" "${source_dir}" || return 1
	log
}


deploy_env () {
	expect_vars HALCYON_GHC_VERSION \
		HALCYON_CABAL_VERSION HALCYON_CABAL_REPO \
		HALCYON_INTERNAL_RECURSIVE

	local source_dir
	expect_args source_dir -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version="${HALCYON_GHC_VERSION}"
	ghc_magic_hash=$( determine_ghc_magic_hash "${source_dir}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version="${HALCYON_CABAL_VERSION}"
	cabal_magic_hash=$( determine_cabal_magic_hash "${source_dir}" ) || die
	cabal_repo="${HALCYON_CABAL_REPO}"

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		log 'Deploying environment'

		describe_storage || die

		log_indent_label 'GHC version:' "${ghc_version}"
		[[ -n "${ghc_magic_hash}" ]] && log_indent_label 'GHC magic hash:' "${ghc_magic_hash:0:7}"

		log_indent_label 'Cabal version:' "${cabal_version}"
		[[ -n "${cabal_magic_hash}" ]] && log_indent_label 'Cabal magic hash:' "${cabal_magic_hash:0:7}"
		log_indent_label 'Cabal repository:' "${cabal_repo%%:*}"
		log
	fi

	local tag
	tag=$(
		create_tag '' '' '' '' '' \
			"${ghc_version}" "${ghc_magic_hash}" \
			"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
			''
	) || die

	if ! do_deploy_env "${tag}" "${source_dir}"; then
		log_warning 'Cannot deploy environment'
		return 1
	fi

	announce_deploy "${tag}" || die
}


do_deploy_from_install_dir () {
	local tag source_dir
	expect_args tag source_dir -- "$@"

	local install_dir
	install_dir=$( get_tmp_dir 'halcyon-install' ) || die

	restore_install_dir "${tag}" "${install_dir}" || return 1
	install_app "${tag}" "${source_dir}" "${install_dir}" || die
	link_cabal_config || die

	rm -rf "${install_dir}"
}


deploy_from_install_dir () {
	expect_vars HALCYON_PREFIX HALCYON_RESTORE_DEPENDENCIES \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE HALCYON_APP_REINSTALL \
		HALCYON_GHC_REBUILD \
		HALCYON_CABAL_REBUILD HALCYON_CABAL_UPDATE \
		HALCYON_SANDBOX_REBUILD \
		HALCYON_INTERNAL_RECURSIVE

	local label source_hash source_dir
	expect_args label source_hash source_dir -- "$@"
	expect_existing "${source_dir}"

	if [[ ! -f "${source_dir}/cabal.config" ]] || (( HALCYON_RESTORE_DEPENDENCIES )) ||
		(( HALCYON_APP_REBUILD )) || (( HALCYON_APP_RECONFIGURE )) || (( HALCYON_APP_REINSTALL )) ||
		(( HALCYON_GHC_REBUILD )) ||
		(( HALCYON_CABAL_REBUILD )) || (( HALCYON_CABAL_UPDATE )) ||
		(( HALCYON_SANDBOX_REBUILD ))
	then
		return 1
	fi

	log 'Deploying app from install'

	log_indent_label 'Prefix:' "${HALCYON_PREFIX}"
	log_indent_label 'Label:' "${label}"
	log_indent_label 'Source hash:' "${source_hash:0:7}"

	describe_storage || die
	log

	local tag
	tag=$(
		create_tag "${HALCYON_PREFIX}" "${label}" "${source_hash}" '' '' \
			'' '' \
			'' '' '' '' \
			''
	) || die

	if ! do_deploy_from_install_dir "${tag}" "${source_dir}"; then
		log
		return 1
	fi

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		announce_deploy "${tag}" || die
		touch_cached_env_files || die
	fi
}


prepare_source_dir () {
	local label source_dir
	expect_args label source_dir -- "$@"
	expect_existing "${source_dir}"

	local magic_dir
	magic_dir="${source_dir}/.halcyon-magic"

# Standard files
	if [[ -n "${HALCYON_CONSTRAINTS:+_}" ]]; then
		if [[ -d "${HALCYON_CONSTRAINTS}" ]]; then
			copy_file "${HALCYON_CONSTRAINTS}/${label}.cabal.config" "${source_dir}/cabal.config" || die
		else
			copy_file "${HALCYON_CONSTRAINTS}" "${source_dir}/cabal.config" || die
		fi
	fi

# General magic files
	if [[ -n "${HALCYON_EXTRA_CONFIGURE_FLAGS:+_}" ]]; then
		copy_file <( echo "${HALCYON_EXTRA_CONFIGURE_FLAGS}" ) "${magic_dir}/extra-configure-flags" || die
	fi
	if [[ -n "${HALCYON_PRE_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_PRE_BUILD_HOOK}" "${magic_dir}/pre-build-hook" || die
	fi
	if [[ -n "${HALCYON_POST_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_POST_BUILD_HOOK}" "${magic_dir}/post-build-hook" || die
	fi

# Install-time magic files
	if [[ -n "${HALCYON_EXTRA_APPS:+_}" ]]; then
		local -a extra_apps
		extra_apps=( ${HALCYON_EXTRA_APPS} )

		copy_file <( IFS=$'\n' && echo "${extra_apps[*]}" ) "${magic_dir}/extra-apps" || die
	fi
	if [[ -n "${HALCYON_EXTRA_APPS_CONSTRAINTS:+_}" ]]; then
		if [[ -d "${HALCYON_EXTRA_APPS_CONSTRAINTS}" ]]; then
			copy_dir_over "${HALCYON_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/extra-apps-constraints" || die
		else
			copy_file "${HALCYON_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/extra-apps-constraints" || die
		fi
	fi
	if [[ -n "${HALCYON_EXTRA_DATA_FILES:+_}" ]]; then
		copy_file <( echo "${HALCYON_EXTRA_DATA_FILES}" ) "${magic_dir}/extra-data-files" || die
	fi
	if [[ -n "${HALCYON_PRE_INSTALL_HOOK:+_}" ]]; then
		copy_file "${HALCYON_PRE_INSTALL_HOOK}" "${magic_dir}/pre-install-hook" || die
	fi
	if [[ -n "${HALCYON_POST_INSTALL_HOOK:+_}" ]]; then
		copy_file "${HALCYON_POST_INSTALL_HOOK}" "${magic_dir}/post-install-hook" || die
	fi

# GHC layer magic files
	if [[ -n "${HALCYON_GHC_PRE_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_GHC_PRE_BUILD_HOOK}" "${magic_dir}/ghc-pre-build-hook" || die
	fi
	if [[ -n "${HALCYON_GHC_POST_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_GHC_POST_BUILD_HOOK}" "${magic_dir}/ghc-post-build-hook" || die
	fi

# Cabal layer options
	if [[ -n "${HALCYON_CABAL_PRE_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_CABAL_PRE_BUILD_HOOK}" "${magic_dir}/cabal-pre-build-hook" || die
	fi
	if [[ -n "${HALCYON_CABAL_POST_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_CABAL_POST_BUILD_HOOK}" "${magic_dir}/cabal-post-build-hook" || die
	fi
	if [[ -n "${HALCYON_CABAL_PRE_UPDATE_HOOK:+_}" ]]; then
		copy_file "${HALCYON_CABAL_PRE_UPDATE_HOOK}" "${magic_dir}/cabal-pre-update-hook" || die
	fi
	if [[ -n "${HALCYON_CABAL_POST_UPDATE_HOOK:+_}" ]]; then
		copy_file "${HALCYON_CABAL_POST_UPDATE_HOOK}" "${magic_dir}/cabal-post-update-hook" || die
	fi

# Sandbox layer magic files
	if [[ -n "${HALCYON_SANDBOX_SOURCES:+_}" ]]; then
		local -a sandbox_sources
		sandbox_sources=( ${HALCYON_SANDBOX_SOURCES} )

		copy_file <( IFS=$'\n' && echo "${sandbox_sources[*]}" ) "${magic_dir}/sandbox-sources" || die
	fi
	if [[ -n "${HALCYON_SANDBOX_EXTRA_APPS:+_}" ]]; then
		local -a extra_apps
		extra_apps=( ${HALCYON_SANDBOX_EXTRA_APPS} )

		copy_file <( IFS=$'\n' && echo "${extra_apps[*]}" ) "${magic_dir}/sandbox-extra-apps" || die
	fi
	if [[ -n "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS:+_}" ]]; then
		if [[ -d "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS}" ]]; then
			copy_dir_over "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/sandbox-extra-apps-constraints" || die
		else
			copy_file "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/sandbox-extra-apps-constraints" || die
		fi
	fi
	if [[ -n "${HALCYON_SANDBOX_EXTRA_CONFIGURE_FLAGS:+_}" ]]; then
		copy_file <( echo "${HALCYON_SANDBOX_EXTRA_CONFIGURE_FLAGS}" ) "${magic_dir}/sandbox-extra-configure-flags" || die
	fi
	if [[ -n "${HALCYON_SANDBOX_EXTRA_LIBS:+_}" ]]; then
		local -a extra_libs
		extra_libs=( ${HALCYON_SANDBOX_EXTRA_LIBS} )

		copy_file <( IFS=$'\n' && echo "${extra_libs[*]}" ) "${magic_dir}/sandbox-extra-libs" || die
	fi
	if [[ -n "${HALCYON_SANDBOX_PRE_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_SANDBOX_PRE_BUILD_HOOK}" "${magic_dir}/sandbox-pre-build-hook" || die
	fi
	if [[ -n "${HALCYON_SANDBOX_POST_BUILD_HOOK:+_}" ]]; then
		copy_file "${HALCYON_SANDBOX_POST_BUILD_HOOK}" "${magic_dir}/sandbox-post-build-hook" || die
	fi
}


do_deploy_app () {
	expect_vars HALCYON_BASE \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE HALCYON_APP_REINSTALL \
		HALCYON_INTERNAL_RECURSIVE

	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	local saved_sandbox build_dir install_dir
	saved_sandbox=''
	build_dir=$( get_tmp_dir 'halcyon-build' ) || die
	install_dir=$( get_tmp_dir 'halcyon-install' ) || die

	do_deploy_env "${tag}" "${source_dir}" || return 1

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if [[ -d "${HALCYON_BASE}/sandbox" ]]; then
			saved_sandbox=$( get_tmp_dir 'halcyon-saved-sandbox' ) || die
			mv "${HALCYON_BASE}/sandbox" "${saved_sandbox}" || die
		fi
	fi

	install_sandbox_layer "${tag}" "${source_dir}" "${constraints}" || return 1
	validate_actual_constraints "${tag}" "${source_dir}" "${constraints}" || die
	log

	install_build_dir "${tag}" "${source_dir}" "${build_dir}" || return 1
	log

	local must_prepare
	must_prepare=1
	if ! (( HALCYON_APP_REBUILD )) && ! (( HALCYON_APP_RECONFIGURE )) && ! (( HALCYON_APP_REINSTALL )) &&
		restore_install_dir "${tag}" "${install_dir}"
	then
		must_prepare=0
	fi
	if (( must_prepare )); then
		if ! prepare_install_dir "${tag}" "${source_dir}" "${build_dir}" "${install_dir}"; then
			log_warning 'Cannot prepare install'
			return 1
		fi
		archive_install_dir "${install_dir}" || die
	fi

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if [[ -n "${saved_sandbox}" ]]; then
			rm -rf "${HALCYON_BASE}/sandbox" || die
			mv "${saved_sandbox}" "${HALCYON_BASE}/sandbox" || die
		fi
	fi

	install_app "${tag}" "${source_dir}" "${install_dir}" || die
	link_cabal_config || die

	rm -rf "${build_dir}" "${install_dir}" || die
}


deploy_app () {
	expect_vars HALCYON_PREFIX \
		HALCYON_CABAL_VERSION HALCYON_CABAL_REPO \
		HALCYON_INTERNAL_RECURSIVE

	local label source_dir
	expect_args label source_dir -- "$@"
	expect_existing "${source_dir}"

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'label' ]]; then
		echo "${label}"
		return 0
	fi

	# NOTE: This is the first out of the two moments when source_dir is modified.

	prepare_source_dir "${label}" "${source_dir}" || die

	local source_hash
	if [[ -f "${source_dir}/cabal.config" ]]; then
		source_hash=$( hash_tree "${source_dir}" ) || die

		if [[ "${HALCYON_INTERNAL_COMMAND}" == 'deploy' ]] &&
			deploy_from_install_dir "${label}" "${source_hash}" "${source_dir}"
		then
			return 0
		fi
	fi

	local constraints
	if [[ ! -f "${source_dir}/cabal.config" ]]; then
		HALCYON_GHC_REBUILD=0 \
		HALCYON_CABAL_REBUILD=0 HALCYON_CABAL_UPDATE=0 \
		HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY=1 \
			deploy_env "${source_dir}" || return 1

		constraints=$( cabal_freeze_implicit_constraints "${label}" "${source_dir}" ) || die

		log_warning 'Using implicit constraints'
		log_warning 'Expected cabal.config with explicit constraints'
		log
		if (( HALCYON_INTERNAL_REMOTE_SOURCE )); then
			log "To use explicit constraints, specify --constraints=cabal.config"
		else
			log 'To use explicit constraints, add cabal.config'
		fi
		log_indent "$ cat >cabal.config <<EOF"
		format_constraints <<<"${constraints}" >&2 || die
		echo 'EOF' >&2
		log

		# NOTE: This is the second out of the two moments when source_dir is modified.

		format_constraints <<<"${constraints}" >"${source_dir}/cabal.config" || die
		source_hash=$( hash_tree "${source_dir}" ) || die

		if [[ "${HALCYON_INTERNAL_COMMAND}" == 'deploy' ]] &&
			deploy_from_install_dir "${label}" "${source_hash}" "${source_dir}"
		then
			return 0
		fi
	else
		constraints=$( detect_constraints "${label}" "${source_dir}" ) || die
	fi

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'constraints' ]]; then
		format_constraints <<<"${constraints}" || die
		return 0
	fi

	log 'Deploying app'

	local constraints_hash magic_hash
	constraints_hash=$( hash_constraints "${constraints}" ) || die
	magic_hash=$( hash_magic "${source_dir}" ) || die

	local ghc_version ghc_magic_hash
	ghc_version=$( determine_ghc_version "${constraints}" ) || die
	ghc_magic_hash=$( determine_ghc_magic_hash "${source_dir}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version="${HALCYON_CABAL_VERSION}"
	cabal_magic_hash=$( determine_cabal_magic_hash "${source_dir}" ) || die
	cabal_repo="${HALCYON_CABAL_REPO}"

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die

	log_indent_label 'Prefix:' "${HALCYON_PREFIX}"
	log_indent_label 'Label:' "${label}"
	log_indent_label 'Source hash:' "${source_hash:0:7}"

	log_indent_label 'Constraints hash:' "${constraints_hash:0:7}"
	describe_extra 'Extra apps:' "${source_dir}/.halcyon-magic/extra-apps"
	describe_extra 'Extra data files:' "${source_dir}/.halcyon-magic/extra-data-files"
	[[ -n "${magic_hash}" ]] && log_indent_label 'Magic hash:' "${magic_hash:0:7}"

	describe_storage || die

	log_indent_label 'GHC version:' "${ghc_version}"
	[[ -n "${ghc_magic_hash}" ]] && log_indent_label 'GHC magic hash:' "${ghc_magic_hash:0:7}"

	log_indent_label 'Cabal version:' "${cabal_version}"
	[[ -n "${cabal_magic_hash}" ]] && log_indent_label 'Cabal magic hash:' "${cabal_magic_hash:0:7}"
	log_indent_label 'Cabal repository:' "${cabal_repo%%:*}"

	[[ -n "${sandbox_magic_hash}" ]] && log_indent_label 'Sandbox magic hash:' "${sandbox_magic_hash:0:7}"
	describe_extra 'Sandbox sources:' "${source_dir}/.halcyon-magic/sandbox-sources"
	describe_extra 'Sandbox extra apps:' "${source_dir}/.halcyon-magic/sandbox-extra-apps"
	describe_extra 'Sandbox extra libs:' "${source_dir}/.halcyon-magic/sandbox-extra-libs"

	local tag
	tag=$(
		create_tag "${HALCYON_PREFIX}" "${label}" "${source_hash}" "${constraints_hash}" "${magic_hash}" \
			"${ghc_version}" "${ghc_magic_hash}" \
			"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
			"${sandbox_magic_hash}" || die
	) || die

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'tag' ]]; then
		echo "${tag}"
		return 0
	fi

	log
	if ! do_deploy_app "${tag}" "${source_dir}" "${constraints}"; then
		log_warning 'Cannot deploy app'
		return 1
	fi

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		announce_deploy "${tag}" || die
	fi
}


deploy_local_app () {
	expect_vars HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE

	local local_dir
	expect_args local_dir -- "$@"

	local source_dir
	if ! (( HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE )); then
		source_dir=$( get_tmp_dir 'halcyon-source' ) || die

		copy_source_dir_over "${local_dir}" "${source_dir}" || die
	else
		source_dir="${local_dir}"
	fi

	local label
	if ! label=$( detect_label "${source_dir}" ); then
		die 'Cannot detect label'
	fi

	deploy_app "${label}" "${source_dir}" || return 1

	if ! (( HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE )); then
		rm -rf "${source_dir}" || die
	fi
}


deploy_cloned_app () {
	local url
	expect_args url -- "$@"

	local clone_dir source_dir
	clone_dir=$( get_tmp_dir 'halcyon-clone' ) || die
	source_dir=$( get_tmp_dir 'halcyon-source' ) || die

	log_begin "Cloning ${url}..."

	local commit_hash
	if ! commit_hash=$( git_clone_over "${url}" "${clone_dir}" ); then
		log_end 'error'
		die 'Cannot clone app'
	fi
	log_end "done, ${commit_hash:0:7}"

	copy_source_dir_over "${clone_dir}" "${source_dir}" || die

	local label
	if ! label=$( detect_label "${source_dir}" ); then
		die 'Cannot detect label'
	fi

	HALCYON_INTERNAL_REMOTE_SOURCE=1 \
		deploy_app "${label}" "${source_dir}" || return 1

	rm -rf "${clone_dir}" "${source_dir}" || die
}


deploy_unpacked_app () {
	local thing
	expect_args thing -- "$@"

	local unpack_dir source_dir
	unpack_dir=$( get_tmp_dir 'halcyon-unpack' ) || die
	source_dir=$( get_tmp_dir 'halcyon-source' ) || die

	HALCYON_NO_APP=1 \
	HALCYON_GHC_REBUILD=0 \
	HALCYON_CABAL_REBUILD=0 HALCYON_CABAL_UPDATE=0 \
	HALCYON_INTERNAL_NO_ANNOUNCE_DEPLOY=1 \
		deploy_env '/dev/null' || return 1

	log 'Unpacking app'

	local label
	label=$( cabal_unpack_over "${thing}" "${unpack_dir}" ) || die

	copy_source_dir_over "${unpack_dir}/${label}" "${source_dir}" || die

	if [[ "${label}" != "${thing}" ]]; then
		log_warning "Using implicit version of ${thing}"
		log_warning 'Expected label with explicit version'
	fi

	HALCYON_INTERNAL_REMOTE_SOURCE=1 \
		deploy_app "${label}" "${source_dir}" || return 1

	rm -rf "${unpack_dir}" "${source_dir}" || die
}


halcyon_deploy () {
	expect_vars HALCYON_NO_APP

	local cache_dir
	cache_dir=$( get_tmp_dir 'halcyon-cache' ) || die

	prepare_cache "${cache_dir}" || die

	install_pigz || die

	if (( HALCYON_NO_APP )); then
		deploy_env '/dev/null' || return 1
	elif ! (( $# )) || [[ "$1" == '' ]]; then
		if ! detect_label '.' >'/dev/null'; then
			HALCYON_NO_APP=1 \
				deploy_env '/dev/null' || return 1
		else
			deploy_local_app '.' || return 1
		fi
	else
		if validate_git_url "$1"; then
			deploy_cloned_app "$1" || return 1
		elif [[ -d "$1" ]]; then
			deploy_local_app "${1%/}" || return 1
		else
			deploy_unpacked_app "$1" || return 1
		fi

		if (( $# > 1 )); then
			shift
			log
			log_warning "Unexpected args: $*"
		fi
	fi

	clean_cache "${cache_dir}" || die

	rm -rf "${cache_dir}" || die
}
