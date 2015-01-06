private_storage () {
	expect_vars HALCYON_NO_PRIVATE_STORAGE

	if (( HALCYON_NO_PRIVATE_STORAGE )); then
		return 1
	fi

	[[ -n "${HALCYON_AWS_ACCESS_KEY_ID:+_}"
	&& -n "${HALCYON_AWS_SECRET_ACCESS_KEY:+_}"
	&& -n "${HALCYON_S3_BUCKET:+_}"
	&& -n "${HALCYON_S3_ENDPOINT:+_}"
	&& -n "${HALCYON_S3_ACL:+_}" ]] || return 1
}


format_public_storage_url () {
	expect_vars HALCYON_PUBLIC_STORAGE

	local object
	expect_args object -- "$@"

	echo "${HALCYON_PUBLIC_STORAGE}/${object}"
}


describe_storage () {
	expect_vars HALCYON_NO_PUBLIC_STORAGE

	if private_storage && ! (( HALCYON_NO_PUBLIC_STORAGE )); then
		log_indent_label 'External storage:' 'private and public'
	elif private_storage; then
		log_indent_label 'External storage:' 'private'
	elif ! (( HALCYON_NO_PUBLIC_STORAGE )); then
		log_indent_label 'External storage:' 'public'
	else
		log_indent_label 'External storage:' 'none'
	fi
}


create_cached_archive () {
	expect_vars HALCYON_CACHE

	local src_dir dst_file_name
	expect_args src_dir dst_file_name -- "$@"

	expect_existing "${src_dir}" || return 1

	create_archive "${src_dir}" "${HALCYON_CACHE}/${dst_file_name}" || return 1
}


extract_cached_archive_over () {
	expect_vars HALCYON_CACHE

	local src_file_name dst_dir
	expect_args src_file_name dst_dir -- "$@"

	if [[ ! -f "${HALCYON_CACHE}/${src_file_name}" ]]; then
		return 1
	fi

	extract_archive_over "${HALCYON_CACHE}/${src_file_name}" "${dst_dir}" || return 1
}


touch_cached_file () {
	expect_vars HALCYON_CACHE

	local file_name
	expect_args file_name -- "$@"

	if [[ ! -f "${HALCYON_CACHE}/${file_name}" ]]; then
		return 0
	fi

	touch "${HALCYON_CACHE}/${file_name}" || return 0
}


acquire_original_source () {
	local original_url dst_dir
	expect_args original_url dst_dir -- "$@"

	local original_name
	original_name=$( basename "${original_url}" ) || return 1

	if ! extract_cached_archive_over "${original_name}" "${dst_dir}"; then
		if ! cache_original_stored_file "${original_url}"; then
			log_error 'Failed to download original archive'
			return 1
		fi
		if ! extract_cached_archive_over "${original_name}" "${dst_dir}"; then
			log_error 'Failed to extract original archive'
			return 1
		fi
	else
		touch_cached_file "${original_name}" || true
	fi
}


touch_cached_ghc_and_cabal_files () {
	expect_vars HALCYON_CACHE

	local name
	find_tree "${HALCYON_CACHE}" -maxdepth 1 -type f |
		filter_matching "^(halcyon-ghc-.*|halcyon-cabal-.*)$" |
		while read -r name; do
			touch "${HALCYON_CACHE}/${name}" || true
		done || return 0
}


upload_cached_file () {
	expect_vars HALCYON_CACHE HALCYON_NO_UPLOAD

	local prefix file_name
	expect_args prefix file_name -- "$@"

	if (( HALCYON_NO_UPLOAD )) || ! private_storage; then
		return 1
	fi

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE}/${file_name}"

	s3_upload "${file}" "${HALCYON_S3_BUCKET}" "${object}" "${HALCYON_S3_ACL}" || return 1
}


cache_stored_file () {
	expect_vars HALCYON_CACHE HALCYON_NO_PUBLIC_STORAGE

	local prefix file_name
	expect_args prefix file_name -- "$@"

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE}/${file_name}"

	if private_storage &&
		s3_download "${HALCYON_S3_BUCKET}" "${object}" "${file}"
	then
		return 0
	fi

	! (( HALCYON_NO_PUBLIC_STORAGE )) || return 1

	local public_url
	public_url=$( format_public_storage_url "${object}" )
	if ! curl_download "${public_url}" "${file}"; then
		return 1
	fi
	upload_cached_file "${prefix}" "${file_name}" || true
}


