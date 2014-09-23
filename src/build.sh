#!/usr/bin/env bash


function echo_build_tag () {
	expect_vars HALCYON_DIR

	local ghc_version app_label
	expect_args ghc_version app_label -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${HALCYON_DIR}\t${os}\tghc-${ghc_version}\t${app_label}"
}


function echo_build_tag_ghc_version () {
	local build_tag
	expect_args build_tag -- "$@"

	awk '{ print $3 }' <<<"${build_tag}" | sed 's/^ghc-//'
}


function echo_build_tag_app_label () {
	local build_tag
	expect_args build_tag -- "$@"

	awk '{ print $4 }' <<<"${build_tag}"
}




function echo_build_archive () {
	local build_tag
	expect_args build_tag -- "$@"

	local ghc_version app_label
	ghc_version=$( echo_build_tag_ghc_version "${build_tag}" ) || die
	app_label=$( echo_build_tag_app_label "${build_tag}" ) || die

	echo "halcyon-build-ghc-${ghc_version}-${app_label}.tar.gz"
}




function echo_tmp_build_dir () {
	mktemp -du "/tmp/halcyon-build.XXXXXXXXXX"
}


function echo_tmp_old_build_dir () {
	mktemp -du "/tmp/halcyon-build.old.XXXXXXXXXX"
}


function echo_tmp_build_dist_dir () {
	mktemp -du "/tmp/halcyon-build.dist.XXXXXXXXXX"
}




function validate_build_tag () {
	local build_tag
	expect_args build_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	if [ "${candidate_tag}" != "${build_tag}" ]; then
		return 1
	fi
}




function fake_build_dir () {
	local app_label
	expect_args app_label -- "$@"

	local build_dir
	build_dir=$( echo_tmp_build_dir ) || die

	mkdir -p "${build_dir}" || die
	echo_fake_package "${app_label}" >"${build_dir}/${app_label}.cabal" || die

	echo "${build_dir}"
}




function configure_build () {
	local build_dir
	expect_args build_dir -- "$@"

	log 'Configuring build'

	cabal_configure_app "${build_dir}" || die
}


function build () {
	local build_dir build_tag
	expect_args build_dir build_tag -- "$@"

	log 'Building'

	cabal_build_app "${build_dir}" || die

	echo "${build_tag}" >"${build_dir}/tag" || die
}




function cache_build () {
	expect_vars HALCYON_CACHE_DIR

	local build_dir build_tag
	expect_args build_dir build_tag -- "$@"
	expect "${build_dir}/dist"

	log 'Caching build'

	local build_archive os
	build_archive=$( echo_build_archive "${build_tag}" ) || die
	os=$( detect_os ) || die

	rm -f "${HALCYON_CACHE_DIR}/${build_archive}" || die
	tar_archive "${build_dir}"                      \
		"${HALCYON_CACHE_DIR}/${build_archive}" \
		--exclude '.halcyon'                    \
		--exclude '.ghc'                        \
		--exclude '.cabal'                      \
		--exclude '.cabal-sandbox'              \
		--exclude 'cabal.sandbox.config' || die
	upload_prepared "${HALCYON_CACHE_DIR}/${build_archive}" "${os}" || die
}


function restore_build () {
	expect_vars HALCYON_CACHE_DIR

	local build_dir build_tag
	expect_args build_dir build_tag -- "$@"
	expect "${build_dir}"
	expect_no "${build_dir}/dist"

	log 'Restoring build'

	local os build_archive tmp_old_dir tmp_dist_dir
	os=$( detect_os ) || die
	build_archive=$( echo_build_archive "${build_tag}" ) || die
	tmp_old_dir=$( echo_tmp_old_build_dir ) || die
	tmp_dist_dir=$( echo_tmp_build_dist_dir ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${build_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${build_archive}" "${tmp_old_dir}" ||
		! [ -f "${tmp_old_dir}/tag" ] ||
		! validate_build_tag "${build_tag}" <"${tmp_old_dir}/tag"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${build_archive}" "${tmp_old_dir}" || die

		if ! download_prepared "${os}" "${build_archive}" "${HALCYON_CACHE_DIR}"; then
			log_warning 'Build is not prepared'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${build_archive}" "${tmp_old_dir}" ||
			! [ -f "${tmp_old_dir}/tag" ] ||
			! validate_build_tag "${build_tag}" <"${tmp_old_dir}/tag"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${build_archive}" "${tmp_old_dir}" || die
			log_warning 'Restoring build failed'
			return 1
		fi
	fi

	log 'Examining build changes'

	mv "${tmp_old_dir}/dist" "${tmp_dist_dir}" || die

	local build_changes path
	build_changes=$(
		compare_recursively "${tmp_old_dir}" "${build_dir}" |
		filter_not_matching '^. (\.halcyon/|tag$)'
	) || die
	filter_matching '^= ' <<<"${build_changes}" |
		sed 's/^= //' |
		while read -r path; do
			cp -p "${tmp_old_dir}/${path}" "${build_dir}/${path}" || die
		done
	filter_not_matching '^= ' <<<"${build_changes}" | log_file_indent || die

	mv "${tmp_dist_dir}" "${build_dir}/dist" || die
	rm -rf "${tmp_old_dir}" || die
}




function infer_build_tag () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local build_dir
	expect_args build_dir -- "$@"

	local ghc_tag app_label
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	app_label=$( detect_app_label "${build_dir}" ) || die

	echo_build_tag "${ghc_version}" "${app_label}" || die
}
