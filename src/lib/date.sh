#!/usr/bin/env bash


case "$( detect_os )" in
'linux-'*)
	function echo_date () {
		date "$@"
	}
	;;
*)
	function echo_date () {
		gdate "$@"
	}
esac


function echo_http_date () {
	echo_date --utc --rfc-2822 "$@"
}


function echo_timestamp () {
	echo_date --utc +'%Y%m%d%H%M%S' "$@"
}
