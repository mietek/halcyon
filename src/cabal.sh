map_cabal_version_to_original_url () {
	local cabal_version
	expect_args cabal_version -- "$@"

	case "${cabal_version}" in
	'1.20.0.3')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.20.0.3/cabal-install-1.20.0.3.tar.gz';;
	'1.20.0.2')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.20.0.2/cabal-install-1.20.0.2.tar.gz';;
	'1.20.0.1')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.20.0.1/cabal-install-1.20.0.1.tar.gz';;
	'1.20.0.0')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.20.0.0/cabal-install-1.20.0.0.tar.gz';;
	'1.18.0.3')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.18.0.3/cabal-install-1.18.0.3.tar.gz';;
	'1.18.0.2')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.18.0.2/cabal-install-1.18.0.2.tar.gz';;
	'1.18.0.1')	echo 'https://www.haskell.org/cabal/release/cabal-install-1.18.0.1/cabal-install-1.18.0.1.tar.gz';;
	*)		die "Unexpected Cabal version: ${cabal_version}"
	esac
}


create_cabal_tag () {
	local cabal_version cabal_magic_hash cabal_repo cabal_date
	expect_args cabal_version cabal_magic_hash cabal_repo cabal_date -- "$@"

	create_tag '' '' \
		'' '' \
		'' '' \
		"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${cabal_date}" \
		'' '' || die
}


detect_cabal_tag () {
	expect_vars HALCYON_DIR

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


derive_bare_cabal_tag () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' || die
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

	echo "${cabal_id} (${repo_name}${cabal_date:+ ${cabal_date}})"
}


format_cabal_config () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local cabal_repo
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	cat <<-EOF
		remote-repo:        ${cabal_repo}
		remote-repo-cache:  ${HALCYON_DIR}/cabal/remote-repo-cache
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

	echo "halcyon-cabal-${cabal_id}-${repo_name}${cabal_date:+-${cabal_date}}.tar.gz"
}


format_bare_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}.tar.gz"
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

	hash_tree "${source_dir}/.halcyon-magic" \
		-path './cabal*' || die
}


copy_cabal_magic () {
	expect_vars HALCYON_DIR

	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${HALCYON_DIR}/cabal"

	local cabal_magic_hash
	cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || die
	if [[ -z "${cabal_magic_hash}" ]]; then
		return 0
	fi

	find_tree "${source_dir}/.halcyon-magic" -type f \
		-path './cabal*' |
			while read -r file; do
				copy_file "${source_dir}/.halcyon-magic/${file}" \
					"${HALCYON_DIR}/cabal/.halcyon-magic/${file}" || die
			done || die
}


