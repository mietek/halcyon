create_slug_tag () {
	local app_label target source_hash
	expect_args app_label target source_hash -- "$@"

	create_tag "${app_label}" "${target}" \
		"${source_hash}" ''           \
		'' ''                         \
		'' '' '' ''                   \
		'' '' || die
}


detect_slug_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_slug_tag '.*' '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect slug tag'
	fi

	echo "${tag}"
}


derive_slug_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label target source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	target=$( get_tag_target "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	create_slug_tag "${app_label}" "${target}" "${source_hash}" || die
}


format_slug_id () {
	local tag
	expect_args tag -- "$@"

	local app_label source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${source_hash:0:7}-${app_label}"
}


format_slug_description () {
	local tag
	expect_args tag -- "$@"

	local app_label source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${app_label} (${source_hash:0:7})"
}


format_slug_archive_name () {
	local tag
	expect_args tag -- "$@"

	local slug_id
	slug_id=$( format_slug_id "${tag}" ) || die

	echo "halcyon-slug-${slug_id}.tar.gz"
}


format_slug_archive_name_prefix () {
	echo 'halcyon-slug-'
}


format_slug_archive_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	echo "halcyon-slug-.*-${app_label//./\.}.tar.gz"
}


deploy_slug_extra_apps () {
	local tag source_dir slug_dir
	expect_args tag source_dir slug_dir -- "$@"

	if [[ ! -f "${source_dir}/.halcyon-magic/slug-extra-apps" ]]; then
		return 0
	fi

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	local -a env_opts
	env_opts+=( --install-dir="${slug_dir}" )
	env_opts+=( --recursive )
	env_opts+=( --ghc-version="${ghc_version}" )
	[[ -n "${ghc_magic_hash}" ]] && env_opts+=( --ghc_magic_hash="${ghc_magic_hash}" )
	env_opts+=( --cabal-version="${cabal_version}" )
	[[ -n "${cabal_magic_hash}" ]] && env_opts+=( --cabal_magic_hash="${cabal_magic_hash}" )
	env_opts+=( --cabal-repo="${cabal_repo}" )

	log 'Deploying slug extra apps'

	local -a slug_apps
	slug_apps=( $( <"${source_dir}/.halcyon-magic/slug-extra-apps" ) ) || die

	local slug_app index
	index=0
	for slug_app in "${slug_apps[@]}"; do
		index=$(( index + 1 ))
		if (( index > 1 )); then
			log
			log
		fi

		local constraints_file
		constraints_file="${source_dir}/.halcyon-magic/slug-extra-apps-constraints/${slug_app}.cabal.config"

		local -a opts
		opts=( "${env_opts[@]}" )
		[[ -f "${constraints_file}" ]] && opts+=( --constraints-file="${constraints_file}" )

		( deploy "${opts[@]}" "${slug_app}" |& quote ) || return 1
	done
}


