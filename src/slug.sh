function create_slug_tag () {
	local app_label target source_hash
	expect_args app_label target source_hash -- "$@"

	create_tag "${app_label}" "${target}" \
		"${source_hash}" ''           \
		'' ''                         \
		'' '' '' ''                   \
		'' '' || die
}


function detect_slug_tag () {
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


function derive_slug_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label target source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	target=$( get_tag_target "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	create_slug_tag "${app_label}" "${target}" "${source_hash}" || die
}


function format_slug_id () {
	local tag
	expect_args tag -- "$@"

	local app_label source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${source_hash:0:7}-${app_label}"
}


function format_slug_description () {
	local tag
	expect_args tag -- "$@"

	local app_label source_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die

	echo "${app_label} (${source_hash:0:7})"
}


function format_slug_archive_name () {
	local tag
	expect_args tag -- "$@"

	local slug_id
	slug_id=$( format_slug_id "${tag}" ) || die

	echo "halcyon-slug-${slug_id}.tar.gz"
}


function format_slug_archive_name_prefix () {
	echo 'halcyon-slug-'
}


function format_slug_archive_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	echo "halcyon-slug-.*-${app_label//./\.}.tar.gz"
}


function deploy_slug_extra_apps () {
	local source_dir slug_dir
	expect_args source_dir slug_dir -- "$@"

	if ! [ -f "${source_dir}/.halcyon-magic/slug-extra-apps" ]; then
		return 0
	fi

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

		local -a deploy_args
		deploy_args=( --install-dir="${slug_dir}" --recursive "${slug_app}" )

		local slug_file
		slug_file="${source_dir}/.halcyon-magic/slug-extra-apps-constraints/${slug_app}.cabal.config"
		if [ -f "${slug_file}" ]; then
			deploy_args+=( --constraints-file="${slug_file}" )
		fi

		if ! ( deploy "${deploy_args[@]}" |& quote ); then
			log_warning 'Cannot deploy slug extra apps'
			return 1
		fi
	done
}


function build_slug () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local tag source_dir slug_dir
	expect_args tag source_dir slug_dir -- "$@"

	log 'Building slug'

	if [ -f "${source_dir}/.halcyon-magic/slug-pre-build-hook" ]; then
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

	# NOTE: PATH is extended to silence a misleading Cabal warning.

	if ! (
		export PATH="${slug_dir}${HALCYON_DIR}/${HALCYON_TARGET}:${PATH}" &&
		sandboxed_cabal_do "${HALCYON_DIR}/app" copy --destdir="${slug_dir}" --verbose=0 |& quote
	); then
		die 'Failed to copy app'
	fi

	if ! deploy_slug_extra_apps "${source_dir}" "${slug_dir}"; then
		log_warning 'Cannot deploy slug extra apps'
		return 1
	fi

	derive_slug_tag "${tag}" >"${slug_dir}/.halcyon-tag" || die

	local copied_size
	copied_size=$( size_tree "${slug_dir}" ) || die

	log "App copied, ${copied_size}"

	if [ -f "${source_dir}/.halcyon-magic/slug-post-build-hook" ]; then
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

	log_indent_begin 'Stripping slug...'

	strip_tree "${slug_dir}" || die

	local stripped_size
	stripped_size=$( size_tree "${slug_dir}" ) || die
	log_end "done, ${stripped_size}"
}


function archive_slug () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE HALCYON_NO_DELETE

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

	tar_create "${slug_dir}" "${HALCYON_CACHE_DIR}/${archive_name}" || die
	if ! upload_stored_file "${os}" "${archive_name}"; then
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


function validate_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local slug_tag
	slug_tag=$( derive_slug_tag "${tag}" ) || die
	detect_tag "${slug_dir}/.halcyon-tag" "${slug_tag//./\.}" || return 1
}


function restore_slug () {
	expect_vars HALCYON_CACHE_DIR

	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local os archive_name archive_file
	os=$( get_tag_os "${tag}" ) || die
	archive_name=$( format_slug_archive_name "${tag}" ) || die
	archive_file="${HALCYON_CACHE_DIR}/${archive_name}"

	log 'Restoring slug'

	local restored_tag description
	if ! tar_extract "${archive_file}" "${slug_dir}" ||
		! restored_tag=$( validate_slug "${tag}" "${slug_dir}" )
	then
		rm -rf "${slug_dir}" || die
		if ! transfer_stored_file "${os}" "${archive_name}" ||
			! tar_extract "${archive_file}" "${slug_dir}" ||
			! restored_tag=$( validate_slug "${tag}" "${slug_dir}" )
		then
			rm -rf "${slug_dir}" || die
			return 1
		fi
	else
		touch -c "${archive_file}" || die
	fi
	description=$( format_slug_description "${restored_tag}" )

	log_pad 'Slug restored:' "${description}"
}


function announce_slug () {
	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local installed_tag description
	installed_tag=$( validate_slug "${tag}" "${slug_dir}" ) || die
	description=$( format_slug_description "${installed_tag}" ) || die

	log_pad 'Slug installed:' "${description}"

	export HALCYON_FORCE_BUILD_SLUG=0
}


function activate_slug () {
	expect_vars HOME HALCYON_DIR HALCYON_RECURSIVE HALCYON_NO_ANNOUNCE_DEPLOY

	local tag slug_dir
	expect_args tag slug_dir -- "$@"

	local installed_tag description
	installed_tag=$( validate_slug "${tag}" "${slug_dir}" ) || die
	description=$( format_slug_description "${installed_tag}" ) || die

	# NOTE: When / is read-only, but HALCYON_DIR is not, both cp -Rp and tar_copy fail, but cp -R
	# succeeds.

	local install_dir
	install_dir='/'
	if [ -n "${HALCYON_INSTALL_DIR:+_}" ]; then
		install_dir="${HALCYON_INSTALL_DIR}"
	fi

	rm -f "${slug_dir}/.halcyon-tag" || die
	mkdir -p "${install_dir}" || die
	cp -R "${slug_dir}/." "${install_dir}" |& quote || die

	# NOTE: Creating config links is necessary to allow the user to easily run Cabal commands,
	# without having to use cabal_do or sandboxed_cabal_do.

	if ! (( HALCYON_RECURSIVE )); then
		if [ -d "${HALCYON_DIR}/cabal" ]; then
			if [ -e "${HOME}/.cabal/config" ] && ! [ -h "${HOME}/.cabal/config" ]; then
				log_warning "Expected no foreign ${HOME}/.cabal/config"
			else
				rm -f "${HOME}/.cabal/config" || die
				mkdir -p "${HOME}/.cabal" || die
				ln -s "${HALCYON_DIR}/cabal/.halcyon-cabal.config" "${HOME}/.cabal/config" || die
			fi
		fi

		if [ -d "${HALCYON_DIR}/sandbox" ] && [ -d "${HALCYON_DIR}/app" ]; then
			rm -f "${HALCYON_DIR}/app/cabal.sandbox.config" || die
			ln -s "${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" "${HALCYON_DIR}/app/cabal.sandbox.config" || die
		fi
	fi

	if ! (( HALCYON_NO_ANNOUNCE_DEPLOY )); then
		log
		log_pad 'App deployed:' "${description}"
	fi
}
