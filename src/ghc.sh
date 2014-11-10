get_default_ghc_version () {
	echo '7.8.3'
}


map_ghc_version_to_linux_libgmp10_x86_64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.3')	echo 'http://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.2')	echo 'http://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.1')	echo 'http://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-unknown-linux-deb7.tar.xz';;
	*)		die "Unexpected GHC version for Linux/libgmp.so.10 (64-bit): ${ghc_version}"
	esac
}


map_ghc_version_to_linux_libgmp3_x86_64_original_url () {
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
	*)		die "Unexpected GHC version for Linux/libgmp.so.3 (64-bit): ${ghc_version}"
	esac
}


map_ghc_version_to_osx_x86_64_original_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.3')	echo 'https://www.haskell.org/ghc/dist/7.8.3/ghc-7.8.3-x86_64-apple-darwin.tar.xz';; # 10.7+
	'7.8.2')	echo 'https://www.haskell.org/ghc/dist/7.8.2/ghc-7.8.2-x86_64-apple-darwin-mavericks.tar.xz';; # 10.9 only?
	'7.8.1')	echo 'https://www.haskell.org/ghc/dist/7.8.1/ghc-7.8.1-x86_64-apple-darwin-mavericks.tar.xz';; # 10.9 only?
	'7.6.3')	echo 'https://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.6.2')	echo 'https://www.haskell.org/ghc/dist/7.6.2/ghc-7.6.2-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.6.1')	echo 'https://www.haskell.org/ghc/dist/7.6.1/ghc-7.6.1-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.4.2')	echo 'https://www.haskell.org/ghc/dist/7.4.2/ghc-7.4.2-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.4.1')	echo 'https://www.haskell.org/ghc/dist/7.4.1/ghc-7.4.1-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.2.2')	echo 'https://www.haskell.org/ghc/dist/7.2.2/ghc-7.2.2-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	'7.2.1')	echo 'https://www.haskell.org/ghc/dist/7.2.1/ghc-7.2.1-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	'7.0.4')	echo 'https://www.haskell.org/ghc/dist/7.0.4/ghc-7.0.4-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	'7.0.3')	echo 'https://www.haskell.org/ghc/dist/7.0.3/ghc-7.0.3-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	'7.0.2')	echo 'https://www.haskell.org/ghc/dist/7.0.2/ghc-7.0.2-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	*)		die "Unexpected GHC version for OS X (64-bit): ${ghc_version}"
	esac
}


map_base_package_version_to_ghc_version () {
	local base_version
	expect_args base_version -- "$@"

	case "${base_version}" in
	'4.7.0.1')	echo '7.8.3';;
	'4.7.0.0')	echo '7.8.2';;
	'4.6.0.1')	echo '7.6.3';;
	'4.6.0.0')	echo '7.6.1';;
	'4.5.1.0')	echo '7.4.2';;
	'4.4.1.0')	echo '7.2.2';;
	'4.3.1.0')	echo '7.0.4';;
	'4.2.0.2')	echo '6.12.3';;
	'4.1.0.0')	echo '6.10.4';;
	*)		die "Unexpected base package version: ${base_version}"
	esac
}


map_constraints_to_ghc_version () {
	local constraints
	expect_args constraints -- "$@"

	local base_version
	if ! base_version=$( match_package_version 'base' <<<"${constraints}" ); then
		die 'Unexpected missing base package version'
	fi

	map_base_package_version_to_ghc_version "${base_version}" || die
}


create_ghc_tag () {
	local ghc_version ghc_magic_hash
	expect_args ghc_version ghc_magic_hash -- "$@"

	create_tag '' '' \
		'' '' \
		"${ghc_version}" "${ghc_magic_hash}" \
		'' '' '' '' \
		'' '' || die
}


detect_ghc_tag () {
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


derive_ghc_tag () {
	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	create_ghc_tag "${ghc_version}" "${ghc_magic_hash}" || die
}


format_ghc_id () {
	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	echo "${ghc_version}${ghc_magic_hash:+.${ghc_magic_hash:0:7}}"
}


format_ghc_description () {
	local tag
	expect_args tag -- "$@"

	format_ghc_id "${tag}" || die
}


format_ghc_archive_name () {
	local tag
	expect_args tag -- "$@"

	local ghc_id
	ghc_id=$( format_ghc_id "${tag}" ) || die

	echo "halcyon-ghc-${ghc_id}.tar.gz"
}


hash_ghc_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" \
		-path './ghc*' || die
}


