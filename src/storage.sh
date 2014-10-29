function get_public_storage_host () {
	echo 's3.halcyon.sh'
}


function format_public_storage_url () {
	local object
	expect_args object -- "$@"

	local host
	host=$( get_public_storage_host ) || die

	echo "http://${host}/${object}"
}


function use_private_storage () {
	[ -n "${HALCYON_AWS_ACCESS_KEY_ID:+_}" ] || return 1
	[ -n "${HALCYON_AWS_SECRET_ACCESS_KEY:+_}" ] || return 1
	[ -n "${HALCYON_S3_BUCKET:+_}" ] || return 1
	[ -n "${HALCYON_S3_ACL:+_}" ] || return 1
}


function describe_storage () {
	expect_vars HALCYON_NO_PUBLIC_STORAGE

	if (( HALCYON_RECURSIVE )); then
		return 0
	fi

	if use_private_storage && ! (( HALCYON_NO_PUBLIC_STORAGE )); then
		log_indent_pad 'External storage:' 'private and public'
	elif use_private_storage; then
		log_indent_pad 'External storage:' 'private'
	elif ! (( HALCYON_NO_PUBLIC_STORAGE )); then
		log_indent_pad 'External storage:' 'public'
	else
		log_indent_pad 'External storage:' 'none'
	fi
}


function download_stored_file () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_PUBLIC_STORAGE

	local prefix file_name
	expect_args prefix file_name -- "$@"

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE_DIR}/${file_name}"

	if use_private_storage && s3_download "${HALCYON_S3_BUCKET}" "${object}" "${file}"; then
		return 0
	fi

	! (( HALCYON_NO_PUBLIC_STORAGE )) || return 1

	local public_url
	public_url=$( format_public_storage_url "${object}" ) || die
	curl_download "${public_url}" "${file}" || return 1
}


function upload_stored_file () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_UPLOAD

	local prefix file_name
	expect_args prefix file_name -- "$@"

	if (( HALCYON_NO_UPLOAD )) || ! use_private_storage; then
		return 1
	fi

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE_DIR}/${file_name}"

	s3_upload "${file}" "${HALCYON_S3_BUCKET}" "${object}" "${HALCYON_S3_ACL}" || return 1
}


function transfer_stored_file () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_PUBLIC_STORAGE

	local prefix file_name
	expect_args prefix file_name -- "$@"

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE_DIR}/${file_name}"

	if use_private_storage && s3_download "${HALCYON_S3_BUCKET}" "${object}" "${file}"; then
		return 0
	fi

	! (( HALCYON_NO_PUBLIC_STORAGE )) || return 1

	local public_url
	public_url=$( format_public_storage_url "${object}" ) || die
	if ! curl_download "${public_url}" "${file}"; then
		return 1
	fi
	upload_stored_file "${prefix}" "${file_name}" || true
}


function transfer_original_stored_file () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_PUBLIC_STORAGE

	local original_url
	expect_args original_url -- "$@"

	local file_name file
	file_name=$( basename "${original_url}" ) || die
	file="${HALCYON_CACHE_DIR}/${file_name}"

	if transfer_stored_file 'original' "${file_name}"; then
		return 0
	fi

	curl_download "${original_url}" "${file}" || return 1
	upload_stored_file 'original' "${file_name}" || true
}


function delete_private_stored_file () {
	expect_vars HALCYON_NO_DELETE

	local prefix file_name
	expect_args prefix file_name -- "$@"

	if (( HALCYON_NO_DELETE )) || ! use_private_storage; then
		return 0
	fi

	local object
	object="${prefix:+${prefix}/}${file_name}"
	if ! s3_delete "${HALCYON_S3_BUCKET}" "${object}"; then
		return 1
	fi
}


function list_private_stored_files () {
	local prefix
	expect_args prefix -- "$@"

	local listing
	if ! use_private_storage || ! listing=$( s3_list "${HALCYON_S3_BUCKET}" "${prefix}" ); then
		return 0
	fi

	echo "${listing}"
}


function list_public_stored_files () {
	local prefix
	expect_args prefix -- "$@"

	local public_url
	public_url=$( format_public_storage_url "${prefix:+?prefix=${prefix}}" ) || die

	local listing
	if (( HALCYON_NO_PUBLIC_STORAGE )) || ! listing=$( curl_list_s3 "${public_url}" ); then
		return 0
	fi

	echo "${listing}"
}


function list_stored_files () {
	local prefix
	expect_args prefix -- "$@"

	list_private_stored_files "${prefix}" || die
	list_public_stored_files "${prefix}" || die
}


function delete_matching_private_stored_files () {
	local prefix match_prefix match_pattern save_name
	expect_args prefix match_prefix match_pattern save_name -- "$@"

	if ! use_private_storage; then
		return 0
	fi

	local old_names
	if old_names=$(
		list_private_stored_files "${prefix}/${match_prefix}" |
		sed "s:${prefix}/::" |
		filter_matching "^${match_pattern}$" |
		filter_not_matching "^${save_name//./\.}$" |
		match_at_least_one
	); then
		local old_name
		while read -r old_name; do
			delete_private_stored_file "${prefix}" "${old_name}" || true
		done <<<"${old_names}"
	fi
}
