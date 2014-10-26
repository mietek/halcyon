function get_default_ghc_version () {
	echo '7.8.3'
}


function map_ghc_version_to_libgmp10_x86_64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.3')	echo 'http://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.2')	echo 'http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.1')	echo 'http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.xz';;
	*)		die "Unexpected GHC version: ${ghc_version} (libgmp.so.10)"
	esac
}


function map_ghc_version_to_libgmp3_x86_64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.3')	echo 'http://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-unknown-linux-centos65.tar.xz';;
	'7.8.2')	echo 'http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-linux-centos65.tar.xz';;
	'7.8.1')	echo 'http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-centos65.tar.xz';;
	'7.6.3')	echo 'http://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-x86_64-unknown-linux.tar.bz2';;
	'7.6.2')	echo 'http://www.haskell.org/ghc/dist/7.6.2/ghc-7.6.2-x86_64-unknown-linux.tar.bz2';;
	'7.6.1')	echo 'http://www.haskell.org/ghc/dist/7.6.1/ghc-7.6.1-x86_64-unknown-linux.tar.bz2';;
	'7.4.2')	echo 'http://www.haskell.org/ghc/dist/7.4.2/ghc-7.4.2-x86_64-unknown-linux.tar.bz2';;
	'7.4.1')	echo 'http://www.haskell.org/ghc/dist/7.4.1/ghc-7.4.1-x86_64-unknown-linux.tar.bz2';;
	'7.2.2')	echo 'http://www.haskell.org/ghc/dist/7.2.2/ghc-7.2.2-x86_64-unknown-linux.tar.bz2';;
	'7.2.1')	echo 'http://www.haskell.org/ghc/dist/7.2.1/ghc-7.2.1-x86_64-unknown-linux.tar.bz2';;
	'7.0.4')	echo 'http://www.haskell.org/ghc/dist/7.0.4/ghc-7.0.4-x86_64-unknown-linux.tar.bz2';;
	'7.0.3')	echo 'http://www.haskell.org/ghc/dist/7.0.3/ghc-7.0.3-x86_64-unknown-linux.tar.bz2';;
	'7.0.2')	echo 'http://www.haskell.org/ghc/dist/7.0.2/ghc-7.0.2-x86_64-unknown-linux.tar.bz2';;
	'7.0.1')	echo 'http://www.haskell.org/ghc/dist/7.0.1/ghc-7.0.1-x86_64-unknown-linux.tar.bz2';;
	'6.12.3')	echo 'http://www.haskell.org/ghc/dist/6.12.3/ghc-6.12.3-x86_64-unknown-linux-n.tar.bz2';;
	'6.12.2')	echo 'http://www.haskell.org/ghc/dist/6.12.2/ghc-6.12.2-x86_64-unknown-linux-n.tar.bz2';;
	'6.12.1')	echo 'http://www.haskell.org/ghc/dist/6.12.1/ghc-6.12.1-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.4')	echo 'http://www.haskell.org/ghc/dist/6.10.4/ghc-6.10.4-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.3')	echo 'http://www.haskell.org/ghc/dist/6.10.3/ghc-6.10.3-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.2')	echo 'http://www.haskell.org/ghc/dist/6.10.2/ghc-6.10.2-x86_64-unknown-linux-libedit2.tar.bz2';;
	'6.10.1')	echo 'http://www.haskell.org/ghc/dist/6.10.1/ghc-6.10.1-x86_64-unknown-linux-libedit2.tar.bz2';;
	*)		die "Unexpected GHC version: ${ghc_version} (libgmp.so.3)"
	esac
}


function map_base_package_version_to_ghc_version () {
	local base_version
	expect_args base_version -- "$@"

	case "${base_version}" in
	'4.7.0.1')	echo '7.8.3';;
	'4.7.0.0')	echo '7.8.2';;
	'4.6.0.1')	echo '7.6.3';;
	'4.6.0.0')	echo '7.6.1';;
	*)		die "Unexpected base package version: ${base_version}"
	esac
}


function map_constraints_to_ghc_version () {
	local constraints
	expect_args constraints -- "$@"

	local base_version
	if ! base_version=$(
		filter_matching "^base " <<<"${constraints}" |
		match_exactly_one |
		sed 's/^.* //'
	); then
		die 'Unexpected missing base package version'
	fi

	map_base_package_version_to_ghc_version "${base_version}" || die
}


