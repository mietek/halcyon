#!/usr/bin/env bash


function filter_last () {
	tail -n 1
}


function filter_not_last () {
	sed '$d'
}


function filter_matching () {
	local pattern
	expect_args pattern -- "$@"

	awk '/'"${pattern//\//\\/}"'/ { print }'
}


function filter_not_matching () {
	local pattern
	expect_args pattern -- "$@"

	awk '!/'"${pattern//\//\\/}"'/ { print }'
}


function match_at_most_one () {
	awk '{ print } NR == 2 { exit 2 }'
}


function match_at_least_one () {
	grep .
}


function match_exactly_one () {
	match_at_most_one | match_at_least_one
}


case "$( detect_os )" in
'linux-'*)
	function sort_naturally () {
		sort -V "$@"
	}
	;;
*)
	function sort_naturally () {
		gsort -V "$@"
	}
esac


function sort0_naturally () {
	sort_naturally -z
}