build_cabal_layer () {
	expect_vars HOME HALCYON_DIR
	expect_existing "${HOME}"

	local tag source_dir
	expect_args tag source_dir -- "$@"

	local ghc_version cabal_version original_url original_name cabal_dir
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	original_url=$( map_cabal_version_to_original_url "${cabal_version}" ) || die
	original_name=$( basename "${original_url}" ) || die
	cabal_dir=$( get_tmp_dir 'halcyon-cabal-source' ) || die

	log 'Building Cabal layer'

	if [[ -d "${HOME}/.ghc" && ! -f "${HOME}/.ghc/.halcyon-mark" ]]; then
		log_error 'Unexpected existing ~/.ghc'
		log
		log 'To continue, remove ~/.ghc and ~/.cabal'
		die
	fi
	if [[ -d "${HOME}/.cabal" && ! -f "${HOME}/.cabal/.halcyon-mark" ]]; then
		log_error 'Unexpected existing ~/.cabal'
		log
		log 'To continue, remove ~/.ghc and ~/.cabal'
		die
	fi
	rm -rf "${HOME}/.ghc" "${HOME}/.cabal" "${HALCYON_DIR}/cabal" || die

	if ! extract_cached_archive_over "${original_name}" "${cabal_dir}"; then
		if ! cache_original_stored_file "${original_url}"; then
			die 'Cannot download original Cabal archive'
		fi
		if ! extract_cached_archive_over "${original_name}" "${cabal_dir}"; then
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
					"${cabal_dir}/cabal-install-${cabal_version}" |& quote
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
			cd "${cabal_dir}/cabal-install-${cabal_version}" &&
			patch -s <<-EOF
				--- a/bootstrap.sh
				+++ b/bootstrap.sh
				@@ -217,3 +217,3 @@ install_pkg () {

				-  \${GHC} --make Setup -o Setup ||
				+  \${GHC} -L"${HALCYON_DIR}/ghc/lib" --make Setup -o Setup ||
				      die "Compiling the Setup script failed."
EOF
		) || die
		;;
	*)
		rm -rf "${cabal_dir}" || die
		die "Unexpected Cabal version for GHC ${ghc_version}: ${cabal_version}"
	esac

	mkdir -p "${HOME}/.ghc" "${HOME}/.cabal" || die
	touch "${HOME}/.ghc/.halcyon-mark" || die
	touch "${HOME}/.cabal/.halcyon-mark" || die

	# NOTE: Bootstrapping cabal-install with GHC 7.8.[23] may fail unless --no-doc
	# is specified.
	# https://ghc.haskell.org/trac/ghc/ticket/9174

	if ! (
		cd "${cabal_dir}/cabal-install-${cabal_version}" &&
		EXTRA_CONFIGURE_OPTS="--extra-lib-dirs=${HALCYON_DIR}/ghc/lib" \
			./bootstrap.sh --no-doc |& quote
	); then
		die 'Failed to bootstrap Cabal'
	fi

	copy_file "${HOME}/.cabal/bin/cabal" "${HALCYON_DIR}/cabal/bin/cabal" || die
	format_cabal_config "${tag}" >"${HALCYON_DIR}/cabal/.halcyon-cabal.config" || die

	copy_cabal_magic "${source_dir}" || die

	local bootstrapped_size
	bootstrapped_size=$( get_size "${HALCYON_DIR}/cabal" ) || die

	log "Cabal bootstrapped, ${bootstrapped_size}"

	if [[ -f "${source_dir}/.halcyon-magic/cabal-post-build-hook" ]]; then
		log 'Executing Cabal post-build hook'
		if ! (
			HALCYON_INTERNAL_RECURSIVE=1 \
				"${source_dir}/.halcyon-magic/cabal-post-build-hook" \
					"${tag}" "${source_dir}" \
					"${cabal_dir}/cabal-install-${cabal_version}" |& quote
		); then
			die 'Failed to execute Cabal post-build hook'
		fi
		log 'Cabal post-build hook executed'
	fi

	log_indent_begin 'Stripping Cabal layer...'

	strip_tree "${HALCYON_DIR}/cabal" || die

	local stripped_size
	stripped_size=$( get_size "${HALCYON_DIR}/cabal" ) || die
	log_end "done, ${stripped_size}"

	derive_bare_cabal_tag "${tag}" >"${HALCYON_DIR}/cabal/.halcyon-tag" || die

	rm -rf "${HOME}/.ghc" "${HOME}/.cabal" "${cabal_dir}" || die
}


update_cabal_layer () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	log 'Updating Cabal layer'

	if ! cabal_do '.' update |& quote; then
		die 'Failed to update Cabal layer'
	fi

	local cabal_tag cabal_date
	cabal_tag=$( detect_cabal_tag "${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	cabal_date=$( get_date ) || die

	local updated_size
	updated_size=$( get_size "${HALCYON_DIR}/cabal" ) || die

	log "Cabal layer updated, ${updated_size}"

	derive_updated_cabal_tag "${cabal_tag}" "${cabal_date}" >"${HALCYON_DIR}/cabal/.halcyon-tag" || die
}


archive_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_ARCHIVE HALCYON_NO_DELETE
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local cabal_tag platform archive_name
	cabal_tag=$( detect_cabal_tag "${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	platform=$( get_tag_platform "${cabal_tag}" ) || die
	archive_name=$( format_cabal_archive_name "${cabal_tag}" ) || die

	log 'Archiving Cabal layer'

	create_cached_archive "${HALCYON_DIR}/cabal" "${archive_name}" || die
	if ! upload_cached_file "${platform}" "${archive_name}"; then
		return 0
	fi

	local cabal_date
	cabal_date=$( get_tag_cabal_date "${cabal_tag}" ) || die
	if [[ -z "${cabal_date}" ]] || (( HALCYON_NO_DELETE )); then
		return 0
	fi

	local updated_prefix updated_pattern
	updated_prefix=$( format_updated_cabal_archive_name_prefix "${cabal_tag}" ) || die
	updated_pattern=$( format_updated_cabal_archive_name_pattern "${cabal_tag}" ) || die

	delete_matching_private_stored_files "${platform}" "${updated_prefix}" "${updated_pattern}" "${archive_name}" || die
}


validate_bare_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local bare_tag
	bare_tag=$( derive_bare_cabal_tag "${tag}" ) || die
	detect_tag "${HALCYON_DIR}/cabal/.halcyon-tag" "${bare_tag//./\.}" || return 1
}


