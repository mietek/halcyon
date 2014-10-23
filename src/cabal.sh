function get_default_cabal_version () {
	echo '1.20.0.3'
}


function get_default_cabal_repo () {
	echo 'Hackage:http://hackage.haskell.org/packages/archive'
}


function map_cabal_version_to_original_url () {
	local cabal_version
	expect_args cabal_version -- "$@"

	case "${cabal_version}" in
	'1.20.0.3')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.20.0.3/cabal-install-1.20.0.3.tar.gz';;
	'1.20.0.2')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.20.0.2/cabal-install-1.20.0.2.tar.gz';;
	'1.20.0.1')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.20.0.1/cabal-install-1.20.0.1.tar.gz';;
	'1.20.0.0')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.20.0.0/cabal-install-1.20.0.0.tar.gz';;
	'1.18.0.3')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.18.0.3/cabal-install-1.18.0.3.tar.gz';;
	'1.18.0.2')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.18.0.2/cabal-install-1.18.0.2.tar.gz';;
	'1.18.0.1')	echo 'http://www.haskell.org/cabal/release/cabal-install-1.18.0.1/cabal-install-1.18.0.1.tar.gz';;
	*)		die "Unexpected Cabal version: ${cabal_version}"
	esac
}


function create_cabal_tag () {
	local cabal_version cabal_magic_hash cabal_repo update_timestamp
	expect_args cabal_version cabal_magic_hash cabal_repo update_timestamp -- "$@"

	create_tag '' '' '' '' \
		'' '' \
		"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${update_timestamp}" \
		'' \
		'' || die
}


function derive_bare_cabal_tag () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' || die
}


function derive_updated_cabal_tag () {
	local tag update_timestamp
	expect_args tag update_timestamp -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${update_timestamp}" || die
}


function derive_updated_cabal_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	create_cabal_tag "${cabal_version//./\.}" "${cabal_magic_hash}" "${cabal_repo//.\.}" '.*' || die
}


function format_cabal_id () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die

	echo "${cabal_version}${cabal_magic_hash:+-${cabal_magic_hash:0:7}}"
}


function format_cabal_repo_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_repo
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	echo "${cabal_repo%%:*}"
}


function format_cabal_description () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name update_timestamp
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" ) || die
	update_timestamp=$( get_tag_update_timestamp "${tag}" ) || die
	if [ -z "${update_timestamp}" ]; then
		echo "${cabal_id} (${repo_name})"
		return 0
	fi

	local timestamp_date timestamp_time
	timestamp_date=$( get_timestamp_date "${update_timestamp}" ) || die
	timestamp_time=$( get_timestamp_time "${update_timestamp}" ) || die

	echo "${cabal_id} (${repo_name} ${timestamp_date} ${timestamp_time} UTC)"
}


function format_cabal_config () {
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


function format_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name update_timestamp
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die
	update_timestamp=$( get_tag_update_timestamp "${tag}" ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}${update_timestamp:+-${update_timestamp}}.tar.xz"
}


function format_bare_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}.tar.xz"
}


function format_updated_cabal_archive_name_prefix () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}-"
}


function format_updated_cabal_archive_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" ) || die
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id//./\.}-${repo_name//./\.}-.*\.tar\.xz"
}


function map_updated_cabal_archive_name_to_timestamp () {
	local archive_name
	expect_args archive_name -- "$@"

	local timestamp_etc
	timestamp_etc="${archive_name#halcyon-cabal-*-*-}"

	echo "${timestamp_etc%.tar.xz}"
}


function hash_cabal_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	hash_spaceless_recursively "${source_dir}/.halcyon-magic" -name 'cabal*' || die
}


function copy_cabal_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	local cabal_magic_hash
	cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || die
	if [ -z "${cabal_magic_hash}" ]; then
		return 0
	fi

	mkdir -p "${HALCYON_DIR}/cabal/.halcyon-magic" || die
	cp -p "${source_dir}/.halcyon-magic/cabal"* "${HALCYON_DIR}/cabal/.halcyon-magic" || die
}


