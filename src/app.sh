function echo_app_tag () {
	expect_vars HALCYON_DIR

	local ghc_tag sandbox_tag app_label app_magic_hash sources_hash slug_dir
	expect_args ghc_tag sandbox_tag app_label app_magic_hash sources_hash slug_dir -- "$@"

	local os ghc_version ghc_magic_hash constraints_hash sandbox_magic_hash
	os=$( detect_os ) || die
	ghc_version=$( echo_ghc_version "${ghc_tag}" ) || die
	ghc_magic_hash=$( echo_ghc_magic_hash "${ghc_tag}" ) || die
	constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_magic_hash}\t${constraints_hash}\t${sandbox_magic_hash}\t${app_label}\t${app_magic_hash}\t${sources_hash}\t${slug_dir}"
}


function echo_valid_app_tag_pattern () {
	expect_vars HALCYON_DIR

	local app_tag
	expect_args app_tag -- "$@"

	echo -e "${app_tag%$'\t'*$'\t'*}"$'\t'".*"$'\t'".*"
}


function echo_app_os () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${app_tag}"
}


function echo_app_label () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $7 }' <<<"${app_tag}"
}


function echo_app_magic_hash () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $8 }' <<<"${app_tag}"
}


function echo_app_sources_hash () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $9 }' <<<"${app_tag}"
}


function echo_app_slug_dir () {
	local app_tag
	expect_args app_tag -- "$@"

	awk -F$'\t' '{ print $10 }' <<<"${app_tag}"
}


function echo_app_id () {
	local app_tag
	expect_args app_tag -- "$@"

	local app_label magic_hash
	app_label=$( echo_app_label "${app_tag}" ) || die
	magic_hash=$( echo_app_magic_hash "${app_tag}" ) || die

	echo "${app_label}${magic_hash:+~${magic_hash:0:7}}"
}


function echo_app_description () {
	local app_tag
	expect_args app_tag -- "$@"

	local app_id
	app_id=$( echo_app_id "${app_tag}" ) || die

	echo "${app_id}"
}


function echo_app_archive_name () {
	local app_tag
	expect_args app_tag -- "$@"

	local ghc_id sandbox_id app_id
	ghc_id=$( echo_ghc_id "${app_tag}" ) || die
	sandbox_id=$( echo_sandbox_id "${app_tag}" ) || die
	app_id=$( echo_app_id "${app_tag}" ) || die

	echo "halcyon-app-ghc-${ghc_id}-${sandbox_id}-${app_id}.tar.gz"
}


