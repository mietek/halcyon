create_build_tag () {
	local prefix label source_hash constraints_hash magic_hash \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash
	expect_args prefix label source_hash constraints_hash magic_hash \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash -- "$@"

	create_tag "${prefix}" "${label}" "${source_hash}" "${constraints_hash}" "${magic_hash}" \
		"${ghc_version}" "${ghc_magic_hash}" \
		'' '' '' ''  \
		"${sandbox_magic_hash}"
}


detect_build_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_build_tag '.*' '.*' '.*' '.*' '.*' '.*' '.*' '.*' )

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		log_error 'Failed to detect build tag'
		return 1
	fi

	echo "${tag}"
}


derive_build_tag () {
	local tag
	expect_args tag -- "$@"

	local prefix label source_hash constraints_hash magic_hash \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash
	prefix=$( get_tag_prefix "${tag}" )
	label=$( get_tag_label "${tag}" )
	source_hash=$( get_tag_source_hash "${tag}" )
	constraints_hash=$( get_tag_constraints_hash "${tag}" )
	magic_hash=$( get_tag_magic_hash "${tag}" )
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" )
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" )

	create_build_tag "${prefix}" "${label}" "${source_hash}" "${constraints_hash}" "${magic_hash}" \
		"${ghc_version}" "${ghc_magic_hash}" \
		"${sandbox_magic_hash}"
}


derive_configured_build_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local prefix label constraints_hash magic_hash \
		ghc_version ghc_magic_hash \
		sandbox_magic_hash
	prefix=$( get_tag_prefix "${tag}" )
	label=$( get_tag_label "${tag}" )
	constraints_hash=$( get_tag_constraints_hash "${tag}" )
	magic_hash=$( get_tag_magic_hash "${tag}" )
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" )
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" )

	create_build_tag "${prefix}" "${label//./\.}" '.*' "${constraints_hash}" '.*' \
		"${ghc_version//./\.}" "${ghc_magic_hash}" \
		"${sandbox_magic_hash}"
}


derive_potential_build_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local label
	label=$( get_tag_label "${tag}" )

	create_build_tag '.*' "${label}" '.*' '.*' '.*' \
		'.*' '.*' \
		'.*'
}


format_build_archive_name () {
	local tag
	expect_args tag -- "$@"

	local label
	label=$( get_tag_label "${tag}" )

	echo "halcyon-build-${label}.tar.gz"
}


