#!/usr/bin/env bash


function expect_args () {
	local specs status
	specs=()
	status=1

	while (( $# )); do
		if [ "$1" = -- ]; then
			status=0
			shift
			break
		fi
		specs+=( "$1" )
		shift
	done

	if (( ${status} )); then
		die "${FUNCNAME[1]:--}: Expected specs, guard, and args:" 'arg1 .. argN -- "$@"'
	fi

	local spec
	for spec in "${specs[@]}"; do
		if ! (( $# )); then
			die "${FUNCNAME[1]:--}: Expected args: ${specs[*]:-}"
		fi
		eval "${spec}=\$1"
		shift
	done
}




function expect_vars () {
	while (( $# )); do
		if [ -z "${!1:+_}" ]; then
			die "${FUNCNAME[1]:--}: Expected var: $1"
		fi
		shift
	done
}


function expect () {
	while (( $# )); do
		if ! [ -e "$1" ]; then
			die "${FUNCNAME[1]:--}: Expected existing $1"
		fi
		shift
	done
}


function expect_no () {
	while (( $# )); do
		if [ -e "$1" ]; then
			die "${FUNCNAME[1]:--}: Unexpected existing $1"
		fi
		shift
	done
}




function has_vars () {
	while (( $# )); do
		if [ -z "${!1:+_}" ]; then
			return 1
		fi
		shift
	done
}
