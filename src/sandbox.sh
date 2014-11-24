create_sandbox_tag () {
	local label constraints_hash \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash
	expect_args label constraints_hash \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash -- "$@"

	create_tag '' "${label}" '' "${constraints_hash}" '' \
		"${ghc_version}" "${ghc_magic_hash}" \
		'' '' '' '' \
		"${sandbox_magic_hash}" || die
}


detect_sandbox_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_sandbox_tag '.*' '.*' '.*' '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect sandbox layer tag'
	fi

	echo "${tag}"
}


derive_sandbox_tag () {
	local tag
	expect_args tag -- "$@"

	local label constraints_hash ghc_version ghc_magic_hash sandbox_magic_hash
	label=$( get_tag_label "${tag}" ) || die
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	create_sandbox_tag "${label}" "${constraints_hash}" \
		"${ghc_version}" "${ghc_magic_hash}" \
		"${sandbox_magic_hash}" || die
}


derive_matching_sandbox_tag () {
	local tag label constraints_hash
	expect_args tag label constraints_hash -- "$@"

	local ghc_version ghc_magic_hash sandbox_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	create_sandbox_tag "${label}" "${constraints_hash}" \
		"${ghc_version}" "${ghc_magic_hash}" \
		"${sandbox_magic_hash}" || die
}


format_sandbox_id () {
	local tag
	expect_args tag -- "$@"

	local constraints_hash sandbox_magic_hash
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "${constraints_hash:0:7}${sandbox_magic_hash:+.${sandbox_magic_hash:0:7}}"
}


format_sandbox_description () {
	local tag
	expect_args tag -- "$@"

	local label sandbox_id
	label=$( get_tag_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "${label} (${sandbox_id})"
}


format_sandbox_archive_name () {
	local tag
	expect_args tag -- "$@"

	local label sandbox_id
	label=$( get_tag_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-${sandbox_id}-${label}.tar.gz"
}


format_sandbox_constraints_file_name () {
	local tag
	expect_args tag -- "$@"

	local label sandbox_id
	label=$( get_tag_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-constraints-${sandbox_id}-${label}.cabal.config"
}


format_sandbox_constraints_file_name_prefix () {
	echo "halcyon-sandbox-constraints-"
}


format_full_sandbox_constraints_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local sandbox_id
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-constraints-${sandbox_id}-.*.cabal.config"
}


format_partial_sandbox_constraints_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local sandbox_magic_hash
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "halcyon-sandbox-constraints-.*${sandbox_magic_hash:+.${sandbox_magic_hash:0:7}}-.*.cabal.config"
}


format_sandbox_common_file_name_prefix () {
	echo "halcyon-sandbox-"
}


format_sandbox_common_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local label
	label=$( get_tag_label "${tag}" ) || die

	echo "halcyon-sandbox-.*-${label}.(tar.gz|cabal.config)"
}


map_sandbox_constraints_file_name_to_label () {
	local constraints_name
	expect_args constraints_name -- "$@"

	local label_etc
	label_etc="${constraints_name#halcyon-sandbox-constraints-*-}"

	echo "${label_etc%.cabal.config}"
}


hash_sandbox_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" \( -path './ghc*' -or -path './sandbox*' \) || die
}


copy_sandbox_magic () {
	expect_vars HALCYON_APP_DIR

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${HALCYON_APP_DIR}/sandbox"

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die
	if [[ -z "${sandbox_magic_hash}" ]]; then
		return 0
	fi

	find_tree "${source_dir}/.halcyon-magic" -type f \( -path './ghc*' -or -path './sandbox*' \) |
		while read -r file; do
			copy_file "${source_dir}/.halcyon-magic/${file}" \
				"${HALCYON_APP_DIR}/sandbox/.halcyon-magic/${file}" || die
		done || die
}


add_sandbox_sources () {
	expect_vars HALCYON_APP_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if [[ ! -f "${source_dir}/.halcyon-magic/sandbox-sources" ]]; then
		return 0
	fi

	log 'Adding sandbox sources'

	local -a sandbox_sources
	sandbox_sources=( $( <"${source_dir}/.halcyon-magic/sandbox-sources" ) ) || die

	local sandbox_url
	for sandbox_url in "${sandbox_sources[@]:-}"; do
		if ! validate_git_url "${sandbox_url}"; then
			die 'Cannot validate sandbox source URL'
		fi

		local dir_name repo_dir
		dir_name=$( basename "${sandbox_url%.git}" ) || die
		repo_dir="${HALCYON_APP_DIR}/sandbox/.halcyon-sandbox-sources/${dir_name}"

		local commit_hash
		if [[ ! -d "${repo_dir}" ]]; then
			log_indent_begin "Cloning ${sandbox_url}..."

			if ! commit_hash=$( git_clone_over "${sandbox_url}" "${repo_dir}" ); then
				log_end 'error'
				die 'Cannot clone sandbox source'
			fi
		else
			log_indent_begin "Updating ${sandbox_url}..."

			if ! commit_hash=$( git_update_into "${sandbox_url}" "${repo_dir}" ); then
				log_end 'error'
				die 'Cannot update sandbox source'
			fi
		fi
		log_end "done, ${commit_hash:0:7}"

		sandboxed_cabal_do "${source_dir}" sandbox add-source "${repo_dir}" || die
	done
}