validate_updated_cabal_date () {
	local candidate_date
	expect_args candidate_date -- "$@"

	local today_date
	today_date=$( get_date ) || die

	if [[ "${candidate_date}" < "${today_date}" ]]; then
		return 1
	fi
}


validate_updated_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local updated_pattern candidate_tag
	updated_pattern=$( derive_updated_cabal_tag_pattern "${tag}" ) || die
	candidate_tag=$( detect_tag "${HALCYON_DIR}/cabal/.halcyon-tag" "${updated_pattern}" ) || return 1

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


restore_bare_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local platform bare_name description
	platform=$( get_tag_platform "${tag}" ) || die
	bare_name=$( format_bare_cabal_archive_name "${tag}" ) || die
	description=$( format_cabal_description "${tag}" ) || die

	if validate_bare_cabal_layer "${tag}" >'/dev/null'; then
		log_label 'Using existing Cabal layer:' "${description}"
		touch_cached_file "${bare_name}" || die
		return 0
	fi

	log 'Restoring Cabal layer'

	if ! extract_cached_archive_over "${bare_name}" "${HALCYON_DIR}/cabal" ||
		! validate_bare_cabal_layer "${tag}" >'/dev/null'
	then
		if ! cache_stored_file "${platform}" "${bare_name}" ||
			! extract_cached_archive_over "${bare_name}" "${HALCYON_DIR}/cabal" ||
			! validate_bare_cabal_layer "${tag}" >'/dev/null'
		then
			return 1
		fi
	else
		touch_cached_file "${bare_name}" || die
	fi

	log_label 'Cabal layer restored:' "${description}"
}


restore_cached_updated_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local updated_name
	updated_name=$(
		find_tree "${HALCYON_CACHE_DIR}" -maxdepth 1 -type f 2>'/dev/null' |
		match_updated_cabal_archive_name "${tag}"
	) || true

	local restored_tag description
	if restored_tag=$( validate_updated_cabal_layer "${tag}" ); then
		description=$( format_cabal_description "${restored_tag}" ) || die

		log_label 'Using existing updated Cabal layer:' "${description}"
		touch_cached_file "${updated_name}" || die
		return 0
	fi

	if [[ -z "${updated_name}" ]]; then
		return 1
	fi

	log 'Restoring Cabal layer'

	if ! extract_cached_archive_over "${updated_name}" "${HALCYON_DIR}/cabal" ||
		! restored_tag=$( validate_updated_cabal_layer "${tag}" )
	then
		return 1
	else
		touch_cached_file "${updated_name}" || die
	fi
	description=$( format_cabal_description "${restored_tag}" ) || die

	log_label 'Cabal layer restored:' "${description}"
}


restore_updated_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	local platform archive_prefix
	platform=$( get_tag_platform "${tag}" ) || die
	archive_prefix=$( format_updated_cabal_archive_name_prefix "${tag}" ) || die

	if restore_cached_updated_cabal_layer "${tag}"; then
		return 0
	fi

	log 'Locating Cabal layers'

	local updated_name
	updated_name=$(
		list_stored_files "${platform}/${archive_prefix}" |
		sed "s:${platform}/::" |
		match_updated_cabal_archive_name "${tag}"
	) || return 1

	log 'Restoring Cabal layer'

	local restored_tag description
	if ! cache_stored_file "${platform}" "${updated_name}" ||
		! extract_cached_archive_over "${updated_name}" "${HALCYON_DIR}/cabal" ||
		! restored_tag=$( validate_updated_cabal_layer "${tag}" )
	then
		rm -rf "${HALCYON_DIR}/cabal" || die
		return 1
	fi
	description=$( format_cabal_description "${restored_tag}" ) || die

	log_label 'Cabal layer restored:' "${description}"
}


announce_cabal_layer () {
	local tag
	expect_args tag -- "$@"

	local installed_tag description
	installed_tag=$( validate_updated_cabal_layer "${tag}" ) || die
	description=$( format_cabal_description "${installed_tag}" ) || die

	log_label 'Cabal layer installed:' "${description}"

	export HALCYON_FORCE_BUILD_CABAL=0
	export HALCYON_FORCE_UPDATE_CABAL=0
}


