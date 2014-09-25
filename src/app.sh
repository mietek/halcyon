#!/usr/bin/env bash


function echo_app_tag () {
	expect_vars HALCYON_DIR

	local ghc_version app_label
	expect_args ghc_version app_label -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${HALCYON_DIR}\t${os}\tghc-${ghc_version}\t${app_label}"
}


function echo_app_tag_ghc_version () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $3 }' <<<"${app_tag}" | sed 's/^ghc-//'
}


function echo_app_tag_app_label () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $4 }' <<<"${app_tag}"
}




function echo_app_archive () {
	local app_tag
	expect_args app_tag -- "$@"

	local ghc_version app_label
	ghc_version=$( echo_app_tag_ghc_version "${app_tag}" ) || die
	app_label=$( echo_app_tag_app_label "${app_tag}" ) || die

	echo "halcyon-app-ghc-${ghc_version}-${app_label}.tar.gz"
}




function echo_tmp_app_dir () {
	mktemp -du '/tmp/halcyon-app.XXXXXXXXXX'
}


function echo_tmp_old_app_dir () {
	mktemp -du '/tmp/halcyon-app.old.XXXXXXXXXX'
}


function echo_tmp_app_dist_dir () {
	mktemp -du '/tmp/halcyon-app.dist.XXXXXXXXXX'
}




function validate_app_tag () {
	local app_tag
	expect_args app_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	if [ "${candidate_tag}" != "${app_tag}" ]; then
		return 1
	fi
}




function echo_fake_package () {
	local app_label
	expect_args app_label -- "$@"

	local app_name app_version build_depends
	if [ "${app_label}" = 'base' ]; then
		app_name='base'
		app_version=$( detect_base_version ) || die
		build_depends='base'
	else
		app_name="${app_label}"
		if ! app_version=$( cabal_list_latest_package_version "${app_label}" ); then
			app_name="${app_label%-*}"
			app_version="${app_label##*-}"
		fi
		build_depends="base, ${app_name} == ${app_version}"
	fi

	cat <<-EOF
		name:           halcyon-fake-${app_name}
		version:        ${app_version}
		build-type:     Simple
		cabal-version:  >= 1.2

		executable halcyon-fake-${app_name}
		  build-depends:  ${build_depends}
EOF
}




function fake_app_dir () {
	local app_label
	expect_args app_label -- "$@"

	local app_dir
	app_dir=$( echo_tmp_app_dir ) || die

	mkdir -p "${app_dir}" || die
	echo_fake_package "${app_label}" >"${app_dir}/${app_label}.cabal" || die

	if has_vars HALCYON_CUSTOMIZE_SANDBOX_SCRIPT; then
		expect_existing "${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT}"

		local script_name
		script_name=$( basename "${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT}" ) || die

		cp "${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT}" "${app_dir}/${script_name}" || die
		export HALCYON_CUSTOMIZE_SANDBOX_SCRIPT="${script_name}"
	fi

	echo "${app_dir}"
}




