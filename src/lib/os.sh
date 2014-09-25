#!/usr/bin/env bash


function echo_os_description () {
	local os
	expect_args os -- "$@"

	case "${os}" in
	'linux-ubuntu-14-04-x64')
		echo 'Ubuntu 14.04 LTS (x86_64)';;
	'linux-ubuntu-12-04-x64')
		echo 'Ubuntu 12.04 LTS (x86_64)';;
	'linux-ubuntu-10-04-x64')
		echo 'Ubuntu 10.04 LTS (x86_64)';;
	*)
		die "Unexpected OS: ${os}"
	esac
}


function detect_arch () {
	local arch
	arch=$( uname -m | tr '[:upper:]' '[:lower:]' ) || die

	case "${arch}" in
	'amd64')
		echo 'x64';;
	'x64')
		echo 'x64';;
	'x86-64')
		echo 'x64';;
	'x86_64')
		echo 'x64';;
	*)
		die "Unexpected architecture: ${arch}"
	esac
}


function detect_os () {
	local os arch
	os=$( uname -s ) || die
	arch=$( detect_arch ) || die

	case "${os}" in
	'Linux')
		local release
		if release=$( lsb_release -rs 2>'/dev/null' | tr '.' '-' ); then
			echo "linux-ubuntu-${release}-${arch}"
		else
			echo "linux-${arch}"
		fi
		;;
	'Darwin')
		echo "darwin-${arch}";;
	*)
		echo "unexpected-${arch}"
	esac
}
