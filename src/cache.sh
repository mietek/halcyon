function prepare_cache () {
	expect_vars HALCYON_CACHE_DIR HALCYON_PURGE_CACHE

	local tmp_cache_dir
	expect_args tmp_cache_dir -- "$@"

	if (( HALCYON_PURGE_CACHE )); then
		rm -rf "${HALCYON_CACHE_DIR}"
		mkdir -p "${HALCYON_CACHE_DIR}"

		log 'Purging cache'
		return 0
	fi

	if ! [ -d "${HALCYON_CACHE_DIR}" ]; then
		mkdir -p "${HALCYON_CACHE_DIR}" || die
	else
		local files
		files=$( find_spaceless_recursively "${HALCYON_CACHE_DIR}" ) || die
		if [ -z "${files}" ]; then
			return 0
		fi

		log 'Examining cache'

		copy_dotless_contents "${HALCYON_CACHE_DIR}" "${tmp_cache_dir}" || die
		touch "${HALCYON_CACHE_DIR}/.halcyon-mark" || die

		sort_naturally <<<"${files}" | quote || die
	fi
}


function clean_cache () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect_existing "${HALCYON_CACHE_DIR}/.halcyon-mark"

	local tmp_cache_dir
	expect_args tmp_cache_dir -- "$@"

	local mark_time
	mark_time=$( echo_file_modification_time "${HALCYON_CACHE_DIR}/.halcyon-mark" ) || die

	rm -f "${HALCYON_CACHE_DIR}/.halcyon-mark" "${HALCYON_CACHE_DIR}/"*'.constraints' || die

	local file
	find_spaceless_recursively "${HALCYON_CACHE_DIR}" |
		while read -r file; do
			local file_time
			file_time=$( echo_file_modification_time "${HALCYON_CACHE_DIR}/${file}" ) || die
			if (( file_time <= mark_time )); then
				rm -f "${file}" || die
			fi
		done

	if [ -d "${tmp_cache_dir}" ]; then
		local changes
		changes=$(  compare_recursively "${tmp_cache_dir}" "${HALCYON_CACHE_DIR}" ) || die
		if [ -z "${changes}" ]; then
			return 0
		fi

		log 'Examining cache changes'

		filter_not_matching '^= ' <<<"${changes}" | quote || die
	fi
}
