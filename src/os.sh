install_pigz () {
	expect_vars HALCYON_BASE HALCYON_CACHE

	local tag
	expect_args tag -- "$@"

	if which 'pigz' &>'/dev/null'; then
		return 0
	fi

	local platform description
	platform=$( get_tag_platform "${tag}" ) || die
	description=$( format_platform_description "${platform}" ) || die

	local original_url
	case "${platform}" in
	'linux-ubuntu-14.10-x86_64')
		original_url='https://mirrors.kernel.org/ubuntu/pool/universe/p/pigz/pigz_2.3.1-1_amd64.deb';;
	'linux-ubuntu-14.04-x86_64')
		original_url='https://mirrors.kernel.org/ubuntu/pool/universe/p/pigz/pigz_2.3-2_amd64.deb';;
	'linux-ubuntu-12.04-x86_64')
		original_url='https://mirrors.kernel.org/ubuntu/pool/universe/p/pigz/pigz_2.1.6-1_amd64.deb';;
	'linux-ubuntu-10.04-x86_64')
		original_url='https://mirrors.kernel.org/ubuntu/pool/universe/p/pigz/pigz_2.1.5-1_amd64.deb';;
	*)
		log_warning "Cannot install pigz on ${description}"
		return 0
	esac

	log 'Installing pigz'

	local original_name dpkg_dir
	original_name=$( basename "${original_url}" ) || die
	dpkg_dir=$( get_tmp_dir 'halcyon-dpkg' ) || die

	if [[ ! -f "${HALCYON_CACHE}/${original_name}" ]] ||
		! dpkg --extract "${HALCYON_CACHE}/${original_name}" "${dpkg_dir}" |& quote
	then
		rm -rf "${dpkg_dir}" || die
		if ! cache_original_stored_file "${original_url}" ||
			! dpkg --extract "${HALCYON_CACHE}/${original_name}" "${dpkg_dir}" |& quote
		then
			log_warning 'Cannot install pigz'
			return 0
		fi
	else
		touch_cached_file "${original_name}" || die
	fi

	copy_file "${dpkg_dir}/usr/bin/pigz" "${HALCYON_BASE}/bin/pigz" || die

	rm -rf "${dpkg_dir}" || die
}


install_linux_ubuntu_packages () {
	local package_names dst_dir
	expect_args package_names dst_dir -- "$@"

	local -a names
	names=( ${package_names} )
	if [[ -z "${names[@]:+_}" ]]; then
		return 0
	fi

	local apt_dir dpkg_dir
	apt_dir=$( get_tmp_dir 'halcyon-apt' ) || die
	dpkg_dir=$( get_tmp_dir 'halcyon-dpkg' ) || die

	local -a opts
	opts+=( -o debug::nolocking='true' )
	opts+=( -o dir::cache="${apt_dir}/cache" )
	opts+=( -o dir::state="${apt_dir}/state" )

	mkdir -p "${apt_dir}/cache/archives/partial" "${apt_dir}/state/lists/partial" || die

	log 'Updating OS package database'

	if ! apt-get "${opts[@]}" update --quiet --quiet |& quote; then
		die 'Failed to update OS package database'
	fi

	local name
	for name in "${names[@]}"; do
		apt-get "${opts[@]}" install --download-only --reinstall --yes "${name}" |& quote || die
	done

	local file
	find_tree "${apt_dir}/cache/archives" -type f -name '*.deb' |
		while read -r file; do
			dpkg --extract "${apt_dir}/cache/archives/${file}" "${dpkg_dir}" |& quote || die
		done

	# TODO: Is this really the best way?

	if [[ -d "${dpkg_dir}/usr/include/x86_64-linux-gnu" ]] ; then
		copy_dir_into "${dpkg_dir}/usr/include/x86_64-linux-gnu" "${dst_dir}/usr/include" || die
	fi
	if [[ -d "${dpkg_dir}/usr/lib/x86_64-linux-gnu" ]]; then
		copy_dir_into "${dpkg_dir}/usr/lib/x86_64-linux-gnu" "${dst_dir}/usr/lib" || die
	fi

	rm -rf "${dpkg_dir}/usr/include/x86_64-linux-gnu" "${dpkg_dir}/usr/lib/x86_64-linux-gnu" || die

	copy_dir_into "${dpkg_dir}" "${dst_dir}" || die

	rm -rf "${dpkg_dir}" || die
}


install_os_packages () {
	local tag package_specs dst_dir
	expect_args tag package_specs dst_dir -- "$@"

	local platform description
	platform=$( get_tag_platform "${tag}" ) || die
	description=$( format_platform_description "${platform}" ) || die

	local -a specs
	specs=( ${package_specs} )
	if [[ -z "${specs[@]:+_}" ]]; then
		return 0
	fi

	local -a names
	local spec
	for spec in "${specs[@]}"; do
		local pattern name
		pattern="${spec%:*}"
		name="${spec#*:}"
		if [[ "${pattern}" == "${name}" || "${platform}" =~ ${pattern} ]]; then
			names+=( "${name}" )
		fi
	done

	case "${platform}" in
	'linux-ubuntu-'*)
		install_linux_ubuntu_packages "${names[*]:-}" "${dst_dir}" || die
		;;
	*)
		log_error "Cannot install OS packages on ${description}"
		return 1
	esac
}
