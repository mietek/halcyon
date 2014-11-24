if ! (( ${HALCYON_INTERNAL_PATHS:-0} )); then
	export HALCYON_INTERNAL_PATHS=1

	export HALCYON_APP_DIR="${HALCYON_APP_DIR:-/app}"

	export PATH="${HALCYON_TOP_DIR}:${PATH:-}"
	export PATH="${HALCYON_APP_DIR}/ghc/bin:${PATH}"
	export PATH="${HALCYON_APP_DIR}/cabal/bin:${PATH}"
	export PATH="${HALCYON_APP_DIR}/sandbox/bin:${PATH}"
	export PATH="${HALCYON_APP_DIR}/sandbox/usr/bin:${PATH}"
	export PATH="${HALCYON_APP_DIR}/bin:${PATH}"

	export LIBRARY_PATH="${HALCYON_APP_DIR}/ghc/usr/lib:${LIBRARY_PATH:-}"
	export LIBRARY_PATH="${HALCYON_APP_DIR}/sandbox/usr/lib:${LIBRARY_PATH}"

	export LD_LIBRARY_PATH="${HALCYON_APP_DIR}/ghc/usr/lib:${LD_LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${HALCYON_APP_DIR}/sandbox/usr/lib:${LD_LIBRARY_PATH}"

	# NOTE: A UTF-8 locale is needed to work around a Cabal issue.
	# https://github.com/haskell/cabal/issues/1883

	export LANG="${LANG:-C.UTF-8}"
fi