link_cabal_config () {
	expect_vars HOME HALCYON_DIR
	expect_existing "${HOME}" "${HALCYON_DIR}/cabal/.halcyon-tag"

	if [[ -d "${HOME}/.cabal" && ! -f "${HOME}/.cabal/.halcyon-mark" ]]; then
		log_error 'Unexpected existing ~/.cabal'
		log
		log 'To continue, remove ~/.cabal'
		die
	fi

	# NOTE: Creating config links is necessary to allow the user to easily run Cabal commands,
	# without having to use cabal_do or sandboxed_cabal_do.

	rm -f "${HOME}/.cabal/config" || die
	mkdir -p "${HOME}/.cabal" || die
	touch "${HOME}/.cabal/.halcyon-mark" || die
	ln -s "${HALCYON_DIR}/cabal/.halcyon-cabal.config" "${HOME}/.cabal/config" || die
}


install_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD_DEPENDENCIES HALCYON_FORCE_BUILD_CABAL HALCYON_FORCE_UPDATE_CABAL

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_BUILD_CABAL )); then
		if ! (( HALCYON_FORCE_UPDATE_CABAL )) &&
			restore_updated_cabal_layer "${tag}"
		then
			link_cabal_config || die
			return 0
		fi

		if restore_bare_cabal_layer "${tag}"; then
			update_cabal_layer || die
			archive_cabal_layer || die
			announce_cabal_layer "${tag}" || die
			link_cabal_config || die
			return 0
		fi

		if (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_warning 'Cannot build Cabal layer'
			return 1
		fi
	fi

	build_cabal_layer "${tag}" "${source_dir}" || die
	archive_cabal_layer || die
	update_cabal_layer || die
	archive_cabal_layer || die
	announce_cabal_layer "${tag}" || die
	link_cabal_config || die
}


cabal_do () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local work_dir
	expect_args work_dir -- "$@"
	expect_existing "${work_dir}"
	shift

	(
		cd "${work_dir}" &&
		cabal --config-file="${HALCYON_DIR}/cabal/.halcyon-cabal.config" "$@"
	) || return 1
}


sandboxed_cabal_do () {
	expect_vars HALCYON_DIR

	local work_dir
	expect_args work_dir -- "$@"
	expect_existing "${HALCYON_DIR}/sandbox" "${work_dir}"
	shift

	# NOTE: Specifying a cabal.sandbox.config file changes where Cabal looks for
	# a cabal.config file.
	# https://github.com/haskell/cabal/issues/1915

	local saved_config
	saved_config=''
	if [[ -f "${HALCYON_DIR}/sandbox/cabal.config" ]]; then
		saved_config=$( get_tmp_file 'halcyon-saved-config' ) || die
		mv "${HALCYON_DIR}/sandbox/cabal.config" "${saved_config}" || die
	fi
	if [[ -f "${work_dir}/cabal.config" ]]; then
		copy_file "${work_dir}/cabal.config" "${HALCYON_DIR}/sandbox/cabal.config" || die
	fi

	local status
	status=0
	if ! (
		cabal_do "${work_dir}" --sandbox-config-file="${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" "$@"
	); then
		status=1
	fi

	rm -f "${HALCYON_DIR}/sandbox/cabal.config" || die
	if [[ -n "${saved_config}" ]]; then
		mv "${saved_config}" "${HALCYON_DIR}/sandbox/cabal.config" || die
	fi

	return "${status}"
}


cabal_freeze_implicit_constraints () {
	local app_label source_dir
	expect_args app_label source_dir -- "$@"

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
		filter_correct_constraints "${app_label}" |
		sort_natural
	); then
		quote <"${stderr}" || die
		die 'Failed to freeze implicit constraints'
	fi

	rm -f "${stderr}" || die

	echo "${constraints}"
}


cabal_freeze_actual_constraints () {
	local app_label source_dir
	expect_args app_label source_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'halcyon-cabal-freeze-stderr' ) || die

	local constraints
	if ! constraints=$(
		sandboxed_cabal_do "${source_dir}" freeze --dry-run 2>"${stderr}" |
		read_dry_frozen_constraints |
		filter_correct_constraints "${app_label}" |
		sort_natural
	); then
		quote <"${stderr}" || die
		die 'Failed to freeze actual constraints'
	fi

	rm -f "${stderr}" || die

	echo "${constraints}"
}


cabal_unpack_app () {
	local app work_dir
	expect_args app work_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'halcyon-unpack-stderr' ) || die

	mkdir -p "${work_dir}" || die

	local app_label
	if ! app_label=$(
		cabal_do "${work_dir}" unpack "${app}" 2>"${stderr}" |
		filter_matching '^Unpacking to ' |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		quote <"${stderr}" || die
		die 'Failed to unpack app'
	fi

	rm -rf "${stderr}" || die

	echo "${app_label}"
}