function detect_app_package () {
	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local package_file
	if ! package_file=$(
		find_spaceless "${app_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	); then
		die "Expected exactly one ${app_dir}/*.cabal"
	fi

	cat "${package_file}"
}


function detect_app_name () {
	local app_dir
	expect_args app_dir -- "$@"

	local app_name
	if ! app_name=$(
		detect_app_package "${app_dir}" |
		awk '/^ *[Nn]ame:/ { print $2 }' |
		match_exactly_one
	); then
		die 'Expected exactly one app name'
	fi

	echo "${app_name}"
}


function detect_app_version () {
	local app_dir
	expect_args app_dir -- "$@"

	local app_version
	if ! app_version=$(
		detect_app_package "${app_dir}" |
		awk '/^ *[Vv]ersion:/ { print $2 }' |
		match_exactly_one
	); then
		die 'Expected exactly one app version'
	fi

	echo "${app_version}"
}


function detect_app_executable () {
	local app_dir
	expect_args app_dir -- "$@"

	local app_executable
	if ! app_executable=$(
		detect_app_package "${app_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		match_exactly_one
	); then
		die 'Expected exactly one app executable'
	fi

	echo "${app_executable}"
}




function detect_app_label () {
	local app_dir
	expect_args app_dir -- "$@"

	local app_name app_version
	app_name=$( detect_app_name "${app_dir}" | sed 's/^halcyon-fake-//' ) || die
	app_version=$( detect_app_version "${app_dir}" ) || die

	echo "${app_name}-${app_version}"
}




function configure_app () {
	expect_vars HALCYON_DIR

	local app_dir
	expect_args app_dir -- "$@"

	log 'Configuring app'

	cabal_configure_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die
}


function build_app () {
	expect_vars HALCYON_DIR

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"

	log 'Building app'

	cabal_build_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die

	echo "${app_tag}" >"${app_dir}/tag" || die
}




function archive_app () {
	expect_vars HALCYON_CACHE_DIR

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"
	expect_existing "${app_dir}/dist"

	log 'Archiving app'

	local app_archive os
	app_archive=$( echo_app_archive "${app_tag}" ) || die
	os=$( detect_os ) || die

	rm -f "${HALCYON_CACHE_DIR}/${app_archive}" || die
	tar_archive "${app_dir}"                      \
		"${HALCYON_CACHE_DIR}/${app_archive}" \
		--exclude '.halcyon'                  \
		--exclude '.ghc'                      \
		--exclude '.cabal'                    \
		--exclude '.cabal-sandbox'            \
		--exclude 'cabal.sandbox.config' || die
	upload_prebuilt "${HALCYON_CACHE_DIR}/${app_archive}" "${os}" || die
}


function restore_app () {
	expect_vars HALCYON_CACHE_DIR

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"
	expect_existing "${app_dir}"
	expect_no_existing "${app_dir}/dist"

	log 'Restoring app'

	local os app_archive tmp_old_dir tmp_dist_dir
	os=$( detect_os ) || die
	app_archive=$( echo_app_archive "${app_tag}" ) || die
	tmp_old_dir=$( echo_tmp_old_app_dir ) || die
	tmp_dist_dir=$( echo_tmp_app_dist_dir ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${app_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" ||
		! [ -f "${tmp_old_dir}/tag" ] ||
		! validate_app_tag "${app_tag}" <"${tmp_old_dir}/tag"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" || die

		if ! download_prebuilt "${os}" "${app_archive}" "${HALCYON_CACHE_DIR}"; then
			log_warning 'App is not prebuilt'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" ||
			! [ -f "${tmp_old_dir}/tag" ] ||
			! validate_app_tag "${app_tag}" <"${tmp_old_dir}/tag"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" || die
			log_warning 'Restoring app failed'
			return 1
		fi
	fi

	log 'Examining app changes'

	mv "${tmp_old_dir}/dist" "${tmp_dist_dir}" || die

	local app_changes path
	app_changes=$(
		compare_recursively "${tmp_old_dir}" "${app_dir}" |
		filter_not_matching '^. (\.halcyon/|tag$)'
	) || die
	filter_matching '^= ' <<<"${app_changes}" |
		sed 's/^= //' |
		while read -r path; do
			cp -p "${tmp_old_dir}/${path}" "${app_dir}/${path}" || die
		done
	filter_not_matching '^= ' <<<"${app_changes}" | log_file_indent || die

	mv "${tmp_dist_dir}" "${app_dir}/dist" || die
	rm -rf "${tmp_old_dir}" || die
}




function infer_app_tag () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/tag"

	local app_dir
	expect_args app_dir -- "$@"

	local ghc_tag app_label
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	app_label=$( detect_app_label "${app_dir}" ) || die

	echo_app_tag "${ghc_version}" "${app_label}" || die
}




function install_app () {
	local app_dir
	expect_args app_dir -- "$@"

	local app_tag
	app_tag=$( infer_app_tag "${app_dir}" ) || die

	if ! restore_app "${app_dir}" "${app_tag}"; then
		configure_app "${app_dir}" || die
	fi

	build_app "${app_dir}" "${app_tag}" || die
	archive_app "${app_dir}" "${app_tag}" || die
}
