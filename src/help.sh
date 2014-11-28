help_usage () {
	log
	quote <<-EOF
		Usage
		  halcyon COMMAND

		Commands
		  deploy APP? OPTION*
		  label APP? OPTION*
		  constraints APP? OPTION*
		  paths

		App
		  directory path
		  label
		  git URL
		  nothing

		General options
		  --base=                                 directory path
		  --root=                                 directory path
		  --prefix=                               directory path
		  --restore-dependencies
		  --no-app
		  --no-build
		  --no-build-dependencies

		Build-time options
		  --constraints=                          file or directory path
		  --extra-configure-flags=                whitespace-separated strings
		  --pre-build-hook=                       file path
		  --post-build-hook=                      file path
		  --app-rebuild
		  --app-reconfigure

		Install-time options
		  --extra-apps=                           whitespace-separated apps
		  --extra-apps-constraints=               file or directory path
		  --extra-data-files=                     whitespace-separated file or directory globs
		  --pre-install-hook=                     file path
		  --post-install-hook=                    file path
		  --include-dependencies
		  --app-reinstall

		Cache options
		  --cache=                                directory path
		  --purge-cache
		  --no-archive
		  --no-clean-cache

		Public storage options
		  --public-storage=                       S3 URL
		  --no-public-storage

		Private storage options
		  --aws-access-key-id=                    string
		  --aws-secret-access-key=                string
		  --s3-bucket=                            S3 bucket name
		  --s3-endpoint=                          Internet address
		  --s3-acl=                               private or public-read
		  --no-private-storage
		  --no-upload
		  --no-clean-private-storage

		GHC layer options
		  --ghc-version=                          version number
		  --ghc-pre-build-hook=                   file path
		  --ghc-post-build-hook=                  file path
		  --ghc-rebuild

		Cabal layer options
		  --cabal-version=                        version number
		  --cabal-repo=                           colon-separated name and URL
		  --cabal-pre-build-hook=                 file path
		  --cabal-post-build-hook=                file path
		  --cabal-pre-update-hook=                file path
		  --cabal-post-update-hook=               file path
		  --cabal-rebuild
		  --cabal-update

		Sandbox layer options
		  --sandbox-sources=                      whitespace-separated sources
		  --sandbox-extra-apps=                   whitespace-separated apps
		  --sandbox-extra-apps-constraints=       file or directory path
		  --sandbox-extra-configure-flags=	  whitespace-separated strings
		  --sandbox-extra-libs=                   whitespace-separated strings
		  --sandbox-pre-build-hook=               file path
		  --sandbox-post-build-hook=              file path
		  --sandbox-rebuild
EOF
}
