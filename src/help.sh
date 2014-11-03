help_usage () {
	log
	quote <<-EOF
		Usage:
		    halcyon COMMAND [OPTIONS] [ARGUMENTS]

		Commands:
		    deploy
		    show-paths
		    show-app-label
		    show-constraints
		    show-tag

		Options:
		    --halcyon-dir=DIRECTORY

		    --cache-dir=DIRECTORY
		    --install-dir=DIRECTORY
		    --recursive
		    --target
		    --only-deploy-env
		    --no-copy-local-source
		    --no-build-dependencies
		    --no-archive
		    --no-upload
		    --no-delete

		    --ghc-version=VERSION
		    --ghc-magic-hash=HASH

		    --cabal-version=VERSION
		    --cabal-magic-hash=HASH
		    --cabal-repo=REPOSITORY

		    --aws-access-key-id=STRING
		    --aws-secret-access-key=STRING
		    --s3-bucket=STRING
		    --s3-acl=STRING
		    --purge-cache
		    --no-cache
		    --no-public-storage

		    --constraints-file=FILE
		    --force-restore-all
		    --no-announce-deploy

		    --ghc-pre-build-hook=FILE
		    --ghc-post-build-hook=FILE
		    --force-build-ghc

		    --cabal-pre-build-hook=FILE
		    --cabal-post-build-hook=FILE
		    --force-build-cabal
		    --force-update-cabal

		    --sandbox-extra-libs=NAMES
		    --sandbox-extra-apps=LABELS
		    --sandbox-extra-apps-constraints-dir=DIRECTORY
		    --sandbox-pre-build-hook=FILE
		    --sandbox-post-build-hook=FILE
		    --force-build-sandbox

		    --app-extra-configure-flags=FLAGS
		    --app-pre-build-hook=FILE
		    --app-post-build-hook=FILE
		    --force-build-app

		    --slug-extra-apps=LABELS
		    --slug-extra-apps-constraints-dir=DIRECTORY
		    --slug-pre-build-hook=FILE
		    --slug-post-build-hook=FILE
		    --force-build-slug

		Arguments:
		    (none)
		        Deploy environment or local app in current directory.
		    DIRECTORY
		        Deploy local app in specified directory.
		    LABEL
		        Unpack and deploy app from Cabal repository.
		    GIT_URL
		        Clone and deploy app from specified Git repository.
EOF
}


help_add_explicit_constraints () {
	local constraints
	expect_args constraints -- "$@"

	log 'To use explicit constraints, add a cabal.config:'
	log_indent '$ cat >cabal.config <<EOF'
	format_constraints <<<"${constraints}" >&2 || die
	echo 'EOF' >&2
}
