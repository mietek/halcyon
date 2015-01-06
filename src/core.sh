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

	local -a extra_a
	extra_a=( $( <"${extra_file}" ) ) || die
	if [[ -z "${extra_a[@]:+_}" ]]; then
		return 0
	fi

	local only_first extra
	only_first="${extra_label}"
	for extra in "${extra_a[@]}"; do
		log_indent_label "${only_first}" "${extra}"
		only_first=''
	done
}


hash_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	# NOTE: The version number of Cabal and the contents of its package
	# database could conceivably be treated as dependencies.

	hash_tree "${source_dir}/.halcyon" -not -path './cabal*' || die
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


announce_install () {
	expect_vars HALCYON_NO_APP HALCYON_DEPENDENCIES_ONLY \
		HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL

	local tag
	expect_args tag -- "$@"

	if (( HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL )); then
		return 0
	fi

	if (( HALCYON_NO_APP )); then
		log_label 'GHC and Cabal installed'
		return 0
	fi

	local thing label
	if (( HALCYON_DEPENDENCIES_ONLY )); then
		thing='Dependencies'
	else
		thing='App'
	fi
	label=$( get_tag_label "${tag}" )

	case "${HALCYON_INTERNAL_COMMAND}" in
	'install')
		log
		log_label "${thing} installed:" "${label}"
		;;
	'build')
		log
		log_label "${thing} built:" "${label}"
	esac
}


do_install_ghc_and_cabal_dirs () {
	expect_vars HALCYON_INTERNAL_RECURSIVE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if ! validate_ghc_dir "${tag}" >'/dev/null' ||
			! validate_updated_cabal_dir "${tag}" >'/dev/null'
		then
			die 'Failed to validate existing GHC and Cabal directories'
		fi
		return 0
	fi

	install_ghc_dir "${tag}" "${source_dir}" || return 1
	log

	install_cabal_dir "${tag}" "${source_dir}" || return 1
	log
}


install_ghc_and_cabal_dirs () {
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
		log 'Installing GHC and Cabal'

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
	)

	if ! do_install_ghc_and_cabal_dirs "${tag}" "${source_dir}"; then
		log_warning 'Cannot install GHC and Cabal'
		return 1
	fi

	announce_install "${tag}" || die
}


do_fast_install_app () {
	local tag source_dir
	expect_args tag source_dir -- "$@"

	local label install_dir
	label=$( get_tag_label "${tag}" )
	install_dir=$( get_tmp_dir 'halcyon-install' ) || die

	restore_install_dir "${tag}" "${install_dir}/${label}" || return 1
	install_app "${tag}" "${source_dir}" "${install_dir}/${label}" || die
	link_cabal_config || die

	rm -rf "${install_dir}"
}


fast_install_app () {
	expect_vars HALCYON_PREFIX HALCYON_DEPENDENCIES_ONLY HALCYON_RESTORE_DEPENDENCIES \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE HALCYON_APP_REINSTALL \
		HALCYON_GHC_VERSION HALCYON_GHC_REBUILD \
		HALCYON_CABAL_REBUILD HALCYON_CABAL_UPDATE \
		HALCYON_SANDBOX_REBUILD \
		HALCYON_INTERNAL_RECURSIVE

	local label source_hash source_dir
	expect_args label source_hash source_dir -- "$@"
	expect_existing "${source_dir}"

	if (( HALCYON_DEPENDENCIES_ONLY )) || (( HALCYON_RESTORE_DEPENDENCIES )) ||
		(( HALCYON_APP_REBUILD )) || (( HALCYON_APP_RECONFIGURE )) || (( HALCYON_APP_REINSTALL )) ||
		(( HALCYON_GHC_REBUILD )) ||
		(( HALCYON_CABAL_REBUILD )) || (( HALCYON_CABAL_UPDATE )) ||
		(( HALCYON_SANDBOX_REBUILD ))
	then
		return 1
	fi

	log_indent_label 'Label:' "${label}"
	log_indent_label 'Prefix:' "${HALCYON_PREFIX}"
	log_indent_label 'Source hash:' "${source_hash:0:7}"
	log_indent_label 'GHC version:' "${HALCYON_GHC_VERSION}"

	describe_storage || die
	log

	local tag
	tag=$(
		create_tag "${HALCYON_PREFIX}" "${label}" "${source_hash}" '' '' \
			"${HALCYON_GHC_VERSION}" '' \
			'' '' '' '' \
			''
	)

	if ! do_fast_install_app "${tag}" "${source_dir}"; then
		log
		return 1
	fi

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		announce_install "${tag}" || die
		touch_cached_ghc_and_cabal_files || die
	fi
}


