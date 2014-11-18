create_install_tag () {
	local prefix label source_hash
	expect_args prefix label source_hash -- "$@"

	create_tag "${prefix}" "${label}" "${source_hash}" '' '' \
		'' '' \
		'' '' '' '' \
		'' || die
}


detect_install_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_install_tag '.*' '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect install tag'
	fi

	echo "${tag}"
}


derive_install_tag () {
	local tag
	expect_args tag -- "$@"

	local prefix label source_hash
	prefix=$( get_tag_prefix "${tag}" ) || die
	label=$( get_tag_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	create_install_tag "${prefix}" "${label}" "${source_hash}" || die
}


format_install_id () {
	local tag
	expect_args tag -- "$@"

	local label source_hash
	label=$( get_tag_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${source_hash:0:7}-${label}"
}


format_install_archive_name () {
	local tag
	expect_args tag -- "$@"

	local install_id
	install_id=$( format_install_id "${tag}" ) || die

	echo "halcyon-install-${install_id}.tar.gz"
}


format_install_archive_name_prefix () {
	echo 'halcyon-install-'
}


format_install_archive_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local label
	label=$( get_tag_label "${tag}" ) || die

	echo "halcyon-install-.*-${label//./\.}.tar.gz"
}


deploy_extra_apps () {
	local tag source_dir install_dir
	expect_args tag source_dir install_dir -- "$@"

	if [[ ! -f "${source_dir}/.halcyon-magic/extra-apps" ]]; then
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
	constraints_dir="${source_dir}/.halcyon-magic/extra-apps-constraints"

	local -a opts
	opts+=( --root="${install_dir}" )
	opts+=( --ghc-version="${ghc_version}" )
	opts+=( --cabal-version="${cabal_version}" )
	opts+=( --cabal-repo="${cabal_repo}" )
	[[ -d "${constraints_dir}" ]] && opts+=( --constraints-dir="${constraints_dir}" )

	log 'Deploying extra apps'

	local -a extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/extra-apps" ) ) || die

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


prepare_install_dir () {
	expect_vars HALCYON_APP_DIR \
		HALCYON_INCLUDE_SOURCE HALCYON_INCLUDE_BUILD HALCYON_INCLUDE_ALL

	local tag source_dir build_dir install_dir
	expect_args tag source_dir build_dir install_dir -- "$@"
	expect_existing "${build_dir}/.halcyon-tag"

	local prefix
	prefix=$( get_tag_prefix "${tag}" ) || die

	log 'Preparing install'

	if (( HALCYON_INCLUDE_SOURCE )) || (( HALCYON_INCLUDE_ALL )); then
		log_indent 'Copying source'

		copy_dir_into "${source_dir}" "${install_dir}${HALCYON_APP_DIR}" || die
	fi

	if (( HALCYON_INCLUDE_BUILD )) || (( HALCYON_INCLUDE_ALL )); then
		log_indent 'Copying build'

		copy_dir_into "${build_dir}" "${install_dir}${HALCYON_APP_DIR}" || die
	fi

	log_indent 'Copying app'

	# NOTE: PATH is extended to silence a misleading Cabal warning.

	if ! (
		PATH="${install_dir}${prefix}:${PATH}" \
			sandboxed_cabal_do "${build_dir}" copy --destdir="${install_dir}" --verbose=0 |& quote
	); then
		die 'Failed to copy app'
	fi

	if ! deploy_extra_apps "${tag}" "${source_dir}" "${install_dir}"; then
		log_warning 'Cannot deploy extra apps'
		return 1
	fi

	if (( HALCYON_INCLUDE_ALL )); then
		log_indent 'Copying GHC layer'

		copy_dir_into "${HALCYON_APP_DIR}/ghc" "${install_dir}${HALCYON_APP_DIR}/ghc" || die

		log_indent 'Copying Cabal layer'

		copy_dir_into "${HALCYON_APP_DIR}/cabal" "${install_dir}${HALCYON_APP_DIR}/cabal" || die

		log_indent 'Copying sandbox layer'

		copy_dir_into "${HALCYON_APP_DIR}/sandbox" "${install_dir}${HALCYON_APP_DIR}/sandbox" || die
	else
		# NOTE: Cabal libraries may require data files at runtime.  See filestore for an example.
		# https://haskell.org/cabal/users-guide/developing-packages.html#accessing-data-files-from-package-code

		if find_tree "${HALCYON_APP_DIR}/sandbox/share" -type f |
			match_at_least_one >'/dev/null'
		then
			copy_dir_into "${HALCYON_APP_DIR}/sandbox/share" "${install_dir}${HALCYON_APP_DIR}/sandbox/share" || die
		fi
	fi

	local prepared_size
	prepared_size=$( get_size "${install_dir}" ) || die

	log "Install prepared, ${prepared_size}"

	if [[ -d "${install_dir}/share/doc" ]]; then
		log_indent_begin 'Removing documentation from install...'

		rm -rf "${install_dir}/share/doc" || die

		local trimmed_size
		trimmed_size=$( get_size "${install_dir}" ) || die
		log_end "done, ${trimmed_size}"
	fi

	derive_install_tag "${tag}" >"${install_dir}/.halcyon-tag" || die
}


archive_install_dir () {
	expect_vars HALCYON_NO_ARCHIVE_ANY HALCYON_NO_DELETE_ANY

	local install_dir
	expect_args install_dir -- "$@"
	expect_existing "${install_dir}/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE_ANY )); then
		return 0
	fi

	local install_tag platform archive_name
	install_tag=$( detect_install_tag "${install_dir}/.halcyon-tag" ) || die
	platform=$( get_tag_platform "${install_tag}" ) || die
	archive_name=$( format_install_archive_name "${install_tag}" ) || die

	log 'Archiving install'

	create_cached_archive "${install_dir}" "${archive_name}" || die
	if ! upload_cached_file "${platform}" "${archive_name}"; then
		return 0
	fi

	if (( HALCYON_NO_DELETE_ANY )); then
		return 0
	fi

	local archive_prefix archive_pattern
	archive_prefix=$( format_install_archive_name_prefix ) || die
	archive_pattern=$( format_install_archive_name_pattern "${install_tag}" ) || die

	delete_matching_private_stored_files "${platform}" "${archive_prefix}" "${archive_pattern}" "${archive_name}" || die
}


validate_install_dir () {
	local tag install_dir
	expect_args tag install_dir -- "$@"

	local install_tag
	install_tag=$( derive_install_tag "${tag}" ) || die
	detect_tag "${install_dir}/.halcyon-tag" "${install_tag//./\.}" || return 1
}


restore_install_dir () {
	local tag install_dir
	expect_args tag install_dir -- "$@"

	local platform archive_name archive_pattern
	platform=$( get_tag_platform "${tag}" ) || die
	archive_name=$( format_install_archive_name "${tag}" ) || die
	archive_pattern=$( format_install_archive_name_pattern "${tag}" ) || die

	log 'Restoring install'

	if ! extract_cached_archive_over "${archive_name}" "${install_dir}" ||
		! validate_install_dir "${tag}" "${install_dir}" >'/dev/null'
	then
		if ! cache_stored_file "${platform}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${install_dir}" ||
			! validate_install_dir "${tag}" "${install_dir}" >'/dev/null'
		then
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi

	log 'Install restored'
}


install_app () {
	expect_vars HALCYON_APP_DIR \
		HALCYON_INTERNAL_RECURSIVE HALCYON_INTERNAL_NO_PURGE_APP_DIR

	local tag source_dir install_dir root
	expect_args tag source_dir install_dir root -- "$@"

	if ! (( HALCYON_INTERNAL_RECURSIVE )) &&
		! (( HALCYON_INTERNAL_NO_PURGE_APP_DIR ))
	then
		rm -rf "${HALCYON_APP_DIR}" || die
	fi

	local saved_tag
	saved_tag=''
	if [[ -f "${install_dir}/.halcyon-tag" ]]; then
		saved_tag=$( get_tmp_file 'halcyon-saved-tag' ) || die
		mv "${install_dir}/.halcyon-tag" "${saved_tag}" || die
	fi

	if [[ -f "${source_dir}/.halcyon-magic/pre-install-hook" ]]; then
		log 'Executing pre-install hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/pre-install-hook" \
					"${tag}" "${source_dir}" "${install_dir}" "${root}" |& quote
		); then
			log_warning 'Cannot execute pre-install hook'
			return 1
		fi
		log 'Pre-install hook executed'
	fi

	log_begin "Installing app in ${HALCYON_APP_DIR}..."

	# NOTE: When / is read-only, but HALCYON_APP_DIR is not, cp -Rp fails, but cp -R succeeds.
	# Copying .halcyon-tag is avoided for the same reason.

	mkdir -p "${root}" || die
	cp -R "${install_dir}/." "${root}" |& quote || die

	local installed_size
	installed_size=$( get_size "${install_dir}" ) || die
	log_end "done, ${installed_size}"

	if [[ -f "${source_dir}/.halcyon-magic/post-install-hook" ]]; then
		log 'Executing post-install hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/post-install-hook" \
					"${tag}" "${source_dir}" "${install_dir}" "${root}" |& quote
		); then
			log_warning 'Cannot execute post-install hook'
			return 1
		fi
		log 'Post-install hook executed'
	fi

	if [[ -n "${saved_tag}" ]]; then
		mv "${saved_tag}" "${install_dir}/.halcyon-tag" || die
	fi
}
