function prepare_cache () {
	expect_vars HALCYON_CACHE_DIR HALCYON_RECURSIVE HALCYON_PURGE_CACHE HALCYON_NO_CACHE

	local cache_dir
	expect_args cache_dir -- "$@"

	if (( HALCYON_RECURSIVE )) || (( HALCYON_NO_CACHE )); then
		return 0
	fi

	if (( HALCYON_PURGE_CACHE )); then
		log 'Purging cache'
		log

		rm -rf "${HALCYON_CACHE_DIR}"
	fi

	mkdir -p "${HALCYON_CACHE_DIR}" "${cache_dir}" || die

	if ! (( HALCYON_PURGE_CACHE )); then
		local files
		if files=$(
			find_tree "${HALCYON_CACHE_DIR}" -maxdepth 1 -type f 2>'/dev/null' |
			sed "s:^\./::" |
			sort_naturally |
			match_at_least_one
		); then
			log 'Examining cache contents'

			tar_copy "${HALCYON_CACHE_DIR}" "${cache_dir}" || die

			quote <<<"${files}"
			log
		fi
	fi

	touch "${cache_dir}" || die
}


function clean_cache () {
	expect_vars HALCYON_CACHE_DIR HALCYON_RECURSIVE HALCYON_NO_CACHE

	local cache_dir
	expect_args cache_dir -- "$@"

	if (( HALCYON_RECURSIVE )) || (( HALCYON_NO_CACHE )); then
		return 0
	fi

	local mark_time name_prefix
	mark_time=$( get_modification_time "${cache_dir}" ) || die
	name_prefix=$( format_sandbox_constraints_file_name_prefix ) || die

	rm -f "${HALCYON_CACHE_DIR}/${name_prefix}"* || die

	local file
	find "${HALCYON_CACHE_DIR}" -maxdepth 1 -type f 2>'/dev/null' |
		while read -r file; do
			local file_time
			file_time=$( get_modification_time "${file}" ) || die
			if (( file_time < mark_time )); then
				rm -f "${file}" || die
			fi
		done

	local changed_files
	if changed_files=$(
		compare_tree "${cache_dir}" "${HALCYON_CACHE_DIR}" |
		filter_not_matching '^= ' |
		match_at_least_one
	); then
		log
		log 'Examining cache changes'

		quote <<<"${changed_files}"
	fi
}