cache_original_stored_file () {
	expect_vars HALCYON_CACHE HALCYON_NO_PUBLIC_STORAGE

	local original_url
	expect_args original_url -- "$@"

	local file_name file
	file_name=$( basename "${original_url}" ) || return 1
	file="${HALCYON_CACHE}/${file_name}"

	if cache_stored_file 'original' "${file_name}"; then
		return 0
	fi

	curl_download "${original_url}" "${file}" || return 1
	upload_cached_file 'original' "${file_name}" || true
}


delete_private_stored_file () {
	expect_vars HALCYON_NO_CLEAN_PRIVATE_STORAGE

	local prefix file_name
	expect_args prefix file_name -- "$@"

	if ! private_storage; then
		return 0
	fi

	local object
	object="${prefix:+${prefix}/}${file_name}"
	s3_delete "${HALCYON_S3_BUCKET}" "${object}" || return 1
}


list_private_stored_files () {
	local prefix
	expect_args prefix -- "$@"

	local listing
	if ! private_storage || ! listing=$( s3_list "${HALCYON_S3_BUCKET}" "${prefix}" ); then
		return 0
	fi

	echo "${listing}"
}


list_public_stored_files () {
	local public_url
	public_url=$( format_public_storage_url '' )

	local listing
	if (( HALCYON_NO_PUBLIC_STORAGE )) || ! listing=$( curl_list_s3 "${public_url}" ); then
		return 0
	fi

	echo "${listing}"
}


list_stored_files () {
	local prefix
	expect_args prefix -- "$@"

	list_private_stored_files "${prefix}" || die

	list_public_stored_files |
		filter_matching "^${prefix//./\.}" || die
}


delete_matching_private_stored_files () {
	local prefix match_prefix match_pattern save_name
	expect_args prefix match_prefix match_pattern save_name -- "$@"

	if ! private_storage; then
		return 0
	fi

	local old_name
	list_private_stored_files "${prefix}/${match_prefix}" |
		sed "s:^${prefix}/::" |
		filter_matching "^${match_pattern}$" |
		filter_not_matching "^${save_name//./\.}$" |
		while read -r old_name; do
			delete_private_stored_file "${prefix}" "${old_name}" || die
		done || die
}


prepare_cache () {
	expect_vars HALCYON_CACHE HALCYON_PURGE_CACHE HALCYON_NO_CLEAN_CACHE \
		HALCYON_INTERNAL_RECURSIVE

	local cache_dir
	expect_args cache_dir -- "$@"

	if (( HALCYON_NO_CLEAN_CACHE )) || (( HALCYON_INTERNAL_RECURSIVE )); then
		return 0
	fi

	if (( HALCYON_PURGE_CACHE )); then
		log 'Purging cache'
		log

		rm -rf "${HALCYON_CACHE}"
	fi

	mkdir -p "${HALCYON_CACHE}" "${cache_dir}" || die

	if ! (( HALCYON_PURGE_CACHE )); then
		local files
		if files=$(
			find_tree "${HALCYON_CACHE}" -maxdepth 1 -type f |
			sort_natural |
			match_at_least_one
		); then
			log 'Examining cache contents'

			copy_dir_over "${HALCYON_CACHE}" "${cache_dir}" || die

			quote <<<"${files}"
			log
		fi
	fi

	touch "${cache_dir}" || die
}


clean_cache () {
	expect_vars HALCYON_CACHE HALCYON_NO_CLEAN_CACHE \
		HALCYON_INTERNAL_RECURSIVE

	local cache_dir
	expect_args cache_dir -- "$@"

	if (( HALCYON_NO_CLEAN_CACHE )) || (( HALCYON_INTERNAL_RECURSIVE )); then
		return 0
	fi

	local mark_time name_prefix
	mark_time=$( get_modification_time "${cache_dir}" ) || die
	name_prefix=$( format_sandbox_common_file_name_prefix )

	rm -f "${HALCYON_CACHE}/${name_prefix}"* || die

	local file
	find "${HALCYON_CACHE}" -maxdepth 1 -type f 2>'/dev/null' |
		while read -r file; do
			local file_time
			file_time=$( get_modification_time "${file}" ) || die
			if (( file_time < mark_time )); then
				rm -f "${file}" || die
			fi
		done

	local changed_files
	if changed_files=$(
		compare_tree "${cache_dir}" "${HALCYON_CACHE}" |
		filter_not_matching '^(= |. apt/)' |
		match_at_least_one
	); then
		log
		log 'Examining cache changes'

		quote <<<"${changed_files}"
	fi
}
