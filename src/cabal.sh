map_cabal_version_to_original_url () {
	local cabal_version
	expect_args cabal_version -- "$@"

	case "${cabal_version}" in
	'1.20.0.3')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.3/cabal-install-1.20.0.3.tar.gz';;
	'1.20.0.2')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.2/cabal-install-1.20.0.2.tar.gz';;
	'1.20.0.1')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.1/cabal-install-1.20.0.1.tar.gz';;
	'1.20.0.0')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.0/cabal-install-1.20.0.0.tar.gz';;
	'1.18.0.3')	echo 'https://haskell.org/cabal/release/cabal-install-1.18.0.3/cabal-install-1.18.0.3.tar.gz';;
	'1.18.0.2')	echo 'https://haskell.org/cabal/release/cabal-install-1.18.0.2/cabal-install-1.18.0.2.tar.gz';;
	'1.18.0.1')	echo 'https://haskell.org/cabal/release/cabal-install-1.18.0.1/cabal-install-1.18.0.1.tar.gz';;
	*)		die "Unexpected Cabal version: ${cabal_version}"
	esac
}


create_cabal_tag () {
	local cabal_version cabal_magic_hash cabal_repo cabal_date
	expect_args cabal_version cabal_magic_hash cabal_repo cabal_date -- "$@"

	create_tag '' '' '' '' '' \
		'' '' \
		"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${cabal_date}" \
		'' || die
}


detect_cabal_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_cabal_tag '.*' '.*' '.*' '.*' ) || die

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		die 'Cannot detect Cabal layer tag'
	fi

	echo "${tag}"
}


derive_base_cabal_tag () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" '' '' || die
}


derive_updated_cabal_tag () {
	local tag cabal_date
	expect_args tag cabal_date -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${cabal_date}" || die
}


derive_updated_cabal_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	create_cabal_tag "${cabal_version//./\.}" "${cabal_magic_hash}" "${cabal_repo//.\.}" '.*' || die
}


format_cabal_id () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die

	echo "${cabal_version}${cabal_magic_hash:+.${cabal_magic_hash:0:7}}"
}


format_cabal_repo_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_repo
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	echo "${cabal_repo%%:*}"
}


format_cabal_description () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name cabal_date
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" ) || die
	cabal_date=$( get_tag_cabal_date "${tag}" ) || die

	echo "${cabal_id} ${repo_name:+(${repo_name} ${cabal_date})}"
}


format_cabal_config () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local cabal_repo
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	cat <<-EOF
		remote-repo:        ${cabal_repo}
		remote-repo-cache:  ${HALCYON_BASE}/cabal/remote-repo-cache
		avoid-reinstalls:   True
		reorder-goals:      True
		require-sandbox:    True
		jobs:               \$ncpus
EOF
}


format_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name cabal_date
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die
	cabal_date=$( get_tag_cabal_date "${tag}" ) || die

	echo "halcyon-cabal-${cabal_id}${repo_name:+-${repo_name}-${cabal_date}}.tar.gz"
}


format_base_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id
	cabal_id=$( format_cabal_id "${tag}" ) || die

	echo "halcyon-cabal-${cabal_id}.tar.gz"
}


format_updated_cabal_archive_name_prefix () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}-"
}


format_updated_cabal_archive_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id//./\.}-${repo_name//./\.}-.*\.tar\.gz"
}


map_updated_cabal_archive_name_to_date () {
	local archive_name
	expect_args archive_name -- "$@"

	local date_etc
	date_etc="${archive_name#halcyon-cabal-*-*-}"

	echo "${date_etc%.tar.gz}"
}


hash_cabal_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_tree "${source_dir}/.halcyon-magic" -path './cabal*' || die
}


copy_cabal_magic () {
	expect_vars HALCYON_BASE

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${HALCYON_BASE}/cabal"

	local cabal_magic_hash
	cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || die
	if [[ -z "${cabal_magic_hash}" ]]; then
		return 0
	fi

	local file
	find_tree "${source_dir}/.halcyon-magic" -type f -path './cabal*' |
		while read -r file; do
			copy_file "${source_dir}/.halcyon-magic/${file}" \
				"${HALCYON_BASE}/cabal/.halcyon-magic/${file}" || die
		done || die
}


