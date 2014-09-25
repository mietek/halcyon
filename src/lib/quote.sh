#!/usr/bin/env bash


case "$( detect_os )" in
'linux-'*)
	function sed_unbuffered () {
		sed -u "$@"
	}
	;;
'darwin-'*)
	function sed_unbuffered () {
		sed -l "$@"
	}
	;;
*)
	function sed_unbuffered () {
		sed "$@"
	}
esac


function quote () {
	sed_unbuffered 's/^/       /' >&2
}


function quote_quietly () {
	expect_args quiet cmd -- "$@"
	shift 2

	if (( ${quiet} )); then
		local tmp_log
		tmp_log=$( mktemp -u "/tmp/${cmd}.log.XXXXXXXXXX" ) || die

		if ! "${cmd}" "$@" >&"${tmp_log}"; then
			quote <"${tmp_log}"
			die
		fi

		rm -f "${tmp_log}" || die
	else
		"${cmd}" "$@" |& quote || die
	fi
}
