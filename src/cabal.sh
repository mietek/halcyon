function echo_cabal_original_url () {
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


function echo_default_cabal_version () {
	echo '1.20.0.3'
}


function echo_default_cabal_remote_repo () {
	echo 'Hackage:http://hackage.haskell.org/packages/archive'
}


function echo_cabal_tag () {
	expect_vars HALCYON_DIR

	local cabal_version remote_repo magic_hash cabal_timestamp
	expect_args cabal_version remote_repo magic_hash cabal_timestamp -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${os}\t${HALCYON_DIR}\tcabal-${cabal_version}\t${remote_repo}\t${magic_hash}\t${cabal_timestamp}"
}


function echo_cabal_os () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${cabal_tag}"
}


function echo_cabal_halcyon_dir () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	awk -F$'\t' '{ print $2 }' <<<"${cabal_tag}"
}


function echo_cabal_version () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	awk -F$'\t' '{ print $3 }' <<<"${cabal_tag}" | sed 's/^cabal-//'
}


function echo_cabal_remote_repo () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	awk -F$'\t' '{ print $4 }' <<<"${cabal_tag}"
}


function echo_cabal_magic_hash () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	awk -F$'\t' '{ print $5 }' <<<"${cabal_tag}"
}


function echo_cabal_timestamp () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	awk -F$'\t' '{ print $6 }' <<<"${cabal_tag}"
}


function echo_cabal_id () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local cabal_version magic_hash
	cabal_version=$( echo_cabal_version "${cabal_tag}" ) || die
	magic_hash=$( echo_cabal_magic_hash "${cabal_tag}" ) || die

	echo "${cabal_version}${magic_hash:+~${magic_hash:0:7}}"
}


function echo_cabal_remote_repo_name () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local remote_repo
	remote_repo=$( echo_cabal_remote_repo "${cabal_tag}" ) || die

	echo "${remote_repo%%:*}"
}


function echo_cabal_timestamp_date () {
	local cabal_timestamp
	expect_args cabal_timestamp -- "$@"

	echo "${cabal_timestamp:0:4}-${cabal_timestamp:4:2}-${cabal_timestamp:6:2}"
}


function echo_cabal_timestamp_time () {
	local cabal_timestamp
	expect_args cabal_timestamp -- "$@"

	echo "${cabal_timestamp:8:2}:${cabal_timestamp:10:2}:${cabal_timestamp:12:2}"
}


function echo_cabal_description () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local cabal_id repo_name cabal_timestamp
	cabal_id=$( echo_cabal_id "${cabal_tag}" ) || die
	repo_name=$( echo_cabal_remote_repo_name "${cabal_tag}" ) || die
	cabal_timestamp=$( echo_cabal_timestamp "${cabal_tag}" ) || die
	if [ -z "${cabal_timestamp}" ]; then
		echo "${cabal_id} with ${repo_name}"
		return 0
	fi

	local timestamp_date timestamp_time
	timestamp_date=$( echo_cabal_timestamp_date "${cabal_timestamp}" ) || die
	timestamp_time=$( echo_cabal_timestamp_time "${cabal_timestamp}" ) || die

	echo "${cabal_id} (${repo_name} ${timestamp_date} ${timestamp_time} UTC)"
}


function echo_cabal_config () {
	expect_vars HALCYON_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local remote_repo
	remote_repo=$( echo_cabal_remote_repo "${cabal_tag}" ) || die

	cat <<-EOF
		remote-repo:        ${remote_repo}
		remote-repo-cache:  ${HALCYON_DIR}/cabal/remote-repo-cache
		avoid-reinstalls:   True
		reorder-goals:      True
		require-sandbox:    True
		jobs:               \$ncpus
EOF
}


function echo_cabal_archive_name () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local cabal_id repo_name cabal_timestamp
	cabal_id=$( echo_cabal_id "${cabal_tag}" ) || die
	repo_name=$( echo_cabal_remote_repo_name "${cabal_tag}" | tr '[:upper:]' '[:lower:]' ) || die
	cabal_timestamp=$( echo_cabal_timestamp "${cabal_tag}" ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}${cabal_timestamp:+-${cabal_timestamp}}.tar.xz"
}


