#!/usr/bin/env bash


function echo_tar_format_flag () {
	local archive_name
	expect_args archive_name -- "$@"

	local archive_format
	archive_format="${archive_name##*.}"

	case "${archive_format}" in
	'gz')
		echo '-z';;
	'bz2')
		echo '-j';;
	'xz')
		echo '-J';;
	*)
		die "Unexpected archive format: ${archive_name}"
	esac
}




function tar_archive () {
	local src_dir archive_file
	expect_args src_dir archive_file -- "$@"
	shift 2
	expect "${src_dir}"
	expect_no "${archive_file}"

	local archive_name format_flag dst_dir
	archive_name=$( basename "${archive_file}" ) || die
	format_flag=$( echo_tar_format_flag "${archive_name}" ) || die
	dst_dir=$( dirname "${archive_file}" ) || die

	log_indent_begin "Archiving ${archive_name}..."

	mkdir -p "${dst_dir}" || die
	if ! tar -c "${format_flag}" -f "${archive_file}" -C "${src_dir}" '.' "$@" &> '/dev/null'; then
		rm -f "${archive_file}" || die
		return 1
	fi

	local archive_size
	archive_size=$( measure_recursively "${archive_file}" ) || die
	log_end "done, ${archive_size}"
}


function tar_extract () {
	local archive_file dst_dir
	expect_args archive_file dst_dir -- "$@"
	shift 2
	expect "${archive_file}"
	expect_no "${dst_dir}"

	local archive_name format_flag
	archive_name=$( basename "${archive_file}" ) || die
	format_flag=$( echo_tar_format_flag "${archive_name}" ) || die

	log_indent_begin "Extracting ${archive_name}..."

	mkdir -p "${dst_dir}" || die
	if ! tar -x "${format_flag}" -f "${archive_file}" -C "${dst_dir}" "$@" &> '/dev/null'; then
		rm -rf "${dst_dir}" || die
		return 1
	fi

	log_end 'done'
}
