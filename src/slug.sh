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


function install_slug () {
	expect_vars HALCYON_DIR HALCYON_TMP_SLUG_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local tag
	expect_args tag -- "$@"

	local target
	target=$( get_tag_target "${tag}" ) || die

	log 'Installing slug'

	if [ -f "${source_dir}/.halcyon-magic/slug-preinstall-hook" ]; then
		log 'Running slug pre-install hook'
		( "${source_dir}/.halcyon-magic/slug-preinstall-hook" "${tag}" |& quote ) || die
	fi

	deploy_extra_apps 'slug' "${source_dir}" || die

	log 'Copying app'

	# NOTE: PATH is extended to silence a misleading Cabal warning.

	if ! (
		export PATH="${HALCYON_TMP_SLUG_DIR}${HALCYON_DIR}/${target}:${PATH}" &&
		sandboxed_cabal_do "${HALCYON_DIR}/app" copy --destdir="${HALCYON_TMP_SLUG_DIR}" --verbose=0 |& quote
	); then
		die 'Cannot install slug'
	fi

	if [ -f "${source_dir}/.halcyon-magic/slug-postinstall-hook" ]; then
		log 'Running slug post-install hook'
		( "${source_dir}/.halcyon-magic/slug-postinstall-hook" "${tag}" |& quote ) || die
	fi

	derive_app_tag "${tag}" >"${HALCYON_TMP_SLUG_DIR}/.halcyon-tag" || die
}


function archive_slug () {
	expect_vars HALCYON_TMP_SLUG_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE HALCYON_NO_ARCHIVE_SLUG
	expect_existing "${HALCYON_TMP_SLUG_DIR}/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )) || (( HALCYON_NO_ARCHIVE_SLUG )); then
		return 0
	fi

	local slug_size
	slug_size=$( measure_recursively "${HALCYON_TMP_SLUG_DIR}" ) || die

	log "Archiving slug (${slug_size})"

	local app_tag archive_name
	app_tag=$( detect_app_tag "${HALCYON_TMP_SLUG_DIR}/.halcyon-tag" ) || die
	archive_name=$( format_slug_archive_name "${app_tag}" ) || die

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" || die
	tar_archive "${HALCYON_TMP_SLUG_DIR}" "${HALCYON_CACHE_DIR}/${archive_name}" || die

	local os ghc_version
	os=$( get_tag_os "${app_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${app_tag}" ) || die
	upload_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" || die
}


function validate_slug () {
	expect_vars HALCYON_TMP_SLUG_DIR

	local tag
	expect_args tag -- "$@"

	local app_tag
	app_tag=$( derive_app_tag "${tag}" ) || die
	detect_tag "${HALCYON_TMP_SLUG_DIR}/.halcyon-tag" "${app_tag//./\.}" || return 1
}


function restore_slug () {
	expect_vars HALCYON_TMP_SLUG_DIR HALCYON_CACHE_DIR HALCYON_NO_RESTORE_SLUG

	local tag
	expect_args tag -- "$@"

	! (( HALCYON_NO_RESTORE_SLUG )) || return 1

	local os ghc_version archive_name
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_slug_archive_name "${tag}" ) || die

	log
	if validate_slug "${tag}" >'/dev/null'; then
		log 'Using existing slug'
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
		return 0
	fi
	rm -rf "${HALCYON_TMP_SLUG_DIR}" || die

	log 'Restoring slug'

	if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_TMP_SLUG_DIR}" ||
		! validate_slug "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_TMP_SLUG_DIR}" || die
		if ! download_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" ||
			! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_TMP_SLUG_DIR}" ||
			! validate_slug "${tag}" >'/dev/null'
		then
			rm -rf "${HALCYON_TMP_SLUG_DIR}" || die
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
	fi
}


function apply_slug () {
	expect_vars HALCYON_TMP_SLUG_DIR

	local tag
	expect_args tag -- "$@"

	local installed_tag
	if ! installed_tag=$( validate_slug "${tag}" ); then
		log_warning 'Cannot deploy app'
		return 1
	fi

	# NOTE: On a Heroku dyno, / is read-only.

	rm -f "${HALCYON_TMP_SLUG_DIR}/.halcyon-tag" || die
	cp -R "${HALCYON_TMP_SLUG_DIR}/." '/' || die
	rm -rf "${HALCYON_TMP_SLUG_DIR}" || die

	local description
	description=$( format_app_description "${installed_tag}" ) || die

	log 'App deployed:                            ' "${description}"
}
