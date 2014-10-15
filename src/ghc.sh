function echo_ghc_libgmp10_x86_64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.3')
		echo 'http://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.2')
		echo 'http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.1')
		echo 'http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.xz';;
	*)
		die "Unexpected GHC version: ${ghc_version} (libgmp.so.10)"
	esac
}


function echo_ghc_libgmp3_x86_64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.3')
		echo 'http://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-unknown-linux-centos65.tar.xz';;
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
		die "Unexpected GHC version: ${ghc_version} (libgmp.so.3)"
	esac
}


function echo_ghc_version_from_base_version () {
	local base_version
	expect_args base_version -- "$@"

	case "${base_version}" in
	'4.7.0.1')
		echo '7.8.3';;
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
	echo '7.8.3'
}


function make_ghc_tag () {
	expect_vars HALCYON_DIR

	local ghc_version ghc_hooks_hash
	expect_args ghc_version ghc_hooks_hash -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_hooks_hash}"
}


function echo_ghc_tag_os () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${ghc_tag}"
}


function echo_ghc_tag_halcyon_dir () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	awk -F$'\t' '{ print $2 }' <<<"${ghc_tag}"
}


function echo_ghc_tag_version () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	awk -F$'\t' '{ print $3 }' <<<"${ghc_tag}" | sed 's/^ghc-//'
}


function echo_ghc_tag_hooks_hash () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	awk -F$'\t' '{ print $4 }' <<<"${ghc_tag}"
}


function echo_ghc_id () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	local ghc_version ghc_hooks_hash
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_hooks_hash=$( echo_ghc_tag_hooks_hash "${ghc_tag}" ) || die

	echo "${ghc_version}${ghc_hooks_hash:+~${ghc_hooks_hash:0:7}}"
}


function echo_ghc_archive () {
	local ghc_tag
	expect_args ghc_tag -- "$@"

	local ghc_id
	ghc_id=$( echo_ghc_id "${ghc_tag}" ) || die

	echo "halcyon-ghc-${ghc_id}.tar.xz"
}


function echo_tmp_ghc_dir () {
	mktemp -du '/tmp/halcyon-ghc.XXXXXXXXXX'
}


function detect_base_version () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc"

	ghc-pkg list --simple-output |
		grep -oE '\bbase-[0-9\.]+\b' |
		sed 's/^base-//' || die
}


function determine_ghc_version () {
	expect_vars HALCYON_NO_WARN_CONSTRAINTS

	local app_dir
	expect_args app_dir -- "$@"

	log_begin 'Determining GHC version...'

	local ghc_version
	if has_vars HALCYON_FORCE_GHC_VERSION; then
		ghc_version="${HALCYON_FORCE_GHC_VERSION}"

		log_end "${ghc_version} (forced)"
	elif [ -f "${app_dir}/cabal.config" ]; then
		local base_version
		base_version=$(
			detect_constraints "${app_dir}" |
			filter_matching "^base " |
			match_exactly_one |
			sed 's/^.* //'
		) || die

		ghc_version=$( echo_ghc_version_from_base_version "${base_version}" ) || die

		log_end "${ghc_version}"
	else
		ghc_version=$( echo_ghc_default_version ) || die

		log_end "${ghc_version} (default)"
		if ! (( "${HALCYON_NO_WARN_CONSTRAINTS}" )); then
			log_warning 'Expected cabal.config with explicit constraints'
		fi
	fi

	echo "${ghc_version}"
}


