function create_sandbox_tag () {
	local app_label constraints_hash       \
		ghc_version ghc_magic_hash     \
		sandbox_magic_hash
	expect_args app_label constraints_hash \
		ghc_version ghc_magic_hash     \
		sandbox_magic_hash -- "$@"

	create_tag "${app_label}" ''                 \
		'' "${constraints_hash}"             \
		"${ghc_version}" "${ghc_magic_hash}" \
		'' '' '' ''                          \
		"${sandbox_magic_hash}" '' || die
}


function detect_sandbox_tag () {
	expect_vars HALCYON_DIR

	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_sandbox_tag '.*' '.*' '.*' '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect sandbox layer tag'
	fi

	echo "${tag}"
}


function derive_sandbox_tag () {
	local tag
	expect_args tag -- "$@"

	local app_label constraints_hash ghc_version ghc_magic_hash sandbox_magic_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	create_sandbox_tag "${app_label}" "${constraints_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"            \
		"${sandbox_magic_hash}" || die
}


function derive_matching_sandbox_tag () {
	local tag app_label constraints_hash
	expect_args tag app_label constraints_hash -- "$@"

	local ghc_version ghc_magic_hash sandbox_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	create_sandbox_tag "${app_label}" "${constraints_hash}" \
		"${ghc_version}" "${ghc_magic_hash}"            \
		"${sandbox_magic_hash}" || die
}


function format_sandbox_id () {
	local tag
	expect_args tag -- "$@"

	local constraints_hash sandbox_magic_hash
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "${constraints_hash:0:7}${sandbox_magic_hash:+.${sandbox_magic_hash:0:7}}"
}


function format_sandbox_description () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "${app_label} (${sandbox_id})"
}


function format_sandbox_archive_name () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-${sandbox_id}-${app_label}.tar.xz"
}


function format_sandbox_constraints_file_name () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-constraints-${sandbox_id}-${app_label}.cabal.config"
}


function format_sandbox_constraints_file_name_prefix () {
	echo "halcyon-sandbox-constraints-"
}


function format_full_sandbox_constraints_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local sandbox_id
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-constraints-${sandbox_id}-.*.cabal.config"
}


function format_partial_sandbox_constraints_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local sandbox_magic_hash
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "halcyon-sandbox-constraints-.*${sandbox_magic_hash:+.${sandbox_magic_hash:0:7}}-.*.cabal.config"
}


function format_sandbox_common_file_name_prefix () {
	echo "halcyon-sandbox-"
}


function format_sandbox_common_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	echo "halcyon-sandbox-.*-${app_label}.(tar.xz|cabal.config)"
}


function map_sandbox_constraints_file_name_to_app_label () {
	local file_name
	expect_args file_name -- "$@"

	local app_label_etc
	app_label_etc="${file_name#halcyon-sandbox-*-}"

	echo "${app_label_etc%.cabal.config}"
}


function hash_sandbox_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" \
		\(                               \
		-path './ghc*'     -or           \
		-path './sandbox*'               \
		\) || die
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
	find_tree "${source_dir}/.halcyon-magic" -type f \
			\(                               \
			-path './ghc*'     -or           \
			-path './sandbox*'               \
			\) |
		while read -r file; do
			cp -p "${source_dir}/.halcyon-magic/${file}" \
				"${HALCYON_DIR}/sandbox/.halcyon-magic" || die
		done || die
}


function deploy_sandbox_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	if ! [ -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]; then
		return 0
	fi

	log 'Deploying sandbox extra apps'

	local -a sandbox_apps
	sandbox_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) ) || die

	local sandbox_app index
	index=0
	for sandbox_app in "${sandbox_apps[@]}"; do
		index=$(( index + 1 ))
		if (( index > 1 )); then
			log
			log
		fi

		local -a deploy_args
		deploy_args=( --recursive --target='sandbox' "${sandbox_app}" )

		local sandbox_file
		sandbox_file="${source_dir}/.halcyon-magic/sandbox-extra-apps-constraints/${sandbox_app}.cabal.config"
		if [ -f "${sandbox_file}" ]; then
			deploy_args+=( --constraints-file="${sandbox_file}" )
		fi

		if ! ( deploy "${deploy_args[@]}" |& quote ); then
			log_warning 'Cannot deploy sandbox extra apps'
			return 1
		fi
	done
}