do_build_app () {
	expect_vars HALCYON_BASE

	local tag must_copy must_configure source_dir build_dir
	expect_args tag must_copy must_configure source_dir build_dir -- "$@"
	expect_existing "${source_dir}"
	if (( must_copy )); then
		if ! copy_source_dir_over "${source_dir}" "${build_dir}"; then
			log_error 'Failed to create build directory'
			return 1
		fi
	else
		expect_existing "${build_dir}/.halcyon-tag"
	fi

	local prefix
	prefix=$( get_tag_prefix "${tag}" )

	if (( must_copy )) || (( must_configure )); then
		log 'Configuring app'

		local -a opts_a
		opts_a=()
		if [[ -f "${source_dir}/.halcyon/extra-configure-flags" ]]; then
			local -a raw_opts_a
			raw_opts_a=( $( <"${source_dir}/.halcyon/extra-configure-flags" ) ) || die
			opts_a=( $( IFS=$'\n' && echo "${raw_opts_a[*]:-}" | filter_not_matching '^--prefix' ) )
		fi
		opts_a+=( --prefix="${prefix}" )
		opts_a+=( --verbose )

		local stdout
		stdout=$( get_tmp_file 'halcyon-cabal-configure-stdout' ) || return 1

		if ! sandboxed_cabal_do "${build_dir}" configure "${opts_a[@]}" >"${stdout}" 2>&1 | quote; then
			quote <"${stdout}"
			die 'Failed to configure app'
		fi

		# NOTE: This helps implement HALCYON_EXTRA_DATA_FILES, which
		# works around unusual Cabal globbing for the data-files
		# package description entry.
		# https://github.com/haskell/cabal/issues/713
		# https://github.com/haskell/cabal/issues/784

		local data_dir
		data_dir=$(
			awk '	/Data files installed in:/ { i = 1 }
				/Documentation installed in:/ { i = 0 }
				i' <"${stdout}" |
			strip_trailing_newline |
			tr '\n' ' ' |
			sed 's/^Data files installed in: //'
		) || die

		echo "${data_dir}" >"${build_dir}/dist/.halcyon-data-dir"

		rm -f "${stdout}" || die
	else
		expect_existing "${build_dir}/dist/.halcyon-data-dir"
	fi

	if [[ -f "${source_dir}/.halcyon/pre-build-hook" ]]; then
		log 'Executing pre-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon/pre-build-hook" \
					"${tag}" "${source_dir}" "${build_dir}" 2>&1 | quote
		); then
			die 'Failed to execute pre-build hook'
		fi
		log 'Pre-build hook executed'
	fi

	log 'Building app'

	if ! sandboxed_cabal_do "${build_dir}" build 2>&1 | quote; then
		die 'Failed to build app'
	fi

	local built_size
	built_size=$( get_size "${build_dir}" ) || die
	log "App built, ${built_size}"

	if [[ -f "${source_dir}/.halcyon/post-build-hook" ]]; then
		log 'Executing post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon/post-build-hook" \
					"${tag}" "${source_dir}" "${build_dir}" 2>&1 | quote
		); then
			die 'Failed to execute post-build hook'
		fi
		log 'Post-build hook executed'
	fi

	log_indent_begin 'Stripping app...'

	strip_tree "${build_dir}" || die

	local stripped_size
	stripped_size=$( get_size "${build_dir}" ) || die
	log_indent_end "done, ${stripped_size}"

	if ! derive_build_tag "${tag}" >"${build_dir}/.halcyon-tag"; then
		log_error 'Failed to write build tag'
		return 1
	fi
}


archive_build_dir () {
	expect_vars HALCYON_NO_ARCHIVE \
		HALCYON_INTERNAL_PLATFORM

	local build_dir
	expect_args build_dir -- "$@"
	expect_existing "${build_dir}/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local build_tag ghc_id archive_name
	build_tag=$( detect_build_tag "${build_dir}/.halcyon-tag" ) || return 1
	ghc_id=$( format_ghc_id "${build_tag}" )
	archive_name=$( format_build_archive_name "${build_tag}" )

	log 'Archiving build directory'

	create_cached_archive "${build_dir}" "${archive_name}" || die
	upload_cached_file "${HALCYON_INTERNAL_PLATFORM}/ghc-${ghc_id}" "${archive_name}" || true
}


validate_potential_build_dir () {
	local tag build_dir
	expect_args tag build_dir -- "$@"

	local recognized_pattern
	recognized_pattern=$( derive_potential_build_tag_pattern "${tag}" )
	detect_tag "${build_dir}/.halcyon-tag" "${recognized_pattern}" || return 1
}


validate_configured_build_dir () {
	local tag build_dir
	expect_args tag build_dir -- "$@"

	local configured_pattern
	configured_pattern=$( derive_configured_build_tag_pattern "${tag}" )
	detect_tag "${build_dir}/.halcyon-tag" "${configured_pattern}" || return 1
}


validate_build_dir () {
	local tag build_dir
	expect_args tag build_dir -- "$@"

	local build_tag
	build_tag=$( derive_build_tag "${tag}" )
	detect_tag "${build_dir}/.halcyon-tag" "${build_tag//./\.}" || return 1
}


restore_build_dir () {
	expect_vars HALCYON_INTERNAL_PLATFORM

	local tag build_dir
	expect_args tag build_dir -- "$@"

	local ghc_id archive_name
	ghc_id=$( format_ghc_id "${tag}" )
	archive_name=$( format_build_archive_name "${tag}" )

	log 'Restoring build directory'

	if ! extract_cached_archive_over "${archive_name}" "${build_dir}" ||
		! validate_potential_build_dir "${tag}" "${build_dir}" >'/dev/null'
	then
		if ! cache_stored_file "${HALCYON_INTERNAL_PLATFORM}/ghc-${ghc_id}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${build_dir}" ||
			! validate_potential_build_dir "${tag}" "${build_dir}" >'/dev/null'
		then
			rm -rf "${build_dir}" || die
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi
}