function echo_updated_cabal_archive_name_prefix () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( echo_cabal_id "${cabal_tag}" ) || die
	repo_name=$( echo_cabal_remote_repo_name "${cabal_tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id}-${repo_name}-"
}


function echo_updated_cabal_archive_name_pattern () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( echo_cabal_id "${cabal_tag}" ) || die
	repo_name=$( echo_cabal_remote_repo_name "${cabal_tag}" | tr '[:upper:]' '[:lower:]' ) || die

	echo "halcyon-cabal-${cabal_id//./\.}-${repo_name}-.*\.tar\.xz"
}


function echo_timestamp_from_updated_cabal_archive_name () {
	local cabal_archive
	expect_args cabal_archive -- "$@"

	local timestamp_etc
	timestamp_etc="${cabal_archive#halcyon-cabal-*-*-}"

	echo "${timestamp_etc%.tar.xz}"
}


function derive_updated_cabal_tag () {
	expect_vars HALCYON_DIR

	local cabal_tag cabal_timestamp
	expect_args cabal_tag cabal_timestamp -- "$@"

	local cabal_version remote_repo magic_hash
	cabal_version=$( echo_cabal_version "${cabal_tag}" ) || die
	remote_repo=$( echo_cabal_remote_repo "${cabal_tag}" ) || die
	magic_hash=$( echo_cabal_magic_hash "${cabal_tag}" ) || die

	echo_cabal_tag "${cabal_version}" "${remote_repo}" "${magic_hash}" "${cabal_timestamp}" || die
}


function validate_cabal_tag () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	if [ "${candidate_tag}" != "${cabal_tag}" ]; then
		return 1
	fi
}


function validate_cabal_magic () {
	local magic_hash app_dir
	expect_args magic_hash app_dir -- "$@"

	local candidate_hash
	candidate_hash=$( hash_spaceless_recursively "${app_dir}/.halcyon-magic" -name 'cabal-*' ) || die

	if [ "${candidate_hash}" != "${magic_hash}" ]; then
		return 1
	fi
}


function validate_cabal () {
	expect_vars HALCYON_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local magic_hash
	magic_hash=$( echo_cabal_magic_hash "${cabal_tag}" ) || die

	if ! [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ] ||
		! validate_cabal_tag "${cabal_tag}" <"${HALCYON_DIR}/cabal/.halcyon-tag" ||
		! validate_cabal_magic "${magic_hash}" "${HALCYON_DIR}/cabal"
	then
		return 1
	fi
}


function validate_updated_cabal_timestamp () {
	local candidate_timestamp
	expect_args candidate_timestamp -- "$@"

	local yesterday_timestamp
	yesterday_timestamp=$( echo_timestamp -d yesterday ) || die

	if [[ "${candidate_timestamp}" < "${yesterday_timestamp}" ]]; then
		return 1
	fi
}


function validate_updated_cabal_tag () {
	expect_vars HALCYON_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	local os cabal_version remote_repo magic_hash
	os=$( echo_cabal_os "${cabal_tag}" ) || die
	cabal_version=$( echo_cabal_version "${cabal_tag}" ) || die
	remote_repo=$( echo_cabal_remote_repo "${cabal_tag}" ) || die
	magic_hash=$( echo_cabal_magic_hash "${cabal_tag}" ) || die

	local candidate_os candidate_dir candidate_version candidate_repo candidate_hash
	candidate_os=$( echo_cabal_os "${candidate_tag}" ) || die
	candidate_dir=$( echo_cabal_halcyon_dir "${candidate_tag}" ) || die
	candidate_version=$( echo_cabal_version "${candidate_tag}" ) || die
	candidate_repo=$( echo_cabal_remote_repo "${candidate_tag}" ) || die
	candidate_hash=$( echo_cabal_magic_hash "${candidate_tag}" ) || die

	if [ "${candidate_os}" != "${os}" ] ||
		[ "${candidate_dir}" != "${HALCYON_DIR}" ] ||
		[ "${candidate_version}" != "${cabal_version}" ] ||
		[ "${candidate_repo}" != "${remote_repo}" ] ||
		[ "${candidate_hash}" != "${magic_hash}" ]
	then
		return 1
	fi

	local candidate_timestamp
	candidate_timestamp=$( echo_cabal_timestamp "${candidate_tag}" ) || die

	validate_updated_cabal_timestamp "${candidate_timestamp}"
}