function build_cabal_layer () {
	expect_vars HOME HALCYON_DIR HALCYON_CACHE_DIR
	expect_existing "${HOME}"
	expect_no_existing "${HALCYON_DIR}/cabal"

	if [ -e "${HOME}/.cabal/config" ] && ! [ -h "${HOME}/.cabal/config" ]; then
		die "Expected no foreign ${HOME}/.cabal/config"
	fi
	rm -f "${HOME}/.cabal/config" || die

	# NOTE: Cabal sometimes creates HOME/.cabal/setup-exe-cache, and there is no way to use a different path.
	# https://github.com/haskell/cabal/issues/1242

	rm -rf "${HOME}/.cabal/setup-exe-cache" || die
	rmdir "${HOME}/.cabal" 2>'/dev/null' || true
	expect_no_existing "${HOME}/.cabal" "${HOME}/.ghc"

	local tag source_dir
	expect_args tag source_dir -- "$@"

	local ghc_version cabal_version original_url original_name build_dir
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	original_url=$( map_cabal_version_to_original_url "${cabal_version}" ) || die
	original_name=$( basename "${original_url}" ) || die
	build_dir=$( get_tmp_dir 'halcyon.cabal' ) || die

	log 'Starting to build Cabal layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${original_name}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${original_name}" "${build_dir}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${original_name}" "${build_dir}" || die
		transfer_original "${original_name}" "${original_url}" "${HALCYON_CACHE_DIR}" || die
		if ! tar_extract "${HALCYON_CACHE_DIR}/${original_name}" "${build_dir}"; then
			rm -rf "${HALCYON_CACHE_DIR}/${original_name}" "${build_dir}" || die
			die 'Cannot extract original archive'
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${original_name}" || true
	fi

	if [ -f "${source_dir}/.halcyon-magic/cabal-prebuild-hook" ]; then
		log 'Running Cabal pre-build hook'
		( "${source_dir}/.halcyon-magic/cabal-prebuild-hook" "${tag}" "${build_dir}/cabal-install-${cabal_version}" ) |& quote || die
	fi

	log 'Bootstrapping Cabal'

	# NOTE: Bootstrapping cabal-install 1.20.0.0 with GHC 7.6.* fails.

	case "${ghc_version}-${cabal_version}" in
	'7.8.'*'-1.20.0.'*)
		(
			cd "${build_dir}/cabal-install-${cabal_version}" &&
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
		rm -rf "${build_dir}" || die
		die "Unexpected Cabal and GHC combination: ${cabal_version} and ${ghc_version}"
	esac

	# NOTE: PATH is extended to silence a misleading Cabal warning.

	# NOTE: Bootstrapping cabal-install with GHC 7.8.[23] may fail unless --no-doc is specified.
	# https://ghc.haskell.org/trac/ghc/ticket/9174

	if ! (
		export PATH="${HOME}/.cabal/bin:${PATH}" &&
		export EXTRA_CONFIGURE_OPTS="--extra-lib-dirs=${HALCYON_DIR}/ghc/lib" &&
		cd "${build_dir}/cabal-install-${cabal_version}" &&
		./bootstrap.sh --no-doc |& quote
	); then
		die 'Failed to bootstrap Cabal'
	fi

	mkdir -p "${HALCYON_DIR}/cabal/bin" || die
	mv "${HOME}/.cabal/bin/cabal" "${HALCYON_DIR}/cabal/bin/cabal" || die
	format_cabal_config "${tag}" >"${HALCYON_DIR}/cabal/.halcyon-cabal-config" || die

	if [ -f "${source_dir}/.halcyon-magic/cabal-postbuild-hook" ]; then
		log 'Running Cabal post-build hook'
		( "${source_dir}/.halcyon-magic/cabal-postbuild-hook" "${tag}" "${build_dir}/cabal-install-${cabal_version}" ) |& quote || die
	fi

	copy_cabal_magic "${source_dir}" || die
	derive_bare_cabal_tag "${tag}" >"${HALCYON_DIR}/cabal/.halcyon-tag" || die

	local layer_size
	layer_size=$( measure_recursively "${HALCYON_DIR}/cabal" ) || die
	log "Finished building Cabal layer... ${layer_size}"

	rm -rf "${HOME}/.cabal" "${HOME}/.ghc" "${build_dir}" || die
}


function update_cabal_layer () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local cabal_tag
	cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die

	log 'Starting to update Cabal layer'

	cabal_do '.' update |& quote || die

	local update_timestamp
	update_timestamp=$( format_timestamp ) || die
	derive_updated_cabal_tag "${cabal_tag}" "${update_timestamp}" >"${HALCYON_DIR}/cabal/.halcyon-tag" || die

	local layer_size
	layer_size=$( measure_recursively "${HALCYON_DIR}/cabal" ) || die
	log "Finished updating Cabal layer... ${layer_size}"
}