prepare_file_option () {
	local magic_var magic_file
	expect_args magic_var magic_file -- "$@"

	if [[ -z "${magic_var}" ]]; then
		return 0
	fi

	copy_file "${magic_var}" "${magic_file}" || die
}


prepare_file_strings_option () {
	local magic_var magic_file
	expect_args magic_var magic_file -- "$@"

	if [[ -z "${magic_var}" ]]; then
		return 0
	fi
	if [[ -f "${magic_var}" ]]; then
		copy_file "${magic_var}" "${magic_file}" || die
		return 0
	fi

	local -a strings_a
	strings_a=( ${magic_var} )

	copy_file <( IFS=$'\n' && echo "${strings_a[*]}" ) "${magic_file}" || die
}


prepare_constraints_option () {
	local magic_var magic_file
	expect_args magic_var magic_file -- "$@"

	if [[ -z "${magic_var}" ]]; then
		return 0
	fi
	if [[ -d "${magic_var}" ]]; then
		copy_dir_over "${magic_var}" "${magic_file}" || die
		return 0
	fi
	if [[ -f "${magic_var}" ]]; then
		copy_file "${magic_var}" "${magic_file}" || die
		return 0
	fi

	copy_file <( echo "${magic_var}" ) "${magic_file}" || die
}


prepare_source_dir () {
	local label source_dir
	expect_args label source_dir -- "$@"
	expect_existing "${source_dir}"

	local magic_dir
	magic_dir="${source_dir}/.halcyon"

# Build-time magic files
	prepare_file_strings_option "${HALCYON_EXTRA_CONFIGURE_FLAGS}" "${magic_dir}/extra-configure-flags" || die
	prepare_file_option "${HALCYON_PRE_BUILD_HOOK}" "${magic_dir}/pre-build-hook" || die
	prepare_file_option "${HALCYON_POST_BUILD_HOOK}" "${magic_dir}/post-build-hook" || die

# Install-time magic files
	prepare_file_strings_option "${HALCYON_EXTRA_APPS}" "${magic_dir}/extra-apps" || die
	prepare_constraints_option "${HALCYON_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/extra-apps-constraints" || die
	prepare_file_strings_option "${HALCYON_EXTRA_DATA_FILES}" "${magic_dir}/extra-data-files" || die
	prepare_file_strings_option "${HALCYON_EXTRA_OS_PACKAGES}" "${magic_dir}/extra-os-packages" || die
	prepare_file_strings_option "${HALCYON_EXTRA_DEPENDENCIES}" "${magic_dir}/extra-dependencies" || die
	prepare_file_option "${HALCYON_PRE_INSTALL_HOOK}" "${magic_dir}/pre-install-hook" || die
	prepare_file_option "${HALCYON_POST_INSTALL_HOOK}" "${magic_dir}/post-install-hook" || die

# GHC magic files
	prepare_file_option "${HALCYON_GHC_PRE_BUILD_HOOK}" "${magic_dir}/ghc-pre-build-hook" || die
	prepare_file_option "${HALCYON_GHC_POST_BUILD_HOOK}" "${magic_dir}/ghc-post-build-hook" || die

# Cabal magic files
	prepare_file_option "${HALCYON_CABAL_PRE_BUILD_HOOK}" "${magic_dir}/cabal-pre-build-hook" || die
	prepare_file_option "${HALCYON_CABAL_POST_BUILD_HOOK}" "${magic_dir}/cabal-post-build-hook" || die
	prepare_file_option "${HALCYON_CABAL_PRE_UPDATE_HOOK}" "${magic_dir}/cabal-pre-update-hook" || die
	prepare_file_option "${HALCYON_CABAL_POST_UPDATE_HOOK}" "${magic_dir}/cabal-post-update-hook" || die

# Sandbox magic files
	prepare_file_strings_option "${HALCYON_SANDBOX_EXTRA_CONFIGURE_FLAGS}" "${magic_dir}/sandbox-extra-configure-flags" || die
	prepare_file_strings_option "${HALCYON_SANDBOX_SOURCES}" "${magic_dir}/sandbox-sources" || die
	prepare_file_strings_option "${HALCYON_SANDBOX_EXTRA_APPS}" "${magic_dir}/sandbox-extra-apps" || die
	prepare_constraints_option "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/sandbox-extra-apps-constraints" || die
	prepare_file_strings_option "${HALCYON_SANDBOX_EXTRA_OS_PACKAGES}" "${magic_dir}/sandbox-extra-os-packages" || die
	prepare_file_option "${HALCYON_SANDBOX_PRE_BUILD_HOOK}" "${magic_dir}/sandbox-pre-build-hook" || die
	prepare_file_option "${HALCYON_SANDBOX_POST_BUILD_HOOK}" "${magic_dir}/sandbox-post-build-hook" || die
}


