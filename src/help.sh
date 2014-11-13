help_usage () {
	log
	quote <<-EOF
		Usage:
		    halcyon COMMAND

		Commands:
		    deploy APP* OPTION*
		    app-label APP* OPTION*
		    constraints APP* OPTION*
		    tag APP* OPTION*
		    paths

		App:
		    (none)
		        Local app in current directory, or only environment.
		    PATH
		        Local app in specified directory.
		    APP_LABEL
		        Remote app with specified label in Cabal repository.
		    URL
		        Remote app in git repository at specified URL.

		General options:
		    --halcyon-dir=PATH
		    --install-dir=PATH
		    --target=slug or --target=sandbox
		    --only-deploy-env
		    --no-build-dependencies
		    --no-archive
		    --no-upload
		    --no-delete

		Public storage options:
		    --public-storage-url=STRING
		    --no-public-storage

		Private storage options:
		    --aws-access-key-id=STRING
		    --aws-secret-access-key=STRING
		    --s3-bucket=STRING
		    --s3-acl=STRING
		    --s3-host=STRING

		Cache options:
		    --cache-dir=PATH
		    --purge-cache
		    --no-cache

		GHC layer options:
		    --ghc-version=STRING

		Cabal layer options:
		    --cabal-version=STRING
		    --cabal-repo=STRING

		Non-recursive general options:
		    --constraints-dir=PATH

		Non-recursive GHC layer options:
		    --ghc-pre-build-hook=PATH
		    --ghc-post-build-hook=PATH
		    --force-build-ghc

		Non-recursive Cabal layer options:
		    --cabal-pre-build-hook=PATH
		    --cabal-post-build-hook=PATH
		    --force-build-cabal
		    --force-update-cabal

		Non-recursive sandbox layer options:
		    --sandbox-sources=STRINGS
		    --sandbox-extra-libs=STRINGS
		    --sandbox-extra-apps=STRINGS
		    --sandbox-extra-constraints-dir=PATH
		    --sandbox-pre-build-hook=PATH
		    --sandbox-post-build-hook=PATH
		    --force-build-sandbox

		Non-recursive app layer options:
		    --app-extra-configure-flags=STRING
		    --app-pre-build-hook=PATH
		    --app-post-build-hook=PATH
		    --force-build-app

		Non-recursive slug options:
		    --slug-extra-apps=STRINGS
		    --slug-extra-constraints-dir=PATH
		    --slug-pre-build-hook=PATH
		    --slug-post-build-hook=PATH
		    --force-build-slug

		See the programmer’s reference for a description of available
		commands and options:  http://halcyon.sh/reference/
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
