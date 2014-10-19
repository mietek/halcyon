function prepare_cache () {
	expect_vars HALCYON_CACHE_DIR HALCYON_PURGE_CACHE

	if (( HALCYON_PURGE_CACHE )); then
		log 'Purging cache'

		rm -rf "${HALCYON_CACHE_DIR}"
		mkdir -p "${HALCYON_CACHE_DIR}"
		return 0
	fi

	log 'Examining cache'

	export HALCYON_INTERNAL_OLD_CACHE_DIR=$( echo_tmp_dir_name 'halcyon.old-cache' ) || die
	rm -rf "${HALCYON_INTERNAL_OLD_CACHE_DIR}" || die

	mkdir -p "${HALCYON_CACHE_DIR}" || die
	rm -f "${HALCYON_CACHE_DIR}/.halcyon-mark" || die
	cp -R "${HALCYON_CACHE_DIR}" "${HALCYON_INTERNAL_OLD_CACHE_DIR}" || die
	find_spaceless_recursively "${HALCYON_CACHE_DIR}" |
		sort_naturally |
		quote || die
	touch "${HALCYON_CACHE_DIR}/.halcyon-mark" || die
}


function clean_cache () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect_existing "${HALCYON_CACHE_DIR}/.halcyon-mark"

	local mark_time
	mark_time=$( echo_file_modification_time "${HALCYON_CACHE_DIR}/.halcyon-mark" ) || die

	rm -f "${HALCYON_CACHE_DIR}/.halcyon-mark" "${HALCYON_CACHE_DIR}/"*'.cabal.config' || die

	local -a files
	files=( "${HALCYON_CACHE_DIR}/"* )

	local file
	for file in "${files[@]}"; do
		if ! [ -f "${file}" ]; then
			continue
		fi

		local file_time
		file_time=$( echo_file_modification_time "${file}" ) || die

		if (( file_time <= mark_time )); then
			rm -f "${file}" || die
		fi
	done

	if has_vars HALCYON_INTERNAL_OLD_CACHE_DIR && [ -d "${HALCYON_INTERNAL_OLD_CACHE_DIR}" ]; then
		log 'Examining cache changes'

		compare_recursively "${HALCYON_INTERNAL_OLD_CACHE_DIR}" "${HALCYON_CACHE_DIR}" |
			filter_not_matching '^= ' |
			quote || die
		rm -rf "${HALCYON_INTERNAL_OLD_CACHE_DIR}" || die
	fi
}