function determine_ghc_hooks_hash () {
	local app_dir
	expect_args app_dir -- "$@"

	log_begin 'Determining GHC hooks hash...'

	local ghc_hooks_hash
	ghc_hooks_hash=$( hash_hooks "${app_dir}/.halcyon-hooks/ghc-"* ) || die

	if [ -z "${ghc_hooks_hash}" ]; then
		log_end '(none)'
	else
		log_end "${ghc_hooks_hash:0:7}"
	fi

	echo "${ghc_hooks_hash}"
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


function validate_ghc_hooks () {
	local ghc_hooks_hash hooks_dir
	expect_args ghc_hooks_hash hooks_dir -- "$@"

	local candidate_hooks_hash
	candidate_hooks_hash=$( hash_hooks "${hooks_dir}/ghc-"* ) || die

	if [ "${candidate_hooks_hash}" != "${ghc_hooks_hash}" ]; then
		return 1
	fi
}


function validate_ghc () {
	expect_vars HALCYON_DIR

	local ghc_tag
	expect_args ghc_tag -- "$@"

	local ghc_hooks_hash
	ghc_hooks_hash=$( echo_ghc_tag_hooks_hash "${ghc_tag}" ) || die

	if ! [ -f "${HALCYON_DIR}/ghc/.halcyon-tag" ] ||
		! validate_ghc_tag "${ghc_tag}" <"${HALCYON_DIR}/ghc/.halcyon-tag" ||
		! validate_ghc_hooks "${ghc_hooks_hash}" "${HALCYON_DIR}/ghc/.halcyon-hooks"
	then
		return 1
	fi
}


function prepare_ghc_libs () {
	expect_vars HALCYON_DIR
	expect_no_existing "${HALCYON_DIR}/ghc/lib"

	local ghc_version
	expect_args ghc_version -- "$@"

	local os
	os=$( detect_os ) || die

	case "${os}-ghc-${ghc_version}" in
	'linux-ubuntu-14.04-x86_64-ghc-7.8.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp10_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		expect_existing "${libtinfo5_file}" "${libgmp10_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp10_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp10_x86_64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-14.04-x86_64-ghc-7.6.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp10_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		expect_existing "${libtinfo5_file}" "${libgmp10_file}"

		# NOTE: There is no libgmp.so.3 on Ubuntu 14.04 LTS, and there is no
		# .10-flavoured binary distribution of GHC 7.6.*.  However, GHC does not
		# use the `mpn_bdivmod` function, which is the only difference between
		# the ABI of .3 and .10.  Hence, following Gentoo/Haskell, we symlink
		# .10 to .3, and use the .3-flavoured binary distribution.
		# https://github.com/gentoo-haskell/gentoo-haskell/blob/master/dev-lang/ghc/files/ghc-apply-gmp-hack

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp10_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die
		ln -s "${libgmp10_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so.3" || die

		echo_ghc_libgmp3_x86_64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-12.04-x86_64-ghc-7.8.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp10_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		expect_existing "${libtinfo5_file}" "${libgmp10_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp10_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp10_x86_64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-12.04-x86_64-ghc-7.6.'*)
		libtinfo5_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp3_file='/usr/lib/libgmp.so.3'
		expect_existing "${libtinfo5_file}" "${libgmp3_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp3_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp3_x86_64_original_url "${ghc_version}" || die
		;;
	'linux-ubuntu-10.04-x86_64-ghc-7.'[68]'.'*)
		libncurses5_file='/lib/libncurses.so.5'
		libgmp3_file='/usr/lib/libgmp.so.3'
		expect_existing "${libncurses5_file}" "${libgmp3_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libncurses5_file}" "${HALCYON_DIR}/ghc/lib/libtinfo.so.5" || die
		ln -s "${libgmp3_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

		echo_ghc_libgmp3_x86_64_original_url "${ghc_version}" || die
		;;
	*)
		local os_description
		os_description=$( echo_os_description "${os}" ) || die
		die "Unexpected GHC and OS combination: ${ghc_version} and ${os_description}"
	esac
}


function build_ghc () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_GHC HALCYON_QUIET
	expect_no_existing "${HALCYON_DIR}/ghc"

	local ghc_tag app_dir
	expect_args ghc_tag app_dir -- "$@"

	local ghc_version ghc_id
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_id=$( echo_ghc_id "${ghc_tag}" ) || die

	if (( ${HALCYON_FORCE_BUILD_ALL} )) || (( ${HALCYON_FORCE_BUILD_GHC} )); then
		log "Building GHC layer ${ghc_id} (forced)"
	else
		log "Building GHC layer ${ghc_id}"
	fi

	local original_url original_archive tmp_dir
	original_url=$( prepare_ghc_libs "${ghc_version}" ) || die
	original_archive=$( basename "${original_url}" ) || die
	tmp_dir=$( echo_tmp_ghc_dir ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${original_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}" || die

		if ! prepare_original "${original_archive}" "${original_url}" "${HALCYON_CACHE_DIR}"; then
			die "Cannot download GHC ${ghc_version} original archive"
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}"; then
			rm -rf "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_dir}" || die
			die "Cannot extract GHC ${ghc_version} original archive"
		fi
	fi

	if [ -f "${app_dir}/.halcyon-hooks/ghc-pre-build" ]; then
		log "Running GHC ${ghc_id} pre-build hook"
		( quote_quietly "${app_dir}/.halcyon-hooks/ghc-pre-build" "${ghc_tag}" "${tmp_dir}/ghc-${ghc-version}" "${app_dir}" ) || die

		mkdir -p "${HALCYON_DIR}/ghc/.halcyon-hooks" || die
		cp "${app_dir}/.halcyon-hooks/ghc-pre-build" "${HALCYON_DIR}/ghc/.halcyon-hooks" || die
	fi

	log "Installing GHC ${ghc_id}"

	if ! (
		cd "${tmp_dir}/ghc-${ghc_version}" &&
		quote_quietly "${HALCYON_QUIET}" ./configure --prefix="${HALCYON_DIR}/ghc" &&
		quote_quietly "${HALCYON_QUIET}" make install
	); then
		die "Failed to install GHC ${ghc_id}"
	fi

	log "Finished installing GHC ${ghc_id}"

	if [ -f "${app_dir}/.halcyon-hooks/ghc-post-build" ]; then
		log "Running GHC ${ghc_id} post-build hook"
		( quote_quietly "${app_dir}/.halcyon-hooks/ghc-post-build" "${ghc_tag}" "${tmp_dir}/ghc-${ghc-version}" "${app_dir}" ) || die

		mkdir -p "${HALCYON_DIR}/ghc/.halcyon-hooks" || die
		cp "${app_dir}/.halcyon-hooks/ghc-post-build" "${HALCYON_DIR}/ghc/.halcyon-hooks" || die
	fi

	echo "${ghc_tag}" >"${HALCYON_DIR}/ghc/.halcyon-tag" || die

	rm -rf "${tmp_dir}" || die

	local ghc_size
	ghc_size=$( measure_recursively "${HALCYON_DIR}/ghc" ) || die
	log "Finished building GHC layer ${ghc_id}, ${ghc_size}"
}