do_full_install_app () {
	expect_vars HALCYON_BASE HALCYON_DEPENDENCIES_ONLY \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE HALCYON_APP_REINSTALL \
		HALCYON_SANDBOX_REBUILD \
		HALCYON_INTERNAL_RECURSIVE

	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	local label build_dir install_dir saved_sandbox
	label=$( get_tag_label "${tag}" )
	build_dir=$( get_tmp_dir 'halcyon-build' ) || die
	install_dir=$( get_tmp_dir 'halcyon-install' ) || die
	saved_sandbox=''

	do_install_ghc_and_cabal_dirs "${tag}" "${source_dir}" || return 1

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if [[ -d "${HALCYON_BASE}/sandbox" ]]; then
			saved_sandbox=$( get_tmp_dir 'halcyon-saved-sandbox' ) || die
			mv "${HALCYON_BASE}/sandbox" "${saved_sandbox}" || die
		fi
	fi

	install_sandbox_dir "${tag}" "${source_dir}" "${constraints}" || return 1
	validate_actual_constraints "${tag}" "${source_dir}" "${constraints}" || die
	log

	if ! (( HALCYON_DEPENDENCIES_ONLY )); then
		build_app "${tag}" "${source_dir}" "${build_dir}/${label}" || return 1
	fi

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
		! (( HALCYON_DEPENDENCIES_ONLY ))
	then
		log

		local must_prepare
		must_prepare=1
		if ! (( HALCYON_APP_REBUILD )) &&
			! (( HALCYON_APP_RECONFIGURE )) &&
			! (( HALCYON_APP_REINSTALL )) &&
			! (( HALCYON_SANDBOX_REBUILD )) &&
			restore_install_dir "${tag}" "${install_dir}/${label}"
		then
			must_prepare=0
		fi
		if (( must_prepare )); then
			if ! prepare_install_dir "${tag}" "${source_dir}" "${constraints}" "${build_dir}/${label}" "${install_dir}/${label}"; then
				log_warning 'Cannot prepare install directory'
				return 1
			fi
			archive_install_dir "${install_dir}/${label}" || die
		fi
	fi

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if [[ -n "${saved_sandbox}" ]]; then
			rm -rf "${HALCYON_BASE}/sandbox" || die
			mv "${saved_sandbox}" "${HALCYON_BASE}/sandbox" || die
		fi
	fi

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
		! (( HALCYON_DEPENDENCIES_ONLY ))
	then
		install_app "${tag}" "${source_dir}" "${install_dir}/${label}" || die
		link_cabal_config || die
	fi

	rm -rf "${build_dir}" "${install_dir}" || die
}


