function hash_constraints () {
	openssl sha1 | sed 's/^.* //'
}


function echo_constraints () {
	awk 'BEGIN { printf "constraints:"; separator = " " }
		!/^$/ { printf "%s%s ==%s", separator, $1, $2; separator = ",\n             " }
		END { printf "\n" }'
}


function echo_constraints_difference () {
	expect_args old_constraints new_constraints -- "$@"

	local old_constraints_hash new_constraints_hash
	old_constraints_hash=$( hash_constraints <<<"${old_constraints}" ) || die
	new_constraints_hash=$( hash_constraints <<<"${new_constraints}" ) || die

	local tmp_old_config tmp_new_config
	tmp_old_config=$( echo_tmp_file_name 'halcyon.old-config' ) || die
	tmp_new_config=$( echo_tmp_file_name 'halcyon.new-config' ) || die

	echo_constraints <<<"${old_constraints}" >"${tmp_old_config}" || die
	echo_constraints <<<"${new_constraints}" >"${tmp_new_config}" || die

	echo "--- ${old_constraints_hash:0:7}/cabal.config"
	echo "+++ ${new_constraints_hash:0:7}/cabal.config"
	diff -u "${tmp_old_config}" "${tmp_new_config}" | tail -n +3 || true

	rm -f "${tmp_old_config}" "${tmp_new_config}" || die
}


function read_constraints () {
	awk '/^ *[Cc]onstraints:/, !/[:,]/ { print }' |
		tr -d '\r' |
		sed 's/[Cc]onstraints://;s/[, ]//g;s/==/ /;/^$/d'
}


function read_constraints_dry_run () {
	tail -n +3 |
		sed 's/ == / /'
}


function filter_valid_constraints () {
	local -A constraints_A

	local candidate_package candidate_version
	while read -r candidate_package candidate_version; do
		if [ -n "${constraints_A[${candidate_package}]:+_}" ]; then
			die "Expected at most one ${candidate_package} constraint"
		fi
		constraints_A["${candidate_package}"]="${candidate_version}"

		echo "${candidate_package} ${candidate_version}"
	done

	if [ -z "${constraints_A[base]:+_}" ]; then
		die 'Expected base package constraint'
	fi
}


function score_constraints () {
	local constraints description
	expect_args constraints description -- "$@"

	local -A constraints_A

	local package version
	while read -r package version; do
		constraints_A["${package}"]="${version}"
	done <<<"${constraints}"

	local score candidate_package candidate_version
	score=0
	while read -r candidate_package candidate_version; do
		local version
		version="${constraints_A[${candidate_package}]:-}"
		if [ -z "${version}" ]; then
			log_indent "Cannot use ${description} as ${candidate_package} is not needed"
			echo 0
			return 0
		fi
		if [ "${candidate_version}" != "${version}" ]; then
			log_indent "Cannot use ${description} as ${candidate_package}-${candidate_version} is not ${version}"
			echo 0
			return 0
		fi
		score=$(( score + 1 ))
	done

	log_indent "${score}"$'\t'"${description}"
	echo "${score}"
}


function detect_app_constraint () {
	local app_dir
	expect_args app_dir -- "$@"

	local app_name app_version
	app_name=$( detect_app_name "${app_dir}" ) || die
	app_version=$( detect_app_version "${app_dir}" ) || die

	echo "${app_name} ${app_version}"
}


function echo_ghc_version_from_constraints () {
	local constraints
	expect_args constraints -- "$@"

	local base_version
	base_version=$(
		filter_matching "^base " <<<"${constraints}" |
		match_exactly_one |
		sed 's/^.* //'
	) || die

	echo_ghc_version_from_base_package_version "${base_version}" || die
}


function filter_correct_constraints () {
	local app_dir
	expect_args app_dir -- "$@"

	# NOTE: An application should not be its own dependency.
	# https://github.com/haskell/cabal/issues/1908

	local app_constraint
	app_constraint=$( detect_app_constraint "${app_dir}" ) || die

	filter_valid_constraints |
		filter_not_matching "^${app_constraint}$" |
		sort_naturally
}


function detect_constraints () {
	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}/cabal.config"

	read_constraints <"${app_dir}/cabal.config" |
		filter_correct_constraints "${app_dir}" || die
}
