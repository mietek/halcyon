function has_private_storage () {
	has_vars HALCYON_AWS_ACCESS_KEY_ID HALCYON_AWS_SECRET_ACCESS_KEY HALCYON_S3_BUCKET HALCYON_S3_ACL
}


function format_public_storage_url () {
	local object
	expect_args object -- "$@"

	echo "http://s3.halcyon.sh/${object}"
}


function transfer_original () {
	expect_vars HALCYON_NO_UPLOAD

	local src_file_name original_url dst_dir
	expect_args src_file_name original_url dst_dir -- "$@"

	local src_object dst_file
	src_object="original/${src_file_name}"
	dst_file="${dst_dir}/${src_file_name}"
	expect_no_existing "${dst_file}"

	if has_private_storage &&
		s3_download "${HALCYON_S3_BUCKET}" "${src_object}" "${dst_file}"
	then
		return 0
	fi

	if ! curl_download "${original_url}" "${dst_file}"; then
		die 'Cannot download original archive'
	fi

	if has_private_storage &&
		! (( HALCYON_NO_UPLOAD )) &&
		! s3_upload "${dst_file}" "${HALCYON_S3_BUCKET}" "${src_object}" "${HALCYON_S3_ACL}"
	then
		log_warning 'Cannot upload original archive'
	fi
}


function download_layer () {
	local src_prefix src_file_name dst_dir
	expect_args src_prefix src_file_name dst_dir -- "$@"

	local src_object dst_file
	src_object="${src_prefix:+${src_prefix}/}${src_file_name}"
	dst_file="${dst_dir}/${src_file_name}"
	expect_no_existing "${dst_file}"

	if has_private_storage; then
		if ! s3_download "${HALCYON_S3_BUCKET}" "${src_object}" "${dst_file}"; then
			return 1
		fi
		return 0
	fi

	local src_url
	src_url=$( format_public_storage_url "${src_object}" ) || die
	if ! curl_download "${src_url}" "${dst_file}"; then
		return 1
	fi
}


function upload_layer () {
	expect_vars HALCYON_NO_UPLOAD

	local src_file dst_prefix
	expect_args src_file dst_prefix -- "$@"

	local src_file_name dst_object
	src_file_name=$( basename "${src_file}" ) || die
	dst_object="${dst_prefix:+${dst_prefix}/}${src_file_name}"

	if has_private_storage &&
		! (( HALCYON_NO_UPLOAD )) &&
		! s3_upload "${src_file}" "${HALCYON_S3_BUCKET}" "${dst_object}" "${HALCYON_S3_ACL}"
	then
		return 1
	fi
}


function delete_layer () {
	local dst_prefix dst_file_name
	expect_args dst_prefix dst_file_name -- "$@"

	local dst_object
	dst_object="${dst_prefix:+${dst_prefix}/}${dst_file_name}"

	if has_private_storage &&
		! (( HALCYON_NO_UPLOAD )) &&
		! s3_delete "${HALCYON_S3_BUCKET}" "${dst_object}"
	then
		return 1
	fi
}


function list_layer () {
	local src_prefix
	expect_args src_prefix -- "$@"

	if has_private_storage; then
		local listing
		if ! listing=$( s3_list "${HALCYON_S3_BUCKET}" "${src_prefix}" ); then
			return 1
		fi
		if [ -n "${listing}" ]; then
			sort_naturally <<<"${listing}" | quote || die
			echo "${listing}"
		fi
		return 0
	fi

	local src_url
	src_url=$( format_public_storage_url "${src_prefix:+?prefix=${src_prefix}}" ) || die

	log_indent_begin "Listing ${src_url}..."

	local listing
	if ! listing=$( curl_do "${src_url}" -o >( read_s3_listing_xml ) ); then
		return 1
	fi
	if [ -n "${listing}" ]; then
		sort_naturally <<<"${listing}" | quote || die
		echo "${listing}"
	fi

}
