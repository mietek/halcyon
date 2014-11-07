create_app_tag () {
	local app_label target               \
		source_hash constraints_hash \
		ghc_version ghc_magic_hash   \
		sandbox_magic_hash app_magic_hash
	expect_args app_label target         \
		source_hash constraints_hash \
		ghc_version ghc_magic_hash   \
		sandbox_magic_hash app_magic_hash -- "$@"

	create_tag "${app_label}" "${target}"          \
		"${source_hash}" "${constraints_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"   \
		'' '' '' ''                            \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


detect_app_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_app_tag '.*' '.*' '.*' '.*' '.*' '.*' '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect app layer tag'
	fi

	echo "${tag}"
}


derive_app_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label target               \
		source_hash constraints_hash \
		ghc_version ghc_magic_hash   \
		sandbox_magic_hash app_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	target=$( get_tag_target "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	create_app_tag "${app_label}" "${target}"      \
		"${source_hash}" "${constraints_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"   \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


derive_configured_app_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label target             \
		constraints_hash           \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash app_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	target=$( get_tag_target "${tag}" ) || die
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	create_app_tag "${app_label//./\.}" "${target}"    \
		'.*' "${constraints_hash}"                 \
		"${ghc_version//./\.}" "${ghc_magic_hash}" \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


derive_recognized_app_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	create_app_tag "${app_label}" '.*' '.*' '.*' '.*' '.*' '.*' '.*' || die
}


format_app_id () {
	local tag
	expect_args tag -- "$@"

	get_tag_app_label "${tag}" || die
}


format_app_description () {
	local tag
	expect_args tag -- "$@"

	get_tag_app_label "${tag}" || die
}


format_app_archive_name () {
	local tag
	expect_args tag -- "$@"

	local app_id
	app_id=$( format_app_id "${tag}" ) || die

	echo "halcyon-app-${app_id}.tar.gz"
}


format_app_constraints_file_name () {
	local tag
	expect_args tag -- "$@"

	local app_id
	app_id=$( format_app_id "${tag}" ) || die

	echo "halcyon-app-constraints-${app_id}.cabal.config"
}


hash_app_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" \
		\(                               \
		-path './ghc*'     -or           \
		-path './sandbox*' -or           \
		-path './app*'                   \
		\) || die
}


copy_app_source_over () {
	local source_dir work_dir
	expect_args source_dir work_dir -- "$@"

	copy_dir_over "${source_dir}" "${work_dir}" \
		--exclude '.git'                    \
		--exclude '.gitmodules'             \
		--exclude '.ghc'                    \
		--exclude '.cabal'                  \
		--exclude '.cabal-sandbox'          \
		--exclude 'cabal.sandbox.config' || die
}


build_app_layer () {
	expect_vars HALCYON_DIR HALCYON_TARGET

	local tag must_copy must_configure source_dir
	expect_args tag must_copy must_configure source_dir -- "$@"

	if (( must_copy )); then
		rm -rf "${HALCYON_DIR}/app" || die
	else
		expect_existing "${HALCYON_DIR}/app/.halcyon-tag"
	fi
	expect_existing "${source_dir}"

	log 'Building app layer'

	if (( must_copy )); then
		copy_app_source_over "${source_dir}" "${HALCYON_DIR}/app" || die
	fi

	if (( must_copy )) || (( must_configure )); then
		log 'Configuring app'

		local -a opts
		if [[ -f "${source_dir}/.halcyon-magic/app-extra-configure-flags" ]]; then
			opts=( $( <"${source_dir}/.halcyon-magic/app-extra-configure-flags" ) ) || die
		fi
		opts+=( --prefix="${HALCYON_DIR}/${HALCYON_TARGET}" )

		if ! sandboxed_cabal_do "${HALCYON_DIR}/app" configure "${opts[@]}" |& quote; then
			die 'Failed to configure app'
		fi
	fi

	if [[ -f "${source_dir}/.halcyon-magic/app-pre-build-hook" ]]; then
		log 'Executing app pre-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1                              \
				"${source_dir}/.halcyon-magic/app-pre-build-hook" \
				"${tag}" "${source_dir}" |& quote
		); then
			die 'Failed to execute app pre-build hook'
		fi
		log 'App pre-build hook executed'
	fi

	log 'Compiling app'

	if ! sandboxed_cabal_do "${HALCYON_DIR}/app" build |& quote; then
		die 'Failed to compile app'
	fi

	local compiled_size
	compiled_size=$( size_tree "${HALCYON_DIR}/app" ) || die

	log "App compiled, ${compiled_size}"

	if [[ -f "${source_dir}/.halcyon-magic/app-post-build-hook" ]]; then
		log 'Executing app post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1                               \
				"${source_dir}/.halcyon-magic/app-post-build-hook" \
				"${tag}" "${source_dir}" |& quote
		); then
			die 'Failed to execute app post-build hook'
		fi
		log 'App post-build hook executed'
	fi

	derive_app_tag "${tag}" >"${HALCYON_DIR}/app/.halcyon-tag" || die
}


archive_app_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag" "${HALCYON_DIR}/app/cabal.config"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local app_tag platform ghc_version archive_name constraints_name
	app_tag=$( detect_app_tag "${HALCYON_DIR}/app/.halcyon-tag" ) || die
	platform=$( get_tag_platform "${app_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${app_tag}" ) || die
	archive_name=$( format_app_archive_name "${app_tag}" ) || die
	constraints_name=$( format_app_constraints_file_name "${app_tag}" ) || die

	log 'Archiving app layer'

	create_cached_archive "${HALCYON_DIR}/app" "${archive_name}" || die
	copy_file "${HALCYON_DIR}/app/cabal.config" "${HALCYON_CACHE_DIR}/${constraints_name}"
	upload_cached_file "${platform}/ghc-${ghc_version}" "${archive_name}" || true
	upload_cached_file "${platform}/ghc-${ghc_version}" "${constraints_name}" || true
}


