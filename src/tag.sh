function create_tag () {
	expect_vars HALCYON_DIR

	local app_label target                                             \
		source_hash constraint_hash                                \
		ghc_version ghc_magic_hash                                 \
		cabal_version cabal_magic_hash cabal_repo update_timestamp \
		sandbox_magic_hash app_magic_hash
	expect_args app_label target                                       \
		source_hash constraint_hash                                \
		ghc_version ghc_magic_hash                                 \
		cabal_version cabal_magic_hash cabal_repo update_timestamp \
		sandbox_magic_hash app_magic_hash -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "1\t${os}\t${HALCYON_DIR}\t${app_label}\t${target}\t${source_hash}\t${constraint_hash}\t${ghc_version}\t${ghc_magic_hash}\t${cabal_version}\t${cabal_magic_hash}\t${cabal_repo}\t${update_timestamp}\t${sandbox_magic_hash}\t${app_magic_hash}"
}


function get_tag_version () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${tag}"
}


function get_tag_os () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $2 }' <<<"${tag}"
}


function get_tag_halcyon_dir () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $3 }' <<<"${tag}"
}


function get_tag_app_label () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $4 }' <<<"${tag}"
}


function get_tag_target () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $5 }' <<<"${tag}"
}


function get_tag_source_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $6 }' <<<"${tag}"
}


function get_tag_constraint_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $7 }' <<<"${tag}"
}


function get_tag_ghc_version () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $8 }' <<<"${tag}" | sed 's/^ghc-//'
}


function get_tag_ghc_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $9 }' <<<"${tag}"
}


function get_tag_cabal_version () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $10 }' <<<"${tag}" | sed 's/^cabal-//'
}


function get_tag_cabal_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $11 }' <<<"${tag}"
}


function get_tag_cabal_repo () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $12 }' <<<"${tag}"
}


function get_tag_update_timestamp () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $13 }' <<<"${tag}"
}


function get_tag_sandbox_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $14 }' <<<"${tag}"
}


function get_tag_app_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $15 }' <<<"${tag}"
}


function detect_tag () {
	local file tag_pattern
	expect_args file tag_pattern -- "$@"

	if ! [ -f "${file}" ]; then
		return 1
	fi

	local candidate_tag
	if ! candidate_tag=$(
		filter_matching "^${tag_pattern}$" <"${file}" |
		match_exactly_one
	); then
		return 1
	fi

	echo "${candidate_tag}"
}


function determine_env_tag () {
	local ghc_version
	if has_vars HALCYON_GHC_VERSION; then
		ghc_version="${HALCYON_GHC_VERSION}"
	else
		ghc_version=$( get_default_ghc_version ) || die
	fi

	local cabal_version cabal_repo
	if has_vars HALCYON_CABAL_VERSION; then
		cabal_version="${HALCYON_CABAL_VERSION}"
	else
		cabal_version=$( get_default_cabal_version ) || die
	fi
	if has_vars HALCYON_CABAL_REPO; then
		cabal_repo="${HALCYON_CABAL_REPO}"
	else
		cabal_repo=$( get_default_cabal_repo ) || die
	fi

	create_tag '' ''                                 \
		'' ''                                    \
		"${ghc_version}" ''                      \
		"${cabal_version}" '' "${cabal_repo}" '' \
		'' '' || die
}


function determine_full_tag () {
	expect_vars HALCYON_TARGET

	local env_tag app_label constraints source_dir
	expect_args env_tag app_label constraints source_dir -- "$@"
	expect_existing "${source_dir}"

	local source_hash constraints_hash
	source_hash=$( hash_spaceless_recursively "${source_dir}" ) || die
	constraint_hash=$( hash_constraints "${constraints}" ) || die

	local ghc_version ghc_magic_hash
	if has_vars HALCYON_GHC_VERSION; then
		ghc_version="${HALCYON_GHC_VERSION}"
	else
		ghc_version=$( map_constraints_to_ghc_version "${constraints}" ) || die
	fi
	ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${env_tag}" ) || die
	cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${env_tag}" ) || die

	local sandbox_magic_hash app_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die
	app_magic_hash=$( hash_app_magic "${source_dir}" ) || die

	create_tag "${app_label}" "${HALCYON_TARGET}"                       \
		"${source_hash}" "${constraint_hash}"                       \
		"${ghc_version}" "${ghc_magic_hash}"                        \
		"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
		"${sandbox_magic_hash}" "${app_magic_hash}" || die
}


function describe_env_tag () {
	local tag
	expect_args tag -- "$@"

	local ghc_version
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die

	log_indent 'GHC version:                             ' "${ghc_version}"

	local cabal_version cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" ) || die
	cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

	log_indent 'Cabal version:                           ' "${cabal_version}"
	log_indent 'Cabal repository:                        ' "${cabal_repo%%:*}"
}


function describe_full_tag () {
	local tag
	expect_args tag -- "$@"

	local target
	target=$( get_tag_target "${tag}" ) || die

	if [ "${target}" = 'sandbox' ]; then
		log_indent 'Target:                                  ' 'sandbox'
	fi

	local source_hash constraint_hash
	source_hash=$( get_tag_source_hash "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die

	log_indent 'Source hash:                             ' "${source_hash:0:7}"
	log_indent 'Constraint hash:                         ' "${constraint_hash:0:7}"

	if ! (( HALCYON_RECURSIVE )); then
		local ghc_version ghc_magic_hash
		ghc_version=$( get_tag_ghc_version "${tag}" ) || die
		ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" ) || die

		log_indent 'GHC version:                             ' "${ghc_version}"
		if [ -n "${ghc_magic_hash}" ]; then
			log_indent 'GHC magic hash:                          ' "${ghc_magic_hash:0:7}"
		fi

		local cabal_version cabal_magic_hash cabal_repo
		cabal_version=$( get_tag_cabal_version "${tag}" ) || die
		cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" ) || die
		cabal_repo=$( get_tag_cabal_repo "${tag}" ) || die

		log_indent 'Cabal version:                           ' "${cabal_version}"
		if [ -n "${cabal_magic_hash}" ]; then
			log_indent 'Cabal magic hash:                        ' "${cabal_magic_hash:0:7}"
		fi
		log_indent 'Cabal repository:                        ' "${cabal_repo%%:*}"
	fi

	local sandbox_magic_hash app_magic_hash
	sandbox_magic_hash=$( get_tag_sandbox_magic_hash "${tag}" ) || die
	app_magic_hash=$( get_tag_app_magic_hash "${tag}" ) || die

	if [ -n "${sandbox_magic_hash}" ]; then
		log_indent 'Sandbox magic hash:                      ' "${sandbox_magic_hash:0:7}"
	fi
	if [ -n "${app_magic_hash}" ]; then
		log_indent 'App magic hash:                          ' "${app_magic_hash:0:7}"
	fi
}
