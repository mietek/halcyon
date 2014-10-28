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


function validate_private_storage () {
	[ -n "${HALCYON_AWS_ACCESS_KEY_ID:+_}" ] || return 1
	[ -n "${HALCYON_AWS_SECRET_ACCESS_KEY:+_}" ] || return 1
	[ -n "${HALCYON_S3_BUCKET:+_}" ] || return 1
	[ -n "${HALCYON_S3_ACL:+_}" ] || return 1
}


function describe_storage () {
	if (( HALCYON_RECURSIVE )); then
		return 0
	fi

	if validate_private_storage; then
		log_indent_pad 'External storage:' "${HALCYON_S3_BUCKET}, private"
	elif ! (( HALCYON_NO_DOWNLOAD_PUBLIC )); then
		local host
		host=$( get_public_storage_host ) || die
		log_indent_pad 'External storage:' "${host}, public"
	else
		log_indent_pad 'External storage:' 'none'
	fi
}


function transfer_original_file () {
	expect_vars HALCYON_NO_DOWNLOAD_PUBLIC

	local original_url
	expect_args original_url -- "$@"

	local file_name object file
	file_name=$( basename "${original_url}" ) || die
	object="original/${file_name}"
	file="${HALCYON_CACHE_DIR}/${file_name}"
	expect_no_existing "${file}"

	if validate_private_storage &&
		s3_download "${HALCYON_S3_BUCKET}" "${object}" "${file}"
	then
		return 0
	fi

	if ! (( HALCYON_NO_DOWNLOAD_PUBLIC )); then
		local public_url
		public_url=$( format_public_storage_url "${object}" ) || die
		if curl_download "${public_url}" "${file}"; then
			upload_stored_file 'original' "${file_name}" || true
			return 0
		fi
	fi

	if ! curl_download "${original_url}" "${file}"; then
		die 'Cannot download original file'
	fi
	upload_stored_file 'original' "${file_name}" || true
}


function download_stored_file () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_DOWNLOAD_PUBLIC

	local prefix file_name
	expect_args prefix file_name -- "$@"

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE_DIR}/${file_name}"

	if validate_private_storage &&
		s3_download "${HALCYON_S3_BUCKET}" "${object}" "${file}"
	then
		return 0
	fi

	! (( HALCYON_NO_DOWNLOAD_PUBLIC )) || return 1

	local public_url
	public_url=$( format_public_storage_url "${object}" ) || die
	curl_download "${public_url}" "${file}" || return 1
}


function upload_stored_file () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_UPLOAD

	local prefix file_name
	expect_args prefix file_name -- "$@"

	if (( HALCYON_NO_UPLOAD )) ||
		! validate_private_storage
	then
		return 1
	fi

	local object file
	object="${prefix:+${prefix}/}${file_name}"
	file="${HALCYON_CACHE_DIR}/${file_name}"
	expect_existing "${file}"

	if ! s3_upload "${file}" "${HALCYON_S3_BUCKET}" "${object}" "${HALCYON_S3_ACL}"; then
		log_warning 'Cannot upload stored file'
		return 1
	fi
}


function delete_private_stored_file () {
	expect_vars HALCYON_NO_DELETE

	local prefix file_name
	expect_args prefix file_name -- "$@"

	if (( HALCYON_NO_DELETE )) ||
		! validate_private_storage
	then
		return 0
	fi

	local object
	object="${prefix:+${prefix}/}${file_name}"
	if ! s3_delete "${HALCYON_S3_BUCKET}" "${object}"; then
		log_warning 'Cannot delete stored file'
		return 1
	fi
}


function delete_matching_private_stored_files () {
	local prefix match_prefix match_pattern save_name
	expect_args prefix match_prefix match_pattern save_name -- "$@"

	if ! validate_private_storage; then
		return 0
	fi

	local old_names
	if old_names=$(
		list_stored_files "${prefix}/${match_prefix}" |
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


function list_stored_files () {
	local prefix
	expect_args prefix -- "$@"

	if validate_private_storage; then
		local listing
		if listing=$( s3_list "${HALCYON_S3_BUCKET}" "${prefix}" ); then
			echo "${listing}"
			return 0
		fi
	fi

	! (( HALCYON_NO_DOWNLOAD_PUBLIC )) || return 1

	local public_url
	public_url=$( format_public_storage_url "${prefix:+?prefix=${prefix}}" ) || die

	local listing
	listing=$( curl_list_s3 "${public_url}" ) || return 1
	echo "${listing}"
}