function validate_updated_cabal () {
	expect_vars HALCYON_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local magic_hash
	magic_hash=$( echo_cabal_magic_hash "${cabal_tag}" ) || die

	if ! [ -f "${HALCYON_DIR}/cabal/.halcyon-tag" ] ||
		! validate_updated_cabal_tag "${cabal_tag}" <"${HALCYON_DIR}/cabal/.halcyon-tag" ||
		! validate_cabal_magic "${magic_hash}" "${HALCYON_DIR}/cabal"
	then
		return 1
	fi
}


function validate_updated_cabal_archive () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local updated_pattern
	updated_pattern=$( echo_updated_cabal_archive_name_pattern "${cabal_tag}" ) || die

	local candidate_archive
	if ! candidate_archive=$(
		filter_matching "^${updated_pattern}$" |
		match_exactly_one
	); then
		return 1
	fi

	local candidate_timestamp
	candidate_timestamp=$( echo_timestamp_from_updated_cabal_archive_name "${candidate_archive}" ) || die

	validate_updated_cabal_timestamp "${candidate_timestamp}"
}


function build_cabal () {
	expect_vars HOME HALCYON_DIR HALCYON_CACHE_DIR
	expect_existing "${HOME}" "${HALCYON_DIR}/ghc/.halcyon-tag"
	expect_no_existing "${HOME}/.cabal" "${HOME}/.ghc" "${HALCYON_DIR}/cabal"

	local cabal_tag app_dir
	expect_args cabal_tag app_dir -- "$@"

	local ghc_tag ghc_version cabal_version original_url original_archive tmp_cabal_dir
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	ghc_version=$( echo_ghc_version "${ghc_tag}" ) || die
	cabal_version=$( echo_cabal_version "${cabal_tag}" ) || die
	original_url=$( echo_cabal_original_url "${cabal_version}" ) || die
	original_archive=$( basename "${original_url}" ) || die
	tmp_cabal_dir=$( echo_tmp_dir_name 'halcyon.build_cabal' ) || die

	log 'Starting to build Cabal layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${original_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_cabal_dir}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_cabal_dir}" || die
		transfer_original "${original_archive}" "${original_url}" "${HALCYON_CACHE_DIR}" || die
		if ! tar_extract "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_cabal_dir}"; then
			rm -rf "${HALCYON_CACHE_DIR}/${original_archive}" "${tmp_cabal_dir}" || die
			die 'Cannot extract original archive'
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${original_archive}" || true
	fi

	if [ -f "${app_dir}/.halcyon-magic/cabal-prebuild-hook" ]; then
		log 'Running Cabal pre-build hook'
		( "${app_dir}/.halcyon-magic/cabal-prebuild-hook" "${ghc_tag}" "${cabal_tag}" "${tmp_cabal_dir}/cabal-install-${cabal_version}" "${app_dir}" ) |& quote || die
	fi

	log 'Bootstrapping Cabal'

	# NOTE: Bootstrapping cabal-install 1.20.0.0 with GHC 7.6.* does not work.

	case "${ghc_version}-${cabal_version}" in
	'7.8.'*'-1.20.0.'*)
		(
			cd "${tmp_cabal_dir}/cabal-install-${cabal_version}" &&
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
		rm -rf "${tmp_cabal_dir}" || die
		die "Unexpected Cabal and GHC combination: ${cabal_version} and ${ghc_version}"
	esac

	# NOTE: Bootstrapping cabal-install with GHC 7.8.[23] may fail unless --no-doc is specified.
	# https://ghc.haskell.org/trac/ghc/ticket/9174

	if ! (
		export EXTRA_CONFIGURE_OPTS="--extra-lib-dirs=${HALCYON_DIR}/ghc/lib" &&
		cd "${tmp_cabal_dir}/cabal-install-${cabal_version}" &&
		./bootstrap.sh --no-doc |& quote
	); then
		die 'Failed to bootstrap Cabal'
	fi

	mkdir -p "${HALCYON_DIR}/cabal/bin" || die
	mv "${HOME}/.cabal/bin/cabal" "${HALCYON_DIR}/cabal/bin/cabal" || die
	echo_cabal_config "${cabal_tag}" >"${HALCYON_DIR}/cabal/.halcyon-cabal.config" || die

	if [ -f "${app_dir}/.halcyon-magic/cabal-postbuild-hook" ]; then
		log 'Running Cabal post-build hook'
		( "${app_dir}/.halcyon-magic/cabal-postbuild-hook" "${ghc_tag}" "${cabal_tag}" "${tmp_cabal_dir}/cabal-install-${cabal_version}" "${app_dir}" ) |& quote || die
	fi

	if find_spaceless_recursively "${app_dir}/.halcyon-magic" -name 'cabal-*' |
		match_at_least_one >'/dev/null'
	then
		mkdir -p "${HALCYON_DIR}/cabal/.halcyon-magic" || die
		cp "${app_dir}/.halcyon-magic/cabal-"* "${HALCYON_DIR}/cabal/.halcyon-magic" || die
	fi

	echo "${cabal_tag}" >"${HALCYON_DIR}/cabal/.halcyon-tag" || die

	local cabal_size
	cabal_size=$( measure_recursively "${HALCYON_DIR}/cabal" ) || die
	log "Finished building Cabal layer, ${cabal_size}"

	rm -rf "${HOME}/.cabal" "${HOME}/.ghc" "${tmp_cabal_dir}" || die
}