build_cabal_layer () {
	expect_vars HALCYON_BASE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	local ghc_version cabal_version original_url original_name cabal_build_dir cabal_home_dir
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	original_url=$( map_cabal_version_to_original_url "${cabal_version}" ) || die
	original_name=$( basename "${original_url}" ) || die
	cabal_build_dir=$( get_tmp_dir 'halcyon-cabal-source' ) || die
	cabal_home_dir=$( get_tmp_dir 'halcyon-cabal-home.disregard-this-advice' ) || die

	log 'Building Cabal layer'

	rm -rf "${HALCYON_BASE}/cabal" || die

	if ! extract_cached_archive_over "${original_name}" "${cabal_build_dir}"; then
		if ! cache_original_stored_file "${original_url}"; then
			die 'Cannot download original Cabal archive'
		fi
		if ! extract_cached_archive_over "${original_name}" "${cabal_build_dir}"; then
			die 'Cannot bootstrap Cabal'
		fi
	else
		touch_cached_file "${original_name}" || die
	fi

	if [[ -f "${source_dir}/.halcyon-magic/cabal-pre-build-hook" ]]; then
		log 'Executing Cabal pre-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/cabal-pre-build-hook" \
					"${tag}" "${source_dir}" \
					"${cabal_build_dir}/cabal-install-${cabal_version}" |& quote
		); then
			die 'Failed to execute Cabal pre-build hook'
		fi
		log 'Cabal pre-build hook executed'
	fi

	log 'Bootstrapping Cabal'

	# NOTE: Bootstrapping cabal-install 1.20.0.0 with GHC 7.6.* fails.

	case "${ghc_version}-${cabal_version}" in
	'7.8.'*'-1.20.0.'*)
		(
			cd "${cabal_build_dir}/cabal-install-${cabal_version}" &&
			patch -s <<-EOF
				--- a/bootstrap.sh
				+++ b/bootstrap.sh
				@@ -217,3 +217,3 @@ install_pkg () {

				-  \${GHC} --make Setup -o Setup ||
				+  \${GHC} -L"${HALCYON_BASE}/ghc/usr/lib" --make Setup -o Setup ||
				      die "Compiling the Setup script failed."
EOF
		) || die
		;;
	*)
		rm -rf "${cabal_build_dir}" || die
		die "Unexpected Cabal version for GHC ${ghc_version}: ${cabal_version}"
	esac

	# NOTE: Bootstrapping cabal-install with GHC 7.8.[23] may fail unless --no-doc
	# is specified.
	# https://ghc.haskell.org/trac/ghc/ticket/9174

	if ! (
		cd "${cabal_build_dir}/cabal-install-${cabal_version}" &&
		HOME="${cabal_home_dir}" \
		EXTRA_CONFIGURE_OPTS="--extra-lib-dirs=${HALCYON_BASE}/ghc/usr/lib" \
			./bootstrap.sh --no-doc |& quote
	); then
		die 'Failed to bootstrap Cabal'
	fi

	copy_file "${cabal_home_dir}/.cabal/bin/cabal" "${HALCYON_BASE}/cabal/bin/cabal" || die
	copy_cabal_magic "${source_dir}" || die

	local bootstrapped_size
	bootstrapped_size=$( get_size "${HALCYON_BASE}/cabal" ) || die

	log "Cabal bootstrapped, ${bootstrapped_size}"

	if [[ -f "${source_dir}/.halcyon-magic/cabal-post-build-hook" ]]; then
		log 'Executing Cabal post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/cabal-post-build-hook" \
					"${tag}" "${source_dir}" \
					"${cabal_build_dir}/cabal-install-${cabal_version}" |& quote
		); then
			die 'Failed to execute Cabal post-build hook'
		fi
		log 'Cabal post-build hook executed'
	fi

	log_indent_begin 'Stripping Cabal layer...'

	strip_tree "${HALCYON_BASE}/cabal" || die

	local stripped_size
	stripped_size=$( get_size "${HALCYON_BASE}/cabal" ) || die
	log_end "done, ${stripped_size}"

	derive_base_cabal_tag "${tag}" >"${HALCYON_BASE}/cabal/.halcyon-tag" || die

	rm -rf "${cabal_build_dir}" "${cabal_home_dir}" || die
}


