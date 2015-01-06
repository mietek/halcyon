read_constraints () {
	sed 's/^\(.*\)-\(.*\)$/\1 \2/'
}


read_constraints_from_cabal_freeze () {
	awk '/^ *[Cc]onstraints:/, !/[:,]/ { print }' |
		tr -d '\r' |
		sed 's/[Cc]onstraints://;s/[, ]//g;s/==/ /;/^$/d'
}


read_constraints_from_cabal_dry_freeze () {
	awk '/The following packages would be frozen:/ { i = 1 } i' |
		filter_not_first |
		sed 's/ == / /'
}


match_package_version () {
	local package_name
	expect_args package_name -- "$@"

	filter_matching "^${package_name} " |
		match_exactly_one |
		sed 's/^.* //' || return 1
}


filter_correct_constraints () {
	local label
	expect_args label -- "$@"

	# NOTE: Cabal includes the package itself in the list of frozen constraints.
	# https://github.com/haskell/cabal/issues/1908

	local name version
	name="${label%-*}"
	version="${label##*-}"
	if [[ ${name} == 'base' ]]; then
		name='halcyon-fake-base'
	fi

	filter_not_matching "^${name} ${version}$" || die
}


format_constraints () {
	sed 's/ /-/'
}


format_constraints_to_cabal_freeze () {
	awk 'BEGIN { printf "constraints:"; separator = " " }
		!/^$/ { printf "%s%s ==%s", separator, $1, $2; separator = ",\n             " }
		END { printf "\n" }'
}


hash_constraints () {
	local constraints
	expect_args constraints -- "$@"

	get_hash <<<"${constraints}" || die
}


prepare_constraints () {
	expect_vars HALCYON_IGNORE_ALL_CONSTRAINTS

	local label source_dir
	expect_args label source_dir -- "$@"

	local magic_dir
	magic_dir="${source_dir}/.halcyon"

	if [[ -n "${HALCYON_CONSTRAINTS:+_}" ]]; then
		if [[ -d "${HALCYON_CONSTRAINTS}" && -f "${HALCYON_CONSTRAINTS}/${label}.constraints" ]]; then
			copy_file "${HALCYON_CONSTRAINTS}/${label}.constraints" "${magic_dir}/constraints" || die
		elif [[ -f "${HALCYON_CONSTRAINTS}" ]]; then
			copy_file "${HALCYON_CONSTRAINTS}" "${magic_dir}/constraints" || die
		else
			copy_file <( echo "${HALCYON_CONSTRAINTS}" ) "${magic_dir}/constraints" || die
		fi
	fi

	if (( HALCYON_IGNORE_ALL_CONSTRAINTS )); then
		rm -f "${source_dir}/cabal.config" || die
		return 0
	fi

	if [[ -f "${magic_dir}/constraints" ]]; then
		read_constraints <"${magic_dir}/constraints" |
			sort_natural |
			format_constraints_to_cabal_freeze >"${source_dir}/cabal.config" || die
	fi
}


detect_constraints () {
	local label source_dir
	expect_args label source_dir -- "$@"
	expect_existing "${source_dir}/cabal.config"

	local constraints
	constraints=$(
		read_constraints_from_cabal_freeze <"${source_dir}/cabal.config" |
		filter_correct_constraints "${label}" |
		sort_natural
	) || return 1
	if [[ -z "${constraints}" ]]; then
		return 0
	fi

	local -A packages_A
	local base_version candidate_package candidate_version
	packages_A=()
	base_version=''
	while read -r candidate_package candidate_version; do
		if [[ -n "${packages_A[${candidate_package}]:+_}" ]]; then
			log_error "Unexpected duplicate constraint: ${candidate_package}-${candidate-version} (${packages_A[${candidate_package}]})"
			return 1
		fi
		packages_A["${candidate_package}"]="${candidate_version}"
		if [[ ${candidate_package} == 'base' ]]; then
			base_version="${candidate_version}"
		fi
	done <<<"${constraints}"
	if [[ -z "${base_version}" ]]; then
		log_error 'Expected base package constraint'
		return 1
	fi

	echo "${constraints}"
}


