help_usage () {
	log
	quote <<-EOF
		Usage
		  halcyon                                 COMMAND

		Commands
		  deploy                                  APP? OPTION*
		  label                                   APP? OPTION*
		  constraints                             APP? OPTION*
		  paths

		App
		  directory path
		  label
		  git URL
		  nothing

		General options
		  --base=                                 DIR
		  --prefix=                               DIR
		  --root=                                 DIR
		  --no-app
		  --log-timestamp

		Build-time options
		  --constraints=                          STRINGS | FILE | DIR
		  --extra-configure-flags=                STRINGS | FILE
		  --pre-build-hook=                       FILE
		  --post-build-hook=                      FILE
		  --app-rebuild
		  --app-reconfigure
		  --no-build
		  --no-build-layers

		Install-time options
		  --extra-apps=                           STRINGS | FILE
		  --extra-apps-constraints=               STRINGS | FILE | DIR
		  --extra-data-files=                     STRINGS | FILE
		  --extra-os-packages=                    SPECIAL STRINGS | FILE
		  --include-layers
		  --restore-layers
		  --pre-install-hook=                     FILE
		  --post-install-hook=                    FILE
		  --app-reinstall

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

		GHC layer options
		  --ghc-version=                          VERSION
		  --ghc-pre-build-hook=                   FILE
		  --ghc-post-build-hook=                  FILE
		  --ghc-rebuild

		Cabal layer options
		  --cabal-version=                        VERSION
		  --cabal-repo=                           SPECIAL STRING | FILE
		  --cabal-pre-build-hook=                 FILE
		  --cabal-post-build-hook=                FILE
		  --cabal-pre-update-hook=                FILE
		  --cabal-post-update-hook=               FILE
		  --cabal-rebuild
		  --cabal-update

		Sandbox layer options
		  --sandbox-sources=                      STRINGS | FILE
		  --sandbox-extra-apps=                   STRINGS | FILE
		  --sandbox-extra-apps-constraints=       STRINGS | FILE | DIR
		  --sandbox-extra-configure-flags=	  STRINGS | FILE
		  --sandbox-extra-os-packages=            SPECIAL STRINGS | FILE
		  --sandbox-pre-build-hook=               FILE
		  --sandbox-post-build-hook=              FILE
		  --sandbox-rebuild
EOF
}
