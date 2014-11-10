create_sandbox_tag () {
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


detect_sandbox_tag () {
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


derive_sandbox_tag () {
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


derive_matching_sandbox_tag () {
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


format_sandbox_id () {
	local tag
	expect_args tag -- "$@"

	local constraints_hash sandbox_magic_hash
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "${constraints_hash:0:7}${sandbox_magic_hash:+.${sandbox_magic_hash:0:7}}"
}


format_sandbox_description () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "${app_label} (${sandbox_id})"
}


format_sandbox_archive_name () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-${sandbox_id}-${app_label}.tar.gz"
}


format_sandbox_constraints_file_name () {
	local tag
	expect_args tag -- "$@"

	local app_label sandbox_id
	app_label=$( get_tag_app_label "${tag}" ) || die
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-constraints-${sandbox_id}-${app_label}.cabal.config"
}


format_sandbox_constraints_file_name_prefix () {
	echo "halcyon-sandbox-constraints-"
}


format_full_sandbox_constraints_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local sandbox_id
	sandbox_id=$( format_sandbox_id "${tag}" ) || die

	echo "halcyon-sandbox-constraints-${sandbox_id}-.*.cabal.config"
}


format_partial_sandbox_constraints_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local sandbox_magic_hash
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die

	echo "halcyon-sandbox-constraints-.*${sandbox_magic_hash:+.${sandbox_magic_hash:0:7}}-.*.cabal.config"
}


format_sandbox_common_file_name_prefix () {
	echo "halcyon-sandbox-"
}


format_sandbox_common_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local app_label
	app_label=$( get_tag_app_label "${tag}" ) || die

	echo "halcyon-sandbox-.*-${app_label}.(tar.gz|cabal.config)"
}


map_sandbox_constraints_file_name_to_app_label () {
	local constraints_name
	expect_args constraints_name -- "$@"

	local app_label_etc
	app_label_etc="${constraints_name#halcyon-sandbox-constraints-*-}"

	echo "${app_label_etc%.cabal.config}"
}


hash_sandbox_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" \
		\(                               \
		-path './ghc*'     -or           \
		-path './sandbox*'               \
		\) || die
}


copy_sandbox_magic () {
	expect_vars HALCYON_DIR

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${HALCYON_DIR}/sandbox"

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die
	if [[ -z "${sandbox_magic_hash}" ]]; then
		return 0
	fi

	find_tree "${source_dir}/.halcyon-magic" -type f \
			\(                               \
			-path './ghc*'     -or           \
			-path './sandbox*'               \
			\) |
		while read -r file; do
			copy_file "${source_dir}/.halcyon-magic/${file}" \
				"${HALCYON_DIR}/sandbox/.halcyon-magic/${file}" || die
		done || die
}


install_sandbox_extra_libs () {
	expect_vars HALCYON_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if [[ ! -f "${source_dir}/.halcyon-magic/sandbox-extra-libs" ]]; then
		return 0
	fi

	local platform description apt_dir
	platform=$( get_tag_platform "${tag}" ) || die
	description=$( format_platform_description "${platform}" ) || die
	apt_dir=$( get_tmp_dir 'halcyon-sandbox-extra-libs' ) || die

	log 'Installing sandbox extra libs'

	case "${platform}" in
	'linux-ubuntu-14.04-x86_64');&
	'linux-ubuntu-12.04-x86_64');&
	'linux-ubuntu-10.04-x86_64')
		true;;
	*)
		log_warning "Cannot install sandbox extra libs on ${description}"
		return 0
	esac

	local -a opts
	opts+=( -o debug::nolocking='true' )
	opts+=( -o dir::cache="${apt_dir}/cache" )
	opts+=( -o dir::state="${apt_dir}/state" )

	mkdir -p "${apt_dir}/cache/archives/partial" "${apt_dir}/state/lists/partial" || die

	log_indent_begin 'Updating package lists...'

	apt-get "${opts[@]}" update --quiet --quiet |& quote || die

	log_end 'done'

	local -a sandbox_libs
	sandbox_libs=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-libs" ) ) || die

	local sandbox_lib
	for sandbox_lib in "${sandbox_libs[@]}"; do
		apt-get "${opts[@]}" install --download-only --reinstall --yes "${sandbox_lib}" |& quote || die
	done

	find_tree "${apt_dir}/cache/archives" -type f -name '*.deb' |
		while read -r file; do
			dpkg --extract "${apt_dir}/cache/archives/${file}" \
				"${HALCYON_DIR}/sandbox/.halcyon-sandbox-extra-libs" |& quote || die
		done || die
}