update_cabal_package_db () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local cabal_date
	cabal_date=$( get_iso_date ) || die

	log 'Updating Cabal layer'

	format_cabal_config "${tag}" >"${HALCYON_BASE}/cabal/.halcyon-cabal.config" || die

	if [[ -f "${source_dir}/.halcyon-magic/cabal-pre-update-hook" ]]; then
		log 'Executing Cabal pre-update hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/cabal-pre-update-hook" |& quote
		); then
			die 'Failed to execute Cabal pre-update hook'
		fi
		log 'Cabal pre-update hook executed'
	fi

	log 'Updating Cabal package database'

	if ! cabal_do '.' update |& quote; then
		die 'Failed to update Cabal package database'
	fi

	local updated_size
	updated_size=$( get_size "${HALCYON_BASE}/cabal" ) || die

	log "Cabal package database updated, ${updated_size}"

	if [[ -f "${source_dir}/.halcyon-magic/cabal-post-update-hook" ]]; then
		log 'Executing Cabal post-update hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/cabal-post-update-hook" |& quote
		); then
			die 'Failed to execute Cabal post-update hook'
		fi
		log 'Cabal post-update hook executed'
	fi

	derive_updated_cabal_tag "${tag}" "${cabal_date}" >"${HALCYON_BASE}/cabal/.halcyon-tag" || die
}


archive_cabal_layer () {
	expect_vars HALCYON_BASE HALCYON_NO_ARCHIVE HALCYON_NO_CLEAN_PRIVATE_STORAGE
	expect_existing "${HALCYON_BASE}/cabal/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local cabal_tag platform archive_name
	cabal_tag=$( detect_cabal_tag "${HALCYON_BASE}/cabal/.halcyon-tag" ) || die
	platform=$( get_tag_platform "${cabal_tag}" ) || die
	archive_name=$( format_cabal_archive_name "${cabal_tag}" ) || die

	log 'Archiving Cabal layer'

	create_cached_archive "${HALCYON_BASE}/cabal" "${archive_name}" || die
	if ! upload_cached_file "${platform}" "${archive_name}" || (( HALCYON_NO_CLEAN_PRIVATE_STORAGE )); then
		return 0
	fi

	local cabal_date
	cabal_date=$( get_tag_cabal_date "${cabal_tag}" ) || die
	if [[ -z "${cabal_date}" ]]; then
		return 0
	fi

	local updated_prefix updated_pattern
	updated_prefix=$( format_updated_cabal_archive_name_prefix "${cabal_tag}" ) || die
	updated_pattern=$( format_updated_cabal_archive_name_pattern "${cabal_tag}" ) || die

	delete_matching_private_stored_files "${platform}" "${updated_prefix}" "${updated_pattern}" "${archive_name}" || die
}


validate_base_cabal_layer () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local base_tag
	base_tag=$( derive_base_cabal_tag "${tag}" ) || die
	detect_tag "${HALCYON_BASE}/cabal/.halcyon-tag" "${base_tag//./\.}" || return 1
}


validate_updated_cabal_date () {
	local candidate_date
	expect_args candidate_date -- "$@"

	local today_date
	today_date=$( get_iso_date ) || die

	if [[ "${candidate_date}" < "${today_date}" ]]; then
		return 1
	fi
}


validate_updated_cabal_layer () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local updated_pattern candidate_tag
	updated_pattern=$( derive_updated_cabal_tag_pattern "${tag}" ) || die
	candidate_tag=$( detect_tag "${HALCYON_BASE}/cabal/.halcyon-tag" "${updated_pattern}" ) || return 1

	local candidate_date
	candidate_date=$( get_tag_cabal_date "${candidate_tag}" ) || die
	validate_updated_cabal_date "${candidate_date}" || return 1

	echo "${candidate_tag}"
}


match_updated_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local updated_pattern candidate_name
	updated_pattern=$( format_updated_cabal_archive_name_pattern "${tag}" ) || die
	candidate_name=$(
		filter_matching "^${updated_pattern}$" |
		sort_natural -u |
		filter_last |
		match_exactly_one
	) || return 1

	local candidate_date
	candidate_date=$( map_updated_cabal_archive_name_to_date "${candidate_name}" ) || die
	validate_updated_cabal_date "${candidate_date}" || return 1

	echo "${candidate_name}"
}