install_sandbox_extra_libs () {
	expect_vars HALCYON_APP_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	# NOTE: The lib dir is always created to prevent spurious linker warnings on OS X.

	mkdir -p "${HALCYON_APP_DIR}/sandbox/usr/lib" || die

	if [[ ! -f "${source_dir}/.halcyon-magic/sandbox-extra-libs" ]]; then
		return 0
	fi

	local platform description apt_dir
	platform=$( get_tag_platform "${tag}" ) || die
	description=$( format_platform_description "${platform}" ) || die
	apt_dir=$( get_tmp_dir 'halcyon-sandbox-extra-libs' ) || die

	log 'Installing sandbox extra libs'

	case "${platform}" in
	'linux-ubuntu-14.10-x86_64');&
	'linux-ubuntu-14.04-x86_64');&
	'linux-ubuntu-12.04-x86_64');&
	'linux-ubuntu-10.04-x86_64')
		true;;
	*)
		log_warning "Cannot install sandbox extra libs on ${description}"
		return 0
	esac

	local -a opts
	opts+=( -o debug::nolocking='true' )
	opts+=( -o dir::cache="${apt_dir}/cache" )
	opts+=( -o dir::state="${apt_dir}/state" )

	mkdir -p "${apt_dir}/cache/archives/partial" "${apt_dir}/state/lists/partial" || die

	log_indent_begin 'Updating package lists...'

	apt-get "${opts[@]}" update --quiet --quiet |& quote || die

	log_end 'done'

	local -a extra_libs
	extra_libs=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-libs" ) ) || die

	local extra_lib
	for extra_lib in "${extra_libs[@]:-}"; do
		apt-get "${opts[@]}" install --download-only --reinstall --yes "${extra_lib}" |& quote || die
	done

	find_tree "${apt_dir}/cache/archives" -type f -name '*.deb' |
		while read -r file; do
			dpkg --extract "${apt_dir}/cache/archives/${file}" \
				"${HALCYON_APP_DIR}/sandbox" |& quote || die
		done || die
}


deploy_sandbox_extra_apps () {
	expect_vars HALCYON_APP_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if [[ ! -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]]; then
		return 0
	fi

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	local constraints_dir
	constraints_dir="${source_dir}/.halcyon-magic/sandbox-extra-apps-constraints"

	local -a opts
	opts+=( --ghc-version="${ghc_version}" )
	opts+=( --cabal-version="${cabal_version}" )
	opts+=( --cabal-repo="${cabal_repo}" )
	opts+=( --prefix="${HALCYON_APP_DIR}/sandbox" )
	[[ -d "${constraints_dir}" ]] && opts+=( --constraints-dir="${constraints_dir}" )

	log 'Deploying sandbox extra apps'

	local -a extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) ) || die

	local extra_app index
	index=0
	for extra_app in "${extra_apps[@]:-}"; do
		index=$(( index + 1 ))
		if (( index > 1 )); then
			log
			log
		fi

		(
			HALCYON_INTERNAL_RECURSIVE=1 \
			HALCYON_INTERNAL_GHC_MAGIC_HASH="${ghc_magic_hash}" \
			HALCYON_INTERNAL_CABAL_MAGIC_HASH="${cabal_magic_hash}" \
				halcyon deploy "${opts[@]}" "${extra_app}" |& quote
		) || return 1
	done
}