function detect_app_package_description () {
	local sources_dir
	expect_args sources_dir -- "$@"
	expect_existing "${sources_dir}"

	local package_file
	if ! package_file=$(
		find_spaceless_recursively "${sources_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	); then
		die 'Expected exactly one app package description'
	fi

	cat "${sources_dir}/${package_file}"
}


function detect_app_name () {
	local sources_dir
	expect_args sources_dir -- "$@"

	local app_name
	if ! app_name=$(
		detect_app_package_description "${sources_dir}" |
		awk '/^ *[Nn]ame:/ { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	); then
		die 'Expected exactly one name in app package description'
	fi

	echo "${app_name}"
}


function detect_app_version () {
	local sources_dir
	expect_args sources_dir -- "$@"

	local app_version
	if ! app_version=$(
		detect_app_package_description "${sources_dir}" |
		awk '/^ *[Vv]ersion:/ { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	); then
		die 'Expected exactly one version in app package description'
	fi

	echo "${app_version}"
}


function detect_app_executable () {
	local sources_dir
	expect_args sources_dir -- "$@"

	local app_executable
	if ! app_executable=$(
		detect_app_package_description "${sources_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	); then
		die 'Expected exactly one executable in app package description'
	fi

	echo "${app_executable}"
}


function detect_app_label () {
	local sources_dir
	expect_args sources_dir -- "$@"

	local app_name app_version
	app_name=$( detect_app_name "${sources_dir}" | sed 's/^halcyon-fake-//' ) || die
	app_version=$( detect_app_version "${sources_dir}" ) || die

	echo "${app_name}-${app_version}"
}


function hash_app_magic () {
	local app_dir
	expect_args app_dir -- "$@"

	hash_spaceless_recursively          \
		"${app_dir}/.halcyon-magic" \
		\(                          \
		-name 'helper-apps' -or     \
		-name 'helper-hook' -or     \
		-name 'build-tools' -or     \
		-name 'app*'                \
		\) || die
}


function partially_validate_app_tag () {
	expect_vars HALCYON_DIR

	local app_tag
	expect_args app_tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/app/.halcyon-tag" ]; then
		return 1
	fi

	local valid_pattern
	valid_pattern=$( echo_valid_app_tag_pattern "${app_tag}" ) || die
	if ! filter_matching "^${valid_pattern}$" <"${HALCYON_DIR}/app/.halcyon-tag" |
		match_exactly_one >'/dev/null'
	then
		return 1
	fi
}


function fully_validate_app_tag () {
	expect_vars HALCYON_DIR

	local app_tag
	expect_args app_tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/app/.halcyon-tag" ]; then
		return 1
	fi

	local candidate_tag
	candidate_tag=$( match_exactly_one <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	if [ "${candidate_tag}" != "${app_tag}" ]; then
		return 1
	fi
}


function validate_app_tag_slug_dir () {
	expect_vars HALCYON_DIR

	local app_tag
	expect_args app_tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/app/.halcyon-tag" ]; then
		return 1
	fi

	local slug_dir candidate_tag candidate_dir
	slug_dir=$( echo_app_slug_dir "${app_tag}" ) || die
	candidate_tag=$( match_exactly_one <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	candidate_dir=$( echo_app_slug_dir "${candidate_tag}" ) || die
	if [ "${candidate_dir}" != "${slug_dir}" ]; then
		return 1
	fi
}


function build_app () {
	expect_vars HALCYON_DIR

	local app_tag must_copy must_configure sources_dir
	expect_args app_tag must_copy must_configure sources_dir -- "$@"
	if (( must_copy )); then
		expect_no_existing "${HALCYON_DIR}/app"
	else
		expect_existing "${HALCYON_DIR}/app/.halcyon-tag"
	fi
	expect_existing "${sources_dir}"

	local slug_dir
	slug_dir=$( echo_app_slug_dir "${app_tag}" ) || die

	log 'Starting to build app layer'

	if (( must_copy )); then
		log 'Copying app'

		copy_entire_contents "${sources_dir}" "${HALCYON_DIR}/app" || die
	fi

	if (( must_copy )) || (( must_configure )); then
		log 'Configuring app'

		cabal_configure_app "${HALCYON_DIR}/sandbox" "${HALCYON_DIR}/app" --prefix="${slug_dir}" || die
	fi

	if [ -f "${sources_dir}/.halcyon-magic/app-prebuild-hook" ]; then
		log 'Running app pre-build hook'
		( "${sources_dir}/.halcyon-magic/app-prebuild-hook" "${app_tag}" ) |& quote || die
	fi

	log 'Building app'

	cabal_build_app "${HALCYON_DIR}/sandbox" "${HALCYON_DIR}/app" || die

	if [ -f "${sources_dir}/.halcyon-magic/app-postbuild-hook" ]; then
		log 'Running app post-build hook'
		( "${sources_dir}/.halcyon-magic/app-postbuild-hook" "${app_tag}" ) |& quote || die
	fi

	echo "${app_tag}" >"${HALCYON_DIR}/app/.halcyon-tag" || die

	log 'Finished building app layer'
}


function archive_app () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local app_tag os app_archive
	app_tag=$( <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	os=$( echo_app_os "${app_tag}" ) || die
	app_archive=$( echo_app_archive_name "${app_tag}" ) || die

	log 'Archiving app layer'

	rm -f "${HALCYON_CACHE_DIR}/${app_archive}" || die
	tar_archive "${HALCYON_DIR}/app"              \
		"${HALCYON_CACHE_DIR}/${app_archive}" \
		--exclude '.halcyon'                  \
		--exclude '.haskell-on-heroku'        \
		--exclude '.ghc'                      \
		--exclude '.cabal'                    \
		--exclude '.cabal-sandbox'            \
		--exclude 'cabal.sandbox.config' || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${app_archive}" "${os}"; then
		log_warning 'Cannot upload app layer archive'
	fi
}


function restore_app () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local app_tag
	expect_args app_tag -- "$@"

	local os app_archive
	os=$( echo_app_os "${app_tag}" ) || die
	app_archive=$( echo_app_archive_name "${app_tag}" ) || die

	if partially_validate_app_tag "${app_tag}"; then
		touch -c "${HALCYON_CACHE_DIR}/${app_archive}" || true
		log 'Using existing app layer'
		return 0
	fi
	rm -rf "${HALCYON_DIR}/app" || die

	log 'Restoring app layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${app_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${HALCYON_DIR}/app" ||
		! partially_validate_app_tag "${app_tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${HALCYON_DIR}/app" || die
		if ! download_layer "${os}" "${app_archive}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download app layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${app_archive}" "${HALCYON_DIR}/app" ||
			! partially_validate_app_tag "${app_tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${app_archive}" "${HALCYON_DIR}/app" || die
			log_warning 'Cannot extract app layer archive'
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${app_archive}" || true
	fi
}


function determine_app_tag () {
	expect_vars HALCYON_DIR HALCYON_AS_BUILD_TOOL

	local sources_dir
	expect_args sources_dir -- "$@"

	log_begin 'Determining app label...                 '

	local app_label
	app_label=$( detect_app_label "${sources_dir}" ) || die
	log_end "${app_label}"

	log_begin 'Determining app magic hash...            '

	local magic_hash
	magic_hash=$( hash_app_magic "${sources_dir}" ) || die
	if [ -z "${magic_hash}" ]; then
		log_end '(none)'
	else
		log_end "${magic_hash:0:7}"
	fi

	log_begin 'Determining app sources hash...          '

	local sources_hash
	sources_hash=$( hash_spaceless_recursively "${sources_dir}" ) || die
	if [ -z "${sources_hash}" ]; then
		log_end '(none)'
		die 'Cannot install app layer'
	fi
	log_end "${sources_hash:0:7}"

	log_begin 'Determining app slug directory...        '
	local slug_dir
	if (( HALCYON_AS_BUILD_TOOL )); then
		slug_dir="${HALCYON_DIR}/sandbox"
	else
		slug_dir="${HALCYON_DIR}/slug"
	fi
	log_end "${slug_dir}"

	local ghc_tag sandbox_tag app_tag
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die

	echo_app_tag "${ghc_tag}" "${sandbox_tag}" "${app_label}" "${magic_hash}" "${sources_hash}" "${slug_dir}" || die
}


function activate_app () {
	expect_vars HALCYON_DIR HALCYON_TMP_SLUG_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local app_tag app_description
	app_tag=$( <"${HALCYON_DIR}/app/.halcyon-tag" ) || die
	app_description=$( echo_app_description "${app_tag}" ) || die

	# NOTE: Cabal emits a spurious warning  about HALCYON_TMP_SLUG_DIR/.../bin not being in PATH,
	# hence the decreased verbosity.

	log 'Populating app slug directory'
	cabal_copy_app "${HALCYON_DIR}/sandbox" "${HALCYON_DIR}/app" --destdir="${HALCYON_TMP_SLUG_DIR}" --verbose=0 || die

	log 'App layer installed:'
	log_indent "${app_description}"
}


function prepare_app_files () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/app/.halcyon-tag"

	local sources_dir
	expect_args sources_dir -- "$@"

	local prepare_dir
	prepare_dir=$( echo_tmp_dir_name 'halcyon.prepare_app_files' ) || die

	log 'Examining app changes'

	local files
	if ! files=$(
		compare_recursively "${HALCYON_DIR}/app" "${sources_dir}" |
		filter_not_matching '^. (\.halcyon/|\.haskell-on-heroku/|\.ghc/|\.cabal/|\.cabal-sandbox/|cabal.sandbox.config$)' |
		filter_not_matching '^. (\.halcyon-tag$|dist/)' |
		match_at_least_one
	); then
		log_indent '(none)'

		# NOTE: The 0 means re-running configure is not required.
		echo 0
		return 0
	fi

	local changed_files
	if ! changed_files=$(
		filter_not_matching '^= ' <<<"${files}" |
		match_at_least_one
	); then
		log_indent '(none)'

		# NOTE: The 0 means re-running configure is not required.
		echo 0
		return 0
	else
		quote <<<"${changed_files}"
	fi

	copy_entire_contents "${sources_dir}" "${prepare_dir}"

	# NOTE: Restoring file modification times of unchanged files is necessary to avoid needless recompilation.
	local unchanged_files
	if unchanged_files=$(
		filter_matching '^= ' <<<"${files}" |
		match_at_least_one
	); then
		local file
		while read -r file; do
			cp -p "${HALCYON_DIR}/app/${file#= }" "${prepare_dir}/${file#= }" || die
		done <<<"${unchanged_files}"
	fi

	rm -rf "${prepare_dir}/dist" || die
	mv "${HALCYON_DIR}/app/dist" "${prepare_dir}/dist" || die
	mv "${HALCYON_DIR}/app/.halcyon-tag" "${prepare_dir}/.halcyon-tag" || die

	rm -rf "${HALCYON_DIR}/app" || die
	mv "${prepare_dir}" "${HALCYON_DIR}/app" || die

	# NOTE: With 'build-type: Custom' packages, changing the 'Setup.hs' file requires manually re-running
	# 'cabal configure', as Cabal does not detect the change.
	# https://github.com/mietek/haskell-on-heroku/issues/29

	if filter_matching "^. Setup.hs$" <<<"${changed_files}" |
		match_exactly_one >'/dev/null'
	then
		echo 1
	else
		echo 0
	fi
}


function install_app () {
	expect_vars HALCYON_DIR HALCYON_REBUILD_APP HALCYON_NO_BUILD

	local sources_dir
	expect_args sources_dir -- "$@"
	expect_existing "${sources_dir}"

	local app_tag
	app_tag=$( determine_app_tag "${sources_dir}" ) || die

	if ! (( HALCYON_REBUILD_APP )) && restore_app "${app_tag}"; then
		if fully_validate_app_tag "${app_tag}"; then
			activate_app || die
			return 0
		fi

		local must_copy must_configure
		must_copy=0
		must_configure=$( prepare_app_files "${sources_dir}" ) || die
		if ! validate_app_tag_slug_dir "${app_tag}"; then
			must_configure=1
		fi
		build_app "${app_tag}" "${must_copy}" "${must_configure}" "${sources_dir}" || die
		archive_app || die
		activate_app || die
		return 0
	fi

	if ! (( HALCYON_REBUILD_APP )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build app layer'
		return 1
	fi

	local must_copy must_configure
	must_copy=1
	must_configure=1
	rm -rf "${HALCYON_DIR}/app" || die
	build_app "${app_tag}" "${must_copy}" "${must_configure}" "${sources_dir}" || die
	archive_app || die
	activate_app || die
}