copy_ghc_magic () {
	expect_vars HALCYON_DIR

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${HALCYON_DIR}/ghc"

	local ghc_magic_hash
	ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || die
	if [[ -z "${ghc_magic_hash}" ]]; then
		return 0
	fi

	find_tree "${source_dir}/.halcyon-magic" -type f \
		-path './ghc*' |
			while read -r file; do
				copy_file "${source_dir}/.halcyon-magic/${file}" \
					"${HALCYON_DIR}/ghc/.halcyon-magic/${file}" || die
			done || die
}


prepare_ghc_layer () {
	expect_vars HALCYON_DIR
	expect_no_existing "${HALCYON_DIR}/ghc/lib"

	local tag
	expect_args tag -- "$@"

	local platform description ghc_version
	platform=$( get_tag_platform "${tag}" ) || die
	description=$( format_platform_description "${platform}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die

	local libgmp_name libgmp_file libtinfo_file url
	case "${platform}-ghc-${ghc_version}" in
	'linux-ubuntu-14.04-x86_64-ghc-7.8.'*)
		libgmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.10'
		url=$( map_ghc_version_to_linux_libgmp10_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-14.04-x86_64-ghc-'*)
		# NOTE: There is no libgmp.so.3 on Ubuntu 14.04 LTS, and there is no .10-flavoured
		# binary distribution of GHC <7.8.*. However, GHC does not use the `mpn_bdivmod`
		# function, which is the only difference between the ABI of .3 and .10. Hence,
		# .10 is symlinked to .3, and the .3-flavoured binary distribution is used.

		libgmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.3'
		url=$( map_ghc_version_to_linux_libgmp3_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-12.04-x86_64-ghc-7.8.'*)
		libgmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.10'
		url=$( map_ghc_version_to_linux_libgmp10_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-12.04-x86_64-ghc-'*)
		libgmp_file='/usr/lib/libgmp.so.3'
		libtinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		libgmp_name='libgmp.so.3'
		url=$( map_ghc_version_to_linux_libgmp3_x86_64_original_url "${ghc_version}" ) || die
		;;
	'linux-ubuntu-10.04-x86_64-ghc-'*)
		libgmp_file='/usr/lib/libgmp.so.3'
		libtinfo_file='/lib/libncurses.so.5'
		libgmp_name='libgmp.so.3'
		url=$( map_ghc_version_to_linux_libgmp3_x86_64_original_url "${ghc_version}" ) || die
		;;
	'osx-'*'-x86_64-ghc-'*)
		# TODO: Improve cross-version compatibility.

		url=$( map_ghc_version_to_osx_x86_64_original_url "${ghc_version}" ) || die
		;;
	*)
		die "Unexpected GHC version for ${description}: ${ghc_version}"
	esac

	if [ -n "${libgmp_file:-}" ]; then
		expect_existing "${libgmp_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libgmp_file}" "${HALCYON_DIR}/ghc/lib/${libgmp_name}" || die
		ln -s "${libgmp_file}" "${HALCYON_DIR}/ghc/lib/libgmp.so" || die
	fi

	if [ -n "${libtinfo_file:-}" ]; then
		expect_existing "${libtinfo_file}"

		mkdir -p "${HALCYON_DIR}/ghc/lib" || die
		ln -s "${libtinfo_file}" "${HALCYON_DIR}/ghc/lib/libtinfo.so.5" || die
		ln -s "${libtinfo_file}" "${HALCYON_DIR}/ghc/lib/libtinfo.so" || die
	fi

	echo "${url}"
}


