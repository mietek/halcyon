function derive_app_tag () {
	expect_vars HALCYON_DIR

	local ghc_tag sandbox_tag app_label app_hook
	expect_args ghc_tag sandbox_tag app_label app_hook -- "$@"

	local os
	os=$( detect_os ) || die

	local ghc_os ghc_halcyon_dir ghc_version ghc_hook
	ghc_os=$( echo_ghc_tag_os "${ghc_tag}" ) || die
	ghc_halcyon_dir=$( echo_ghc_tag_halcyon_dir "${ghc_tag}" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_hook=$( echo_ghc_tag_hook "${ghc_tag}" ) || die

	if [ "${os}" != "${ghc_os}" ]; then
		die "Unexpected OS in GHC tag: ${ghc_os}"
	fi
	if [ "${HALCYON_DIR}" != "${ghc_halcyon_dir}" ]; then
		die "Unexpected HALCYON_DIR in GHC tag: ${ghc_halcyon_dir}"
	fi

	local sandbox_os sandbox_halcyon_dir sandbox_ghc_version sandbox_ghc_hook sandbox_app_label sandbox_digest sandbox_hook
	sandbox_os=$( echo_sandbox_tag_os "${sandbox_tag}" ) || die
	sandbox_halcyon_dir=$( echo_sandbox_tag_halcyon_dir "${sandbox_tag}" ) || die
	sandbox_ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	sandbox_ghc_hook=$( echo_sandbox_tag_ghc_hook "${sandbox_tag}" ) || die
	sandbox_app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die
	sandbox_hook=$( echo_sandbox_tag_hook "${sandbox_tag}" ) || die

	if [ "${os}" != "${sandbox_os}" ]; then
		die "Unexpected OS in sandbox tag: ${sandbox_os}"
	fi
	if [ "${HALCYON_DIR}" != "${sandbox_halcyon_dir}" ]; then
		die "Unexpected HALCYON_DIR in sandbox tag: ${sandbox_halcyon_dir}"
	fi
	if [ "${ghc_version}" != "${sandbox_ghc_version}" ]; then
		die "Unexpected GHC version in sandbox tag: ${sandbox_ghc_version}"
	fi
	if [ "${ghc_hook}" != "${sandbox_ghc_hook}" ]; then
		die "Unexpected GHC hook in sandbox tag: ${sandbox_ghc_hook}"
	fi
	if [ "${app_label}" != "${sandbox_app_label}" ]; then
		die "Unexpected app label in sandbox tag: ${sandbox_app_label}"
	fi

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_hook}\t${sandbox_digest}\t${sandbox_hook}\t${app_label}\t${app_hook}"
}


function echo_app_tag_os () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $1 }' <<<"${app_tag}"
}


function echo_app_tag_halcyon_dir () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $2 }' <<<"${app_tag}"
}


function echo_app_tag_ghc_version () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $3 }' <<<"${app_tag}" | sed 's/^ghc-//'
}


function echo_app_tag_ghc_hook () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $4 }' <<<"${app_tag}"
}


function echo_app_tag_sandbox_digest () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $5 }' <<<"${app_tag}"
}


function echo_app_tag_sandbox_hook () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $6 }' <<<"${app_tag}"
}


function echo_app_tag_label () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $7 }' <<<"${app_tag}"
}


function echo_app_tag_hook () {
	local app_tag
	expect_args app_tag -- "$@"

	awk '{ print $8 }' <<<"${app_tag}"
}


function echo_app_description () {
	local app_tag
	expect_args app_tag -- "$@"

	local app_label app_hook
	app_label=$( echo_app_tag_label "${app_tag}" ) || die
	app_hook=$( echo_app_tag_hook "${app_tag}" ) || die

	echo "app ${app_label}${app_hook:+~${app_hook:0:7}}"
}