function update_cabal () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local cabal_tag
	cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die

	log 'Starting to update Cabal layer'

	cabal_update || die

	local cabal_timestamp updated_cabal_tag
	cabal_timestamp=$( echo_timestamp ) || die
	updated_tag=$( derive_updated_cabal_tag "${cabal_tag}" "${cabal_timestamp}" ) || die

	echo "${updated_tag}" >"${HALCYON_DIR}/cabal/.halcyon-tag" || die

	local cabal_size
	cabal_size=$( measure_recursively "${HALCYON_DIR}/cabal" ) || die
	log "Finished updating Cabal layer, ${cabal_size}"
}


function archive_cabal () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local cabal_tag os cabal_archive
	cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	os=$( echo_cabal_os "${cabal_tag}" ) || die
	cabal_archive=$( echo_cabal_archive_name "${cabal_tag}" ) || die

	log 'Archiving Cabal layer'

	rm -f "${HALCYON_CACHE_DIR}/${cabal_archive}" || die
	tar_archive "${HALCYON_DIR}/cabal" "${HALCYON_CACHE_DIR}/${cabal_archive}" || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${cabal_archive}" "${os}"; then
		log_warning 'Cannot upload Cabal layer archive'
	fi
}


function restore_cabal () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local os cabal_archive
	os=$( echo_cabal_os "${cabal_tag}" ) || die
	cabal_archive=$( echo_cabal_archive_name "${cabal_tag}" ) || die

	if validate_cabal "${cabal_tag}"; then
		touch -c "${HALCYON_CACHE_DIR}/${cabal_archive}" || true
		log 'Using existing Cabal layer'
		return 0
	fi
	rm -rf "${HALCYON_DIR}/cabal" || die

	log 'Restoring Cabal layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${cabal_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" ||
		! validate_cabal "${cabal_tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" || die
		if ! download_layer "${os}" "${cabal_archive}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download Cabal layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" ||
			! validate_cabal "${cabal_tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" || die
			log_warning 'Cannot extract Cabal layer archive'
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${cabal_archive}" || true
	fi
}


