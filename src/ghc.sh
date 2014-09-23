#!/usr/bin/env bash


function echo_ghc_libgmp10_x64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.2')
		echo 'http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.1')
		echo 'http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.xz';;
	*)
		die "Unexpected GHC version for use with libgmp.so.10: ${ghc_version}"
	esac
}


function echo_ghc_libgmp3_x64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.2')
		echo 'http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-linux-centos65.tar.xz';;
	'7.8.1')
		echo 'http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-centos65.tar.xz';;
	'7.6.3')
		echo 'http://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-x86_64-unknown-linux.tar.bz2';;
	'7.6.2')
		echo 'http://www.haskell.org/ghc/dist/7.6.2/ghc-7.6.2-x86_64-unknown-linux.tar.bz2';;
	'7.6.1')
		echo 'http://www.haskell.org/ghc/dist/7.6.1/ghc-7.6.1-x86_64-unknown-linux.tar.bz2';;
	'7.4.2')
		echo 'http://www.haskell.org/ghc/dist/7.4.2/ghc-7.4.2-x86_64-unknown-linux.tar.bz2';;
	'7.4.1')
		echo 'http://www.haskell.org/ghc/dist/7.4.1/ghc-7.4.1-x86_64-unknown-linux.tar.bz2';;
	'7.2.2')
		echo 'http://www.haskell.org/ghc/dist/7.2.2/ghc-7.2.2-x86_64-unknown-linux.tar.bz2';;
	'7.2.1')
		echo 'http://www.haskell.org/ghc/dist/7.2.1/ghc-7.2.1-x86_64-unknown-linux.tar.bz2';;
	'7.0.4')
		echo 'http://www.haskell.org/ghc/dist/7.0.4/ghc-7.0.4-x86_64-unknown-linux.tar.bz2';;
	'7.0.3')
		echo 'http://www.haskell.org/ghc/dist/7.0.3/ghc-7.0.3-x86_64-unknown-linux.tar.bz2';;
	'7.0.2')
		echo 'http://www.haskell.org/ghc/dist/7.0.2/ghc-7.0.2-x86_64-unknown-linux.tar.bz2';;
	'7.0.1')
		echo 'http://www.haskell.org/ghc/dist/7.0.1/ghc-7.0.1-x86_64-unknown-linux.tar.bz2';;
	'6.12.3')
		echo 'http://www.haskell.org/ghc/dist/6.12.3/ghc-6.12.3-x86_64-unknown-linux-n.tar.bz2';;
	'6.12.2')
		echo 'http://www.haskell.org/ghc/dist/6.12.2/ghc-6.12.2-x86_64-unknown-linux-n.tar.bz2';;
	'6.12.1')
		echo 'http://www.haskell.org/ghc/dist/6.12.1/ghc-6.12.1-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.4')
		echo 'http://www.haskell.org/ghc/dist/6.10.4/ghc-6.10.4-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.3')
		echo 'http://www.haskell.org/ghc/dist/6.10.3/ghc-6.10.3-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.2')
		echo 'http://www.haskell.org/ghc/dist/6.10.2/ghc-6.10.2-x86_64-unknown-linux-libedit2.tar.bz2';;
	'6.10.1')
		echo 'http://www.haskell.org/ghc/dist/6.10.1/ghc-6.10.1-x86_64-unknown-linux-libedit2.tar.bz2';;
	*)
		die "Unexpected GHC version for use with libgmp.so.3: ${ghc_version}"
	esac
}


function echo_ghc_version_from_base_version () {
	local base_version
	expect_args base_version -- "$@"

	case "${base_version}" in
	'4.7.0.0')
		echo '7.8.2';;
	'4.6.0.1')
		echo '7.6.3';;
	'4.6.0.0')
		echo '7.6.1';;
	*)
		die "Unexpected base version: ${base_version}"
	esac
}


function echo_ghc_default_version () {
	echo '7.8.2'
}




function echo_ghc_tag () {
	expect_vars HALCYON_DIR

	local ghc_version ghc_variant
	expect_args ghc_version ghc_variant -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${HALCYON_DIR}\t${os}\tghc-${ghc_version}\t${ghc_variant}"
}