function echo_app_archive () {
	local app_tag
	expect_args app_tag -- "$@"

	local ghc_version ghc_hook sandbox_digest sandbox_hook app_label app_hook
	ghc_version=$( echo_app_tag_ghc_version "${app_tag}" ) || die
	ghc_hook=$( echo_app_tag_ghc_hook "${app_tag}" ) || die
	sandbox_digest=$( echo_app_tag_digest "${app_tag}" ) || die
	sandbox_hook=$( echo_app_tag_hook "${app_tag}" ) || die
	app_label=$( echo_app_tag_app_label "${app_tag}" ) || die
	app_hook=$( echo_app_tag_app_hook "${app_tag}" ) || die

	echo "halcyon-app-ghc-${ghc_version}${ghc_hook:+~${ghc_hook:0:7}}-${sandbox_digest:0:7}${sandbox_hook:+~${sandbox_hook:0:7}}-${app_label}${app_hook:+~${app_hook:0:7}}.tar.gz"
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


function echo_fake_app_package () {
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
	echo_fake_app_package "${app_label}" >"${app_dir}/${app_label}.cabal" || die

	if [ -d '.halcyon-hooks' ]; then
		cp -R '.halcyon-hooks' "${app_dir}"
	fi

	echo "${app_dir}"
}


function detect_app_package () {
	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local package_file
	if ! package_file=$(
		find_spaceless_recursively "${app_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	); then
		die "Expected exactly one ${app_dir}/*.cabal"
	fi

	cat "${app_dir}/${package_file}"
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


function detect_app_hook () {
	local app_dir
	expect_args app_dir -- "$@"

	echo_digest "${app_dir}/.halcyon-hooks/"*'-app-'*
}


function configure_app () {
	expect_vars HALCYON_DIR

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"

	local app_description
	app_description=$( echo_app_description "${app_tag}" ) || die

	log "Configuring ${app_description}"

	cabal_configure_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die
}


function build_app () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"

	local ghc_tag sandbox_tag app_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	app_description=$( echo_app_description "${app_tag}" ) || die

	log "Building ${app_description}"

	if [ -f "${app_dir}/.halcyon-hooks/app-pre-build" ]; then
		log "Running app pre-build hook"
		"${app_dir}/.halcyon-hooks/app-pre-build" "${ghc_tag}" "${sandbox_tag}" "${app_tag}" "${app_dir}" || die
	fi

	cabal_build_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die

	echo "${app_tag}" >"${app_dir}/.halcyon-tag" || die

	if [ -f "${app_dir}/.halcyon-hooks/app-post-build" ]; then
		log "Running app post-build hook"
		"${app_dir}/.halcyon-hooks/app-post-build" "${ghc_tag}" "${sandbox_tag}" "${app_tag}" "${app_dir}" || die
	fi
}


function archive_app () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}/.halcyon-tag" "${app_dir}/dist"

	if (( ${HALCYON_NO_ARCHIVE} )); then
		return 0
	fi

	local app_tag os app_archive app_description
	app_tag=$( <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	os=$( echo_app_tag_os "${app_tag}" ) || die
	app_archive=$( echo_app_archive "${app_tag}" ) || die
	app_description=$( echo_app_description "${app_tag}" ) || die

	log "Archiving ${app_description}"

	rm -f "${HALCYON_CACHE_DIR}/${app_archive}" || die
	tar_archive "${app_dir}"                      \
		"${HALCYON_CACHE_DIR}/${app_archive}" \
		--exclude '.halcyon'                  \
		--exclude '.ghc'                      \
		--exclude '.cabal'                    \
		--exclude '.cabal-sandbox'            \
		--exclude 'cabal.sandbox.config' || die
	upload_layer "${HALCYON_CACHE_DIR}/${app_archive}" "${os}" || die
}


function restore_app () {
	expect_vars HALCYON_CACHE_DIR

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"
	expect_existing "${app_dir}"
	expect_no_existing "${app_dir}/.halcyon-tag" "${app_dir}/dist"

	local os app_archive app_description
	os=$( echo_app_tag_os "${app_tag}" ) || die
	app_archive=$( echo_app_archive "${app_tag}" ) || die
	app_description=$( echo_app_description "${app_tag}" ) || die

	log "Restoring ${app_description}"

	local tmp_old_dir tmp_dist_dir
	tmp_old_dir=$( echo_tmp_old_app_dir ) || die
	tmp_dist_dir=$( echo_tmp_app_dist_dir ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${app_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" ||
		! [ -f "${tmp_old_dir}/.halcyon-tag" ] ||
		! validate_app_tag "${app_tag}" <"${tmp_old_dir}/.halcyon-tag"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" || die

		if ! download_layer "${os}" "${app_archive}" "${HALCYON_CACHE_DIR}"; then
			log "Downloading ${app_archive} failed"
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" ||
			! [ -f "${tmp_old_dir}/.halcyon-tag" ] ||
			! validate_app_tag "${app_tag}" <"${tmp_old_dir}/.halcyon-tag"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" || die
			log_warning "Restoring ${app_archive} failed"
			return 1
		fi
	fi

	log 'Examining source changes'

	mv "${tmp_old_dir}/dist" "${tmp_dist_dir}" || die

	local source_changes path
	source_changes=$(
		compare_recursively "${tmp_old_dir}" "${app_dir}" |
		filter_not_matching '^. (\.halcyon/|\.halcyon-tag$)'
	) || die
	filter_matching '^= ' <<<"${source_changes}" |
		sed 's/^= //' |
		while read -r path; do
			cp -p "${tmp_old_dir}/${path}" "${app_dir}/${path}" || die
		done
	filter_not_matching '^= ' <<<"${source_changes}" | quote || die

	local force_configure
	force_configure=0
	if filter_matching "^[^=] Setup.hs$" <<<"${source_changes}" |
		match_exactly_one >'/dev/null'
	then
		force_configure=1
	fi

	mv "${tmp_dist_dir}" "${app_dir}/dist" || die
	rm -rf "${tmp_old_dir}" || die

	return "${force_configure}"
}


function install_app () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_APP HALCYON_NO_BUILD
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local app_dir
	expect_args app_dir -- "$@"

	local ghc_tag sandbox_tag app_label app_hook app_tag
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	app_label=$( detect_app_label "${app_dir}" ) || die
	app_hook=$( detect_app_hook "${app_dir}" ) || die
	app_tag=$( derive_app_tag "${ghc_tag}" "${sandbox_tag}" "${app_label}" "${app_hook}" ) || die

	! (( ${HALCYON_NO_BUILD} )) || return 1

	if (( ${HALCYON_FORCE_BUILD_ALL} )) ||
		(( ${HALCYON_FORCE_BUILD_APP} )) ||
		! restore_app "${app_dir}" "${app_tag}"
	then
		configure_app "${app_dir}" "${app_tag}" || die
	fi

	build_app "${app_dir}" "${app_tag}" || die
	archive_app "${app_dir}" || die
}