function match_updated_cabal_archive () {
	local cabal_tag
	expect_args cabal_tag -- "$@"

	local updated_pattern
	updated_pattern=$( echo_updated_cabal_archive_name_pattern "${cabal_tag}" ) || die

	local updated_archive
	if ! updated_archive=$(
		filter_matching "^${updated_pattern}$" |
		sort_naturally |
		filter_last |
		match_exactly_one
	); then
		return 1
	fi

	if ! validate_updated_cabal_archive "${cabal_tag}" <<<"${updated_archive}"; then
		return 1
	fi

	echo "${updated_archive}"
}


function restore_cached_updated_cabal () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local cabal_archive
	cabal_archive=$(
		find_spaceless_recursively "${HALCYON_CACHE_DIR}" |
		match_updated_cabal_archive "${cabal_tag}"
	) || true

	if validate_updated_cabal "${cabal_tag}"; then
		local updated_tag cabal_timestamp timestamp_date timestamp_time
		updated_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
		cabal_timestamp=$( echo_cabal_timestamp "${updated_tag}" ) || die
		timestamp_date=$( echo_cabal_timestamp_date "${cabal_timestamp}" ) || die
		timestamp_time=$( echo_cabal_timestamp_time "${cabal_timestamp}" ) || die

		log 'Determining Cabal timestamp...           ' "${timestamp_date} ${timestamp_time} UTC"

		touch -c "${HALCYON_CACHE_DIR}/${cabal_archive}" || true
		log 'Using existing updated Cabal layer'
		return 0
	fi
	rm -rf "${HALCYON_DIR}/cabal" || die

	if [ -z "${cabal_archive}" ]; then
		return 1
	fi

	if ! tar_extract "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" ||
		! validate_updated_cabal "${cabal_tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" || die
		return 1
	else
		touch -c "${HALCYON_CACHE_DIR}/${cabal_archive}" || true
	fi
}


function restore_updated_cabal () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local cabal_tag
	expect_args cabal_tag -- "$@"

	local os archive_prefix
	os=$( echo_cabal_os "${cabal_tag}" ) || die
	archive_prefix=$( echo_updated_cabal_archive_name_prefix "${cabal_tag}" ) || die

	if restore_cached_updated_cabal "${cabal_tag}"; then
		return 0
	fi

	log 'Locating updated Cabal layers'

	local cabal_archives
	if ! cabal_archives=$(
		list_layer "${os}/${archive_prefix}" |
		sed "s:${os}/::" |
		match_at_least_one
	); then
		log 'Cannot locate any updated Cabal layer archive'
		return 1
	fi

	local cabal_archive
	cabal_archive=$( match_updated_cabal_archive "${cabal_tag}" <<<"${cabal_archives}" ) || true

	if has_private_storage; then
		local old_archives
		if old_archives=$(
			filter_not_matching "^${cabal_archive//./\.}$" <<<"${cabal_archives}" |
			match_at_least_one
		); then
			log 'Cleaning Cabal layer archives'

			local old_archive
			while read -r old_archive; do
				delete_layer "${os}" "${old_archive}" || true
			done <<<"${old_archives}"
		fi
	fi

	if [ -z "${cabal_archive}" ]; then
		log 'Cannot locate any updated Cabal layer archive'
		return 1
	fi

	local cabal_timestamp timestamp_date timestamp_time
	cabal_timestamp=$( echo_timestamp_from_updated_cabal_archive_name "${cabal_archive}" ) || die
	timestamp_date=$( echo_cabal_timestamp_date "${cabal_timestamp}" ) || die
	timestamp_time=$( echo_cabal_timestamp_time "${cabal_timestamp}" ) || die

	log 'Determining Cabal timestamp...           ' "${timestamp_date} ${timestamp_time} UTC"
	log 'Restoring updated Cabal layer'

	expect_no_existing "${HALCYON_CACHE_DIR}/${cabal_archive}"
	if ! download_layer "${os}" "${cabal_archive}" "${HALCYON_CACHE_DIR}"; then
		log_warning 'Cannot download updated Cabal layer archive'
		return 1
	fi

	if ! tar_extract "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" ||
		! validate_updated_cabal "${cabal_tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${cabal_archive}" "${HALCYON_DIR}/cabal" || die
		log_warning 'Cannot extract updated Cabal layer archive'
		return 1
	fi
}


