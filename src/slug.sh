function format_slug_id () {
	local tag
	expect_args tag -- "$@"

	local app_label source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${source_hash:0:7}-${app_label}"
}


function format_slug_archive_name () {
	local tag
	expect_args tag -- "$@"

	local slug_id
	slug_id=$( format_slug_id "${tag}" ) || die

	echo "halcyon-slug-${slug_id}.tar.gz"
}


function format_slug_description () {
	local tag
	expect_args tag -- "$@"

	local app_label source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${app_label} (${source_hash:0:7})"
}


function prepare_slug () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local tag source_dir slug_dir
	expect_args tag source_dir slug_dir -- "$@"

	local target
	target=$( get_tag_target "${tag}" ) || die

	log 'Preparing slug'

	# NOTE: PATH is extended to silence a misleading Cabal warning.

	if ! (
		export PATH="${slug_dir}${HALCYON_DIR}/${target}:${PATH}" &&
		sandboxed_cabal_do "${HALCYON_DIR}/app" copy --destdir="${slug_dir}" --verbose=0 |& quote
	); then
		die 'Failed to prepare slug'
	fi

	if [ -f "${source_dir}/.halcyon-magic/slug-extra-hook" ]; then
		log 'Running slug extra hook'
		if ! ( HALCYON_RECURSIVE=1 HALCYON_SLUG_DIR="${slug_dir}" "${source_dir}/.halcyon-magic/slug-extra-hook" "${tag}" "${source_dir}" "${slug_dir}" |& quote ); then
			die 'Failed to run slug extra hook'
		fi
	fi

	if ! deploy_slug_extra_apps "${source_dir}" "${slug_dir}"; then
		log_warning 'Cannot prepare slug'
		return 1
	fi

	derive_app_tag "${tag}" >"${slug_dir}/.halcyon-tag" || die

	local prepared_size
	prepared_size=$( size_tree "${slug_dir}" ) || die

	log "Slug prepared (${prepared_size})"
	log_indent_begin 'Stripping slug...'

	strip_tree "${slug_dir}" || die

	local stripped_size
	stripped_size=$( size_tree "${slug_dir}" ) || die
	log_end "done (${stripped_size})"
}


function archive_slug () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE HALCYON_NO_ARCHIVE_SLUG

	local slug_dir
	expect_args slug_dir -- "$@"
	expect_existing "${slug_dir}/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )) || (( HALCYON_NO_ARCHIVE_SLUG )); then
		return 0
	fi

	local app_tag archive_name
	app_tag=$( detect_app_tag "${slug_dir}/.halcyon-tag" ) || die
	archive_name=$( format_slug_archive_name "${app_tag}" ) || die

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" || die
	tar_archive "${slug_dir}" "${HALCYON_CACHE_DIR}/${archive_name}" || die

	local os ghc_version
	os=$( get_tag_os "${app_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${app_tag}" ) || die
	upload_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" || die
}


function validate_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local app_tag
	app_tag=$( derive_app_tag "${tag}" ) || die
	detect_tag "${slug_dir}/.halcyon-tag" "${app_tag//./\.}" || return 1
}


function restore_slug () {
	expect_vars HALCYON_CACHE_DIR

	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local os ghc_version archive_name
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_slug_archive_name "${tag}" ) || die

	log 'Restoring slug'

	local restored_tag description
	if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${slug_dir}" ||
		! restored_tag=$( validate_slug "${tag}" "${slug_dir}" )
	then
		rm -rf "${slug_dir}" || die
		if ! download_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" ||
			! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${slug_dir}" ||
			! restored_tag=$( validate_slug "${tag}" "${slug_dir}" )
		then
			rm -rf "${slug_dir}" || die
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
	fi
	description=$( format_slug_description "${restored_tag}" )

	log 'Slug restored:                           ' "${description}"
}


function apply_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local installed_tag description
	installed_tag=$( validate_slug "${tag}" "${slug_dir}" ) || die
	description=$( format_app_description "${installed_tag}" ) || die

	log 'Applying slug'

	cp -Rpv "${slug_dir}${HALCYON_DIR}/." "${HALCYON_SLUG_DIR}${HALCYON_DIR}" | quote || die

	log
	log 'App deployed:                            ' "${description}"
}