validate_actual_constraints () {
	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	# NOTE: Cabal sometimes gives different results when freezing constraints before and after
	# installation.
	# https://github.com/haskell/cabal/issues/1896
	# https://github.com/mietek/halcyon/issues/1

	local label actual_constraints
	label=$( get_tag_label "${tag}" )
	if ! actual_constraints=$( sandboxed_cabal_dry_freeze_constraints "${label}" "${source_dir}" ); then
		log_warning 'Failed to freeze constraints'
		return 0
	fi

	local constraints_hash actual_hash
	constraints_hash=$( get_tag_constraints_hash "${tag}" )
	actual_hash=$( hash_constraints "${actual_constraints}" ) || die
	if [[ "${actual_hash}" != "${constraints_hash}" ]]; then
		log_warning 'Unexpected constraints difference'
		log_warning 'See https://github.com/mietek/halcyon/issues/1 for details'
		diff --unified \
			<( format_constraints <<<"${constraints}" ) \
			<( format_constraints <<<"${actual_constraints}" ) |
				filter_not_first |
				filter_not_first |
				quote || true
	fi
}


validate_full_constraints_file () {
	local tag candidate_file
	expect_args tag candidate_file -- "$@"

	if [[ ! -f "${candidate_file}" ]]; then
		return 1
	fi

	local candidate_constraints
	candidate_constraints=$( read_constraints <"${candidate_file}" ) || die

	local constraints_hash candidate_hash
	constraints_hash=$( get_tag_constraints_hash "${tag}" )
	candidate_hash=$( hash_constraints "${candidate_constraints}" ) || die

	if [[ "${candidate_hash}" != "${constraints_hash}" ]]; then
		return 1
	fi

	echo "${candidate_hash}"
}


validate_partial_constraints_file () {
	local candidate_file
	expect_args candidate_file -- "$@"

	if [[ ! -f "${candidate_file}" ]]; then
		return 1
	fi

	local candidate_constraints
	candidate_constraints=$( read_constraints <"${candidate_file}" ) || die

	local constraints_name short_hash_etc short_hash candidate_hash
	constraints_name=$( basename "${candidate_file}" ) || die
	short_hash_etc="${constraints_name#halcyon-sandbox-}"
	short_hash="${short_hash_etc%%[-.]*}"
	candidate_hash=$( hash_constraints "${candidate_constraints}" ) || die

	if [[ "${candidate_hash:0:7}" != "${short_hash}" ]]; then
		return 1
	fi

	echo "${candidate_hash}"
}


match_full_sandbox_dir () {
	expect_vars HALCYON_CACHE \
		HALCYON_INTERNAL_PLATFORM

	local tag all_names
	expect_args tag all_names -- "$@"

	local ghc_id full_pattern full_names
	ghc_id=$( format_ghc_id "${tag}" ) || die
	full_pattern=$( format_full_sandbox_constraints_file_name_pattern "${tag}" ) || die
	full_names=$(
		filter_matching "^${full_pattern}$" <<<"${all_names}" |
		match_at_least_one
	) || return 1

	log 'Examining fully matching sandbox directories'

	local full_name full_file full_hash
	while read -r full_name; do
		full_file="${HALCYON_CACHE}/${full_name}"
		if ! full_hash=$( validate_full_constraints_file "${tag}" "${full_file}" ); then
			if ! cache_stored_file "${HALCYON_INTERNAL_PLATFORM}/ghc-${ghc_id}" "${full_name}" ||
				! full_hash=$( validate_full_constraints_file "${tag}" "${full_file}" )
			then
				continue
			fi
		else
			touch_cached_file "${full_name}" || die
		fi

		local full_label full_tag
		full_label=$( map_sandbox_constraints_file_name_to_label "${full_name}" ) || die
		full_tag=$( derive_matching_sandbox_tag "${tag}" "${full_label}" "${full_hash}" )

		echo "${full_tag}"
		return 0
	done <<<"${full_names}"

	return 1
}


