function create_app_tag () {
	local app_label target              \
		source_hash constraint_hash \
		ghc_version ghc_magic_hash  \
		sandbox_magic_hash app_magic_hash
	expect_args app_label target        \
		source_hash constraint_hash \
		ghc_version ghc_magic_hash  \
		sandbox_magic_hash app_magic_hash -- "$@"

	create_tag "${app_label}" "${target}"         \
		"${source_hash}" "${constraint_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"  \
		'' '' '' ''                           \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


function detect_app_tag () {
	expect_vars HALCYON_DIR

	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$(
		create_app_tag '.*' '.*' \
			'.*' '.*'    \
			'.*' '.*'    \
			'.*' '.*'
	) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect app layer tag'
	fi

	echo "${tag}"
}


function derive_app_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label target              \
		source_hash constraint_hash \
		ghc_version ghc_magic_hash  \
		sandbox_magic_hash app_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	target=$( get_tag_target "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	create_app_tag "${app_label}" "${target}"     \
		"${source_hash}" "${constraint_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"  \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


function derive_configured_app_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label target             \
		constraint_hash            \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash app_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	target=$( get_tag_target "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	create_app_tag "${app_label//./\.}" "${target}"    \
		'.*' "${constraint_hash}"                  \
		"${ghc_version//./\.}" "${ghc_magic_hash}" \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


function derive_recognized_app_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	create_app_tag "${app_label}" '.*' \
		'.*' '.*'                  \
		'.*' '.*'                  \
		'.*' '.*' || die
}


function format_app_id () {
	local tag
	expect_args tag -- "$@"

	get_tag_app_label "${tag}" || die
}


function format_app_description () {
	local tag
	expect_args tag -- "$@"

	format_app_id "${tag}" || die
}


function format_app_archive_name () {
	local tag
	expect_args tag -- "$@"

	local app_id
	app_id=$( format_app_id "${tag}" ) || die

	echo "halcyon-app-${app_id}.tar.gz"
}


function hash_app_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_spaceless_recursively "${source_dir}/.halcyon-magic" \( -name 'ghc*' -or -name 'sandbox*' -or -name 'app*' \) || die
}


function copy_app_source () {
	local source_dir work_dir
	expect_args source_dir work_dir -- "$@"

	# NOTE: On a Heroku dyno, HALCYON_DIR (/app/.halcyon) is a subdirectory of source_dir (/app),
	# which means .halcyon must be excluded when copying source_dir to HALCYON_DIR/app.

	tar_copy "${source_dir}" "${work_dir}" \
		--exclude '.halcyon'           \
		--exclude '.haskell-on-heroku' \
		--exclude '.git'               \
		--exclude '.ghc'               \
		--exclude '.cabal'             \
		--exclude '.cabal-sandbox'     \
		--exclude 'cabal.sandbox.config' || die
}


function build_app_layer () {
	expect_vars HALCYON_DIR

	local tag must_copy must_configure source_dir
	expect_args tag must_copy must_configure source_dir -- "$@"
	if (( must_copy )); then
		expect_no_existing "${HALCYON_DIR}/app"
	else
		expect_existing "${HALCYON_DIR}/app/.halcyon-tag"
	fi
	expect_existing "${source_dir}"

	log 'Building app layer'

	if (( must_copy )); then
		copy_app_source "${source_dir}" "${HALCYON_DIR}/app" || die
	fi

	if (( must_copy )) || (( must_configure )); then
		log 'Configuring app'

		local target
		target=$( get_tag_target "${tag}" ) || die

		if ! sandboxed_cabal_do "${HALCYON_DIR}/app" configure --prefix="${HALCYON_DIR}/${target}" |& quote; then
			die 'Cannot configure app'
		fi
	fi

	if [ -f "${source_dir}/.halcyon-magic/app-build-hook" ]; then
		log 'Running app build hook'
		if ! ( "${source_dir}/.halcyon-magic/app-build-hook" "${tag}" |& quote ); then
			die 'App build hook failed'
		fi
	fi

	log 'Building app'

	if ! sandboxed_cabal_do "${HALCYON_DIR}/app" build |& quote; then
		die 'Cannot build app'
	fi

	derive_app_tag "${tag}" >"${HALCYON_DIR}/app/.halcyon-tag" || die
}


function archive_app_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local layer_size
	layer_size=$( measure_recursively "${HALCYON_DIR}/app" ) || die

	log "Archiving app layer (${layer_size})"

	local app_tag archive_name
	app_tag=$( detect_app_tag "${HALCYON_DIR}/app/.halcyon-tag" ) || die
	archive_name=$( format_app_archive_name "${app_tag}" ) || die

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" || die
	tar_archive "${HALCYON_DIR}/app" "${HALCYON_CACHE_DIR}/${archive_name}" || die

	local os ghc_version
	os=$( get_tag_os "${app_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${app_tag}" ) || die
	upload_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" || die
}


function validate_identical_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local app_tag
	app_tag=$( derive_app_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/app/.halcyon-tag" "${app_tag//./\.}" || return 1
}


function validate_configured_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local configured_pattern
	configured_pattern=$( derive_configured_app_tag_pattern "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/app/.halcyon-tag" "${configured_pattern}" || return 1
}


function validate_recognized_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local recognized_pattern
	recognized_pattern=$( derive_recognized_app_tag_pattern "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/app/.halcyon-tag" "${recognized_pattern}" || return 1
}


function restore_app_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os ghc_version archive_name
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_app_archive_name "${tag}" ) || die

	if validate_identical_app_layer "${tag}" >'/dev/null'; then
		log 'Using existing app layer'
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
		return 0
	fi
	rm -rf "${HALCYON_DIR}/app" || die

	log 'Restoring app layer'

	if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/app" ||
		! validate_recognized_app_layer "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_DIR}/app" || die
		if ! download_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" ||
			! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/app" ||
			! validate_recognized_app_layer "${tag}" >'/dev/null'
		then
			rm -rf "${HALCYON_DIR}/app" || die
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
	fi
}


function prepare_app_layer () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	log 'Examining app changes'

	local work_dir
	work_dir=$( get_tmp_dir 'halcyon.changed-source' ) || die
	copy_app_source "${source_dir}" "${work_dir}" || die

	local all_files
	all_files=$(
		compare_recursively "${HALCYON_DIR}/app" "${work_dir}" |
		filter_not_matching '^. (\.halcyon-tag$|dist/)'
	)

	local changed_files
	if ! changed_files=$(
		filter_not_matching '^= ' <<<"${all_files}" |
		match_at_least_one
	); then
		log_indent '(none)'
		return 0
	fi

	quote <<<"${changed_files}"

	# NOTE: Restoring file modification times of unchanged files is necessary to avoid needless
	# recompilation.

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

	# NOTE: Any build products outside dist will have to be rebuilt.  See alex or happy for an
	# example.

	rm -rf "${work_dir}/dist" || die
	mv "${HALCYON_DIR}/app/dist" "${work_dir}/dist" || die
	mv "${HALCYON_DIR}/app/.halcyon-tag" "${work_dir}/.halcyon-tag" || die

	rm -rf "${HALCYON_DIR}/app" || die
	mv "${work_dir}" "${HALCYON_DIR}/app" || die

	# NOTE: With build-type: Custom, changing Setup.hs requires manually re-running configure, as
	# Cabal fails to detect the change.
	# https://github.com/mietek/haskell-on-heroku/issues/29

	local must_configure
	must_configure=0
	if filter_matching "^. Setup.hs$" <<<"${changed_files}" |
		match_exactly_one >'/dev/null'
	then
		must_configure=1
	fi

	return "${must_configure}"
}


function install_app_layer () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_APP

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_BUILD_APP )) && restore_app_layer "${tag}"; then
		if validate_identical_app_layer "${tag}" >'/dev/null'; then
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
		return 0
	fi

	local must_copy must_configure
	must_copy=1
	must_configure=1
	rm -rf "${HALCYON_DIR}/app" || die
	build_app_layer "${tag}" "${must_copy}" "${must_configure}" "${source_dir}" || die
	archive_app_layer || die
}


function deploy_app_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	local installed_tag
	if ! install_app_layer "${tag}" "${source_dir}" ||
		! installed_tag=$( validate_recognized_app_layer "${tag}" )
	then
		log 'Cannot deploy app layer'
		return 1
	fi

	local description
	description=$( format_app_description "${installed_tag}" ) || die

	log 'App layer deployed:                      ' "${description}"
}
