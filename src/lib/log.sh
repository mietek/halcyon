#!/usr/bin/env bash


function prefix_log () {
	local prefix
	prefix="$1"
	shift

	echo "${*:+${prefix}$*}" >&2
}


function prefix_log_begin () {
	local prefix
	prefix="$1"
	shift

	echo -n "${*:+${prefix}$* }" >&2
}




function log () {
	prefix_log '-----> ' "$@"
}


function log_begin () {
	prefix_log_begin '-----> ' "$@"
}


function log_end () {
	prefix_log '' "$@"
}


function log_indent () {
	prefix_log '       ' "$@"
}


function log_indent_begin () {
	prefix_log_begin '       ' "$@"
}


function log_debug () {
	prefix_log '   *** DEBUG: ' "$@"
}


function log_warning () {
	prefix_log '   *** WARNING: ' "$@"
}


function log_error () {
	prefix_log '   *** ERROR: ' "$@"
}




function log_file_indent () {
	unbuffered_sed "s/^/       /" >&2
}




function die () {
	if [ -n "${*:+_}" ]; then
		log_error "$@"
	fi
	exit 1
}