function create_ghc_tag () {
	local ghc_version ghc_magic_hash
	expect_args ghc_version ghc_magic_hash -- "$@"

	create_tag '' ''                             \
		'' ''                                \
		"${ghc_version}" "${ghc_magic_hash}" \
		'' '' '' ''                          \
		'' '' || die
}


function detect_ghc_tag () {
	expect_vars HALCYON_DIR

	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_ghc_tag '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect GHC layer tag'
	fi

	echo "${tag}"
}


function derive_ghc_tag () {
	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	create_ghc_tag "${ghc_version}" "${ghc_magic_hash}" || die
}


function format_ghc_id () {
	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	echo "${ghc_version}${ghc_magic_hash:+.${ghc_magic_hash:0:7}}"
}


function format_ghc_description () {
	local tag
	expect_args tag -- "$@"

	format_ghc_id "${tag}" || die
}


function format_ghc_archive_name () {
	local tag
	expect_args tag -- "$@"

	local ghc_id
	ghc_id=$( format_ghc_id "${tag}" ) || die

	echo "halcyon-ghc-${ghc_id}.tar.xz"
}


function hash_ghc_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" -name 'ghc*' || die
}


function copy_ghc_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	local ghc_magic_hash
	ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || die
	if [ -z "${ghc_magic_hash}" ]; then
		return 0
	fi

	mkdir -p "${HALCYON_DIR}/ghc/.halcyon-magic" || die
	cp -p "${source_dir}/.halcyon-magic/ghc"* "${HALCYON_DIR}/ghc/.halcyon-magic" || die
}


