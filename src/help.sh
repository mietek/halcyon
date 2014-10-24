function help_configure_storage () {
	quote <<-EOF
		To use private storage:
		$ export HALCYON_AWS_ACCESS_KEY_ID=...
		$ export HALCYON_AWS_SECRET_ACCESS_KEY=...
		$ export HALCYON_S3_BUCKET=...

		To use public storage:
		$ export HALCYON_PUBLIC_STORAGE=1
EOF
}


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
