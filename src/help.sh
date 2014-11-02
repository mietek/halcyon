help_add_explicit_constraints () {
	local constraints
	expect_args constraints -- "$@"

	log 'To use explicit constraints, add a cabal.config:'
	log_indent '$ cat >cabal.config <<EOF'
	format_constraints <<<"${constraints}" >&2 || die
	echo 'EOF' >&2
}