function echo_ghc_tag_version () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	awk '{ print $3 }' <<<"${ghc_tag}" | sed 's/^ghc-//'
}


function echo_ghc_tag_variant () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	awk '{ print $4 }' <<<"${ghc_tag}"
}




function echo_ghc_archive () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	local ghc_version ghc_variant
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_variant=$( echo_ghc_tag_variant "${ghc_tag}" ) || die

	echo "halcyon-ghc-${ghc_version}${ghc_variant:+-${ghc_variant}}.tar.xz"
}


function echo_ghc_description () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	local ghc_version ghc_variant
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_variant=$( echo_ghc_tag_variant "${ghc_tag}" ) || die

	echo "GHC ${ghc_version}${ghc_variant:+ (${ghc_variant})}"
}




function echo_tmp_ghc_dir () {
	mktemp -du "/tmp/halcyon-ghc.XXXXXXXXXX"
}




function validate_ghc_tag () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	if [ "${candidate_tag}" != "${ghc_tag}" ]; then
		return 1
	fi
}




function detect_base_version () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc"

	ghc-pkg list --simple-output |
		grep -oE '\bbase-[0-9\.]+\b' |
		sed 's/^base-//' || die
}




function prepare_ghc_libs () {
	expect_vars HALCYON_DIR
	expect_no "${HALCYON_DIR}/ghc/lib"

	local ghc_version
	expect_args ghc_version -- "$@"

	local os
	os=$( detect_os ) || die

	case "${os}-ghc-${ghc_version}" in
	'linux-ubuntu-14-04-x64-ghc-7.8.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp10_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		expect "${libtinfo5_file}" "${libgmp10_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp10_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp10_x64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-12-04-x64-ghc-7.8.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp10_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		expect "${libtinfo5_file}" "${libgmp10_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp10_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp10_x64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-12-04-x64-ghc-7.6.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp3_file='/usr/lib/libgmp.so.3'
		expect "${libtinfo5_file}" "${libgmp3_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp3_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp3_x64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-10-04-x64-ghc-7.'[68]'.'*)
		libncurses5_file='/lib/libncurses.so.5'
		libgmp3_file='/usr/lib/libgmp.so.3'
		expect "${libncurses5_file}" "${libgmp3_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libncurses5_file}" "${HALCYON_DIR}/ghc/lib/libtinfo.so.5" || die
		ln -s "${libgmp3_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp3_x64_original_url "${ghc_version}" || die
		;;
	*)
		local os_description
		os_description=$( echo_os_description "${os}" ) || die
		die "Installing GHC ${ghc_version} on ${os_description} is not implemented yet"
	esac
}




function build_ghc () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect_no "${HALCYON_DIR}/ghc"

	local ghc_version
	expect_args ghc_version -- "$@"

	log "Building GHC ${ghc_version}"

	local original_url
	original_url=$( prepare_ghc_libs "${ghc_version}" ) || die

	local original_archive tmp_dir
	original_archive=$( basename "${original_url}" ) || die
	tmp_dir=$( echo_tmp_ghc_dir ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${original_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}" || die

		if ! download_original "${original_archive}" "${original_url}" "${HALCYON_CACHE_DIR}"; then
			die "GHC ${ghc_version} is not available"
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}"; then
			rm -rf "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}" || die
			die "Restoring ${original_archive} failed"
		fi
	fi

	log "Installing GHC ${ghc_version}"

	if ! (
		cd "${tmp_dir}/ghc-${ghc_version}" &&
		silently ./configure --prefix="${HALCYON_DIR}/ghc" &&
		silently make install
	); then
		rm -rf "${tmp_dir}" || die
		die "Installing GHC ${ghc_version} failed"
	fi

	rm -rf "${HALCYON_DIR}/ghc/share" "${tmp_dir}" || die

	echo_ghc_tag "${ghc_version}" 'uncut' >"${HALCYON_DIR}/ghc/tag" || die

	local ghc_size
	ghc_size=$( measure_recursively "${HALCYON_DIR}/ghc" ) || die
	log "Installed GHC ${ghc_version}, ${ghc_size}"
}


