function create_sandbox_tag () {
	local app_label constraint_hash       \
		ghc_version ghc_magic_hash    \
		sandbox_magic_hash
	expect_args app_label constraint_hash \
		ghc_version ghc_magic_hash    \
		sandbox_magic_hash -- "$@"

	create_tag "${app_label}" '' '' "${constraint_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"         \
		'' '' '' ''                                  \
		"${sandbox_magic_hash}"                      \
		'' || die
}


function derive_sandbox_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label constraint_hash ghc_version ghc_magic_hash sandbox_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	create_sandbox_tag "${app_label}" "${constraint_hash}" "${ghc_version}" "${ghc_magic_hash}" "${sandbox_magic_hash}" || die
}


function derive_matching_sandbox_tag () {
	local tag app_label constraint_hash
	expect_args tag app_label constraint_hash -- "$@"

	local ghc_version ghc_magic_hash sandbox_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	create_sandbox_tag "${app_label}" "${constraint_hash}" "${ghc_version}" "${ghc_magic_hash}" "${sandbox_magic_hash}" || die
}


function format_sandbox_id () {
	local tag
	expect_args tag -- "$@"

	local constraint_hash sandbox_magic_hash
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "${constraint_hash:0:7}${sandbox_magic_hash:+-${sandbox_magic_hash:0:7}}"
}


function format_sandbox_description () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "${app_label}, ${sandbox_id}"
}


function format_sandbox_archive_name () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-${sandbox_id}-${app_label}.tar.xz"
}


function hash_sandbox_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_spaceless_recursively "${source_dir}/.halcyon-magic" \( -name 'ghc*' -or -name 'sandbox*' \) || die
}


function copy_sandbox_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die
	if [ -z "${sandbox_magic_hash}" ]; then
		return 0
	fi

	mkdir -p "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
	find_spaceless_recursively "${source_dir}/.halcyon-magic" \( -name 'ghc*' -or -name 'sandbox*'
		while read -r file; do
			cp -p "${source_dir}/.halcyon-magic/${file}" "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
		done
}


function build_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag constraints must_create source_dir
	expect_args tag constraints must_create source_dir -- "$@"
	if (( must_create )); then
		expect_no_existing "${HALCYON_DIR}/sandbox"
	else
		expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-constraints.config"
	fi
	expect_existing "${source_dir}"

	log 'Building sandbox layer'

	if (( must_create )); then
		log 'Creating sandbox'

		mkdir -p "${HALCYON_DIR}/sandbox" || die
		cabal_do "${HALCYON_DIR}/sandbox" sandbox init --sandbox '.' |& quote || die
		mv "${HALCYON_DIR}/sandbox/cabal.sandbox.config" "${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" || die
	fi

	if [ -f "${source_dir}/.halcyon-magic/sandbox-apps" ]; then
		deploy_sandbox_apps "${source_dir}" || die
	fi

	if [ -f "${source_dir}/.halcyon-magic/sandbox-prebuild-hook" ]; then
		log 'Running sandbox pre-build hook'
		( "${source_dir}/.halcyon-magic/sandbox-prebuild-hook" "${tag}" "${must_create}" ) |& quote || die
	fi

	log 'Building sandbox'

	# NOTE: Listing executable-only packages in build-tools causes Cabal to expect the executables
	# to be installed, but not to install the packages.
	# https://github.com/haskell/cabal/issues/220

	# NOTE: Listing executable-only packages in build-depends causes Cabal to install the packages,
	# and to fail to recognise the packages have been installed.
	# https://github.com/haskell/cabal/issues/779

	sandboxed_cabal_do "${source_dir}" install --dependencies-only |& quote || die

	format_constraints <<<"${constraints}" >"${HALCYON_DIR}/sandbox/.halcyon-constraints.config" || die

	if [ -f "${source_dir}/.halcyon-magic/sandbox-postbuild-hook" ]; then
		log 'Running sandbox post-build hook'
		( "${source_dir}/.halcyon-magic/sandbox-postbuild-hook" "${tag}" "${must_create}" ) |& quote || die
	fi

	copy_sandbox_magic "${source_dir}" || die
	derive_sandbox_tag "${tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die

	local layer_size
	log_begin 'Measuring sandbox layer...'
	layer_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log_end "${layer_size}"

	local app_label actual_constraints
	app_label=$( get_tag_app_label "${tag}" ) || die
	actual_constraints=$( freeze_actual_constraints "${app_label}" "${source_dir}" ) || die
	validate_actual_constraints "${tag}" "${constraints}" "${actual_constraints}" || die
}


