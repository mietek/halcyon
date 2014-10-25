function help_add_explicit_constraints () {
	local constraints
	expect_args constraints -- "$@"

	quote <<-EOF
		To use explicit constraints, add a cabal.config:
		$ cat >cabal.config <<EOF
EOF
	format_constraints <<<"${constraints}" >&2 || die
	echo 'EOF' >&2
}