function activate_cabal () {
	expect_vars HOME HALCYON_DIR
	expect_existing "${HOME}" "${HALCYON_DIR}/cabal/.halcyon-tag"

	local cabal_tag cabal_description
	cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
	cabal_description=$( echo_cabal_description "${cabal_tag}" ) || die

	if [ -e "${HOME}/.cabal/config" ] && ! [ -h "${HOME}/.cabal/config" ]; then
		die "Expected no foreign ${HOME}/.cabal/config"
	fi

	mkdir -p "${HOME}/.cabal" || die
	rm -f "${HOME}/.cabal/config" || die
	ln -s "${HALCYON_DIR}/cabal/.halcyon-cabal.config" "${HOME}/.cabal/config" || die

	log 'Cabal layer installed:'
	log_indent "${cabal_description}"
}


function deactivate_cabal () {
	expect_vars HOME HALCYON_DIR
	expect_existing "${HOME}"

	if [ -e "${HOME}/.cabal/config" ] && ! [ -h "${HOME}/.cabal/config" ]; then
		die "Expected no foreign ${HOME}/.cabal/config"
	fi

	# NOTE: There is no way to prevent Cabal for creating "${HOME}/.cabal/setup-exe-cache".
	# https://github.com/haskell/cabal/issues/1242

	rm -rf "${HALCYON_DIR}/cabal" "${HOME}/.cabal/config" "${HOME}/.cabal/setup-exe-cache" || die
	rmdir "${HOME}/.cabal" 2>'/dev/null' || true
}


function determine_cabal_tag () {
	local app_dir
	expect_args app_dir -- "$@"

	log_begin 'Determining Cabal version...             '

	local cabal_version
	if has_vars HALCYON_CABAL_VERSION; then
		cabal_version="${HALCYON_CABAL_VERSION}"

		log_end "${cabal_version}"
	else
		cabal_version=$( echo_default_cabal_version ) || die

		log_end "${cabal_version} (default)"
	fi

	log_begin 'Determining Cabal remote repo...         '

	local remote_repo
	if has_vars HALCYON_CABAL_REMOTE_REPO; then
		remote_repo="${HALCYON_CABAL_REMOTE_REPO}"

		log_end "${remote_repo%%:*}"
	else
		remote_repo=$( echo_default_cabal_remote_repo ) || die

		log_end "${remote_repo%%:*} (default)"
	fi

	log_begin 'Determining Cabal magic hash...          '

	local magic_hash
	magic_hash=$( hash_spaceless_recursively "${app_dir}/.halcyon-magic" -name 'cabal-*' ) || die
	if [ -z "${magic_hash}" ]; then
		log_end '(none)'
	else
		log_end "${magic_hash:0:7}"
	fi

	echo_cabal_tag "${cabal_version}" "${remote_repo}" "${magic_hash}" '' || die
}


function install_cabal () {
	expect_vars HALCYON_BUILD_CABAL HALCYON_UPDATE_CABAL HALCYON_NO_BUILD

	local app_dir
	expect_args app_dir -- "$@"

	local cabal_tag
	cabal_tag=$( determine_cabal_tag "${app_dir}" ) || die

	if ! (( HALCYON_BUILD_CABAL )) && ! (( HALCYON_UPDATE_CABAL )) && restore_updated_cabal "${cabal_tag}"; then
		activate_cabal || die
		return 0
	fi

	if ! (( HALCYON_BUILD_CABAL )) && restore_cabal "${cabal_tag}"; then
		update_cabal || die
		archive_cabal || die
		activate_cabal || die
		return 0
	fi

	if ! (( HALCYON_BUILD_CABAL )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build Cabal layer'
		return 1
	fi

	deactivate_cabal || die
	build_cabal "${cabal_tag}" "${app_dir}" || die
	archive_cabal || die
	update_cabal || die
	archive_cabal || die
	activate_cabal || die
}


function cabal_do () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local work_dir
	expect_args work_dir -- "$@"
	shift
	expect_existing "${work_dir}"

	if ! ( cd "${work_dir}" && cabal --config-file="${HALCYON_DIR}/cabal/.halcyon-cabal.config" "$@" ); then
		die 'Failed to run Cabal:' "$@"
	fi
}


