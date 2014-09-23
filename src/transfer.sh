#!/usr/bin/env bash


function has_s3 () {
	has_vars HALCYON_AWS_ACCESS_KEY_ID HALCYON_AWS_SECRET_ACCESS_KEY HALCYON_S3_BUCKET HALCYON_S3_ACL
}




function echo_default_s3_url () {
	local object
	expect_args object -- "$@"

	echo "http://s3.halcyon.sh/${object}"
}




function download_original () {
	local src_item original_url dst_dir
	expect_args src_item original_url dst_dir -- "$@"

	local src_object dst_file
	src_object="original/${src_item}"
	dst_file="${dst_dir}/${src_item}"
	expect_no "${dst_file}"

	if has_s3; then
		if s3_download "${HALCYON_S3_BUCKET}" "${src_object}" "${dst_file}"; then
			return 0
		fi
	fi

	if ! curl_download "${original_url}" "${dst_file}"; then
		return 1
	fi

	if has_s3; then
		if ! s3_upload "${dst_file}" "${HALCYON_S3_BUCKET}" "${src_object}" "${HALCYON_S3_ACL}"; then
			return 1
		fi
	fi
}




function download_prepared () {
	local src_prefix src_item dst_dir
	expect_args src_prefix src_item dst_dir -- "$@"

	local src_object dst_file
	src_object="${src_prefix:+${src_prefix}/}${src_item}"
	dst_file="${dst_dir}/${src_item}"
	expect_no "${dst_file}"

	if has_s3; then
		if s3_download "${HALCYON_S3_BUCKET}" "${src_object}" "${dst_file}"; then
			return 0
		fi
		return 1
	fi

	local src_url
	src_url=$( echo_default_s3_url "${src_object}" ) || die

	curl_download "${src_url}" "${dst_file}"
}


function list_prepared () {
	local src_prefix
	expect_args src_prefix -- "$@"

	if has_s3; then
		if s3_list "${HALCYON_S3_BUCKET}" "${src_prefix}"; then
			return 0
		fi
		return 1
	fi

	local bucket_url src_url
	bucket_url=$( echo_default_s3_url '' ) || die
	src_url="${bucket_url}${src_prefix:+?prefix=${src_prefix}}"

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


function upload_prepared () {
	local src_file dst_prefix
	expect_args src_file dst_prefix -- "$@"

	local src_item dst_object
	src_item=$( basename "${src_file}" ) || die
	dst_object="${dst_prefix:+${dst_prefix}/}${src_item}"

	if has_s3; then
		s3_upload "${src_file}" "${HALCYON_S3_BUCKET}" "${dst_object}" "${HALCYON_S3_ACL}"
	fi
}




function download_any_prepared () {
	local src_prefix src_items dst_dir
	expect_args src_prefix src_items dst_dir -- "$@"

	local status src_item
	status=1
	while read -r src_item; do
		if download_prepared "${src_prefix}" "${src_item}" "${dst_dir}"; then
			status=0
		fi
	done <<<"${src_items}"

	return "${status}"
}
