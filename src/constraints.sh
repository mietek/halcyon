function read_constraints () {
	awk '/^ *[Cc]onstraints:/, !/[:,]/ { print }' |
		tr -d '\r' |
		sed 's/[Cc]onstraints://;s/[, ]//g;s/==/ /;/^$/d'
}


function read_dry_frozen_constraints () {
	tail -n +3 | sed 's/ == / /'
}


function match_package_version () {
	local package_name
	expect_args package_name -- "$@"

	filter_matching "^${package_name} " |
		match_exactly_one |
		sed 's/^.* //' || return 1
}


function filter_correct_constraints () {
	local app_label
	expect_args app_label -- "$@"

	# NOTE: Cabal includes the package itself in the list of frozen constraints.
	# https://github.com/haskell/cabal/issues/1908

	local app_name app_version
	app_name="${app_label%-*}"
	app_version="${app_label##*-}"
	if [ "${app_name}" = 'base' ]; then
		app_name='halcyon-fake-base'
	fi

	filter_not_matching "^${app_name} ${app_version}$" || die
}


function format_constraints () {
	awk 'BEGIN { printf "constraints:"; separator = " " }
		!/^$/ { printf "%s%s ==%s", separator, $1, $2; separator = ",\n             " }
		END { printf "\n" }'
}


function hash_constraints () {
	local constraints
	expect_args constraints -- "$@"

	do_hash <<<"${constraints}" || die
}


function detect_constraints () {
	local app_label source_dir
	expect_args app_label source_dir -- "$@"
	expect_existing "${source_dir}/cabal.config"

	local constraints
	constraints=$(
		read_constraints <"${source_dir}/cabal.config" |
		filter_correct_constraints "${app_label}" |
		sort_naturally
	) || die

	local -A package_version_map
	package_version_map=()

	local base_version candidate_package candidate_version
	base_version=
	while read -r candidate_package candidate_version; do
		if [ -n "${package_version_map[${candidate_package}]:+_}" ]; then
			die "Unexpected duplicate constraint: ${candidate_package}-${package_version_map[${candidate_package}]} and ${candidate_package}-${candidate-version}"
		fi
		package_version_map["${candidate_package}"]="${candidate_version}"
		if [ "${candidate_package}" = 'base' ]; then
			base_version="${candidate_version}"
		fi
	done <<<"${constraints}"
	if [ -z "${base_version}" ]; then
		die 'Expected base package constraint'
	fi

	echo "${constraints}"
}


function validate_actual_constraints () {
	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	# NOTE: Cabal sometimes gives different results when freezing constraints before and after
	# installation.
	# https://github.com/haskell/cabal/issues/1896
	# https://github.com/mietek/halcyon/issues/1

	local app_label constraints_hash actual_constraints actual_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	actual_constraints=$( cabal_freeze_actual_constraints "${app_label}" "${source_dir}" ) || die
	actual_hash=$( hash_constraints "${actual_constraints}" ) || die
	if [ "${actual_hash}" = "${constraints_hash}" ]; then
		return 0
	fi

	log_warning 'Unexpected constraints difference'
	log_warning 'Please report this on https://github.com/mietek/halcyon/issues/1'
	log_indent "--- ${constraints_hash:0:7}/cabal.config"
	log_indent "+++ ${actual_hash:0:7}/cabal.config"
	diff -u <( echo "${constraints}" ) <( echo "${actual_constraints}" ) | tail -n +3 |& quote || true
}


function validate_full_constraints_file () {
	local tag candidate_file
	expect_args tag candidate_file -- "$@"
	[ -f "${candidate_file}" ] || return 1

	local candidate_constraints
	candidate_constraints=$( read_constraints <"${candidate_file}" ) || die

	local constraints_hash candidate_hash
	constraints_hash=$( get_tag_constraints_hash "${tag}" ) || die
	candidate_hash=$( hash_constraints "${candidate_constraints}" ) || die
	[ "${candidate_hash}" = "${constraints_hash}" ] || return 1

	echo "${candidate_hash}"
}


function validate_partial_constraints_file () {
	local candidate_file
	expect_args candidate_file -- "$@"
	[ -f "${candidate_file}" ] || return 1

	local candidate_constraints
	candidate_constraints=$( read_constraints <"${candidate_file}" ) || die

	local file_name short_hash_etc short_hash candidate_hash
	file_name=$( basename "${candidate_file}" ) || die
	short_hash_etc="${file_name#halcyon-constraints-}"
	short_hash="${short_hash_etc%%-*}"
	candidate_hash=$( hash_constraints "${candidate_constraints}" ) || die
	[ "${candidate_hash:0:7}" = "${short_hash}" ] || return 1

	echo "${candidate_hash}"
}


function locate_first_full_sandbox_layer () {
	expect_vars HALCYON_CACHE_DIR

	local tag all_names
	expect_args tag all_names -- "$@"

	local os ghc_version full_pattern all_names full_names
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	full_pattern=$( format_full_sandbox_constraints_file_name_pattern "${tag}" ) || die
	full_names=$(
		filter_matching "^${full_pattern}$" <<<"${all_names}" |
		match_at_least_one
	) || return 1

	log 'Examining fully matching sandbox layers'

	local full_name full_file
	while read -r full_name; do
		full_file="${HALCYON_CACHE_DIR}/${full_name}"

		local full_hash
		if ! full_hash=$( validate_full_constraints_file "${tag}" "${full_file}" ); then
			if ! download_stored_file "${os}/ghc-${ghc_version}" "${full_name}" ||
				! full_hash=$( validate_full_constraints_file "${tag}" "${full_file}" )
			then
				continue
			fi
		else
			touch -c "${full_file}" || die
		fi

		local full_label full_tag
		full_label=$( map_sandbox_constraints_file_name_to_app_label "${full_name}" ) || die
		full_tag=$( derive_matching_sandbox_tag "${tag}" "${full_label}" "${full_hash}" ) || die

		echo "${full_tag}"
		return 0
	done <<<"${full_names}"

	return 1
}


