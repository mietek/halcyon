#!/usr/bin/env bash


function echo_tmp_cache_dir () {
	mktemp -du "/tmp/halcyon-cache.XXXXXXXXXX"
}


function echo_tmp_old_cache_dir () {
	mktemp -du "/tmp/halcyon-cache.old.XXXXXXXXXX"
}




function prepare_cache () {
	expect_vars HALCYON_CACHE_DIR HALCYON_PURGE_CACHE

	log_begin 'Preparing cache...'

	if (( ${HALCYON_PURGE_CACHE} )); then
		rm -rf "${HALCYON_CACHE_DIR}"
	fi

	export HALCYON_OLD_CACHE_TMP_DIR=$( echo_tmp_old_cache_dir ) || die
	rm -rf "${HALCYON_OLD_CACHE_TMP_DIR}" || die

	local has_old_cache
	has_old_cache=0
	if [ -d "${HALCYON_CACHE_DIR}" ]; then
		has_old_cache=1
	fi
	mkdir -p "${HALCYON_CACHE_DIR}" || die

	log_end 'done'

	if (( ${has_old_cache} )); then
		log 'Examining cache'

		cp -R "${HALCYON_CACHE_DIR}" "${HALCYON_OLD_CACHE_TMP_DIR}" || die
		find_spaceless "${HALCYON_CACHE_DIR}" |
			sed "s:^${HALCYON_CACHE_DIR}/::" |
			sort_naturally |
			sed 's/^/+ /' |
			log_file_indent || die
	fi
}


function clean_cache () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_OLD_CACHE_TMP_DIR

	expect_args build_dir -- "$@"

	log_begin 'Cleaning cache...'

	local tmp_dir
	tmp_dir=$( echo_tmp_cache_dir ) || die

	mkdir -p "${tmp_dir}" || die

	if [ -f "${HALCYON_DIR}/ghc/tag" ]; then
		local ghc_tag ghc_archive
		ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
		ghc_archive=$( echo_ghc_archive "${ghc_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${ghc_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${ghc_archive}" "${tmp_dir}" || die
		fi
	fi

	if [ -f "${HALCYON_DIR}/cabal/tag" ]; then
		local cabal_tag cabal_archive
		cabal_tag=$( <"${HALCYON_DIR}/cabal/tag" ) || die
		cabal_archive=$( echo_cabal_archive "${cabal_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${cabal_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${cabal_archive}" "${tmp_dir}" || die
		fi
	fi

	if [ -f "${HALCYON_DIR}/sandbox/tag" ]; then
		local sandbox_tag sandbox_archive
		sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
		sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${tmp_dir}" || die
		fi
	fi

	if [ -f "${build_dir}/tag" ]; then
		local build_tag build_archive
		build_tag=$( <"${build_dir}/tag" ) || die
		build_archive=$( echo_build_archive "${build_tag}" ) || die

		if [ -f "${HALCYON_CACHE_DIR}/${build_archive}" ]; then
			mv "${HALCYON_CACHE_DIR}/${build_archive}" "${tmp_dir}" || die
		fi
	fi

	rm -rf "${HALCYON_CACHE_DIR}" || die
	mv "${tmp_dir}" "${HALCYON_CACHE_DIR}" || die

	log_end 'done'

	if [ -d "${HALCYON_OLD_CACHE_TMP_DIR}" ]; then
		log 'Examining cache changes'

		compare_recursively "${HALCYON_OLD_CACHE_TMP_DIR}" "${HALCYON_CACHE_DIR}" |
			filter_not_matching '^= ' |
			log_file_indent || die
		rm -rf "${HALCYON_OLD_CACHE_TMP_DIR}" || die
	fi
}
