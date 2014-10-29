function create_tag () {
	expect_vars HALCYON_DIR

	local app_label target                                       \
		source_hash constraints_hash                         \
		ghc_version ghc_magic_hash                           \
		cabal_version cabal_magic_hash cabal_repo cabal_date \
		sandbox_magic_hash app_magic_hash
	expect_args app_label target                                 \
		source_hash constraints_hash                         \
		ghc_version ghc_magic_hash                           \
		cabal_version cabal_magic_hash cabal_repo cabal_date \
		sandbox_magic_hash app_magic_hash -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "1\t${os}\t${HALCYON_DIR}\t${app_label}\t${target}\t${source_hash}\t${constraints_hash}\t${ghc_version}\t${ghc_magic_hash}\t${cabal_version}\t${cabal_magic_hash}\t${cabal_repo}\t${cabal_date}\t${sandbox_magic_hash}\t${app_magic_hash}"
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


function get_tag_constraints_hash () {
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


function get_tag_cabal_date () {
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
	[ -f "${file}" ] || return 1

	local candidate_tag
	candidate_tag=$(
		filter_matching "^${tag_pattern}$" <"${file}" |
		match_exactly_one
	) || return 1

	echo "${candidate_tag}"
}