function strip_sandbox_layer () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local sandbox_tag
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die

	log_begin 'Measuring sandbox layer...'

	find "${HALCYON_DIR}/sandbox"       \
			-type f        -and \
			\(                  \
			-name '*.so'   -or  \
			-name '*.so.*' -or  \
			-name '*.a'         \
			\)                  \
			-print0 |
		strip0 --strip-unneeded

	local layer_size
	layer_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log_end "${layer_size}"
}


function archive_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-constraints.config"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local sandbox_tag os ghc_version archive_name file_name
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	os=$( get_tag_os "${sandbox_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${sandbox_tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${sandbox_tag}" ) || die
	file_name=$( format_constraint_file_name "${sandbox_tag}" ) || die

	log 'Archiving sandbox layer'

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_CACHE_DIR}/${file_name}" || die
	tar_archive "${HALCYON_DIR}/sandbox" "${HALCYON_CACHE_DIR}/${archive_name}" || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${archive_name}" "${os}/ghc-${ghc_version}"; then
		log_warning 'Cannot upload sandbox layer archive'
	fi
	cp -p "${HALCYON_DIR}/sandbox/.halcyon-constraints.config" "${HALCYON_CACHE_DIR}/${file_name}" || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${file_name}" "${os}/ghc-${ghc_version}"; then
		log_warning 'Cannot upload sandbox layer constraints'
	fi
}


function validate_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/sandbox/.halcyon-tag" ]; then
		return 1
	fi

	local sandbox_tag candidate_tag
	sandbox_tag=$( derive_sandbox_tag "${tag}" ) || die
	candidate_tag=$( match_exactly_one <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	if [ "${candidate_tag}" != "${sandbox_tag}" ]; then
		return 1
	fi
}


function restore_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os ghc_version archive_name
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${tag}" ) || die

	if validate_sandbox_layer "${tag}"; then
		log 'Using existing sandbox layer'
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || true
		return 0
	fi
	rm -rf "${HALCYON_DIR}/sandbox" || die

	log 'Restoring sandbox layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${archive_name}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/sandbox" ||
		! validate_sandbox_layer "${tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/sandbox" || die
		if ! download_layer "${os}/ghc-${ghc_version}" "${archive_name}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download sandbox layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/sandbox" ||
			! validate_sandbox_layer "${tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/sandbox" || die
			log_warning 'Cannot extract sandbox layer archive'
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || true
	fi
}


function install_matching_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD

	local tag constraints matching_tag source_dir
	expect_args tag constraints matching_tag source_dir -- "$@"

	local constraint_hash matching_hash matching_description
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	matching_hash=$( get_tag_constraint_hash "${matching_tag}" ) || die
	matching_description=$( format_sandbox_description "${matching_tag}" ) || die

	if [ "${matching_hash}" = "${constraint_hash}" ]; then
		log "Using fully matching sandbox layer, ${matching_description}"

		if ! restore_sandbox_layer "${matching_tag}"; then
			return 1
		fi

		derive_sandbox_tag "${tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die
		return 0
	fi

	log "Using partially matching sandbox layer, ${matching_description}"

	if (( HALCYON_NO_BUILD )) || ! restore_sandbox_layer "${matching_tag}"; then
		return 1
	fi

	local must_create
	must_create=0
	build_sandbox_layer "${tag}" "${constraints}" "${must_create}" "${source_dir}" || die
	strip_sandbox_layer || die
}


function install_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_FORCE_SANDBOX HALCYON_NO_BUILD

	local tag constraints source_dir
	expect_args tag constraints source_dir -- "$@"

	if ! (( HALCYON_FORCE_SANDBOX )) && restore_sandbox_layer "${tag}"; then
		return 0
	fi

	local matching_tag
	if ! (( HALCYON_FORCE_SANDBOX )) &&
		matching_tag=$( locate_best_matching_sandbox_layer "${tag}" "${constraints}" ) &&
		install_matching_sandbox_layer "${tag}" "${constraints}" "${matching_tag}" "${source_dir}"
	then
		archive_sandbox_layer || die
		return 0
	fi

	if ! (( HALCYON_FORCE_SANDBOX )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build sandbox layer'
		return 1
	fi

	local must_create
	must_create=1
	rm -rf "${HALCYON_DIR}/sandbox" || die
	build_sandbox_layer "${tag}" "${constraints}" "${must_create}" "${source_dir}" || die
	strip_sandbox_layer || die
	archive_sandbox_layer || die
}


function deploy_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag constraints source_dir
	expect_args tag constraints source_dir -- "$@"

	if ! install_sandbox_layer "${tag}" "${constraints}" "${source_dir}"; then
		return 1
	fi
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local sandbox_tag description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	description=$( format_sandbox_description "${sandbox_tag}" ) || die

	log 'Sandbox layer deployed:                  ' "${description}"
}