function build_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir constraints must_create
	expect_args tag source_dir constraints must_create -- "$@"
	if (( must_create )); then
		expect_no_existing "${HALCYON_DIR}/sandbox"
	else
		expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" \
			"${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config"
	fi
	expect_existing "${source_dir}"

	log 'Building sandbox layer'

	if (( must_create )); then
		log 'Creating sandbox'

		mkdir -p "${HALCYON_DIR}/sandbox" || die
		if ! cabal_do "${HALCYON_DIR}/sandbox" sandbox init --sandbox '.' |& quote; then
			die 'Failed to create sandbox'
		fi
		mv "${HALCYON_DIR}/sandbox/cabal.sandbox.config" "${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" || die
	fi

	if [ -f "${source_dir}/.halcyon-magic/sandbox-pre-build-hook" ]; then
		log 'Executing sandbox pre-build hook'
		if ! (
			"${source_dir}/.halcyon-magic/sandbox-pre-build-hook" \
				"${tag}" "${source_dir}" "${constraints}" |& quote
		); then
			log_warning 'Cannot execute sandbox pre-build hook'
			return 1
		fi
		log 'Sandbox pre-build hook executed'
	fi

	if ! deploy_sandbox_extra_apps "${source_dir}"; then
		die 'Cannot build sandbox layer'
	fi

	log 'Compiling sandbox'

	# NOTE: Listing executable-only packages in build-tools causes Cabal to expect the executables
	# to be installed, but not to install the packages.
	# https://github.com/haskell/cabal/issues/220

	# NOTE: Listing executable-only packages in build-depends causes Cabal to install the packages,
	# and to fail to recognise the packages have been installed.
	# https://github.com/haskell/cabal/issues/779

	if ! sandboxed_cabal_do "${source_dir}" install --dependencies-only |& quote; then
		die 'Failed to compile sandbox'
	fi

	format_constraints <<<"${constraints}" >"${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config" || die

	copy_sandbox_magic "${source_dir}" || die
	derive_sandbox_tag "${tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die

	local compiled_size
	compiled_size=$( size_tree "${HALCYON_DIR}/sandbox" ) || die

	log "Sandbox compiled, ${compiled_size}"

	if [ -f "${source_dir}/.halcyon-magic/sandbox-post-build-hook" ]; then
		log 'Executing sandbox post-build hook'
		if ! (
			"${source_dir}/.halcyon-magic/sandbox-post-build-hook" \
				"${tag}" "${source_dir}" "${constraints}" |& quote
		); then
			log_warning 'Cannot execute sandbox post-build hook'
			return 1
		fi
		log 'Sandbox post-build hook executed'
	fi

	log_indent_begin 'Stripping sandbox layer...'

	strip_tree "${HALCYON_DIR}/sandbox" || die

	local stripped_size
	stripped_size=$( size_tree "${HALCYON_DIR}/sandbox" ) || die
	log_end "done, ${stripped_size}"
}