function locate_partial_sandbox_layers () {
	expect_vars HALCYON_CACHE_DIR

	local tag constraints all_names
	expect_args tag constraints all_names -- "$@"

	local os ghc_version full_pattern all_names partial_names
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	full_pattern=$( format_full_sandbox_constraints_file_name_pattern "${tag}" ) || die
	partial_names=$(
		filter_not_matching "^${full_pattern}" <<<"${all_names}" |
		match_at_least_one
	) || return 1

	log 'Examining partially matching sandbox layers'

	local -a results
	results=()

	local partial_name partial_file
	while read -r partial_name; do
		partial_file="${HALCYON_CACHE_DIR}/${partial_name}"

		local partial_hash
		if ! partial_hash=$( validate_partial_constraints_file "${partial_file}" ); then
			if ! download_stored_file "${os}/ghc-${ghc_version}" "${partial_name}" ||
				! partial_hash=$( validate_partial_constraints_file "${partial_file}" )
			then
				continue
			fi
		else
			touch -c "${partial_file}" || die
		fi

		local partial_label partial_tag
		partial_label=$( map_sandbox_constraints_file_name_to_app_label "${partial_name}" ) || die
		partial_tag=$( derive_matching_sandbox_tag "${tag}" "${partial_label}" "${partial_hash}" ) || die

		results+=( "${partial_tag}" )
	done <<<"${partial_names}"

	[ -n "${results[@]:+_}" ] || return 1

	( IFS=$'\n' && echo "${results[*]}" )
}


function select_best_partial_sandbox_layer () {
	expect_vars HALCYON_CACHE_DIR

	local constraints partial_tags
	expect_args constraints partial_tags -- "$@"

	local -A package_version_map
	package_version_map=()

	local package version
	while read -r package version; do
		package_version_map["${package}"]="${version}"
	done <<<"${constraints}"

	log 'Selecting best partially matching sandbox layer'

	local -a results
	results=()

	local partial_tag
	while read -r partial_tag; do
		local partial_name partial_file
		partial_name=$( format_sandbox_constraints_file_name "${partial_tag}" ) || die
		partial_file="${HALCYON_CACHE_DIR}/${partial_name}"
		if ! validate_partial_constraints_file "${partial_file}" >'/dev/null'; then
			continue
		fi

		local partial_constraints description
		partial_constraints=$( read_constraints <"${partial_file}" ) || die
		description=$( format_sandbox_description "${partial_tag}" ) || die

		local score partial_package partial_version
		score=0
		while read -r partial_package partial_version; do
			local version
			version="${package_version_map[${partial_package}]:-}"
			if [ -z "${version}" ]; then
				log_indent "Ignoring ${description} as ${partial_package}-${partial_version} is not needed"
				score=
				break
			fi
			if [ "${partial_version}" != "${version}" ]; then
				log_indent "Ignoring ${description} as ${partial_package}-${partial_version} is not ${version}"
				score=
				break
			fi

			score=$(( score + 1 ))
		done <<<"${partial_constraints}"
		if [ -n "${score}" ]; then
			log_indent "${score}"$'\t'"${description}"
			results+=( "${score} ${partial_tag}" )
		fi
	done <<<"${partial_tags}"

	[ -n "${results[@]:+_}" ] || return 1

	local result
	result=$(
		( IFS=$'\n' && echo "${results[*]}" ) |
		filter_not_matching '^0 ' |
		sort_naturally |
		filter_last |
		match_exactly_one
	) || return 1

	echo "${result#* }"
}


function locate_best_matching_sandbox_layer () {
	expect_vars HALCYON_NO_BUILD_DEPENDENCIES
	local tag constraints
	expect_args tag constraints -- "$@"

	local os ghc_version file_name name_prefix partial_pattern
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	file_name=$( format_sandbox_constraints_file_name "${tag}" ) || die
	name_prefix=$( format_sandbox_constraints_file_name_prefix ) || die
	partial_pattern=$( format_partial_sandbox_constraints_file_name_pattern "${tag}" ) || die

	log 'Locating matching sandbox layers'

	local all_names
	all_names=$(
		list_stored_files "${os}/ghc-${ghc_version}/${name_prefix}" |
		sed "s:${os}/ghc-${ghc_version}/::" |
		filter_matching "^${partial_pattern}$" |
		filter_not_matching "^${file_name}$" |
		sort_naturally |
		match_at_least_one
	) || return 1

	local full_tag
	if full_tag=$( locate_first_full_sandbox_layer "${tag}" "${all_names}" ); then
		echo "${full_tag}"
		return 0
	fi

	if (( HALCYON_NO_BUILD_DEPENDENCIES )); then
		return 1
	fi

	local partial_tags partial_tag
	if partial_tags=$( locate_partial_sandbox_layers "${tag}" "${constraints}" "${all_names}" ) &&
		partial_tag=$( select_best_partial_sandbox_layer "${constraints}" "${partial_tags}" )
	then
		echo "${partial_tag}"
		return 0
	fi

	return 1
}
