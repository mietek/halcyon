function detect_app_package () {
	local source_dir
	expect_args source_dir -- "$@"
	expect_existing "${source_dir}"

	local package_file
	if ! package_file=$(
		find_spaceless_recursively "${source_dir}" -maxdepth 1 -name '*.cabal' |
		match_exactly_one
	); then
		return 1
	fi

	cat "${source_dir}/${package_file}"
}


function detect_app_name () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_name
	if ! app_name=$(
		detect_app_package "${source_dir}" |
		awk '/^ *[Nn]ame:/ { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	); then
		return 1
	fi

	echo "${app_name}"
}


function detect_app_version () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_version
	if ! app_version=$(
		detect_app_package "${source_dir}" |
		awk '/^ *[Vv]ersion:/ { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	); then
		return 1
	fi

	echo "${app_version}"
}


function detect_app_executable () {
	local source_dir
	expect_args source_dir -- "$@"

	local app_executable
	if ! app_executable=$(
		detect_app_package "${source_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		tr -d '\r' |
		match_exactly_one
	); then
		return 1
	fi

	echo "${app_executable}"
}


function detect_constraints () {
	local app_label source_dir
	expect_args app_label source_dir -- "$@"

	if ! [ -f "${source_dir}/cabal.config" ]; then
		return 1
	fi

	local constraints
	constraints=$(
		read_constraints <"${source_dir}/cabal.config" |
		filter_correct_constraints "${app_label}" |
		sort_naturally
	) || die

	local -A constraints_A
	local base_version candidate_package candidate_version
	base_version=
	while read -r candidate_package candidate_version; do
		if [ -n "${constraints_A[${candidate_package}]:+_}" ]; then
			return 1
		fi
		constraints_A["${candidate_package}"]="${candidate_version}"

		if [ "${candidate_package}" = 'base' ]; then
			base_version="${candidate_version}"
		fi
	done <<<"${constraints}"

	if [ -z "${base_version}" ]; then
		return 1
	fi

	echo "${constraints}"
}


function ghc_detect_base_package_version () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	local base_version
	if ! base_version=$(
		ghc-pkg list --simple-output |
		awk -F- 'BEGIN { RS=" " } /base-[0-9\.]+/ { print $2 }'
	); then
		return 1
	fi

	echo "${base_version}"
}
