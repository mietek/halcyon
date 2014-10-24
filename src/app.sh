function create_app_tag () {
	local app_label slug_dir source_hash constraint_hash       \
		ghc_version ghc_magic_hash                         \
		sandbox_magic_hash                                 \
		app_magic_hash
	expect_args app_label slug_dir source_hash constraint_hash \
		ghc_version ghc_magic_hash                         \
		sandbox_magic_hash                                 \
		app_magic_hash -- "$@"

	create_tag "${app_label}" "${slug_dir}" "${source_hash}" "${constraint_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"                                  \
		'' '' '' ''                                                           \
		"${sandbox_magic_hash}"                                               \
		"${app_magic_hash}" || die
}


function derive_app_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label slug_dir source_hash constraint_hash \
		ghc_version ghc_magic_hash                   \
		sandbox_magic_hash                           \
		app_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	slug_dir=$( get_tag_slug_dir "${tag}" ) || die
	source_hash=$( get_tag_source_hash "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	create_app_tag "${app_label}" "${slug_dir}" "${source_hash}" "${constraint_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"                                      \
		"${sandbox_magic_hash}"                                                   \
		"${app_magic_hash}" || die
}


function derive_configured_app_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label slug_dir constraint_hash \
		ghc_version ghc_magic_hash       \
		sandbox_magic_hash               \
		app_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	slug_dir=$( get_tag_slug_dir "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	create_app_tag "${app_label//./\.}" "${slug_dir}" '.*' "${constraint_hash}" \
		"${ghc_version//./\.}" "${ghc_magic_hash}"                          \
		"${sandbox_magic_hash}"                                             \
		"${app_magic_hash}" || die
}


function derive_recognized_app_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	create_app_tag "${app_label}" '.*' '.*' '.*' \
		'.*' '.*'                            \
		'.*'                                 \
		'.*' || die
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
		log 'Copying app'

		copy_entire_contents "${source_dir}" "${HALCYON_DIR}/app" || die
	fi

	if (( must_copy )) || (( must_configure )); then
		log 'Configuring app'

		local slug_dir
		slug_dir=$( get_tag_slug_dir "${tag}" ) || die

		sandboxed_cabal_do "${HALCYON_DIR}/app" configure --prefix="${slug_dir}" |& quote || die
	fi

	if [ -f "${source_dir}/.halcyon-magic/app-prebuild-hook" ]; then
		log 'Running app pre-build hook'
		( "${source_dir}/.halcyon-magic/app-prebuild-hook" "${tag}" ) |& quote || die
	fi

	log 'Building app'

	sandboxed_cabal_do "${HALCYON_DIR}/app" build |& quote || die

	if [ -f "${source_dir}/.halcyon-magic/app-postbuild-hook" ]; then
		log 'Running app post-build hook'
		( "${source_dir}/.halcyon-magic/app-postbuild-hook" "${tag}" ) |& quote || die
	fi

	derive_app_tag "${tag}" >"${HALCYON_DIR}/app/.halcyon-tag" || die

	local layer_size
	log_begin 'Measuring app layer...'
	layer_size=$( measure_recursively "${HALCYON_DIR}/app" ) || die
	log_end "${layer_size}"
}


function archive_app_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local app_tag os ghc_version archive_name
	app_tag=$( <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	os=$( get_tag_os "${app_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${app_tag}" ) || die
	archive_name=$( format_app_archive_name "${app_tag}" ) || die

	log 'Archiving app layer'

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" || die
	tar_archive "${HALCYON_DIR}/app"               \
		"${HALCYON_CACHE_DIR}/${archive_name}" \
		--exclude '.halcyon'                   \
		--exclude '.haskell-on-heroku'         \
		--exclude '.ghc'                       \
		--exclude '.cabal'                     \
		--exclude '.cabal-sandbox'             \
		--exclude 'cabal.sandbox.config' || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${archive_name}" "${os}/ghc-${ghc_version}"; then
		log_warning 'Cannot upload app layer archive'
	fi
}


function validate_identical_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/app/.halcyon-tag" ]; then
		return 1
	fi

	local app_tag candidate_tag
	app_tag=$( derive_app_tag "${tag}" ) || die
	candidate_tag=$( match_exactly_one <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	if [ "${candidate_tag}" != "${app_tag}" ]; then
		return 1
	fi
}


function validate_configured_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/app/.halcyon-tag" ]; then
		return 1
	fi

	local configured_pattern
	configured_pattern=$( derive_configured_app_tag_pattern "${tag}" ) || die
	if ! filter_matching "^${configured_pattern}$" <"${HALCYON_DIR}/app/.halcyon-tag" |
		match_exactly_one >'/dev/null'
	then
		return 1
	fi
}