list_partial_sandbox_dirs () {
	expect_vars HALCYON_CACHE \
		HALCYON_INTERNAL_PLATFORM

	local tag constraints all_names
	expect_args tag constraints all_names -- "$@"

	local ghc_id full_pattern partial_names
	ghc_id=$( format_ghc_id "${tag}" ) || die
	full_pattern=$( format_full_sandbox_constraints_file_name_pattern "${tag}" ) || die
	partial_names=$(
		filter_not_matching "^${full_pattern}$" <<<"${all_names}" |
		match_at_least_one
	) || return 0

	log 'Examining partially matching sandbox directories'

	local partial_name partial_file partial_hash
	while read -r partial_name; do
		partial_file="${HALCYON_CACHE}/${partial_name}"
		if ! partial_hash=$( validate_partial_constraints_file "${partial_file}" ); then
			if ! cache_stored_file "${HALCYON_INTERNAL_PLATFORM}/ghc-${ghc_id}" "${partial_name}" ||
				! partial_hash=$( validate_partial_constraints_file "${partial_file}" )
			then
				continue
			fi
		else
			touch_cached_file "${partial_name}" || die
		fi

		local partial_label partial_tag
		partial_label=$( map_sandbox_constraints_file_name_to_label "${partial_name}" ) || die
		partial_tag=$( derive_matching_sandbox_tag "${tag}" "${partial_label}" "${partial_hash}" )

		echo "${partial_tag}"
	done <<<"${partial_names}"
}


score_partial_sandbox_dirs () {
	expect_vars HALCYON_CACHE

	local constraints partial_tags
	expect_args constraints partial_tags -- "$@"

	local -A packages_A
	local package version
	packages_A=()
	while read -r package version; do
		packages_A["${package}"]="${version}"
	done <<<"${constraints}"

	log 'Scoring partially matching sandbox directories'

	local partial_tag partial_name partial_file
	while read -r partial_tag; do
		partial_name=$( format_sandbox_constraints_file_name "${partial_tag}" ) || die
		partial_file="${HALCYON_CACHE}/${partial_name}"
		if ! validate_partial_constraints_file "${partial_file}" >'/dev/null'; then
			continue
		fi

		local partial_constraints description
		partial_constraints=$( read_constraints <"${partial_file}" ) || die
		description=$( format_sandbox_description "${partial_tag}" ) || die

		local partial_package partial_version version score
		score=0
		while read -r partial_package partial_version; do
			version="${packages_A[${partial_package}]:-}"
			if [[ -z "${version}" ]]; then
				log_indent "Ignoring ${description} as ${partial_package}-${partial_version} is not needed"
				score=''
				break
			fi
			if [[ "${partial_version}" != "${version}" ]]; then
				log_indent "Ignoring ${description} as ${partial_package}-${partial_version} is not ${version}"
				score=''
				break
			fi

			score=$(( score + 1 ))
		done <<<"${partial_constraints}"
		if [[ -n "${score}" ]]; then
			local pad
			pad='       '
			log_indent "${pad:0:$(( 7 - ${#score} ))}${score}" "${description}"

			if (( score )); then
				echo "${score} ${partial_tag}"
			fi
		fi
	done <<<"${partial_tags}"
}


match_sandbox_dir () {
	expect_vars HALCYON_NO_BUILD HALCYON_NO_BUILD_DEPENDENCIES \
		HALCYON_INTERNAL_PLATFORM

	local tag constraints
	expect_args tag constraints -- "$@"

	local ghc_id constraints_name name_prefix partial_pattern
	ghc_id=$( format_ghc_id "${tag}" ) || die
	constraints_name=$( format_sandbox_constraints_file_name "${tag}" ) || die
	name_prefix=$( format_sandbox_common_file_name_prefix ) || die
	partial_pattern=$( format_partial_sandbox_constraints_file_name_pattern "${tag}" ) || die

	log 'Locating sandbox directories'

	local all_names
	all_names=$(
		list_stored_files "${HALCYON_INTERNAL_PLATFORM}/ghc-${ghc_id}/${name_prefix}" |
		sed "s:^${HALCYON_INTERNAL_PLATFORM}/ghc-${ghc_id}/::" |
		filter_matching "^${partial_pattern}$" |
		filter_not_matching "^${constraints_name}$" |
		sort_natural -u |
		match_at_least_one
	) || return 1

	local full_tag
	if full_tag=$( match_full_sandbox_dir "${tag}" "${all_names}" ); then
		echo "${full_tag}"
		return 0
	fi

	if (( HALCYON_NO_BUILD )) || (( HALCYON_NO_BUILD_DEPENDENCIES )); then
		return 1
	fi

	local partial_tags result
	partial_tags=$( list_partial_sandbox_dirs "${tag}" "${constraints}" "${all_names}" ) || die
	if result=$(
		score_partial_sandbox_dirs "${constraints}" "${partial_tags}" |
		sort_natural |
		filter_last |
		match_exactly_one
	); then
		echo "${result#* }"
		return 0
	fi

	return 1
}