build_sandbox_layer () {
	expect_vars HALCYON_APP_DIR

	local tag source_dir constraints must_create
	expect_args tag source_dir constraints must_create -- "$@"

	if (( must_create )); then
		rm -rf "${HALCYON_APP_DIR}/sandbox" || die
	else
		expect_existing "${HALCYON_APP_DIR}/sandbox/.halcyon-tag" \
			"${HALCYON_APP_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config"
	fi
	expect_existing "${source_dir}"

	log 'Building sandbox layer'

	if (( must_create )); then
		log 'Creating sandbox'

		mkdir -p "${HALCYON_APP_DIR}/sandbox" || die
		if ! cabal_do "${HALCYON_APP_DIR}/sandbox" sandbox init --sandbox '.' |& quote; then
			die 'Failed to create sandbox'
		fi
		mv "${HALCYON_APP_DIR}/sandbox/cabal.sandbox.config" "${HALCYON_APP_DIR}/sandbox/.halcyon-sandbox.config" || die
	fi

	add_sandbox_sources "${tag}" "${source_dir}" || die

	# NOTE: Listing executable-only packages in build-tools causes Cabal to expect the
	# executables to be installed, but not to install the packages.
	# https://github.com/haskell/cabal/issues/220

	# NOTE: Listing executable-only packages in build-depends causes Cabal to install the
	# packages, and to fail to recognise the packages have been installed.
	# https://github.com/haskell/cabal/issues/779

	if ! deploy_sandbox_extra_apps "${tag}" "${source_dir}"; then
		log_warning 'Cannot deploy sandbox extra apps'
		return 1
	fi

	install_sandbox_extra_libs "${tag}" "${source_dir}" || die

	if [[ -f "${source_dir}/.halcyon-magic/sandbox-pre-build-hook" ]]; then
		log 'Executing sandbox pre-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/sandbox-pre-build-hook" \
					"${tag}" "${source_dir}" "${constraints}" |& quote
		); then
			log_warning 'Cannot execute sandbox pre-build hook'
			return 1
		fi
		log 'Sandbox pre-build hook executed'
	fi

	log 'Building sandbox'

	# TODO: Improve cross-platform compatibility.

	local -a opts
	opts+=( --dependencies-only )

	if [[ -f "${source_dir}/.halcyon-magic/sandbox-extra-libs" ]]; then
		local platform
		platform=$( get_tag_platform "${tag}" ) || die

		case "${platform}" in
		'linux-ubuntu-14.10-x86_64');&
		'linux-ubuntu-14.04-x86_64');&
		'linux-ubuntu-12.04-x86_64');&
		'linux-ubuntu-10.04-x86_64')
			opts+=( --extra-lib-dirs="${HALCYON_APP_DIR}/sandbox/usr/lib" )
			opts+=( --extra-include-dirs="${HALCYON_APP_DIR}/sandbox/usr/include" )
			opts+=( --extra-include-dirs="${HALCYON_APP_DIR}/sandbox/usr/include/x86_64-linux-gnu" )
			;;
		*)
			true
		esac
	fi

	if ! sandboxed_cabal_do "${source_dir}" install "${opts[@]}" |& quote; then
		die 'Failed to build sandbox'
	fi

	format_constraints <<<"${constraints}" >"${HALCYON_APP_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config" || die
	copy_sandbox_magic "${source_dir}" || die

	local built_size
	built_size=$( get_size "${HALCYON_APP_DIR}/sandbox" ) || die

	log "Sandbox built, ${built_size}"

	if [[ -f "${source_dir}/.halcyon-magic/sandbox-post-build-hook" ]]; then
		log 'Executing sandbox post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/sandbox-post-build-hook" \
					"${tag}" "${source_dir}" "${constraints}" |& quote
		); then
			log_warning 'Cannot execute sandbox post-build hook'
			return 1
		fi
		log 'Sandbox post-build hook executed'
	fi

	if [[ -d "${HALCYON_APP_DIR}/sandbox/logs" || -d "${HALCYON_APP_DIR}/sandbox/share/doc" ]]; then
		log_indent_begin 'Removing documentation from sandbox layer...'

		rm -rf "${HALCYON_APP_DIR}/sandbox/logs" "${HALCYON_APP_DIR}/sandbox/share/doc" || die

		local trimmed_size
		trimmed_size=$( get_size "${HALCYON_APP_DIR}/sandbox" ) || die
		log_end "done, ${trimmed_size}"
	fi

	log_indent_begin 'Stripping sandbox layer...'

	strip_tree "${HALCYON_APP_DIR}/sandbox" || die

	local stripped_size
	stripped_size=$( get_size "${HALCYON_APP_DIR}/sandbox" ) || die
	log_end "done, ${stripped_size}"

	derive_sandbox_tag "${tag}" >"${HALCYON_APP_DIR}/sandbox/.halcyon-tag" || die
}


