function make_app_tag () {
	expect_vars HALCYON_DIR

	local ghc_tag sandbox_tag app_label app_hooks_hash
	expect_args ghc_tag sandbox_tag app_label app_hooks_hash -- "$@"

	local os
	os=$( detect_os ) || die

	local ghc_os ghc_halcyon_dir ghc_version ghc_hooks_hash ghc_description
	ghc_os=$( echo_ghc_tag_os "${ghc_tag}" ) || die
	ghc_halcyon_dir=$( echo_ghc_tag_halcyon_dir "${ghc_tag}" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_hooks_hash=$( echo_ghc_tag_hooks_hash "${ghc_tag}" ) || die
	ghc_description=$( echo_ghc_description "${ghc_tag}" ) || die

	if [ "${os}" != "${ghc_os}" ]; then
		die "Unexpected OS in GHC ${ghc_description} tag: ${ghc_os}"
	fi
	if [ "${HALCYON_DIR}" != "${ghc_halcyon_dir}" ]; then
		die "Unexpected HALCYON_DIR in GHC ${ghc_description} tag: ${ghc_halcyon_dir}"
	fi

	local sandbox_os sandbox_halcyon_dir sandbox_ghc_version sandbox_ghc_hooks_hash sandbox_constraints_hash sandbox_hooks_hash sandbox_app_label sandbox_description
	sandbox_os=$( echo_sandbox_tag_os "${sandbox_tag}" ) || die
	sandbox_halcyon_dir=$( echo_sandbox_tag_halcyon_dir "${sandbox_tag}" ) || die
	sandbox_ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	sandbox_ghc_hooks_hash=$( echo_sandbox_tag_ghc_hooks_hash "${sandbox_tag}" ) || die
	sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die
	sandbox_hooks_hash=$( echo_sandbox_tag_hooks_hash "${sandbox_tag}" ) || die
	sandbox_app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	if [ "${os}" != "${sandbox_os}" ]; then
		die "Unexpected OS in sandbox ${sandbox_description} tag: ${sandbox_os}"
	fi
	if [ "${HALCYON_DIR}" != "${sandbox_halcyon_dir}" ]; then
		die "Unexpected HALCYON_DIR in sandbox ${sandbox_description} tag: ${sandbox_halcyon_dir}"
	fi
	if [ "${ghc_version}" != "${sandbox_ghc_version}" ]; then
		die "Unexpected GHC version in sandbox ${sandbox_description} tag: ${sandbox_ghc_version}"
	fi
	if [ "${ghc_hooks_hash}" != "${sandbox_ghc_hooks_hash}" ]; then
		die "Unexpected GHC hooks_hash in sandbox ${sandbox_description} tag: ${sandbox_ghc_hooks_hash}"
	fi
	if [ "${app_label}" != "${sandbox_app_label}" ]; then
		die "Unexpected app label in sandbox ${sandbox_description} tag: ${sandbox_app_label}"
	fi

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_hooks_hash}\t${sandbox_constraints_hash}\t${sandbox_hooks_hash}\t${app_label}\t${app_hooks_hash}"
}


function echo_app_tag_os () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${app_tag}"
}


function echo_app_tag_halcyon_dir () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $2 }' <<<"${app_tag}"
}


function echo_app_tag_ghc_version () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $3 }' <<<"${app_tag}" | sed 's/^ghc-//'
}


function echo_app_tag_ghc_hooks_hash () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $4 }' <<<"${app_tag}"
}


function echo_app_tag_sandbox_constraints_hash () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $5 }' <<<"${app_tag}"
}


function echo_app_tag_sandbox_hooks_hash () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $6 }' <<<"${app_tag}"
}


function echo_app_tag_label () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $7 }' <<<"${app_tag}"
}


function echo_app_tag_hooks_hash () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $8 }' <<<"${app_tag}"
}


function echo_app_id () {
	local app_tag
	expect_args app_tag -- "$@"

	local app_label app_hooks_hash
	app_label=$( echo_app_tag_label "${app_tag}" ) || die
	app_hooks_hash=$( echo_app_tag_hooks_hash "${app_tag}" ) || die

	echo "${app_label}${app_hooks_hash:+~${app_hooks_hash}}"
}


