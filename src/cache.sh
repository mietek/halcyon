function prepare_cache () {
	expect_vars HALCYON_CACHE_DIR HALCYON_PURGE_CACHE

	if (( ${HALCYON_PURGE_CACHE} )); then
		log 'Purging cache'

		rm -rf "${HALCYON_CACHE_DIR}"
		mkdir -p "${HALCYON_CACHE_DIR}"

		export HALCYON_INTERNAL_OLD_CACHE_DIR=''
		return 0
	fi

	log 'Examining cache'

	export HALCYON_INTERNAL_OLD_CACHE_DIR=$( echo_tmp_dir_name 'halcyon.old-cache' ) || die
	rm -rf "${HALCYON_INTERNAL_OLD_CACHE_DIR}" || die

	mkdir -p "${HALCYON_CACHE_DIR}"
	cp -R "${HALCYON_CACHE_DIR}" "${HALCYON_INTERNAL_OLD_CACHE_DIR}" || die
	find_spaceless_recursively "${HALCYON_CACHE_DIR}" |
		sort_naturally |
		quote || die
}


function clean_cache () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	expect_args app_dir -- "$@"

	local tmp_dir
	tmp_dir=$( echo_tmp_dir_name 'halcyon.cache' ) || die

	mkdir -p "${tmp_dir}" || die

	if [ -f "${HALCYON_DIR}/ghc/.halcyon-tag" ]; then
		local ghc_tag ghc_archive
		ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
		ghc_archive=$( echo_ghc_archive "${ghc_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${ghc_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${ghc_archive}" "${tmp_dir}" || die
		fi
	fi

	if [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ]; then
		local cabal_tag cabal_archive
		cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
		cabal_archive=$( echo_cabal_archive "${cabal_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${cabal_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${cabal_archive}" "${tmp_dir}" || die
		fi
	fi

	if [ -f "${HALCYON_DIR}/sandbox/.halcyon-tag" ]; then
		local sandbox_tag sandbox_archive
		sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
		sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${tmp_dir}" || die
		fi
	fi

	if [ -f "${app_dir}/.halcyon-tag" ]; then
		local app_tag app_archive
		app_tag=$( <"${app_dir}/.halcyon-tag" ) || die
		app_archive=$( echo_app_archive "${app_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${app_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_dir}" || die
		fi
	fi

	rm -rf "${HALCYON_CACHE_DIR}" || die
	mv "${tmp_dir}" "${HALCYON_CACHE_DIR}" || die

	if has_vars HALCYON_INTERNAL_OLD_CACHE_DIR && [ -d "${HALCYON_INTERNAL_OLD_CACHE_DIR}" ]; then
		log 'Examining cache changes'

		compare_recursively "${HALCYON_INTERNAL_OLD_CACHE_DIR}" "${HALCYON_CACHE_DIR}" |
			filter_not_matching '^= ' |
			quote || die
		rm -rf "${HALCYON_INTERNAL_OLD_CACHE_DIR}" || die
	fi
}