restore_base_cabal_layer () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local platform base_name
	platform=$( get_tag_platform "${tag}" ) || die
	base_name=$( format_base_cabal_archive_name "${tag}" ) || die

	if validate_base_cabal_layer "${tag}" >'/dev/null'; then
		log 'Using existing Cabal layer'

		touch_cached_file "${base_name}" || die
		return 0
	fi

	log 'Restoring base Cabal layer'

	if ! extract_cached_archive_over "${base_name}" "${HALCYON_BASE}/cabal" ||
		! validate_base_cabal_layer "${tag}" >'/dev/null'
	then
		if ! cache_stored_file "${platform}" "${base_name}" ||
			! extract_cached_archive_over "${base_name}" "${HALCYON_BASE}/cabal" ||
			! validate_base_cabal_layer "${tag}" >'/dev/null'
		then
			return 1
		fi
	else
		touch_cached_file "${base_name}" || die
	fi
}


restore_cached_updated_cabal_layer () {
	expect_vars HALCYON_BASE HALCYON_CACHE

	local tag
	expect_args tag -- "$@"

	local updated_name
	updated_name=$(
		find_tree "${HALCYON_CACHE}" -maxdepth 1 -type f |
		match_updated_cabal_archive_name "${tag}"
	) || true

	if validate_updated_cabal_layer "${tag}" >'/dev/null'; then
		log 'Using existing Cabal layer'

		touch_cached_file "${updated_name}" || die
		return 0
	fi

	if [[ -z "${updated_name}" ]]; then
		return 1
	fi

	log 'Restoring Cabal layer'

	if ! extract_cached_archive_over "${updated_name}" "${HALCYON_BASE}/cabal" ||
		! validate_updated_cabal_layer "${tag}" >'/dev/null'
	then
		return 1
	else
		touch_cached_file "${updated_name}" || die
	fi
}


restore_updated_cabal_layer () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local platform archive_prefix
	platform=$( get_tag_platform "${tag}" ) || die
	archive_prefix=$( format_updated_cabal_archive_name_prefix "${tag}" ) || die

	if restore_cached_updated_cabal_layer "${tag}"; then
		return 0
	fi

	log 'Locating Cabal layers'

	local updated_name=$(
		list_stored_files "${platform}/${archive_prefix}" |
		sed "s:^${platform}/::" |
		match_updated_cabal_archive_name "${tag}"
	) || return 1

	log 'Restoring Cabal layer'

	if ! cache_stored_file "${platform}" "${updated_name}" ||
		! extract_cached_archive_over "${updated_name}" "${HALCYON_BASE}/cabal" ||
		! validate_updated_cabal_layer "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_BASE}/cabal" || die
		return 1
	fi
}


link_cabal_config () {
	expect_vars HOME HALCYON_BASE \
		HALCYON_INTERNAL_RECURSIVE
	expect_existing "${HOME}"

	if [[ ! -f "${HALCYON_BASE}/cabal/.halcyon-tag" ]] || (( HALCYON_INTERNAL_RECURSIVE )); then
		return 0
	fi

	if [[ -d "${HOME}/.cabal" && -e "${HOME}/.cabal/config" ]]; then
		local actual_config
		actual_config=$( readlink "${HOME}/.cabal/config" ) || die
		if [[ "${actual_config}" != "${HALCYON_BASE}/cabal/.halcyon-cabal.config" ]]; then
			log_warning 'Unexpected existing Cabal config'
			log
			log 'To use recommended Cabal config:'
			log_indent '$ rm ~/.cabal/config'
			log_indent "$ ln -s ${HALCYON_BASE}/cabal/.halcyon-cabal.config ~/.cabal/config"
			log
			return 0
		fi
	fi

	# NOTE: Creating config links is necessary to allow the user to easily run Cabal commands,
	# without having to use cabal_do or sandboxed_cabal_do.

	rm -f "${HOME}/.cabal/config" || die
	mkdir -p "${HOME}/.cabal" || die
	ln -s "${HALCYON_BASE}/cabal/.halcyon-cabal.config" "${HOME}/.cabal/config" || die
}