function cut_ghc () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local ghc_tag ghc_version
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die

	log_begin "Cutting GHC ${ghc_version}..."

	case "${ghc_version}" in
	'7.8.'*)
		rm -rf  "${HALCYON_DIR}/ghc/bin/haddock"                        \
			"${HALCYON_DIR}/ghc/bin/haddock-ghc-${ghc_version}"     \
			"${HALCYON_DIR}/ghc/bin/hp2ps"                          \
			"${HALCYON_DIR}/ghc/bin/hpc"                            \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/bin/haddock" \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/bin/hpc"     \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/html"        \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/latex" || die
		find "${HALCYON_DIR}/ghc"              \
				-type f           -and \
				\(                     \
				-name '*_p.a'     -or  \
				-name '*.p_hi'    -or  \
				-name '*HS*.o'    -or  \
				-name '*_debug.a'      \
				\)                     \
				-delete || die
		ghc-pkg recache || die
		;;
	'7.6.'*)
		rm -rf  "${HALCYON_DIR}/ghc/bin/haddock"                    \
			"${HALCYON_DIR}/ghc/bin/haddock-ghc-${ghc_version}" \
			"${HALCYON_DIR}/ghc/bin/hp2ps"                      \
			"${HALCYON_DIR}/ghc/bin/hpc"                        \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/haddock" \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/html"    \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/latex" || die
		find "${HALCYON_DIR}/ghc"              \
				-type f           -and \
				\(                     \
				-name '*_p.a'     -or  \
				-name '*.p_hi'    -or  \
				-name '*.dyn_hi'  -or  \
				-name '*HS*.so'   -or  \
				-name '*HS*.o'    -or  \
				-name '*_debug.a'      \
				\)                     \
				-delete || die
		ghc-pkg recache || die
		;;
	*)
		die "Cutting GHC ${ghc_version} is not implemented yet"
	esac

	echo_ghc_tag "${ghc_version}" '' >"${HALCYON_DIR}/ghc/tag" || die

	local ghc_size
	ghc_size=$( measure_recursively "${HALCYON_DIR}/ghc" ) || die
	log_end "done, ${ghc_size}"
}


function strip_ghc () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local ghc_tag ghc_version
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_description=$( echo_ghc_description "${ghc_tag}" ) || die

	log_begin "Stripping ${ghc_description}..."

	case "${ghc_version}" in
	'7.8.'*)
		strip --strip-unneeded                                                    \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/bin/ghc"               \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/bin/ghc-pkg"           \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/bin/hsc2hs"            \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/bin/runghc"            \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/mkGmpDerivedConstants" \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/unlit" || die
		find "${HALCYON_DIR}/ghc"           \
				-type f        -and \
				\(                  \
				-name '*.so'   -or  \
				-name '*.so.*' -or  \
				-name '*.a'         \
				\)                  \
				-print0 |
			strip0 --strip-unneeded || die
		;;
	'7.6.'*)
		strip --strip-unneeded                                      \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/ghc"     \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/ghc-pkg" \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/hsc2hs"  \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/runghc"  \
			"${HALCYON_DIR}/ghc/lib/ghc-${ghc_version}/unlit" || die
		find "${HALCYON_DIR}/ghc"           \
				-type f        -and \
				\(                  \
				-name '*.so'   -or  \
				-name '*.so.*' -or  \
				-name '*.a'         \
				\)                  \
				-print0 |
			strip0 --strip-unneeded || die
		;;
	*)
		die "Stripping GHC ${ghc_version} is not implemented yet"
	esac

	local ghc_size
	ghc_size=$( measure_recursively "${HALCYON_DIR}/ghc" ) || die
	log_end "done, ${ghc_size}"
}




