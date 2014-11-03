export HALCYON_DIR="${HALCYON_DIR:-/app/.halcyon}"

export PATH="${HALCYON_DIR}/ghc/bin:${PATH:-}"
export PATH="${HALCYON_DIR}/cabal/bin:${PATH}"
export PATH="${HALCYON_DIR}/sandbox/bin:${PATH}"
export PATH="${HALCYON_DIR}/app/bin:${PATH}"
export PATH="${HALCYON_DIR}/slug/bin:${PATH}"

export LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LIBRARY_PATH:-}"
export LIBRARY_PATH="${HALCYON_DIR}/sandbox/.halcyon-sandbox-extra-libs:${LIBRARY_PATH}"

export LD_LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${HALCYON_DIR}/sandbox/.halcyon-sandbox-extra-libs:${LD_LIBRARY_PATH}"

export LANG="${LANG:-en_US.UTF-8}"