function validate_recognized_app_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/app/.halcyon-tag" ]; then
		return 1
	fi

	local recognized_pattern
	recognized_pattern=$( derive_recognized_app_tag_pattern "${tag}" ) || die
	if ! filter_matching "^${recognized_pattern}$" <"${HALCYON_DIR}/app/.halcyon-tag" |
		match_exactly_one >'/dev/null'
	then
		return 1
	fi
}


function restore_app_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os ghc_version archive_name
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_app_archive_name "${tag}" ) || die

	if validate_identical_app_layer "${tag}"; then
		log 'Using existing app layer'
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || true
		return 0
	fi
	rm -rf "${HALCYON_DIR}/app" || die

	log 'Restoring app layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${archive_name}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/app" ||
		! validate_recognized_app_layer "${tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/app" || die
		if ! download_layer "${os}/ghc-${ghc_version}" "${archive_name}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download app layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/app" ||
			! validate_recognized_app_layer "${tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/app" || die
			log_warning 'Cannot extract app layer archive'
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || true
	fi
}


function prepare_app_layer () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	log 'Examining app changes'

	local app_files
	app_files=$(
		compare_recursively "${HALCYON_DIR}/app" "${source_dir}" |
		filter_not_matching '^. (\.halcyon-tag$|\.halcyon/|\.haskell-on-heroku/)' |
		filter_not_matching '^. (\.ghc/|\.cabal/|\.cabal-sandbox/|cabal.sandbox.config$|dist/)'
	)

	local changed_files
	if ! changed_files=$(
		filter_not_matching '^= ' <<<"${app_files}" |
		match_at_least_one
	); then
		log_indent '(none)'
		return 0
	fi

	quote <<<"${changed_files}"

	# NOTE: Restoring file modification times of unchanged files is necessary to avoid needless
	# recompilation.

	local prepare_dir
	prepare_dir=$( get_tmp_dir 'halcyon.source' ) || die

	copy_entire_contents "${source_dir}" "${prepare_dir}"

	local unchanged_files
	if unchanged_files=$(
		filter_matching '^= ' <<<"${app_files}" |
		match_at_least_one
	); then
		local file
		while read -r file; do
			cp -p "${HALCYON_DIR}/app/${file#= }" "${prepare_dir}/${file#= }" || die
		done <<<"${unchanged_files}"
	fi

	# NOTE: Any build products outside dist will have to be rebuilt.  See alex or happy for an
	# example.

	rm -rf "${prepare_dir}/dist" || die
	mv "${HALCYON_DIR}/app/dist" "${prepare_dir}/dist" || die
	mv "${HALCYON_DIR}/app/.halcyon-tag" "${prepare_dir}/.halcyon-tag" || die

	rm -rf "${HALCYON_DIR}/app" || die
	mv "${prepare_dir}" "${HALCYON_DIR}/app" || die

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
	expect_vars HALCYON_DIR HALCYON_FORCE_APP HALCYON_NO_BUILD

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_APP )) && restore_app_layer "${tag}"; then
		if validate_identical_app_layer "${tag}"; then
			return 0
		fi

		# NOTE: HALCYON_NO_BUILD is ignored here.  If even an incremental app build is not
		# acceptable, set HALCYON_NO_APP=1.

		local must_copy must_configure
		must_copy=0
		must_configure=0
		if ! prepare_app_layer "${source_dir}" || ! validate_configured_app_layer "${tag}"; then
			must_configure=1
		fi
		build_app_layer "${tag}" "${must_copy}" "${must_configure}" "${source_dir}" || die
		archive_app_layer || die
		return 0
	fi

	if ! (( HALCYON_FORCE_APP )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build app layer'
		return 1
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

	if ! install_app_layer "${tag}" "${source_dir}"; then
		return 1
	fi
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local app_tag description
	app_tag=$( <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	description=$( format_app_description "${app_tag}" ) || die

	log 'App layer deployed:                      ' "${description}"
}