function prepare_ghc_layer () {
	expect_vars HALCYON_DIR
	expect_no_existing "${HALCYON_DIR}/ghc/lib"

	local tag
	expect_args tag -- "$@"

	local os os_description ghc_version libgmp_name libgmp_file libtinfo_file url
	os=$( get_tag_os "${tag}" ) || die
	description=$( format_os_description "${os}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die

	case "${os}-ghc-${ghc_version}" in
	'linux-ubuntu-14.04-x86_64-ghc-7.8.'*)
		libgmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.10'
		url=$( map_ghc_version_to_libgmp10_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-14.04-x86_64-ghc-7.6.'*)
		# NOTE: There is no libgmp.so.3 on Ubuntu 14.04 LTS, and there is no .10-flavoured
		# binary distribution of GHC 7.6.*. However, GHC does not use the `mpn_bdivmod`
		# function, which is the only difference between the ABI of .3 and .10. Hence, .10 is
		# symlinked to .3, and the .3-flavoured binary distribution is used.

		libgmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.3'
		url=$( map_ghc_version_to_libgmp3_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-12.04-x86_64-ghc-7.8.'*)
		libgmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.10'
		url=$( map_ghc_version_to_libgmp10_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-12.04-x86_64-ghc-7.6.'*)
		libgmp_file='/usr/lib/libgmp.so.3'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.3'
		url=$( map_ghc_version_to_libgmp3_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-10.04-x86_64-ghc-7.'[68]'.'*)
		libgmp_file='/usr/lib/libgmp.so.3'
		libtinfo_file='/lib/libncurses.so.5'
		libgmp_name='libgmp.so.3'
		url=$( map_ghc_version_to_libgmp3_x86_64_original_url "${ghc_version}" ) || die
		;;
	*)
		die "Unexpected GHC and OS combination: ${ghc_version} and ${description}"
	esac
	expect_existing "${libgmp_file}" "${libtinfo_file}"

	mkdir -p "${HALCYON_DIR}/ghc/lib" || die
	ln -s "${libtinfo_file}" "${HALCYON_DIR}/ghc/lib/libtinfo.so.5" || die
	ln -s "${libtinfo_file}" "${HALCYON_DIR}/ghc/lib/libtinfo.so" || die
	ln -s "${libgmp_file}" "${HALCYON_DIR}/ghc/lib/${libgmp_name}" || die
	ln -s "${libgmp_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die

	echo "${url}"
}


function build_ghc_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect_no_existing "${HALCYON_DIR}/ghc"

	local tag source_dir
	expect_args tag source_dir -- "$@"

	local ghc_version original_url original_name ghc_dir
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	original_url=$( prepare_ghc_layer "${tag}" ) || die
	original_name=$( basename "${original_url}" ) || die
	ghc_dir=$( get_tmp_dir 'halcyon.ghc-source' ) || die

	log 'Building GHC layer'

	if ! tar_extract "${HALCYON_CACHE_DIR}/${original_name}" "${ghc_dir}"; then
		transfer_original_file "${original_url}" || die
		if ! tar_extract "${HALCYON_CACHE_DIR}/${original_name}" "${ghc_dir}"; then
			die 'Cannot install GHC'
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${original_name}" || die
	fi

	if [ -f "${source_dir}/.halcyon-magic/ghc-build-hook" ]; then
		log 'Running GHC build hook'
		if ! ( "${source_dir}/.halcyon-magic/ghc-build-hook" "${tag}" "${source_dir}" "${ghc_dir}/ghc-${ghc-version}" |& quote ); then
			die 'Running GHC build hook failed'
		fi
	fi

	log 'Installing GHC'

	if ! (
		cd "${ghc_dir}/ghc-${ghc_version}" &&
		./configure --prefix="${HALCYON_DIR}/ghc" |& quote &&
		make install |& quote
	); then
		die 'Installing GHC failed'
	fi

	copy_ghc_magic "${source_dir}" || die
	derive_ghc_tag "${tag}" >"${HALCYON_DIR}/ghc/.halcyon-tag" || die

	local installed_size
	installed_size=$( size_tree "${HALCYON_DIR}/ghc" ) || die

	log "GHC installed (${installed_size})"
	log_indent_begin 'Stripping GHC layer...'

	strip_tree "${HALCYON_DIR}/ghc" || die

	local stripped_size
	stripped_size=$( size_tree "${HALCYON_DIR}/ghc" ) || die
	log_end "done (${stripped_size})"

	rm -rf "${ghc_dir}" || die
}


function archive_ghc_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local ghc_tag archive_name
	ghc_tag=$( detect_ghc_tag "${HALCYON_DIR}/ghc/.halcyon-tag") || die
	archive_name=$( format_ghc_archive_name "${ghc_tag}" ) || die

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" || die
	tar_archive "${HALCYON_DIR}/ghc" "${HALCYON_CACHE_DIR}/${archive_name}" || die

	local os
	os=$( get_tag_os "${ghc_tag}" ) || die
	upload_stored_file "${os}" "${archive_name}" || die
}


function validate_ghc_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local ghc_tag
	ghc_tag=$( derive_ghc_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/ghc/.halcyon-tag" "${ghc_tag//./\.}" || return 1
}


function restore_ghc_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os archive_name description
	os=$( get_tag_os "${tag}" ) || die
	archive_name=$( format_ghc_archive_name "${tag}" ) || die
	description=$( format_ghc_description "${tag}" ) || die

	if validate_ghc_layer "${tag}" >'/dev/null'; then
		log 'Using existing GHC layer:                ' "${description}"
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
		return 0
	fi
	rm -rf "${HALCYON_DIR}/ghc" || die

	log 'Restoring GHC layer'

	if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/ghc" ||
		! validate_ghc_layer "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_DIR}/ghc" || die
		if ! download_stored_file "${os}" "${archive_name}" ||
			! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/ghc" ||
			! validate_ghc_layer "${tag}" >'/dev/null'
		then
			rm -rf "${HALCYON_DIR}/ghc" || die
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
	fi

	log 'GHC layer restored:                      ' "${description}"
}


function describe_ghc_layer () {
	local tag
	expect_args tag -- "$@"

	local installed_tag description
	installed_tag=$( validate_ghc_layer "${tag}" ) || die
	description=$( format_ghc_description "${installed_tag}" ) || die

	log 'GHC layer installed:                     ' "${description}"
}


function install_ghc_layer () {
	expect_vars HALCYON_DIR HALCYON_ONLY_BUILD_APP HALCYON_FORCE_BUILD_GHC

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_BUILD_GHC )); then
		if restore_ghc_layer "${tag}"; then
			return 0
		fi

		if (( HALCYON_ONLY_BUILD_APP )); then
			log_warning 'Cannot build GHC layer'
			return 1
		fi
	fi

	rm -rf "${HALCYON_DIR}/ghc" || die
	build_ghc_layer "${tag}" "${source_dir}" || die
	archive_ghc_layer || die
	describe_ghc_layer "${tag}"
}