function sandboxed_cabal_do () {
	local sandbox_dir work_dir
	expect_args sandbox_dir work_dir -- "$@"
	shift 2
	expect_existing "${sandbox_dir}"

	# NOTE: Specifying a cabal.sandbox.config file should not change where Cabal looks for a cabal.config file.
	# https://github.com/haskell/cabal/issues/1915

	local tmp_foreign_config
	tmp_foreign_config=
	if [ -f "${sandbox_dir}/cabal.config" ]; then
		tmp_foreign_config=$( echo_tmp_file_name 'halcyon.sandboxed_cabal_do' ) || die
		mv "${sandbox_dir}/cabal.config" "${tmp_foreign_config}" || die
	fi
	if [ -f "${work_dir}/cabal.config" ]; then
		cp "${work_dir}/cabal.config" "${sandbox_dir}/cabal.config" || die
	fi

	local status
	status=0
	if ! cabal_do "${work_dir}" --sandbox-config-file="${sandbox_dir}/.halcyon-sandbox.config" "$@"; then
		status=1
	fi

	rm -f "${sandbox_dir}/cabal.config" || die
	if [ -n "${tmp_foreign_config}" ]; then
		mv "${tmp_foreign_config}" "${sandbox_dir}/cabal.config" || die
	fi

	return "${status}"
}


function read_constraints_from_cabal_dry_freeze () {
	tail -n +3 | sed 's/ == / /'
}


function cabal_freeze_implicit_constraints () {
	local app_dir
	expect_args app_dir -- "$@"

	cabal_do "${app_dir}" --no-require-sandbox freeze --dry-run |
		read_constraints_from_cabal_dry_freeze |
		filter_valid_sandbox_constraints |
		filter_nonself_sandbox_constraints "${app_dir}" || die
}


function cabal_freeze_actual_constraints () {
	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"

	sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" freeze --dry-run |
		read_constraints_from_cabal_dry_freeze |
		filter_valid_sandbox_constraints |
		filter_nonself_sandbox_constraints "${app_dir}" || die
}


function cabal_update () {
	cabal_do '.' update |& quote || die
}


function cabal_list_newest_package_version () {
	local package_name
	expect_args package_name -- "$@"

	cabal_do '.' --no-require-sandbox list --simple-output "${package_name}" |
		filter_matching "^${package_name} " |
		sort_naturally |
		filter_last |
		match_exactly_one |
		sed 's/^.* //'
}


function cabal_create_sandbox () {
	local sandbox_dir
	expect_args sandbox_dir -- "$@"
	expect_no_existing "${sandbox_dir}"

	mkdir -p "${sandbox_dir}" || die
	cabal_do "${sandbox_dir}" sandbox init --sandbox '.' |& quote || die
}


function cabal_install_deps () {
	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"
	shift 2

	# NOTE: Listing executable-only packages in build-tools causes Cabal to
	# expect the executables to be installed, but not to install the packages.
	# https://github.com/haskell/cabal/issues/220

	# NOTE: Listing executable-only packages in build-depends causes Cabal to
	# install the packages, and to fail to recognise the packages have been
	# installed.
	# https://github.com/haskell/cabal/issues/779

	sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" install --dependencies-only "$@" |& quote || die
}


function cabal_configure_app () {
	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"
	shift 2

	sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" configure "$@" |& quote || die
}


function cabal_build_app () {
	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"
	shift 2

	sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" build "$@" |& quote || die
}


function cabal_copy_app () {
	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"
	shift 2

	sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" copy "$@" |& quote || die
}