install_cabal_layer () {
	expect_vars HALCYON_NO_BUILD HALCYON_NO_BUILD_DEPENDENCIES \
		HALCYON_CABAL_REBUILD HALCYON_CABAL_UPDATE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_CABAL_REBUILD )); then
		if ! (( HALCYON_CABAL_UPDATE )) &&
			restore_updated_cabal_layer "${tag}"
		then
			link_cabal_config || die
			return 0
		fi

		if restore_base_cabal_layer "${tag}"; then
			update_cabal_package_db "${tag}" || die
			archive_cabal_layer || die
			link_cabal_config || die
			return 0
		fi

		if (( HALCYON_NO_BUILD )) || (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_warning 'Cannot build Cabal layer'
			return 1
		fi
	fi

	build_cabal_layer "${tag}" "${source_dir}" || die
	archive_cabal_layer || die
	update_cabal_package_db "${tag}" || die
	archive_cabal_layer || die
	link_cabal_config || die
}


cabal_do () {
	expect_vars HALCYON_BASE
	expect_existing "${HALCYON_BASE}/cabal/.halcyon-tag"

	local work_dir
	expect_args work_dir -- "$@"
	expect_existing "${work_dir}"
	shift

	(
		cd "${work_dir}" &&
		cabal --config-file="${HALCYON_BASE}/cabal/.halcyon-cabal.config" "$@"
	) || return 1
}


sandboxed_cabal_do () {
	expect_vars HALCYON_BASE

	local work_dir
	expect_args work_dir -- "$@"
	expect_existing "${HALCYON_BASE}/sandbox" "${work_dir}"
	shift

	# NOTE: Specifying a cabal.sandbox.config file changes where Cabal looks for
	# a cabal.config file.
	# https://github.com/haskell/cabal/issues/1915

	local saved_config
	saved_config=''
	if [[ -f "${HALCYON_BASE}/sandbox/cabal.config" ]]; then
		saved_config=$( get_tmp_file 'halcyon-saved-config' ) || die
		mv "${HALCYON_BASE}/sandbox/cabal.config" "${saved_config}" || die
	fi
	if [[ -f "${work_dir}/cabal.config" ]]; then
		copy_file "${work_dir}/cabal.config" "${HALCYON_BASE}/sandbox/cabal.config" || die
	fi

	local status
	status=0
	if ! (
		cabal_do "${work_dir}" --sandbox-config-file="${HALCYON_BASE}/sandbox/.halcyon-sandbox.config" "$@"
	); then
		status=1
	fi

	rm -f "${HALCYON_BASE}/sandbox/cabal.config" || die
	if [[ -n "${saved_config}" ]]; then
		mv "${saved_config}" "${HALCYON_BASE}/sandbox/cabal.config" || die
	fi

	return "${status}"
}


cabal_freeze_implicit_constraints () {
	local label source_dir
	expect_args label source_dir -- "$@"

	# NOTE: Cabal automatically sets global installed constraints for installed packages, even
	# during a dry run.  Hence, if a local constraint conflicts with an installed package,
	# Cabal will fail to resolve dependencies.
	# https://github.com/haskell/cabal/issues/2178

	local stderr
	stderr=$( get_tmp_file 'halcyon-cabal-freeze-stderr' ) || die

	local constraints
	if ! constraints=$(
		cabal_do "${source_dir}" --no-require-sandbox freeze --dry-run 2>"${stderr}" |
		read_dry_frozen_constraints |
		filter_correct_constraints "${label}" |
		sort_natural
	); then
		quote <"${stderr}" || die
		die 'Failed to freeze implicit constraints'
	fi

	rm -f "${stderr}" || die

	echo "${constraints}"
}


cabal_freeze_actual_constraints () {
	local label source_dir
	expect_args label source_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'halcyon-cabal-freeze-stderr' ) || die

	local constraints
	if ! constraints=$(
		sandboxed_cabal_do "${source_dir}" freeze --dry-run 2>"${stderr}" |
		read_dry_frozen_constraints |
		filter_correct_constraints "${label}" |
		sort_natural
	); then
		quote <"${stderr}" || die
		die 'Failed to freeze actual constraints'
	fi

	rm -f "${stderr}" || die

	echo "${constraints}"
}


cabal_unpack_over () {
	local thing unpack_dir
	expect_args thing unpack_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'halcyon-unpack-stderr' ) || die

	rm -rf "${unpack_dir}" || die
	mkdir -p "${unpack_dir}" || die

	local label
	if ! label=$(
		cabal_do "${unpack_dir}" unpack "${thing}" 2>"${stderr}" |
		filter_matching '^Unpacking to ' |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		quote <"${stderr}" || die
		die 'Failed to unpack app'
	fi

	rm -rf "${stderr}" || die

	echo "${label}"
}