function cache_ghc () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local ghc_tag ghc_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_description=$( echo_ghc_description "${ghc_tag}" ) || die

	log "Caching ${ghc_description}"

	local ghc_archive os
	ghc_archive=$( echo_ghc_archive "${ghc_tag}" ) || die
	os=$( detect_os ) || die

	rm -f "${HALCYON_CACHE_DIR}/${ghc_archive}" || die
	tar_archive "${HALCYON_DIR}/ghc" "${HALCYON_CACHE_DIR}/${ghc_archive}" || die
	upload_prepared "${HALCYON_CACHE_DIR}/${ghc_archive}" "${os}" || die
}


function restore_ghc () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local ghc_tag
	expect_args ghc_tag -- "$@"

	local ghc_description
	ghc_description=$( echo_ghc_description "${ghc_tag}" ) || die

	log "Restoring ${ghc_description}"

	if [ -f "${HALCYON_DIR}/ghc/tag" ] &&
		validate_ghc_tag "${ghc_tag}" <"${HALCYON_DIR}/ghc/tag"
	then
		return 0
	fi
	rm -rf "${HALCYON_DIR}/ghc" || die

	local os ghc_archive
	os=$( detect_os ) || die
	ghc_archive=$( echo_ghc_archive "${ghc_tag}" ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${ghc_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" ||
		! [ -f "${HALCYON_DIR}/ghc/tag" ] ||
		! validate_ghc_tag "${ghc_tag}" <"${HALCYON_DIR}/ghc/tag"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" || die

		if ! download_prepared "${os}" "${ghc_archive}" "${HALCYON_CACHE_DIR}"; then
			log_warning "${ghc_description} is not prepared"
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" ||
			! [ -f "${HALCYON_DIR}/ghc/tag" ] ||
			! validate_ghc_tag "${ghc_tag}" <"${HALCYON_DIR}/ghc/tag"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" || die
			log_warning "Restoring ${ghc_archive} failed"
			return 1
		fi
	fi
}




function infer_ghc_version () {
	local build_dir
	expect_args build_dir -- "$@"

	log_begin 'Inferring GHC version...'

	local ghc_version
	if has_vars HALCYON_FORCE_GHC_VERSION; then
		ghc_version="${HALCYON_FORCE_GHC_VERSION}"

		log_end "${ghc_version}, forced"
	elif [ -f "${build_dir}/cabal.config" ]; then
		local base_version
		base_version=$(
			detect_constraints "${build_dir}" |
			filter_matching "^base " |
			match_exactly_one |
			sed 's/^.* //'
		) || die

		ghc_version=$( echo_ghc_version_from_base_version "${base_version}" ) || die

		log_end "done, ${ghc_version}"
	else
		ghc_version=$( echo_ghc_default_version ) || die

		log_end "${ghc_version}, default"
		if ! (( "${HALCYON_FAKE_BUILD:-0}" )); then
			log_warning 'Expected cabal.config with explicit constraints'
		fi
	fi

	echo "${ghc_version}"
}




function activate_ghc () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local ghc_tag ghc_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_description=$( echo_ghc_description "${ghc_tag}" ) || die

	log_begin "Activating ${ghc_description}..."

	log_end 'done'
}


function deactivate_ghc () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local ghc_tag ghc_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_description=$( echo_ghc_description "${ghc_tag}" ) || die

	log_begin "Dectivating ${ghc_description}..."

	log_end 'done'
}




function install_ghc () {
	expect_vars HALCYON_PREPARED_ONLY HALCYON_NO_CUT_GHC

	local build_dir
	expect_args build_dir -- "$@"

	local ghc_variant
	if (( ${HALCYON_NO_CUT_GHC} )); then
		ghc_variant='uncut'
	else
		ghc_variant=''
	fi

	local ghc_version ghc_tag
	ghc_version=$( infer_ghc_version "${build_dir}" ) || die
	ghc_tag=$( echo_ghc_tag "${ghc_version}" "${ghc_variant}" ) || die

	if restore_ghc "${ghc_tag}"; then
		activate_ghc || die
		return 0
	fi

	! (( ${HALCYON_PREPARED_ONLY} )) || return 1

	build_ghc "${ghc_version}" || die
	if ! (( ${HALCYON_NO_CUT_GHC} )); then
		cut_ghc || die
	fi
	strip_ghc || die
	cache_ghc || die
	activate_ghc || die
}