function archive_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local cabal_tag os archive_name
	cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	os=$( get_tag_os "${cabal_tag}" ) || die
	archive_name=$( format_cabal_archive_name "${cabal_tag}" ) || die

	log 'Archiving Cabal layer'

	rm -f "${HALCYON_CACHE_DIR}/${archive_name}" || die
	tar_archive "${HALCYON_DIR}/cabal" "${HALCYON_CACHE_DIR}/${archive_name}" || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${archive_name}" "${os}"; then
		log_warning 'Cannot upload Cabal layer archive'
	fi
}


function validate_bare_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ]; then
		return 1
	fi

	local bare_tag candidate_tag
	bare_tag=$( derive_bare_cabal_tag "${tag}" ) || die
	candidate_tag=$( match_exactly_one <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	if [ "${candidate_tag}" != "${bare_tag}" ]; then
		return 1
	fi
}


function validate_updated_cabal_timestamp () {
	local candidate_timestamp
	expect_args candidate_timestamp -- "$@"

	local yesterday_timestamp
	yesterday_timestamp=$( format_timestamp -d yesterday ) || die
	if [[ "${candidate_timestamp}" < "${yesterday_timestamp}" ]]; then
		return 1
	fi
}


function validate_updated_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag
	expect_args tag -- "$@"

	if ! [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ]; then
		return 1
	fi

	local updated_pattern candidate_tag
	updated_pattern=$( derive_updated_cabal_tag_pattern "${tag}" ) || die
	if ! candidate_tag=$(
		filter_matching "^${updated_pattern}$" <"${HALCYON_DIR}/cabal/.halcyon-tag" |
		match_exactly_one
	); then
		return 1
	fi

	local candidate_timestamp
	candidate_timestamp=$( get_tag_update_timestamp "${candidate_tag}" ) || die
	if ! validate_updated_cabal_timestamp "${candidate_timestamp}"; then
		return 1
	fi
}


function match_updated_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local updated_pattern candidate_name
	updated_pattern=$( format_updated_cabal_archive_name_pattern "${tag}" ) || die
	if ! candidate_name=$(
		filter_matching "^${updated_pattern}$" |
		sort_naturally |
		filter_last |
		match_exactly_one
	); then
		return 1
	fi

	local candidate_timestamp
	candidate_timestamp=$( map_updated_cabal_archive_name_to_timestamp "${candidate_name}" ) || die
	if ! validate_updated_cabal_timestamp "${candidate_timestamp}"; then
		return 1
	fi

	echo "${candidate_name}"
}


function restore_bare_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os bare_name
	os=$( get_tag_os "${tag}" ) || die
	bare_name=$( format_bare_cabal_archive_name "${tag}" ) || die

	if validate_bare_cabal_layer "${tag}"; then
		touch -c "${HALCYON_CACHE_DIR}/${bare_name}" || true
		return 0
	fi
	rm -rf "${HALCYON_DIR}/cabal" || die

	log 'Restoring bare Cabal layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${bare_name}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${bare_name}" "${HALCYON_DIR}/cabal" ||
		! validate_bare_cabal_layer "${tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${bare_name}" "${HALCYON_DIR}/cabal" || die
		if ! download_layer "${os}" "${bare_name}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download bare Cabal layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${bare_name}" "${HALCYON_DIR}/cabal" ||
			! validate_bare_cabal_layer "${tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${bare_name}" "${HALCYON_DIR}/cabal" || die
			log_warning 'Cannot extract bare Cabal layer archive'
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${bare_name}" || true
	fi
}


function restore_cached_updated_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local updated_name
	updated_name=$(
		find_spaceless_recursively "${HALCYON_CACHE_DIR}" |
		match_updated_cabal_archive_name "${tag}"
	) || true

	if validate_updated_cabal_layer "${tag}"; then
		touch -c "${HALCYON_CACHE_DIR}/${updated_name}" || true
		return 0
	fi
	rm -rf "${HALCYON_DIR}/cabal" || die

	if [ -z "${updated_name}" ]; then
		return 1
	fi

	if ! tar_extract "${HALCYON_CACHE_DIR}/${updated_name}" "${HALCYON_DIR}/cabal" ||
		! validate_updated_cabal_layer "${tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${updated_name}" "${HALCYON_DIR}/cabal" || die
		return 1
	else
		touch -c "${HALCYON_CACHE_DIR}/${updated_name}" || true
	fi
}


