if [ "${HALCYON_INTERNAL_PATHS:-0}" -eq 0 ]; then
	export HALCYON_INTERNAL_PATHS=1

	export HALCYON_BASE="${HALCYON_BASE:-/app}"

	_join () {
		IFS=':' && echo "$*"
	}

	_path=$( _join \
		"${HALCYON_DIR}" \
		"${HALCYON_BASE}/bin" \
		"${HALCYON_BASE}/usr/bin" \
		"${HALCYON_BASE}/ghc/bin" \
		"${HALCYON_BASE}/cabal/bin" \
		"${HALCYON_BASE}/sandbox/bin" \
		"${HALCYON_BASE}/sandbox/usr/bin"
	)
	export PATH="${_path}:${PATH:-}"

	_path=$( _join \
		"${HALCYON_BASE}/include" \
		"${HALCYON_BASE}/usr/include" \
		"${HALCYON_BASE}/sandbox/include" \
		"${HALCYON_BASE}/sandbox/usr/include"
	)
	case "${HALCYON_INTERNAL_PLATFORM}" in
	'linux-debian-'*|'linux-ubuntu-'*)
		_path=$( _join "${_path}" \
			"${HALCYON_BASE}/include/x86_64-linux-gnu" \
			"${HALCYON_BASE}/usr/include/x86_64-linux-gnu" \
			"${HALCYON_BASE}/sandbox/include/x86_64-linux-gnu" \
			"${HALCYON_BASE}/sandbox/usr/include/x86_64-linux-gnu"
		)
	esac
	export CPATH="${_path}:${CPATH:-}"

	_path=$( _join \
		"${HALCYON_BASE}/lib" \
		"${HALCYON_BASE}/usr/lib" \
		"${HALCYON_BASE}/ghc/usr/lib" \
		"${HALCYON_BASE}/sandbox/lib" \
		"${HALCYON_BASE}/sandbox/usr/lib"
	)
	case "${HALCYON_INTERNAL_PLATFORM}" in
	'linux-debian-'*|'linux-ubuntu-'*)
		_path=$( _join "${_path}" \
			"${HALCYON_BASE}/lib/x86_64-linux-gnu" \
			"${HALCYON_BASE}/usr/lib/x86_64-linux-gnu" \
			"${HALCYON_BASE}/sandbox/lib/x86_64-linux-gnu" \
			"${HALCYON_BASE}/sandbox/usr/lib/x86_64-linux-gnu"
		)
		;;
	'linux-centos-'*|'linux-fedora-'*)
		_path=$( _join "${_path}" \
			"${HALCYON_BASE}/lib64" \
			"${HALCYON_BASE}/usr/lib64" \
			"${HALCYON_BASE}/sandbox/lib64" \
			"${HALCYON_BASE}/sandbox/usr/lib64"
		)
	esac
	export LIBRARY_PATH="${_path}:${LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${_path}:${LD_LIBRARY_PATH:-}"

	_path=$( _join \
		"${HALCYON_BASE}/usr/lib/pkgconfig" \
		"${HALCYON_BASE}/usr/share/pkgconfig" \
		"${HALCYON_BASE}/sandbox/usr/lib/pkgconfig" \
		"${HALCYON_BASE}/sandbox/usr/share/pkgconfig"
	)
	case "${HALCYON_INTERNAL_PLATFORM}" in
	'linux-debian-'*|'linux-ubuntu-'*)
		_path=$( _join "${_path}" \
			"${HALCYON_BASE}/usr/lib/x86_64-linux-gnu/pkgconfig" \
			"${HALCYON_BASE}/sandbox/usr/lib/x86_64-linux-gnu/pkgconfig"
		)
		;;
	'linux-centos-'*|'linux-fedora-'*)
		_path=$( _join "${_path}" \
			"${HALCYON_BASE}/usr/lib64/pkgconfig" \
			"${HALCYON_BASE}/sandbox/usr/lib64/pkgconfig"
		)
	esac
	export PKG_CONFIG_PATH="${_path}:${PKG_CONFIG_PATH:-}"

	unset _join _path

	export PKG_CONFIG_SYSROOT_DIR="${HALCYON_BASE}/sandbox"

	# NOTE: UTF-8 locale is needed to work around a Cabal issue.
	# https://github.com/haskell/cabal/issues/1883
	case "${HALCYON_INTERNAL_PLATFORM}" in
	'freebsd-'*)
		export LANG="${LANG:-en_US.UTF-8}"
		;;
	*)
		export LANG="${LANG:-C.UTF-8}"
	esac
fi