full_install_app () {
	expect_vars HALCYON_PREFIX HALCYON_DEPENDENCIES_ONLY \
		HALCYON_CABAL_VERSION HALCYON_CABAL_REPO \
		HALCYON_INTERNAL_RECURSIVE

	local label source_dir
	expect_args label source_dir -- "$@"
	expect_existing "${source_dir}"

	case "${HALCYON_INTERNAL_COMMAND}" in
	'label')
		echo "${label}"
		return 0
		;;
	'executable')
		local executable
		if ! executable=$( detect_executable "${source_dir}" ); then
			die 'Failed to detect executable'
		fi

		echo "${executable}"
		return 0
		;;
	esac

	log "Installing ${label}"

	# NOTE: This is the first of two moments when source_dir is modified.

	prepare_constraints "${label}" "${source_dir}" || die
	prepare_source_dir "${label}" "${source_dir}" || die

	local source_hash
	if [[ -f "${source_dir}/cabal.config" ]]; then
		source_hash=$( hash_tree "${source_dir}" ) || die

		if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
			fast_install_app "${label}" "${source_hash}" "${source_dir}"
		then
			return 0
		fi
	fi

	local constraints
	constraints=''
	if [[ -f "${source_dir}/cabal.config" ]]; then
		log 'Determining constraints'

		if ! constraints=$( detect_constraints "${label}" "${source_dir}" ); then
			die 'Failed to determine constraints'
		fi
	fi
	if [[ -z "${constraints}" ]]; then
		HALCYON_GHC_REBUILD=0 \
		HALCYON_CABAL_REBUILD=0 HALCYON_CABAL_UPDATE=0 \
		HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL=1 \
			install_ghc_and_cabal_dirs "${source_dir}" || return 1

		log 'Determining constraints'

		if ! constraints=$( cabal_determine_constraints "${label}" "${source_dir}" ); then
			die 'Failed to determine constraints'
		fi

		log_warning 'Using newest versions of all packages'
		if [[ "${HALCYON_INTERNAL_COMMAND}" != 'constraints' ]]; then
			format_constraints <<<"${constraints}" | quote
			log
		fi

		# NOTE: This is the second of two moments when source_dir is modified.

		if ! format_constraints_to_cabal_freeze <<<"${constraints}" >"${source_dir}/cabal.config"; then
			log_error 'Failed to write cabal.config file'
			return 1
		fi

		source_hash=$( hash_tree "${source_dir}" ) || die

		if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
			fast_install_app "${label}" "${source_hash}" "${source_dir}"
		then
			return 0
		fi
	fi
	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'constraints' ]]; then
		format_constraints <<<"${constraints}"
		return 0
	fi

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

	log_indent_label 'Label:' "${label}"
	log_indent_label 'Prefix:' "${HALCYON_PREFIX}"
	log_indent_label 'Source hash:' "${source_hash:0:7}"

	log_indent_label 'Constraints hash:' "${constraints_hash:0:7}"
	describe_extra 'Extra configure flags:' "${source_dir}/.halcyon/extra-configure-flags"
	describe_extra 'Extra apps:' "${source_dir}/.halcyon/extra-apps"
	describe_extra 'Extra data files:' "${source_dir}/.halcyon/extra-data-files"
	describe_extra 'Extra OS packages:' "${source_dir}/.halcyon/extra-os-packages"
	describe_extra 'Extra dependencies:' "${source_dir}/.halcyon/extra-dependencies"
	[[ -n "${magic_hash}" ]] && log_indent_label 'Magic hash:' "${magic_hash:0:7}"

	describe_storage || die

	log_indent_label 'GHC version:' "${ghc_version}"
	[[ -n "${ghc_magic_hash}" ]] && log_indent_label 'GHC magic hash:' "${ghc_magic_hash:0:7}"

	log_indent_label 'Cabal version:' "${cabal_version}"
	[[ -n "${cabal_magic_hash}" ]] && log_indent_label 'Cabal magic hash:' "${cabal_magic_hash:0:7}"
	log_indent_label 'Cabal repository:' "${cabal_repo%%:*}"

	[[ -n "${sandbox_magic_hash}" ]] && log_indent_label 'Sandbox magic hash:' "${sandbox_magic_hash:0:7}"
	describe_extra 'Sandbox extra configure flags:' "${source_dir}/.halcyon/sandbox-extra-configure-flags"
	describe_extra 'Sandbox sources:' "${source_dir}/.halcyon/sandbox-sources"
	describe_extra 'Sandbox extra apps:' "${source_dir}/.halcyon/sandbox-extra-apps"
	describe_extra 'Sandbox extra OS packages:' "${source_dir}/.halcyon/sandbox-extra-os-packages"

	local tag
	tag=$(
		create_tag "${HALCYON_PREFIX}" "${label}" "${source_hash}" "${constraints_hash}" "${magic_hash}" \
			"${ghc_version}" "${ghc_magic_hash}" \
			"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
			"${sandbox_magic_hash}"
	)

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'tag' ]]; then
		echo "${tag}"
		return 0
	fi

	log
	if ! do_full_install_app "${tag}" "${source_dir}" "${constraints}"; then
		log_warning 'Cannot install app'
		return 1
	fi

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		announce_install "${tag}" || die
	fi
}