deploy_sandbox_extra_apps () {
	local tag source_dir
	expect_args tag source_dir -- "$@"

	if [[ ! -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]]; then
		return 0
	fi

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	local constraints_dir
	constraints_dir="${source_dir}/.halcyon-magic/sandbox-extra-apps-constraints"

	local -a opts
	opts+=( --target='sandbox' )
	opts+=( --ghc-version="${ghc_version}" )
	opts+=( --cabal-version="${cabal_version}" )
	opts+=( --cabal-repo="${cabal_repo}" )
	[[ -d "${constraints_dir}" ]] && opts+=( --constraints-dir="${constraints_dir}" )

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

		(
			HALCYON_INTERNAL_RECURSIVE=1                            \
			HALCYON_INTERNAL_GHC_MAGIC_HASH="${ghc_magic_hash}"     \
			HALCYON_INTERNAL_CABAL_MAGIC_HASH="${cabal_magic_hash}" \
				halcyon deploy "${opts[@]}" "${sandbox_app}" |& quote
		) || return 1
	done
}


build_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir constraints must_create
	expect_args tag source_dir constraints must_create -- "$@"

	if (( must_create )); then
		rm -rf "${HALCYON_DIR}/sandbox" || die
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

	if [[ -f "${source_dir}/.halcyon-magic/sandbox-pre-build-hook" ]]; then
		log 'Executing sandbox pre-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1                                  \
				"${source_dir}/.halcyon-magic/sandbox-pre-build-hook" \
				"${tag}" "${source_dir}" "${constraints}" |& quote
		); then
			log_warning 'Cannot execute sandbox pre-build hook'
			return 1
		fi
		log 'Sandbox pre-build hook executed'
	fi

	if ! deploy_sandbox_extra_apps "${tag}" "${source_dir}"; then
		log_warning 'Cannot deploy sandbox extra apps'
		return 1
	fi

	if ! install_sandbox_extra_libs "${tag}" "${source_dir}"; then
		log_warning 'Cannot install sandbox extra libs'
		return 1
	fi

	log 'Compiling sandbox'

	# NOTE: Listing executable-only packages in build-tools causes Cabal to expect the
	# executables to be installed, but not to install the packages.
	# https://github.com/haskell/cabal/issues/220

	# NOTE: Listing executable-only packages in build-depends causes Cabal to install the
	# packages, and to fail to recognise the packages have been installed.
	# https://github.com/haskell/cabal/issues/779

	# TODO: Improve cross-platform compatibility.


	local -a opts
	opts+=( --dependencies-only )

	if [[ -d "${HALCYON_DIR}/sandbox/.halcyon-sandbox-extra-libs" ]]; then
		local platform
		platform=$( get_tag_platform "${tag}" ) || die

		case "${platform}" in
		'linux-ubuntu-14.04-x86_64');&
		'linux-ubuntu-12.04-x86_64');&
		'linux-ubuntu-10.04-x86_64')
			opts+=( --extra-lib-dirs="${HALCYON_DIR}/sandbox/.halcyon-sandbox-extra-libs/usr/lib" )
			opts+=( --extra-include-dirs="${HALCYON_DIR}/sandbox/.halcyon-sandbox-extra-libs/usr/include/x86_64-linux-gnu" )
			;;
		*)
			true
		esac
	fi

	if ! sandboxed_cabal_do "${source_dir}" install "${opts[@]}" |& quote; then
		die 'Failed to compile sandbox'
	fi

	format_constraints <<<"${constraints}" >"${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config" || die

	copy_sandbox_magic "${source_dir}" || die

	local compiled_size
	compiled_size=$( get_size "${HALCYON_DIR}/sandbox" ) || die

	log "Sandbox compiled, ${compiled_size}"

	if [[ -f "${source_dir}/.halcyon-magic/sandbox-post-build-hook" ]]; then
		log 'Executing sandbox post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1                                   \
				"${source_dir}/.halcyon-magic/sandbox-post-build-hook" \
				"${tag}" "${source_dir}" "${constraints}" |& quote
		); then
			log_warning 'Cannot execute sandbox post-build hook'
			return 1
		fi
		log 'Sandbox post-build hook executed'
	fi

	if [[ -d "${HALCYON_DIR}/sandbox/logs" || -d "${HALCYON_DIR}/sandbox/share/doc" ]]; then
		log_indent_begin 'Removing documentation from sandbox layer...'

		rm -rf "${HALCYON_DIR}/sandbox/logs" "${HALCYON_DIR}/sandbox/share/doc" || die

		local trimmed_size
		trimmed_size=$( get_size "${HALCYON_DIR}/sandbox" ) || die
		log_end "done, ${trimmed_size}"
	fi

	log_indent_begin 'Stripping sandbox layer...'

	strip_tree "${HALCYON_DIR}/sandbox" || die

	local stripped_size
	stripped_size=$( get_size "${HALCYON_DIR}/sandbox" ) || die
	log_end "done, ${stripped_size}"

	derive_sandbox_tag "${tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die
}


