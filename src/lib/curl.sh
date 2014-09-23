#!/usr/bin/env bash


function curl_do () {
	local url
	expect_args url -- "$@"
	shift

	local status response
	status=0
	if ! response=$(
		curl "${url}"                      \
			--fail                     \
			--location                 \
			--silent                   \
			--show-error               \
			--write-out "%{http_code}" \
			"$@"                       \
			2>'/dev/null'
	); then
		status=1
	fi

	case "${response}" in
	'200')
		log_end 'done';;
	'2'*)
		log_end "done, ${response}";;
	*)
		log_end "${response}"
	esac

	return "${status}"
}




function curl_download () {
	local src_file_url dst_file
	expect_args src_file_url dst_file -- "$@"
	expect_no "${dst_file}"

	log_indent_begin "Downloading ${src_file_url}..."

	local dst_dir
	dst_dir=$( dirname "${dst_file}" ) || die
	mkdir -p "${dst_dir}" || die

	curl_do "${src_file_url}" \
		--output "${dst_file}"
}


function curl_check () {
	local src_url
	expect_args src_url -- "$@"

	log_indent_begin "Checking ${src_url}..."

	curl_do "${src_url}"         \
		--output '/dev/null' \
		--head
}


function curl_upload () {
	local src_file dst_file_url
	expect_args src_file dst_file_url -- "$@"
	expect "${src_file}"

	log_indent_begin "Uploading ${dst_file_url}..."

	curl_do "${dst_file_url}"    \
		--output '/dev/null' \
		--upload-file "${src_file}"
}


function curl_delete () {
	local dst_url
	expect_args dst_url -- "$@"

	log_indent_begin "Deleting ${dst_url}..."

	curl_do "${dst_url}"         \
		--output '/dev/null' \
		--request DELETE
}