function echo_app_description () {
	local app_tag
	expect_args app_tag -- "$@"

	local app_label app_hooks_hash
	app_label=$( echo_app_tag_label "${app_tag}" ) || die
	app_hooks_hash=$( echo_app_tag_hooks_hash "${app_tag}" ) || die

	echo "${app_label}${app_hooks_hash:+~${app_hooks_hash:0:7}}"
}


function echo_app_archive () {
	local app_tag
	expect_args app_tag -- "$@"

	local ghc_id sandbox_id app_id
	ghc_id=$( echo_ghc_id "${app_tag}" ) || die
	sandbox_id=$( echo_sandbox_id "${app_tag}" ) || die
	app_id=$( echo_app_id "${app_tag}" ) || die

	echo "halcyon-app-ghc-${ghc_id}-${sandbox_id}-${app_id}.tar.gz"
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


function detect_app_package () {
	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local package_file
	if ! package_file=$(
		find_spaceless_recursively "${app_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	); then
		die 'Expected exactly one app package'
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
		die 'Expected exactly one name in app package'
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
		die 'Expected exactly one version in app package'
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
		die 'Expected exactly one executable in app package'
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


function determine_app_hooks_hash () {
	local app_dir
	expect_args app_dir -- "$@"

	log_begin 'Determining app hooks hash...'

	local app_hooks_hash
	app_hooks_hash=$( hash_hooks "${app_dir}/.halcyon-hooks/app-"* ) || die

	if [ -z "${app_hooks_hash}" ]; then
		log_end '(none)'
	else
		log_end "${app_hooks_hash:0:7}"
	fi

	echo "${app_hooks_hash}"
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


function validate_app_hooks_hash () {
	local app_hooks_hash hooks_dir
	expect_args app_hooks_hash hooks_dir -- "$@"

	local candidate_hooks_hash
	candidate_hooks_hash=$( hash_hooks "${hooks_dir}/app-"* ) || die

	if [ "${candidate_hooks_hash}" != "${app_hooks_hash}" ]; then
		return 1
	fi
}


function validate_app () {
	expect_vars HALCYON_DIR

	local app_tag tmp_old_dir
	expect_args app_tag tmp_old_dir -- "$@"

	local app_hooks_hash
	app_hooks_hash=$( echo_app_tag_hooks_hash "${app_tag}" ) || die

	if ! [ -f "${tmp_old_dir}/.halcyon-tag" ] ||
		! validate_app_tag "${app_tag}" <"${tmp_old_dir}/.halcyon-tag" ||
		! validate_app_hooks_hash "${app_hooks_hash}" "${tmp_old_dir}/.halcyon-hooks"
	then
		return 1
	fi
}


function configure_app () {
	expect_vars HALCYON_DIR

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"

	local app_description
	app_description=$( echo_app_description "${app_tag}" ) || die

	log "Configuring app ${app_description} layer"

	cabal_configure_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die
}


function build_app () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_APP
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local app_dir app_tag
	expect_args app_dir app_tag -- "$@"

	local ghc_tag sandbox_tag app_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	app_description=$( echo_app_description "${app_tag}" ) || die

	if (( ${HALCYON_FORCE_BUILD_ALL} )) || (( ${HALCYON_FORCE_BUILD_APP} )); then
		log "Building app ${app_description} layer (forced)"
	else
		log "Building app ${app_description} layer"
	fi

	if [ -f "${app_dir}/.halcyon-hooks/app-pre-build" ]; then
		log "Running app ${app_description} pre-build hook"
		( quote_quietly "${app_dir}/.halcyon-hooks/app-pre-build" "${ghc_tag}" "${sandbox_tag}" "${app_tag}" "${app_dir}" ) || die
	fi

	cabal_build_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die

	if [ -f "${app_dir}/.halcyon-hooks/app-post-build" ]; then
		log "Running app ${app_description} post-build hook"
		( quote_quietly "${app_dir}/.halcyon-hooks/app-post-build" "${ghc_tag}" "${sandbox_tag}" "${app_tag}" "${app_dir}" ) || die
	fi

	echo "${app_tag}" >"${app_dir}/.halcyon-tag" || die
}


function archive_app () {
	expect_vars HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}/.halcyon-tag" "${app_dir}/dist"

	if (( ${HALCYON_NO_ARCHIVE} )); then
		return 0
	fi

	local app_tag os app_archive
	app_tag=$( <"${app_dir}/.halcyon-tag" ) || die
	os=$( echo_app_tag_os "${app_tag}" ) || die
	app_archive=$( echo_app_archive "${app_tag}" ) || die

	rm -f "${HALCYON_CACHE_DIR}/${app_archive}" || die
	tar_archive "${app_dir}"                      \
		"${HALCYON_CACHE_DIR}/${app_archive}" \
		--exclude '.halcyon'                  \
		--exclude '.ghc'                      \
		--exclude '.cabal'                    \
		--exclude '.cabal-sandbox'            \
		--exclude 'cabal.sandbox.config' || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${app_archive}" "${os}"; then
		die 'Cannot upload app layer archive'
	fi
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

	log "Restoring app ${app_description} layer"

	local tmp_old_dir tmp_dist_dir
	tmp_old_dir=$( echo_tmp_old_app_dir ) || die
	tmp_dist_dir=$( echo_tmp_app_dist_dir ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${app_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" ||
		! validate_app "${app_tag}" "${tmp_old_dir}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" || die

		if ! download_layer "${os}" "${app_archive}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download app layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" ||
			! validate_app "${app_tag}" "${tmp_old_dir}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${tmp_old_dir}" || die
			log_warning 'Cannot extract app layer archive'
			return 1
		fi
	fi

	log "Examining app ${app_description} changes"

	mv "${tmp_old_dir}/dist" "${tmp_dist_dir}" || die

	local changes path
	changes=$(
		compare_recursively "${tmp_old_dir}" "${app_dir}" |
		filter_not_matching '^. (\.halcyon/|\.halcyon-tag$)'
	) || die
	filter_matching '^= ' <<<"${changes}" |
		sed 's/^= //' |
		while read -r path; do
			cp -p "${tmp_old_dir}/${path}" "${app_dir}/${path}" || die
		done
	filter_not_matching '^= ' <<<"${changes}" | quote || die

	if filter_matching "^[^=] Setup.hs$" <<<"${changes}" |
		match_exactly_one >'/dev/null'
	then
		export HALCYON_INTERNAL_FORCE_CONFIGURE_APP=1
	else
		export HALCYON_INTERNAL_FORCE_CONFIGURE_APP=0
	fi

	mv "${tmp_dist_dir}" "${app_dir}/dist" || die
	rm -rf "${tmp_old_dir}" || die
}


function install_app () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_APP HALCYON_NO_BUILD HALCYON_INTERNAL_FORCE_CONFIGURE_APP
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local app_dir
	expect_args app_dir -- "$@"

	local ghc_tag sandbox_tag app_label app_hooks_hash app_tag app_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	app_label=$( detect_app_label "${app_dir}" ) || die
	app_hooks_hash=$( determine_app_hooks_hash "${app_dir}/.halcyon-hooks" ) || die
	app_tag=$( make_app_tag "${ghc_tag}" "${sandbox_tag}" "${app_label}" "${app_hooks_hash}" ) || die
	app_description=$( echo_app_description "${app_tag}" ) || die

	if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
		! (( ${HALCYON_FORCE_BUILD_APP} )) &&
		restore_app "${app_dir}" "${app_tag}"
	then
		true
	fi

	! (( ${HALCYON_NO_BUILD} )) || return 1

	if (( ${HALCYON_FORCE_BUILD_ALL} )) ||
		(( ${HALCYON_FORCE_BUILD_APP} )) ||
		(( ${HALCYON_INTERNAL_FORCE_CONFIGURE_APP} ))
	then
		configure_app "${app_dir}" "${app_tag}" || die
	fi

	build_app "${app_dir}" "${app_tag}" || die
	archive_app "${app_dir}" || die

	log "Installing app ${app_description}"

	rm -rf "${HALCYON_DIR}/app"
	cabal_install_app "${HALCYON_DIR}/sandbox" "${app_dir}" || die

	if [ -f "${app_dir}/.halcyon-hooks/app-install" ]; then
		log "Running app ${app_description} install hook"
		( quote_quietly "${app_dir}/.halcyon-hooks/app-install" "${ghc_tag}" "${sandbox_tag}" "${app_tag}" "${app_dir}" ) || die
	fi

	echo "${app_tag}" >"${HALCYON_DIR}/app/.halcyon-tag" || die
}
