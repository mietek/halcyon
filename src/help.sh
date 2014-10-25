function help_configure_storage () {
	quote <<-EOF
		To use private external storage:
		$ export HALCYON_STORAGE=private
		$ export HALCYON_AWS_ACCESS_KEY_ID=...
		$ export HALCYON_AWS_SECRET_ACCESS_KEY=...
		$ export HALCYON_S3_BUCKET=...

		To use public external storage:
		$ export HALCYON_STORAGE=public

		To use no external storage:
		$ unset HALCYON_STORAGE
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
