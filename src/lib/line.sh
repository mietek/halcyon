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
	awk 'NR == 1 { line = $0 "\n" } NR == 2 { line = ""; exit 1 } END { printf line }'
}


function match_at_least_one () {
	grep ^
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
