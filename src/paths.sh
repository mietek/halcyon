if ! (( ${HALCYON_INTERNAL_PATHS:-0} )); then
	export HALCYON_INTERNAL_PATHS=1

	export HALCYON_BASE="${HALCYON_BASE:-/app}"

	export PATH="${HALCYON_DIR}:${PATH:-}"
	export PATH="${HALCYON_BASE}/bin:${PATH}"
	export PATH="${HALCYON_BASE}/usr/bin:${PATH}"
	export PATH="${HALCYON_BASE}/ghc/bin:${PATH}"
	export PATH="${HALCYON_BASE}/cabal/bin:${PATH}"
	export PATH="${HALCYON_BASE}/sandbox/bin:${PATH}"
	export PATH="${HALCYON_BASE}/sandbox/usr/bin:${PATH}"

	export LIBRARY_PATH="${HALCYON_BASE}/usr/lib:${LIBRARY_PATH:-}"
	export LIBRARY_PATH="${HALCYON_BASE}/ghc/usr/lib:${LIBRARY_PATH}"
	export LIBRARY_PATH="${HALCYON_BASE}/sandbox/usr/lib:${LIBRARY_PATH}"

	export LD_LIBRARY_PATH="${HALCYON_BASE}/usr/lib:${LD_LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${HALCYON_BASE}/ghc/usr/lib:${LD_LIBRARY_PATH}"
	export LD_LIBRARY_PATH="${HALCYON_BASE}/sandbox/usr/lib:${LD_LIBRARY_PATH}"

	export PKG_CONFIG_PATH="${HALCYON_BASE}/usr/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
	export PKG_CONFIG_PATH="${HALCYON_BASE}/sandbox/usr/lib/pkgconfig:${PKG_CONFIG_PATH}"

	# NOTE: A UTF-8 locale is needed to work around a Cabal issue.
	# https://github.com/haskell/cabal/issues/1883

	export LANG="${LANG:-C.UTF-8}"
fi