function restore_updated_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local tag
	expect_args tag -- "$@"

	local os archive_prefix
	os=$( get_tag_os "${tag}" ) || die
	archive_prefix=$( format_updated_cabal_archive_name_prefix "${tag}" ) || die

	if restore_cached_updated_cabal_layer "${tag}"; then
		return 0
	fi

	log 'Locating updated Cabal layers'

	local archive_names
	if ! archive_names=$(
		list_layer "${os}/${archive_prefix}" |
		sed "s:${os}/::" |
		match_at_least_one
	); then
		log 'Cannot locate any updated Cabal layer archives'
		return 1
	fi

	local updated_name
	updated_name=$( match_updated_cabal_archive_name "${tag}" <<<"${archive_names}" ) || true

	if has_private_storage; then
		local old_names
		if old_names=$(
			filter_not_matching "^${updated_name//./\.}$" <<<"${archive_names}" |
			match_at_least_one
		); then
			log 'Cleaning Cabal layer archives'

			local old_name
			while read -r old_name; do
				delete_layer "${os}" "${old_name}" || true
			done <<<"${old_names}"
		fi
	fi

	if [ -z "${updated_name}" ]; then
		log 'Cannot locate any updated Cabal layer archives'
		return 1
	fi

	log 'Restoring updated Cabal layer'

	rm -rf "${HALCYON_CACHE_DIR}/${updated_name}" "${HALCYON_DIR}/cabal" || die
	if ! download_layer "${os}" "${updated_name}" "${HALCYON_CACHE_DIR}"; then
		log_warning 'Cannot download updated Cabal layer archive'
		return 1
	fi

	if ! tar_extract "${HALCYON_CACHE_DIR}/${updated_name}" "${HALCYON_DIR}/cabal" ||
		! validate_updated_cabal_layer "${tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${updated_name}" "${HALCYON_DIR}/cabal" || die
		log_warning 'Cannot extract updated Cabal layer archive'
		return 1
	fi
}


function install_cabal_layer () {
	expect_vars HALCYON_DIR HALCYON_FORCE_CABAL HALCYON_UPDATE_CABAL HALCYON_NO_BUILD

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_FORCE_CABAL )) && ! (( HALCYON_UPDATE_CABAL )) && restore_updated_cabal_layer "${tag}"; then
		return 0
	fi

	if ! (( HALCYON_FORCE_CABAL )) && restore_bare_cabal_layer "${tag}"; then
		update_cabal_layer || die
		archive_cabal_layer || die
		return 0
	fi

	if ! (( HALCYON_FORCE_CABAL )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build Cabal layer'
		return 1
	fi

	rm -rf "${HALCYON_DIR}/cabal" || die
	build_cabal_layer "${tag}" "${source_dir}" || die
	archive_cabal_layer || die
	update_cabal_layer || die
	archive_cabal_layer || die
}


function deploy_cabal_layer () {
	expect_vars HALCYON_DIR

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! install_cabal_layer "${tag}" "${source_dir}"; then
		return 1
	fi
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local cabal_tag description
	cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	description=$( format_cabal_description "${cabal_tag}" ) || die

	log 'Cabal layer deployed:'
	log_indent "${description}"
}


function cabal_do () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local work_dir
	expect_args work_dir -- "$@"
	expect_existing "${work_dir}"
	shift

	if ! ( cd "${work_dir}" && cabal --config-file="${HALCYON_DIR}/cabal/.halcyon-cabal-config" "$@" ); then
		die 'Failed to run Cabal:' "$@"
	fi
}


function sandboxed_cabal_do () {
	expect_vars HALCYON_DIR

	local work_dir
	expect_args work_dir -- "$@"
	expect_existing "${HALCYON_DIR}/sandbox" "${work_dir}"
	shift

	# NOTE: Specifying a cabal.sandbox.config file changes where Cabal looks for a cabal.config file.
	# https://github.com/haskell/cabal/issues/1915

	local saved_config
	saved_config=
	if [ -f "${HALCYON_DIR}/sandbox/cabal.config" ]; then
		saved_config=$( get_tmp_file 'halcyon.saved-config' ) || die
		mv "${HALCYON_DIR}/sandbox/cabal.config" "${saved_config}" || die
	fi
	if [ -f "${work_dir}/cabal.config" ]; then
		cp -p "${work_dir}/cabal.config" "${HALCYON_DIR}/sandbox/cabal.config" || die
	fi

	local status
	status=0
	if ! cabal_do "${work_dir}" --sandbox-config-file="${HALCYON_DIR}/sandbox/.halcyon-sandbox-config" "$@"; then
		status=1
	fi

	rm -f "${HALCYON_DIR}/sandbox/cabal.config" || die
	if [ -n "${saved_config}" ]; then
		mv "${saved_config}" "${HALCYON_DIR}/sandbox/cabal.config" || die
	fi

	return "${status}"
}