archive_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE HALCYON_NO_DELETE
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" \
		"${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local sandbox_tag platform ghc_version archive_name constraints_name
	sandbox_tag=$( detect_sandbox_tag "${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	platform=$( get_tag_platform "${sandbox_tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${sandbox_tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${sandbox_tag}" ) || die
	constraints_name=$( format_sandbox_constraints_file_name "${sandbox_tag}" ) || die

	log 'Archiving sandbox layer'

	create_cached_archive "${HALCYON_DIR}/sandbox" "${archive_name}" || die
	copy_file "${HALCYON_DIR}/sandbox/.halcyon-sandbox-constraints.cabal.config" \
		"${HALCYON_CACHE_DIR}/${constraints_name}" || die

	local no_delete
	no_delete=0
	if ! upload_cached_file "${platform}/ghc-${ghc_version}" "${archive_name}"; then
		no_delete=1
	fi
	if ! upload_cached_file "${platform}/ghc-${ghc_version}" "${constraints_name}"; then
		no_delete=1
	fi
	if (( HALCYON_NO_DELETE )) || (( no_delete )); then
		return 0
	fi

	local common_prefix common_pattern
	common_prefix=$( format_sandbox_common_file_name_prefix ) || die
	common_pattern=$( format_sandbox_common_file_name_pattern "${sandbox_tag}" ) || die

	delete_matching_private_stored_files "${platform}/ghc-${ghc_version}" "${common_prefix}" "${common_pattern}" "(${archive_name}|${constraints_name})" || die
}


validate_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local sandbox_tag
	sandbox_tag=$( derive_sandbox_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/sandbox/.halcyon-tag" "${sandbox_tag//./\.}" || return 1
}


restore_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local platform ghc_version archive_name description
	platform=$( get_tag_platform "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	archive_name=$( format_sandbox_archive_name "${tag}" ) || die
	description=$( format_sandbox_description "${tag}" ) || die

	if validate_sandbox_layer "${tag}" >'/dev/null'; then
		log_label 'Using existing sandbox layer:' "${description}"
		touch_cached_file "${archive_name}" || die
		return 0
	fi

	log 'Restoring sandbox layer'

	if ! extract_cached_archive_over "${archive_name}" "${HALCYON_DIR}/sandbox" ||
		! validate_sandbox_layer "${tag}" >'/dev/null'
	then
		if ! cache_stored_file "${platform}/ghc-${ghc_version}" "${archive_name}" ||
			! extract_cached_archive_over "${archive_name}" "${HALCYON_DIR}/sandbox" ||
			! validate_sandbox_layer "${tag}" >'/dev/null'
		then
			return 1
		fi
	else
		touch_cached_file "${archive_name}" || die
	fi

	log_label 'Sandbox layer restored:' "${description}"
}


install_matching_sandbox_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir constraints matching_tag
	expect_args tag source_dir constraints matching_tag -- "$@"

	local constraints_hash matching_hash matching_description
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	matching_hash=$( get_tag_constraints_hash "${matching_tag}" ) || die
	matching_description=$( format_sandbox_description "${matching_tag}" ) || die

	if [[ "${matching_hash}" == "${constraints_hash}" ]]; then
		log_label 'Using fully matching sandbox layer:' "${matching_description}"

		restore_sandbox_layer "${matching_tag}" || return 1

		derive_sandbox_tag "${tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die
		return 0
	fi

	log_label 'Using partially matching sandbox layer:' "${matching_description}"

	restore_sandbox_layer "${matching_tag}" || return 1

	local must_create
	must_create=0
	build_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${must_create}" || return 1
}


announce_sandbox_layer () {
	local tag
	expect_args tag -- "$@"

	local installed_tag description
	installed_tag=$( validate_sandbox_layer "${tag}" ) || die
	description=$( format_sandbox_description "${installed_tag}" ) || die

	log_label 'Sandbox layer installed:' "${description}"
}


install_sandbox_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD_DEPENDENCIES HALCYON_FORCE_BUILD_SANDBOX

	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	if ! (( HALCYON_FORCE_BUILD_SANDBOX )); then
		if restore_sandbox_layer "${tag}"; then
			return 0
		fi

		local matching_tag
		if matching_tag=$( match_sandbox_layer "${tag}" "${constraints}" ) &&
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
	if ! build_sandbox_layer "${tag}" "${source_dir}" "${constraints}" "${must_create}"; then
		log_warning 'Cannot build sandbox layer'
		return 1
	fi
	archive_sandbox_layer || die
	announce_sandbox_layer "${tag}" || die

	validate_actual_constraints "${tag}" "${source_dir}" "${constraints}" || die
}