prepare_build_dir () {
	local source_dir build_dir
	expect_args source_dir build_dir -- "$@"
	expect_existing "${source_dir}" "${build_dir}/.halcyon-tag"

	local all_files
	all_files=$(
		compare_tree "${build_dir}" "${source_dir}" |
		filter_not_matching '^. (\.halcyon-tag$|dist/)'
	) || true

	local changed_files
	if ! changed_files=$(
		filter_not_matching '^= ' <<<"${all_files}" |
		match_at_least_one
	); then
		return 0
	fi

	log_indent 'Examining source changes'

	quote <<<"${changed_files}"

	local prepare_dir
	prepare_dir=$( get_tmp_dir 'halcyon-prepare' ) || return 1

	if ! copy_source_dir_over "${source_dir}" "${prepare_dir}"; then
		log_error 'Failed to update build directory'
		return 1
	fi

	# NOTE: Restoring file modification times of unchanged files is necessary to avoid
	# needless recompilation.

	local file
	filter_matching '^= ' <<<"${all_files}" |
		while read -r file; do
			touch -r "${build_dir}/${file#= }" "${prepare_dir}/${file#= }" || die
		done

	# NOTE: Any build products outside dist will have to be rebuilt.  See alex or happy for
	# an example.

	rm -rf "${prepare_dir}/dist" || die
	mv "${build_dir}/dist" "${prepare_dir}/dist" || die
	mv "${build_dir}/.halcyon-tag" "${prepare_dir}/.halcyon-tag" || die

	rm -rf "${build_dir}" || die
	mv "${prepare_dir}" "${build_dir}" || die

	# NOTE: With build-type: Custom, changing Setup.hs requires manually re-running
	# configure, as Cabal fails to detect the change.
	# https://github.com/mietek/haskell-on-heroku/issues/29

	# NOTE: Detecting changes in cabal.config works around a Cabal issue.
	# https://github.com/haskell/cabal/issues/1992

	local must_configure
	must_configure=0
	if filter_matching "^. (\.halcyon/extra-configure-flags|cabal\.config|Setup\.hs|.*\.cabal)$" <<<"${changed_files}" |
		match_at_least_one >'/dev/null'
	then
		must_configure=1
	fi

	return "${must_configure}"
}


build_app () {
	expect_vars HALCYON_NO_BUILD \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE \
		HALCYON_SANDBOX_REBUILD

	local tag source_dir build_dir
	expect_args tag source_dir build_dir -- "$@"

	if (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build app'
		return 1
	fi

	if ! (( HALCYON_APP_REBUILD )) && ! (( HALCYON_SANDBOX_REBUILD )) &&
		restore_build_dir "${tag}" "${build_dir}"
	then
		if ! (( HALCYON_APP_RECONFIGURE )) && validate_build_dir "${tag}" "${build_dir}" >'/dev/null'; then
			return 0
		fi

		local must_copy must_configure
		must_copy=0
		must_configure="${HALCYON_APP_RECONFIGURE}"
		if ! prepare_build_dir "${source_dir}" "${build_dir}" ||
			! validate_configured_build_dir "${tag}" "${build_dir}" >'/dev/null'
		then
			must_configure=1
		fi
		do_build_app "${tag}" "${must_copy}" "${must_configure}" "${source_dir}" "${build_dir}" || die
		archive_build_dir "${build_dir}" || die
		return 0
	fi

	local must_copy must_configure
	must_copy=1
	must_configure=1
	do_build_app "${tag}" "${must_copy}" "${must_configure}" "${source_dir}" "${build_dir}" || die
	archive_build_dir "${build_dir}" || die
}