function archive_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE HALCYON_NO_DELETE
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" \
		"${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local sandbox_tag os ghc_version archive_name file_name
	sandbox_tag=$( detect_sandbox_tag "${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	os=$( get_tag_os "${sandbox_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${sandbox_tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${sandbox_tag}" ) || die
	file_name=$( format_sandbox_constraints_file_name "${sandbox_tag}" ) || die

	log 'Archiving sandbox layer'

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_CACHE_DIR}/${file_name}" || die
	tar_create "${HALCYON_DIR}/sandbox" "${HALCYON_CACHE_DIR}/${archive_name}" || die
	cp -p "${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config" "${HALCYON_CACHE_DIR}/${file_name}" || die

	local no_delete
	no_delete=0
	if ! upload_stored_file "${os}/ghc-${ghc_version}" "${archive_name}"; then
		no_delete=1
	fi
	if ! upload_stored_file "${os}/ghc-${ghc_version}" "${file_name}"; then
		no_delete=1
	fi

	if (( HALCYON_NO_DELETE )) || (( no_delete )); then
		return 0
	fi

	local common_prefix common_pattern
	common_prefix=$( format_sandbox_common_file_name_prefix ) || die
	common_pattern=$( format_sandbox_common_file_name_pattern "${sandbox_tag}" ) || die

	delete_matching_private_stored_files "${os}/ghc-${ghc_version}" "${common_prefix}" "${common_pattern}" "(${archive_name}|${file_name})" || die
}


function validate_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local sandbox_tag
	sandbox_tag=$( derive_sandbox_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/sandbox/.halcyon-tag" "${sandbox_tag//./\.}" || return 1
}


function restore_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os ghc_version archive_name description
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${tag}" ) || die
	description=$( format_sandbox_description "${tag}" ) || die

	if validate_sandbox_layer "${tag}" >'/dev/null'; then
		log_pad 'Using existing sandbox layer:' "${description}"
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
		return 0
	fi
	rm -rf "${HALCYON_DIR}/sandbox" || die

	log 'Restoring sandbox layer'

	if ! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/sandbox" ||
		! validate_sandbox_layer "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_DIR}/sandbox" || die
		if ! transfer_stored_file "${os}/ghc-${ghc_version}" "${archive_name}" ||
			! tar_extract "${HALCYON_CACHE_DIR}/${archive_name}" "${HALCYON_DIR}/sandbox" ||
			! validate_sandbox_layer "${tag}" >'/dev/null'
		then
			rm -rf "${HALCYON_DIR}/sandbox" || die
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${archive_name}" || die
	fi

	log_pad 'Sandbox layer restored:' "${description}"
}


function install_matching_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir constraints matching_tag
	expect_args tag source_dir constraints matching_tag -- "$@"

	local constraints_hash matching_hash matching_description
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	matching_hash=$( get_tag_constraints_hash "${matching_tag}" ) || die
	matching_description=$( format_sandbox_description "${matching_tag}" ) || die

	if [ "${matching_hash}" = "${constraints_hash}" ]; then
		log_pad 'Using fully matching sandbox layer:' "${matching_description}"

		restore_sandbox_layer "${matching_tag}" || return 1

		derive_sandbox_tag "${tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die
		return 0
	fi

	log_pad 'Using partially matching sandbox layer:' "${matching_description}"

	restore_sandbox_layer "${matching_tag}" || return 1

	local must_create
	must_create=0
	build_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${must_create}" || return 1
}


function announce_sandbox_layer () {
	local tag
	expect_args tag -- "$@"

	local installed_tag description
	installed_tag=$( validate_sandbox_layer "${tag}" ) || die
	description=$( format_sandbox_description "${installed_tag}" ) || die

	log_pad 'Sandbox layer installed:' "${description}"
}


function install_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD_DEPENDENCIES HALCYON_FORCE_BUILD_SANDBOX

	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	if ! (( HALCYON_FORCE_BUILD_SANDBOX )); then
		if restore_sandbox_layer "${tag}"; then
			return 0
		fi

		local matching_tag
		if matching_tag=$( locate_best_matching_sandbox_layer "${tag}" "${constraints}" ) &&
			install_matching_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${matching_tag}"
		then
			archive_sandbox_layer || die
			announce_sandbox_layer "${tag}" || die
			return 0
		fi

		if (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_warning 'Cannot build sandbox layer'
			return 1
		fi
	fi

	local must_create
	must_create=1
	rm -rf "${HALCYON_DIR}/sandbox" || die
	if ! build_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${must_create}"; then
		log_warning 'Cannot build sandbox layer'
		return 1
	fi
	archive_sandbox_layer || die
	announce_sandbox_layer "${tag}" || die

	validate_actual_constraints "${tag}" "${source_dir}" "${constraints}" || die
}