archive_sandbox_layer () {
	expect_vars HALCYON_APP_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE HALCYON_NO_DELETE
	expect_existing "${HALCYON_APP_DIR}/sandbox/.halcyon-tag" \
		"${HALCYON_APP_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local sandbox_tag platform ghc_version archive_name constraints_name
	sandbox_tag=$( detect_sandbox_tag "${HALCYON_APP_DIR}/sandbox/.halcyon-tag" ) || die
	platform=$( get_tag_platform "${sandbox_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${sandbox_tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${sandbox_tag}" ) || die
	constraints_name=$( format_sandbox_constraints_file_name "${sandbox_tag}" ) || die

	log 'Archiving sandbox layer'

	create_cached_archive "${HALCYON_APP_DIR}/sandbox" "${archive_name}" || die
	copy_file "${HALCYON_APP_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config" \
		"${HALCYON_CACHE_DIR}/${constraints_name}" || die

	local no_delete
	no_delete=0
	if ! upload_cached_file "${platform}/ghc-${ghc_version}" "${archive_name}"; then
		no_delete=1
	fi
	if ! upload_cached_file "${platform}/ghc-${ghc_version}" "${constraints_name}"; then
		no_delete=1
	fi
	if (( HALCYON_NO_DELETE )) || (( no_delete )); then
		return 0
	fi

	local common_prefix common_pattern
	common_prefix=$( format_sandbox_common_file_name_prefix ) || die
	common_pattern=$( format_sandbox_common_file_name_pattern "${sandbox_tag}" ) || die

	delete_matching_private_stored_files "${platform}/ghc-${ghc_version}" "${common_prefix}" "${common_pattern}" "(${archive_name}|${constraints_name})" || die
}


validate_sandbox_layer () {
	expect_vars HALCYON_APP_DIR

	local tag
	expect_args tag -- "$@"

	local sandbox_tag
	sandbox_tag=$( derive_sandbox_tag "${tag}" ) || die
	detect_tag "${HALCYON_APP_DIR}/sandbox/.halcyon-tag" "${sandbox_tag//./\.}" || return 1
}


restore_sandbox_layer () {
	expect_vars HALCYON_APP_DIR

	local tag
	expect_args tag -- "$@"

	local platform ghc_version archive_name description
	platform=$( get_tag_platform "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${tag}" ) || die
	description=$( format_sandbox_description "${tag}" ) || die

	if validate_sandbox_layer "${tag}" >'/dev/null'; then
		touch_cached_file "${archive_name}" || die
		return 0
	fi

	log 'Restoring sandbox layer'

	if ! extract_cached_archive_over "${archive_name}" "${HALCYON_APP_DIR}/sandbox" ||
		! validate_sandbox_layer "${tag}" >'/dev/null'
	then
		if ! cache_stored_file "${platform}/ghc-${ghc_version}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${HALCYON_APP_DIR}/sandbox" ||
			! validate_sandbox_layer "${tag}" >'/dev/null'
		then
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi
}


install_matching_sandbox_layer () {
	expect_vars HALCYON_APP_DIR

	local tag source_dir constraints matching_tag
	expect_args tag source_dir constraints matching_tag -- "$@"

	local constraints_hash matching_hash matching_description
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	matching_hash=$( get_tag_constraints_hash "${matching_tag}" ) || die
	matching_description=$( format_sandbox_description "${matching_tag}" ) || die

	if [[ "${matching_hash}" == "${constraints_hash}" ]]; then
		log_label 'Using fully matching sandbox layer:' "${matching_description}"

		restore_sandbox_layer "${matching_tag}" || return 1

		derive_sandbox_tag "${tag}" >"${HALCYON_APP_DIR}/sandbox/.halcyon-tag" || die
		return 0
	fi

	log_label 'Using partially matching sandbox layer:' "${matching_description}"

	restore_sandbox_layer "${matching_tag}" || return 1

	local must_create
	must_create=0
	build_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${must_create}" || return 1
}


install_sandbox_layer () {
	expect_vars HALCYON_NO_BUILD HALCYON_NO_BUILD_DEPENDENCIES \
		HALCYON_SANDBOX_REBUILD

	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	if ! (( HALCYON_SANDBOX_REBUILD )); then
		if restore_sandbox_layer "${tag}"; then
			return 0
		fi

		local matching_tag
		if matching_tag=$( match_sandbox_layer "${tag}" "${constraints}" ) &&
			install_matching_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${matching_tag}"
		then
			archive_sandbox_layer || die
			return 0
		fi

		if (( HALCYON_NO_BUILD )) || (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_warning 'Cannot build sandbox layer'
			return 1
		fi
	fi

	local must_create
	must_create=1
	if ! build_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${must_create}"; then
		log_warning 'Cannot build sandbox layer'
		return 1
	fi
	archive_sandbox_layer || die
}
