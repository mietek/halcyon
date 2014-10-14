function has_private_storage () {
	has_vars HALCYON_AWS_ACCESS_KEY_ID HALCYON_AWS_SECRET_ACCESS_KEY HALCYON_S3_BUCKET HALCYON_S3_ACL
}


function expect_storage () {
	expect_vars HALCYON_PUBLIC

	if ! has_private_storage; then
		if ! (( ${HALCYON_PUBLIC} )); then
			log_error 'Storage is not configured'
			log
			help_configure_storage
			log
			die
		fi

		log_warning 'Using public storage'
	else
		if (( ${HALCYON_PUBLIC} )); then
			log_warning 'Ignoring HALCYON_PUBLIC as private storage is configured'
		fi
	fi
}


function echo_public_storage_url () {
	local object
	expect_args object -- "$@"

	echo "http://s3.halcyon.sh/${object}"
}


function prepare_original () {
	expect_vars HALCYON_NO_UPLOAD

	local src_file_name original_url dst_dir
	expect_args src_file_name original_url dst_dir -- "$@"

	local src_object dst_file
	src_object="original/${src_file_name}"
	dst_file="${dst_dir}/${src_file_name}"
	expect_no_existing "${dst_file}"

	if has_private_storage; then
		if s3_download "${HALCYON_S3_BUCKET}" "${src_object}" "${dst_file}"; then
			return 0
		fi
	fi

	if ! curl_download "${original_url}" "${dst_file}"; then
		return 1
	fi

	if has_private_storage && ! (( ${HALCYON_NO_UPLOAD} )); then
		s3_upload "${dst_file}" "${HALCYON_S3_BUCKET}" "${src_object}" "${HALCYON_S3_ACL}"
	fi
}


function download_layer () {
	local src_prefix src_file_name dst_dir
	expect_args src_prefix src_file_name dst_dir -- "$@"

	expect_storage

	local src_object dst_file
	src_object="${src_prefix:+${src_prefix}/}${src_file_name}"
	dst_file="${dst_dir}/${src_file_name}"
	expect_no_existing "${dst_file}"

	if has_private_storage; then
		if s3_download "${HALCYON_S3_BUCKET}" "${src_object}" "${dst_file}"; then
			return 0
		fi
		return 1
	fi

	local src_url
	src_url=$( echo_public_storage_url "${src_object}" ) || die

	curl_download "${src_url}" "${dst_file}"
}


function list_layers () {
	local src_prefix
	expect_args src_prefix -- "$@"

	expect_storage

	if has_private_storage; then
		if s3_list "${HALCYON_S3_BUCKET}" "${src_prefix}"; then
			return 0
		fi
		return 1
	fi

	local src_url
	src_url=$( echo_public_storage_url "${src_prefix:+?prefix=${src_prefix}}" ) || die

	log_indent_begin "Listing ${src_url}..."

	local status response
	status=0
	if ! response=$( curl_do "${src_url}" -o >( read_s3_listing_xml ) ); then
		status=1
	else
		echo "${response}"
	fi

	return "${status}"
}


function upload_layer () {
	expect_vars HALCYON_NO_UPLOAD

	local src_file dst_prefix
	expect_args src_file dst_prefix -- "$@"

	local src_file_name dst_object
	src_file_name=$( basename "${src_file}" ) || die
	dst_object="${dst_prefix:+${dst_prefix}/}${src_file_name}"

	if has_private_storage && ! (( ${HALCYON_NO_UPLOAD} )); then
		s3_upload "${src_file}" "${HALCYON_S3_BUCKET}" "${dst_object}" "${HALCYON_S3_ACL}"
	fi
}