build_ghc_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	rm -rf "${HALCYON_DIR}/ghc" || die

	local ghc_version original_url original_name ghc_dir
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	original_url=$( prepare_ghc_layer "${tag}" ) || die
	original_name=$( basename "${original_url}" ) || die
	ghc_dir=$( get_tmp_dir 'halcyon-ghc-source' ) || die

	log 'Building GHC layer'

	if ! extract_cached_archive_over "${original_name}" "${ghc_dir}"; then
		if ! cache_original_stored_file "${original_url}"; then
			die 'Cannot download original GHC archive'
		fi
		if ! extract_cached_archive_over "${original_name}" "${ghc_dir}"; then
			die 'Cannot install GHC'
		fi
	else
		touch_cached_file "${original_name}" || die
	fi

	if [[ -f "${source_dir}/.halcyon-magic/ghc-pre-build-hook" ]]; then
		log 'Executing GHC pre-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/ghc-pre-build-hook" \
					"${tag}" "${source_dir}" \
					"${ghc_dir}/ghc-${ghc-version}" |& quote
		); then
			die 'Failed to execute GHC pre-build hook'
		fi
		log 'GHC pre-build hook executed'
	fi

	log 'Installing GHC'

	if ! (
		cd "${ghc_dir}/ghc-${ghc_version}" &&
		./configure --prefix="${HALCYON_DIR}/ghc" |& quote &&
		make install |& quote
	); then
		die 'Failed to install GHC'
	fi

	copy_ghc_magic "${source_dir}" || die

	local installed_size
	installed_size=$( get_size "${HALCYON_DIR}/ghc" ) || die

	log "GHC installed, ${installed_size}"

	if [[ -f "${source_dir}/.halcyon-magic/ghc-post-build-hook" ]]; then
		log 'Executing GHC post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/ghc-post-build-hook" \
					"${tag}" "${source_dir}" \
					"${ghc_dir}/ghc-${ghc-version}" |& quote
		); then
			die 'Failed to execute GHC post-build hook'
		fi
		log 'GHC post-build hook executed'
	fi

	if [[ -d "${HALCYON_DIR}/ghc/share/doc" ]]; then
		log_indent_begin 'Removing documentation from GHC layer...'

		rm -rf "${HALCYON_DIR}/ghc/share/doc" || die

		local trimmed_size
		trimmed_size=$( get_size "${HALCYON_DIR}/ghc" ) || die
		log_end "done, ${trimmed_size}"
	fi

	log_indent_begin 'Stripping GHC layer...'

	strip_tree "${HALCYON_DIR}/ghc" || die

	local stripped_size
	stripped_size=$( get_size "${HALCYON_DIR}/ghc" ) || die
	log_end "done, ${stripped_size}"

	derive_ghc_tag "${tag}" >"${HALCYON_DIR}/ghc/.halcyon-tag" || die

	rm -rf "${ghc_dir}" || die
}


archive_ghc_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local ghc_tag platform archive_name
	ghc_tag=$( detect_ghc_tag "${HALCYON_DIR}/ghc/.halcyon-tag") || die
	platform=$( get_tag_platform "${ghc_tag}" ) || die
	archive_name=$( format_ghc_archive_name "${ghc_tag}" ) || die

	log 'Archiving GHC layer'

	create_cached_archive "${HALCYON_DIR}/ghc" "${archive_name}" || die
	upload_cached_file "${platform}" "${archive_name}" || true
}


validate_ghc_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local ghc_tag
	ghc_tag=$( derive_ghc_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/ghc/.halcyon-tag" "${ghc_tag//./\.}" || return 1
}


restore_ghc_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local platform ghc_version archive_name description
	platform=$( get_tag_platform "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_ghc_archive_name "${tag}" ) || die
	description=$( format_ghc_description "${tag}" ) || die

	if validate_ghc_layer "${tag}" >'/dev/null'; then
		log_label 'Using existing GHC layer:' "${description}"
		touch_cached_file "${archive_name}" || die
		return 0
	fi

	log 'Restoring GHC layer'

	if ! extract_cached_archive_over "${archive_name}" "${HALCYON_DIR}/ghc" ||
		! validate_ghc_layer "${tag}" >'/dev/null'
	then
		if ! cache_stored_file "${platform}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${HALCYON_DIR}/ghc" ||
			! validate_ghc_layer "${tag}" >'/dev/null'
		then
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi

	case "${ghc_version}" in
	'7.'*)
		ghc-pkg recache || die;;
	*)
		true
	esac

	log_label 'GHC layer restored:' "${description}"
}


announce_ghc_layer () {
	local tag
	expect_args tag -- "$@"

	local installed_tag description
	installed_tag=$( validate_ghc_layer "${tag}" ) || die
	description=$( format_ghc_description "${installed_tag}" ) || die

	log_label 'GHC layer installed:' "${description}"

	export HALCYON_FORCE_BUILD_GHC=0
}


install_ghc_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD_DEPENDENCIES HALCYON_FORCE_BUILD_GHC

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_BUILD_GHC )); then
		if restore_ghc_layer "${tag}"; then
			return 0
		fi

		if (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_warning 'Cannot build GHC layer'
			return 1
		fi
	fi

	build_ghc_layer "${tag}" "${source_dir}" || die
	archive_ghc_layer || die
	announce_ghc_layer "${tag}"
}
