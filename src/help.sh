help_usage () {
	log
	quote <<-EOF
		Usage:
		    halcyon COMMAND

		Commands:
		    deploy APP OPTION*
		    label APP OPTION*
		    constraints APP OPTION*
		    tag APP OPTION*
		    paths

		App:
		    (none)
		        Local app in current directory, or only environment.
		    PATH
		        Local app in specified directory.
		    LABEL
		        Remote app with specified label in Cabal repository.
		    URL
		        Remote app in git repository at specified URL.

		Options:
		    --app-dir=PATH
		    --root-dir=PATH
		    --prefix=PATH
		    --no-app
		    --no-build-dependencies
		    --no-build-any
		    --no-archive-any
		    --no-upload-any
		    --no-delete-any

		Public storage options:
		    --public-storage-url=STRING
		    --no-public-storage

		Private storage options:
		    --aws-access-key-id=STRING
		    --aws-secret-access-key=STRING
		    --s3-bucket=STRING
		    --s3-acl=STRING
		    --s3-host=STRING
		    --no-private-storage

		Cache options:
		    --cache-dir=PATH
		    --purge-cache
		    --no-clean-cache

		GHC layer options:
		    --ghc-version=STRING
		    --ghc-pre-build-hook=PATH
		    --ghc-post-build-hook=PATH
		    --force-clean-rebuild-ghc

		Cabal layer options:
		    --cabal-version=STRING
		    --cabal-repo=STRING
		    --cabal-pre-build-hook=PATH
		    --cabal-post-build-hook=PATH
		    --cabal-pre-update-hook=PATH
		    --cabal-post-update-hook=PATH
		    --force-clean-rebuild-cabal
		    --force-update-cabal

		Sandbox layer options:
		    --sandbox-sources=STRINGS
		    --sandbox-extra-libs=STRINGS
		    --sandbox-extra-apps=STRINGS
		    --sandbox-extra-apps-constraints-dir=PATH
		    --sandbox-pre-build-hook=PATH
		    --sandbox-post-build-hook=PATH
		    --force-clean-rebuild-sandbox

		App options:
		    --constraints-file=PATH
		    --constraints-dir=PATH
		    --extra-configure-flags=STRINGS
		    --extra-apps=STRINGS
		    --extra-apps-constraints-dir=PATH
		    --extra-copy=source or --extra-copy=build or --extra-copy=all
		    --pre-build-hook=PATH
		    --post-build-hook=PATH
		    --pre-install-hook=PATH
		    --post-install-hook=PATH
		    --force-configure
		    --force-clean-rebuild
EOF
}
