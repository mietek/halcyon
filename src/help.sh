help_usage () {
	cat >&2 <<-EOF
		Usage:
		  halcyon                                 COMMAND

		Commands:
		  install                                 APP? OPTION*
		  build                                   APP? OPTION*
		  label                                   APP? OPTION*
		  executable                              APP? OPTION*
		  constraints                             APP? OPTION*
		  paths

		App:
		  label
		  directory path
		  git URL
		  nothing

		General options:
		  --base=                                 DIR
		  --prefix=                               DIR
		  --root=                                 DIR
		  --no-app
		  --no-modify-home
		  --log-timestamp

		Build-time options:
		  --constraints=                          STRING | FILE | DIR
		  --extra-source-hash-ignore=             STRING | FILE
		  --extra-configure-flags=                STRING | FILE
		  --pre-build-hook=                       FILE
		  --post-build-hook=                      FILE
		  --app-rebuild
		  --app-reconfigure
		  --app-no-strip
		  --ignore-all-constraints
		  --no-build
		  --no-build-dependencies
		  --dependencies-only

		Install-time options:
		  --extra-apps=                           STRING | FILE
		  --extra-apps-constraints=               STRING | FILE | DIR
		  --extra-data-files=                     STRING | FILE
		  --extra-os-packages=                    STRING | FILE
		  --pre-install-hook=                     FILE
		  --post-install-hook=                    FILE
		  --app-reinstall
		  --app-no-remove-doc
		  --keep-dependencies

		Cache options:
		  --cache=                                DIR
		  --purge-cache
		  --no-archive
		  --no-clean-cache

		Public storage options:
		  --public-storage-url=                   S3_URL
		  --no-public-storage

		Private storage options:
		  --aws-access-key-id=                    STRING
		  --aws-secret-access-key=                STRING
		  --s3-bucket=                            S3_NAME
		  --s3-endpoint=                          S3_ADDRESS
		  --s3-acl=                               S3_ACL
		  --no-private-storage
		  --no-upload
		  --no-clean-private-storage

		GHC options:
		  --ghc-version=                          VERSION
		  --ghc-pre-build-hook=                   FILE
		  --ghc-post-build-hook=                  FILE
		  --ghc-rebuild
		  --ghc-no-remove-doc
		  --ghc-no-strip

		Cabal options:
		  --cabal-version=                        VERSION
		  --cabal-remote-repo=                    STRING | FILE
		  --cabal-pre-build-hook=                 FILE
		  --cabal-post-build-hook=                FILE
		  --cabal-pre-update-hook=                FILE
		  --cabal-post-update-hook=               FILE
		  --cabal-rebuild
		  --cabal-update
		  --cabal-no-strip
		  --cabal-binary-only

		Sandbox options:
		  --sandbox-extra-configure-flags=        STRING | FILE
		  --sandbox-sources=                      STRING | FILE
		  --sandbox-extra-apps=                   STRING | FILE
		  --sandbox-extra-apps-constraints=       STRING | FILE | DIR
		  --sandbox-extra-os-packages=            STRING | FILE
		  --sandbox-pre-build-hook=               FILE
		  --sandbox-post-build-hook=              FILE
		  --sandbox-rebuild
		  --sandbox-no-remove-doc
		  --sandbox-no-strip
EOF
}
