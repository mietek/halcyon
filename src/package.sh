#!/usr/bin/env bash


function echo_fake_package () {
	local app_label
	expect_args app_label -- "$@"

	local app_name app_version build_depends
	case "${app_label}" in
	'base')
		app_name='base'
		app_version=$( detect_base_version ) || die
		build_depends='base'
		;;
	*'-'*)
		app_name="${app_label%-*}"
		app_version="${app_label##*-}"
		build_depends="base, ${app_name} == ${app_version}"
		;;
	*)
		die "Unexpected app label: ${app_label}"
	esac

	cat <<-EOF
		name:           halcyon-fake-${app_name}
		version:        ${app_version}
		build-type:     Simple
		cabal-version:  >= 1.2

		executable halcyon-fake-${app_name}
		  build-depends:  ${build_depends}
EOF
}




function detect_package () {
	local build_dir
	expect_args build_dir -- "$@"
	expect "${build_dir}"

	local package_file
	if ! package_file=$(
		find_spaceless "${build_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	); then
		die "Expected exactly one ${build_dir}/*.cabal"
	fi

	cat "${package_file}"
}


function detect_app_name () {
	local build_dir
	expect_args build_dir -- "$@"

	local app_name
	if ! app_name=$(
		detect_package "${build_dir}" |
		awk '/^ *[Nn]ame:/ { print $2 }' |
		match_exactly_one
	); then
		die 'Expected exactly one app name'
	fi

	echo "${app_name}"
}


function detect_app_version () {
	local build_dir
	expect_args build_dir -- "$@"

	local app_version
	if ! app_version=$(
		detect_package "${build_dir}" |
		awk '/^ *[Vv]ersion:/ { print $2 }' |
		match_exactly_one
	); then
		die 'Expected exactly one app version'
	fi

	echo "${app_version}"
}


function detect_app_executable () {
	local build_dir
	expect_args build_dir -- "$@"

	local app_executable
	if ! app_executable=$(
		detect_package "${build_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		match_exactly_one
	); then
		die 'Expected exactly one app executable'
	fi

	echo "${app_executable}"
}




function detect_app_label () {
	local build_dir
	expect_args build_dir -- "$@"

	local app_name app_version
	app_name=$( detect_app_name "${build_dir}" | sed 's/^halcyon-fake-//' ) || die
	app_version=$( detect_app_version "${build_dir}" ) || die

	echo "${app_name}-${app_version}"
}