validate_identical_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local app_tag
	app_tag=$( derive_app_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/app/.halcyon-tag" "${app_tag//./\.}" || return 1
}


validate_configured_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local configured_pattern
	configured_pattern=$( derive_configured_app_tag_pattern "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/app/.halcyon-tag" "${configured_pattern}" || return 1
}


validate_recognized_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local recognized_pattern
	recognized_pattern=$( derive_recognized_app_tag_pattern "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/app/.halcyon-tag" "${recognized_pattern}" || return 1
}


restore_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local platform ghc_version archive_name description
	platform=$( get_tag_platform "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_app_archive_name "${tag}" ) || die
	description=$( format_app_description "${tag}" ) || die

	if validate_identical_app_layer "${tag}" >'/dev/null'; then
		log_pad 'Using existing app layer:' "${description}"
		touch_cached_file "${archive_name}" || die
		return 0
	fi

	log 'Restoring app layer'

	local restored_tag
	if ! extract_cached_archive_over "${archive_name}" "${HALCYON_DIR}/app" ||
		! restored_tag=$( validate_recognized_app_layer "${tag}" )
	then
		if ! cache_stored_file "${platform}/ghc-${ghc_version}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${HALCYON_DIR}/app" ||
			! restored_tag=$( validate_recognized_app_layer "${tag}" )
		then
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi
	description=$( format_app_description "${restored_tag}" ) || die

	log_pad 'App layer restored:' "${description}"
}


prepare_app_layer () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	local work_dir
	work_dir=$( get_tmp_dir 'halcyon-changed-source' ) || die

	copy_app_source_over "${source_dir}" "${work_dir}" || die

	local all_files
	all_files=$(
		compare_tree "${HALCYON_DIR}/app" "${work_dir}" |
		filter_not_matching '^. (\.halcyon-tag$|dist/)'
	) || true

	local changed_files
	if ! changed_files=$(
		filter_not_matching '^= ' <<<"${all_files}" |
		match_at_least_one
	); then
		return 0
	fi

	log 'Examining app changes'

	quote <<<"${changed_files}"

	# NOTE: Restoring file modification times of unchanged files is necessary to avoid
	# needless recompilation.

	local unchanged_files
	if unchanged_files=$(
		filter_matching '^= ' <<<"${all_files}" |
		match_at_least_one
	); then
		local file
		while read -r file; do
			cp -p "${HALCYON_DIR}/app/${file#= }" "${work_dir}/${file#= }" || die
		done <<<"${unchanged_files}"
	fi

	# NOTE: Any build products outside dist will have to be rebuilt.  See alex or happy for
	# an example.

	rm -rf "${work_dir}/dist" || die
	mv "${HALCYON_DIR}/app/dist" "${work_dir}/dist" || die
	mv "${HALCYON_DIR}/app/.halcyon-tag" "${work_dir}/.halcyon-tag" || die

	rm -rf "${HALCYON_DIR}/app" || die
	mv "${work_dir}" "${HALCYON_DIR}/app" || die

	# NOTE: With build-type: Custom, changing Setup.hs requires manually re-running
	# configure, as Cabal fails to detect the change.
	# https://github.com/mietek/haskell-on-heroku/issues/29

	local must_configure
	must_configure=0
	if filter_matching "^. (.halcyon-magic/app-extra-configure-flags|cabal.config|Setup.hs|.*\.cabal)$" <<<"${changed_files}" |
		match_exactly_one >'/dev/null'
	then
		must_configure=1
	fi

	return "${must_configure}"
}


announce_app_layer () {
	local tag
	expect_args tag -- "$@"

	local installed_tag description
	installed_tag=$( validate_identical_app_layer "${tag}" ) || die
	description=$( format_app_description "${installed_tag}" ) || die

	log_pad 'App layer installed:' "${description}"
}


link_app_sandbox_config () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	# NOTE: Creating config links is necessary to allow the user to easily run Cabal commands,
	# without having to use cabal_do or sandboxed_cabal_do.

	rm -f "${HALCYON_DIR}/app/cabal.sandbox.config" || die
	ln -s "${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" "${HALCYON_DIR}/app/cabal.sandbox.config" || die
}


install_app_layer () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_APP

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_BUILD_APP )) && restore_app_layer "${tag}"; then
		if validate_identical_app_layer "${tag}" >'/dev/null'; then
			link_app_sandbox_config || die
			return 0
		fi

		local must_copy must_configure
		must_copy=0
		must_configure=0
		if ! prepare_app_layer "${source_dir}" ||
			! validate_configured_app_layer "${tag}" >'/dev/null'
		then
			must_configure=1
		fi
		build_app_layer "${tag}" "${must_copy}" "${must_configure}" "${source_dir}" || die
		archive_app_layer || die
		announce_app_layer "${tag}" || die
		link_app_sandbox_config || die
		return 0
	fi

	local must_copy must_configure
	must_copy=1
	must_configure=1
	build_app_layer "${tag}" "${must_copy}" "${must_configure}" "${source_dir}" || die
	archive_app_layer || die
	announce_app_layer "${tag}" || die
	link_app_sandbox_config || die
}
