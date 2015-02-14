help_usage () {
	log
	quote <<-EOF
		Usage
		  halcyon                                 COMMAND

		Commands
		  install                                 APP? OPTION*
		  build                                   APP? OPTION*
		  label                                   APP? OPTION*
		  executable                              APP? OPTION*
		  constraints                             APP? OPTION*
		  paths

		App
		  label
		  directory path
		  git URL
		  nothing

		General options
		  --base=                                 DIR
		  --prefix=                               DIR
		  --root=                                 DIR
		  --no-app
		  --no-modify-home
		  --log-timestamp

		Build-time options
		  --extra-source-hash-ignore=             STRING | FILE
		  --constraints=                          STRING | FILE | DIR
		  --extra-configure-flags=                STRING | FILE
		  --pre-build-hook=                       FILE
		  --post-build-hook=                      FILE
		  --app-rebuild
		  --app-reconfigure
		  --ignore-all-constraints
		  --no-build
		  --no-build-dependencies
		  --dependencies-only

		Install-time options
		  --extra-apps=                           STRING | FILE
		  --extra-apps-constraints=               STRING | FILE | DIR
		  --extra-data-files=                     STRING | FILE
		  --extra-os-packages=                    STRING | FILE
		  --pre-install-hook=                     FILE
		  --post-install-hook=                    FILE
		  --app-reinstall
		  --keep-dependencies

		Cache options
		  --cache=                                DIR
		  --purge-cache
		  --no-archive
		  --no-clean-cache

		Public storage options
		  --public-storage=                       S3 URL
		  --no-public-storage

		Private storage options
		  --aws-access-key-id=                    STRING
		  --aws-secret-access-key=                STRING
		  --s3-bucket=                            S3 NAME
		  --s3-endpoint=                          S3 ADDRESS
		  --s3-acl=                               S3 ACL
		  --no-private-storage
		  --no-upload
		  --no-clean-private-storage

		GHC options
		  --ghc-version=                          VERSION
		  --ghc-pre-build-hook=                   FILE
		  --ghc-post-build-hook=                  FILE
		  --ghc-rebuild

		Cabal options
		  --cabal-version=                        VERSION
		  --cabal-remote-repo=                    STRING | FILE
		  --cabal-pre-build-hook=                 FILE
		  --cabal-post-build-hook=                FILE
		  --cabal-pre-update-hook=                FILE
		  --cabal-post-update-hook=               FILE
		  --cabal-rebuild
		  --cabal-update

		Sandbox options
		  --sandbox-extra-configure-flags=        STRING | FILE
		  --sandbox-sources=                      STRING | FILE
		  --sandbox-extra-apps=                   STRING | FILE
		  --sandbox-extra-apps-constraints=       STRING | FILE | DIR
		  --sandbox-extra-os-packages=            STRING | FILE
		  --sandbox-pre-build-hook=               FILE
		  --sandbox-post-build-hook=              FILE
		  --sandbox-rebuild
EOF
}
