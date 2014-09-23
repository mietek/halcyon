#!/usr/bin/env bash


function echo_s3_host () {
	echo "s3.amazonaws.com"
}


function echo_s3_url () {
	local resource
	expect_args resource -- "$@"

	local host
	host=$( echo_s3_host ) || die

	echo "https://${host}${resource}"
}




function read_s3_listing_xml () {
	IFS='>'

	local element contents
	while read -r -d '<' element contents; do
		if [ "${element}" = 'Key' ]; then
			echo "${contents}"
		fi
	done
}




function s3_do () {
	expect_vars HALCYON_AWS_ACCESS_KEY_ID HALCYON_AWS_SECRET_ACCESS_KEY

	local url
	expect_args url -- "$@"
	shift

	local host date
	host=$( echo_s3_host ) || die
	date=$( check_http_date ) || die

	local signature
	signature=$(
		sed "s/S3_DATE/${date}/" |
		perl -pe 'chomp if eof' |
		openssl sha1 -hmac "${HALCYON_AWS_SECRET_ACCESS_KEY}" -binary |
		base64
	) || die

	local auth
	auth="AWS ${HALCYON_AWS_ACCESS_KEY_ID}:${signature}"

	curl_do "${url}"                          \
		--header "Host: ${host}"          \
		--header "Date: ${date}"          \
		--header "Authorization: ${auth}" \
		"$@"
}




function s3_download () {
	local src_bucket src_object dst_file
	expect_args src_bucket src_object dst_file -- "$@"
	expect_no "${dst_file}"

	local src_resource
	src_resource="/${src_bucket}/${src_object}"

	log_indent_begin "Downloading s3:/${src_resource}..."

	local src_url dst_dir
	src_url=$( echo_s3_url "${src_resource}" ) || die
	dst_dir=$( dirname "${dst_file}" ) || die
	mkdir -p "${dst_dir}" || die

	s3_do "${src_url}"             \
		--output "${dst_file}" \
		<<-EOF
			GET


			S3_DATE
			${src_resource}
EOF
}


function s3_list () {
	local src_bucket src_prefix
	expect_args src_bucket src_prefix -- "$@"

	local bucket_resource src_resource
	bucket_resource="/${src_bucket}/"
	src_resource="${bucket_resource}${src_prefix:+?prefix=${src_prefix}}"

	log_indent_begin "Listing s3:/${src_resource}..."

	local src_url
	src_url=$( echo_s3_url "${src_resource}" ) || die

	local status response
	status=0
	if ! response=$(
		s3_do "${src_url}"                        \
			--output >( read_s3_listing_xml ) \
			<<-EOF
				GET


				S3_DATE
				${bucket_resource}
EOF
	); then
		status=1
	else
		echo "${response}"
	fi

	return "${status}"
}


function s3_check () {
	local src_bucket src_object
	expect_args src_bucket src_object -- "$@"

	local src_resource
	src_resource="/${src_bucket}/${src_object}"

	log_indent_begin "Checking s3:/${src_resource}..."

	local src_url
	src_url=$( echo_s3_url "${src_resource}" ) || die

	s3_do "${src_url}"           \
		--output '/dev/null' \
		--head               \
		<<-EOF
			HEAD


			S3_DATE
			${src_resource}
EOF
}


function s3_upload () {
	local src_file dst_bucket dst_object dst_acl
	expect_args src_file dst_bucket dst_object dst_acl -- "$@"
	expect "${src_file}"

	local dst_resource
	dst_resource="/${dst_bucket}/${dst_object}"

	log_indent_begin "Uploading s3:/${dst_resource}..."

	local src_digest
	src_digest=$(
		openssl md5 -binary <"${src_file}" |
		base64
	) || die

	local dst_url
	dst_url=$( echo_s3_url "${dst_resource}" ) || die

	s3_do "${dst_url}"                            \
		--output '/dev/null'                  \
		--header "Content-MD5: ${src_digest}" \
		--header "x-amz-acl: ${dst_acl}"      \
		--upload-file "${src_file}"           \
		<<-EOF
			PUT
			${src_digest}

			S3_DATE
			x-amz-acl:${dst_acl}
			${dst_resource}
EOF
}


function s3_create () {
	local dst_bucket dst_acl
	expect_args dst_bucket dst_acl -- "$@"

	local dst_resource
	dst_resource="/${dst_bucket}/"

	log_indent_begin "Creating s3:/${dst_resource}..."

	local dst_url
	dst_url=$( echo_s3_url "${dst_resource}" ) || die

	s3_do "${dst_url}"                       \
		--output '/dev/null'             \
		--header "x-amz-acl: ${dst_acl}" \
		--request PUT                    \
		<<-EOF
			PUT


			S3_DATE
			x-amz-acl:${dst_acl}
			${dst_resource}
EOF
}


function s3_copy () {
	local src_bucket src_object dst_bucket dst_object dst_acl
	expect_args src_bucket src_object dst_bucket dst_object dst_acl -- "$@"

	local src_resource dst_resource
	src_resource="/${src_bucket}/${src_object}"
	dst_resource="/${dst_bucket}/${dst_object}"

	log_indent_begin "Copying s3:/${src_resource} to s3:/${src_resource}..."

	local dst_url
	dst_url=$( echo_s3_url "${dst_resource}" ) || die

	s3_do "${dst_url}"                                    \
		--output '/dev/null'                          \
		--header "x-amz-acl: ${dst_acl}"              \
		--header "x-amz-copy-source: ${src_resource}" \
		--request PUT                                 \
		<<-EOF
			PUT


			S3_DATE
			x-amz-acl:${dst_acl}
			x-amz-copy-source:${src_resource}
			${dst_resource}
EOF
}


function s3_delete () {
	local dst_bucket dst_object
	expect_args dst_bucket dst_object -- "$@"

	local dst_resource
	dst_resource="/${dst_bucket}/${dst_object}"

	log_indent_begin "Deleting s3:/${dst_resource}..."

	local dst_url
	dst_url=$( echo_s3_url "${dst_resource}" ) || die

	s3_do "${dst_url}"           \
		--output '/dev/null' \
		--request DELETE     \
		<<-EOF
			DELETE


			S3_DATE
			${dst_resource}
EOF
}