function strip_ghc () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	local ghc_tag ghc_version ghc_id
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_id=$( echo_ghc_id "${ghc_tag}" ) || die

	log_indent_begin "Stripping GHC layer ${ghc_id}..."

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
		die "Unexpected GHC version: ${ghc_version}"
	esac

	local ghc_size
	ghc_size=$( measure_recursively "${HALCYON_DIR}/ghc" ) || die
	log_end "${ghc_size}"
}


function archive_ghc () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	if (( ${HALCYON_NO_ARCHIVE} )); then
		return 0
	fi

	local ghc_tag os ghc_archive ghc_id
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	os=$( echo_ghc_tag_os "${ghc_tag}" ) || die
	ghc_archive=$( echo_ghc_archive "${ghc_tag}" ) || die
	ghc_id=$( echo_ghc_id "${ghc_tag}" ) || die

	rm -f "${HALCYON_CACHE_DIR}/${ghc_archive}" || die
	tar_archive "${HALCYON_DIR}/ghc" "${HALCYON_CACHE_DIR}/${ghc_archive}" || die
	upload_layer "${HALCYON_CACHE_DIR}/${ghc_archive}" "${os}" || die
}


function restore_ghc () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local ghc_tag
	expect_args ghc_tag -- "$@"

	local os ghc_archive ghc_id
	os=$( echo_ghc_tag_os "${ghc_tag}" ) || die
	ghc_archive=$( echo_ghc_archive "${ghc_tag}" ) || die
	ghc_id=$( echo_ghc_id "${ghc_tag}" ) || die

	if validate_ghc "${ghc_tag}"; then
		log "Using installed GHC layer ${ghc_id}"
		return 0
	fi
	rm -rf "${HALCYON_DIR}/ghc" || die

	log "Restoring GHC layer ${ghc_id}"

	if ! [ -f "${HALCYON_CACHE_DIR}/${ghc_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" ||
		! validate_ghc "${ghc_tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" || die

		if ! download_layer "${os}" "${ghc_archive}" "${HALCYON_CACHE_DIR}"; then
			log "Cannot download GHC layer archive ${ghc_id}"
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" ||
			! validate_ghc "${ghc_tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${ghc_archive}" "${HALCYON_DIR}/ghc" || die
			log_warning "Cannot extract GHC layer archive ${ghc_id}"
			return 1
		fi
	fi
}


function activate_ghc () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	# TODO: Check ~/.ghc
}


function deactivate_ghc () {
	expect_vars HALCYON_DIR

	# TODO: Check ~/.ghc

	rm -rf "${HALCYON_DIR}/ghc" || die
}


function install_ghc () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_GHC HALCYON_NO_BUILD

	local app_dir
	expect_args app_dir -- "$@"

	local ghc_version ghc_hooks_hash ghc_tag
	ghc_version=$( determine_ghc_version "${app_dir}" ) || die
	ghc_hooks_hash=$( determine_ghc_hooks_hash "${app_dir}/.halcyon-hooks" ) || die
	ghc_tag=$( make_ghc_tag "${ghc_version}" "${ghc_hooks_hash}" ) || die

	if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
		! (( ${HALCYON_FORCE_BUILD_GHC} )) &&
		restore_ghc "${ghc_tag}"
	then
		activate_ghc || die
		return 0
	fi

	! (( ${HALCYON_NO_BUILD} )) || return 1

	deactivate_ghc || die
	build_ghc "${ghc_tag}" "${app_dir}" || die
	strip_ghc || die
	archive_ghc || die
	activate_ghc || die
}