build_slug () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local tag source_dir slug_dir
	expect_args tag source_dir slug_dir -- "$@"

	rm -rf "${slug_dir}" || die

	log 'Building slug'

	if [[ -f "${source_dir}/.halcyon-magic/slug-pre-build-hook" ]]; then
		log 'Executing slug pre-build hook'
		if ! (
			"${source_dir}/.halcyon-magic/slug-pre-build-hook" \
				"${tag}" "${source_dir}" "${slug_dir}" |& quote
		); then
			log_warning 'Cannot execute slug pre-build hook'
			return 1
		fi
		log 'Slug pre-build hook executed'
	fi

	log 'Copying app'

	# NOTE: Cabal libraries may require data files at runtime.  See filestore for an example.
	# http://www.haskell.org/cabal/users-guide/developing-packages.html#accessing-data-files-from-package-code

	if [[ -d "${HALCYON_DIR}/sandbox/share" ]]; then
		copy_dir_into "${HALCYON_DIR}/sandbox/share" "${slug_dir}${HALCYON_DIR}/sandbox/share" || die
	fi

	# NOTE: PATH is extended to silence a misleading Cabal warning.

	if ! (
		export PATH="${slug_dir}${HALCYON_DIR}/${HALCYON_TARGET}:${PATH}" &&
		sandboxed_cabal_do "${HALCYON_DIR}/app" copy --destdir="${slug_dir}" --verbose=0 |& quote
	); then
		die 'Failed to copy app'
	fi

	if ! deploy_slug_extra_apps "${tag}" "${source_dir}" "${slug_dir}"; then
		log_warning 'Cannot deploy slug extra apps'
		return 1
	fi

	local copied_size
	copied_size=$( size_tree "${slug_dir}" ) || die

	log "App copied, ${copied_size}"

	if [[ -f "${source_dir}/.halcyon-magic/slug-post-build-hook" ]]; then
		log 'Executing slug post-build hook'
		if ! (
			"${source_dir}/.halcyon-magic/slug-post-build-hook" \
				"${tag}" "${source_dir}" "${slug_dir}" |& quote
		); then
			log_warning 'Cannot execute slug post-build hook'
			return 1
		fi
		log 'Slug post-build hook executed'
	fi

	if [[ -d "${slug_dir}/share/doc" ]]; then
		log_indent_begin 'Removing documentation from slug...'

		rm -rf "${slug_dir}/share/doc" || die

		local trimmed_size
		trimmed_size=$( size_tree "${slug_dir}" ) || die
		log_end "done, ${trimmed_size}"
	fi

	log_indent_begin 'Stripping slug...'

	strip_tree "${slug_dir}" || die

	local stripped_size
	stripped_size=$( size_tree "${slug_dir}" ) || die
	log_end "done, ${stripped_size}"

	derive_slug_tag "${tag}" >"${slug_dir}/.halcyon-tag" || die
}


archive_slug () {
	expect_vars HALCYON_NO_ARCHIVE HALCYON_NO_DELETE

	local slug_dir
	expect_args slug_dir -- "$@"
	expect_existing "${slug_dir}/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local slug_tag os archive_name
	slug_tag=$( detect_slug_tag "${slug_dir}/.halcyon-tag" ) || die
	os=$( get_tag_os "${slug_tag}" ) || die
	archive_name=$( format_slug_archive_name "${slug_tag}" ) || die

	log 'Archiving slug'

	create_cached_archive "${slug_dir}" "${archive_name}" || die
	if ! upload_cached_file "${os}" "${archive_name}"; then
		return 0
	fi

	if (( HALCYON_NO_DELETE )); then
		return 0
	fi

	local archive_prefix archive_pattern
	archive_prefix=$( format_slug_archive_name_prefix ) || die
	archive_pattern=$( format_slug_archive_name_pattern "${slug_tag}" ) || die

	delete_matching_private_stored_files "${os}" "${archive_prefix}" "${archive_pattern}" "${archive_name}" || die
}


validate_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local slug_tag
	slug_tag=$( derive_slug_tag "${tag}" ) || die
	detect_tag "${slug_dir}/.halcyon-tag" "${slug_tag//./\.}" || return 1
}


restore_slug () {
	expect_vars

	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local os archive_name
	os=$( get_tag_os "${tag}" ) || die
	archive_name=$( format_slug_archive_name "${tag}" ) || die

	log 'Restoring slug'

	local restored_tag description
	if ! extract_cached_archive_over "${archive_name}" "${slug_dir}" ||
		! restored_tag=$( validate_slug "${tag}" "${slug_dir}" )
	then
		if ! cache_stored_file "${os}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${slug_dir}" ||
			! restored_tag=$( validate_slug "${tag}" "${slug_dir}" )
		then
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi
	description=$( format_slug_description "${restored_tag}" )

	log_pad 'Slug restored:' "${description}"
}


announce_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local installed_tag description
	installed_tag=$( validate_slug "${tag}" "${slug_dir}" ) || die
	description=$( format_slug_description "${installed_tag}" ) || die

	log_pad 'Slug installed:' "${description}"
}


apply_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local install_dir
	install_dir="${HALCYON_INSTALL_DIR:-/}"

	rm -f "${slug_dir}/.halcyon-tag" || die
	mkdir -p "${install_dir}" || die

	# NOTE: When / is read-only, but HALCYON_DIR is not, cp -Rp fails, but cp -R succeeds.

	cp -R "${slug_dir}/." "${install_dir}" |& quote || die
}