install_local_app () {
	expect_vars HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE

	local local_dir
	expect_args local_dir -- "$@"

	local label
	if ! label=$( detect_label "${local_dir}" ); then
		die 'Failed to detect label'
	fi

	if (( HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE )); then
		full_install_app "${label}" "${local_dir}" || return 1
		return 0
	fi

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon-source' ) || die

	copy_source_dir_over "${local_dir}" "${source_dir}/${label}" || die

	full_install_app "${label}" "${source_dir}/${label}" || return 1

	rm -rf "${source_dir}" || die
}


install_cloned_app () {
	local url
	expect_args url -- "$@"

	local clone_dir source_dir
	clone_dir=$( get_tmp_dir 'halcyon-clone' ) || die
	source_dir=$( get_tmp_dir 'halcyon-source' ) || die

	log_begin "Cloning ${url}..."

	local commit_hash
	if ! commit_hash=$( git_clone_over "${url}" "${clone_dir}" ); then
		log_end 'error'
		die 'Failed to clone app'
	fi
	log_end "done, ${commit_hash:0:7}"

	local label
	if ! label=$( detect_label "${clone_dir}" ); then
		die 'Failed to detect label'
	fi

	copy_source_dir_over "${clone_dir}" "${source_dir}/${label}" || die

	HALCYON_INTERNAL_REMOTE_SOURCE=1 \
		full_install_app "${label}" "${source_dir}/${label}" || return 1

	rm -rf "${clone_dir}" "${source_dir}" || die
}


install_unpacked_app () {
	local thing
	expect_args thing -- "$@"

	local unpack_dir source_dir
	unpack_dir=$( get_tmp_dir 'halcyon-unpack' ) || die
	source_dir=$( get_tmp_dir 'halcyon-source' ) || die

	HALCYON_NO_APP=1 \
	HALCYON_GHC_REBUILD=0 \
	HALCYON_CABAL_REBUILD=0 HALCYON_CABAL_UPDATE=0 \
	HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL=1 \
		install_ghc_and_cabal_dirs '/dev/null' || return 1

	log 'Unpacking app'

	local label
	label=$( cabal_unpack_over "${thing}" "${unpack_dir}" ) || die

	copy_source_dir_over "${unpack_dir}/${label}" "${source_dir}/${label}" || die

	if [[ "${label}" != "${thing}" ]]; then
		log_warning "Using newest version of ${thing}: ${label}"
	fi

	HALCYON_INTERNAL_REMOTE_SOURCE=1 \
		full_install_app "${label}" "${source_dir}/${label}" || return 1

	rm -rf "${unpack_dir}" "${source_dir}" || die
}


halcyon_install () {
	expect_vars HALCYON_NO_APP

	if (( $# > 1 )); then
		shift
		die "Unexpected args: $*"
	fi

	local cache_dir
	cache_dir=$( get_tmp_dir 'halcyon-cache' ) || die

	prepare_cache "${cache_dir}" || die

	if (( HALCYON_NO_APP )); then
		install_ghc_and_cabal_dirs '/dev/null' || return 1
	elif ! (( $# )) || [[ "$1" == '' ]]; then
		if ! detect_label '.' >'/dev/null'; then
			HALCYON_NO_APP=1 \
				install_ghc_and_cabal_dirs '/dev/null' || return 1
		else
			install_local_app '.' || return 1
		fi
	else
		if validate_git_url "$1"; then
			install_cloned_app "$1" || return 1
		elif [[ -d "$1" ]]; then
			install_local_app "${1%/}" || return 1
		else
			install_unpacked_app "$1" || return 1
		fi
	fi

	clean_cache "${cache_dir}" || die

	rm -rf "${cache_dir}" || die
}
