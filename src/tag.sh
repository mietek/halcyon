create_tag () {
	expect_vars HALCYON_BASE

	local prefix label source_hash constraints_hash magic_hash \
		ghc_version ghc_magic_hash \
		cabal_version cabal_magic_hash cabal_repo cabal_date \
		sandbox_magic_hash
	expect_args prefix label source_hash constraints_hash magic_hash \
		ghc_version ghc_magic_hash \
		cabal_version cabal_magic_hash cabal_repo cabal_date \
		sandbox_magic_hash -- "$@"

	echo -e "1\t${HALCYON_INTERNAL_PLATFORM}\t${HALCYON_BASE}\t${prefix}\t${label}\t${source_hash}\t${constraints_hash}\t${magic_hash}\t${ghc_version}\t${ghc_magic_hash}\t${cabal_version}\t${cabal_magic_hash}\t${cabal_repo}\t${cabal_date}\t${sandbox_magic_hash}"
}


get_tag_version () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${tag}" || return 0
}


get_tag_platform () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $2 }' <<<"${tag}" || return 0
}


get_tag_base () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $3 }' <<<"${tag}" || return 0
}


get_tag_prefix () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $4 }' <<<"${tag}" || return 0
}


get_tag_label () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $5 }' <<<"${tag}" || return 0
}


get_tag_source_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $6 }' <<<"${tag}" || return 0
}


get_tag_constraints_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $7 }' <<<"${tag}" || return 0
}


get_tag_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $8 }' <<<"${tag}" || return 0
}


get_tag_ghc_version () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $9 }' <<<"${tag}" | sed 's/^ghc-//' || return 0
}


get_tag_ghc_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $10 }' <<<"${tag}" || return 0
}


get_tag_cabal_version () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $11 }' <<<"${tag}" | sed 's/^cabal-//' || return 0
}


get_tag_cabal_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $12 }' <<<"${tag}" || return 0
}


get_tag_cabal_repo () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $13 }' <<<"${tag}" || return 0
}


get_tag_cabal_date () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $14 }' <<<"${tag}" || return 0
}


get_tag_sandbox_magic_hash () {
	local tag
	expect_args tag -- "$@"

	awk -F$'\t' '{ print $15 }' <<<"${tag}" || return 0
}


detect_tag () {
	local file tag_pattern
	expect_args file tag_pattern -- "$@"

	if [[ ! -f "${file}" ]]; then
		return 1
	fi

	local candidate_tag
	candidate_tag=$(
		filter_matching "^${tag_pattern}$" <"${file}" |
		match_exactly_one
	) || return 1

	echo "${candidate_tag}"
}
