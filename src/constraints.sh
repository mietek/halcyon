function read_constraints () {
	awk '/^ *[Cc]onstraints:/, !/[:,]/ { print }' |
		tr -d '\r' |
		sed 's/[Cc]onstraints://;s/[, ]//g;s/==/ /;/^$/d'
}


function read_dry_frozen_constraints () {
	tail -n +3 | sed 's/ == / /'
}


function filter_correct_constraints () {
	local app_label
	expect_args app_label -- "$@"

	# NOTE: Cabal includes the package itself in the list of frozen constraints.
	# https://github.com/haskell/cabal/issues/1908

	local app_name app_version
	app_name="${app_label%-*}"
	app_version="${app_label##*-}"

	filter_not_matching "^${app_name} ${app_version}$" || die
}


function format_constraints () {
	awk 'BEGIN { printf "constraints:"; separator = " " }
		!/^$/ { printf "%s%s ==%s", separator, $1, $2; separator = ",\n             " }
		END { printf "\n" }'
}


function format_constraint_file_name () {
	local tag
	expect_args tag -- "$@"

	local app_label constraint_hash
	app_label=$( get_tag_app_label "${tag}" ) || die
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die

	echo "halcyon-constraints-${constraint_hash:0:7}-${app_label}"
}


function format_constraint_file_name_prefix () {
	echo "halcyon-constraints-"
}


function format_full_constraint_file_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local constraint_hash
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die

	echo "halcyon-constraints-${constraint_hash:0:7}-.*"
}


function format_partial_constraint_file_name_pattern () {
	echo "halcyon-constraints-.*-.*"
}


function map_constraint_file_name_to_app_label () {
	local file_name
	expect_args file_name -- "$@"

	echo "${file_name#halcyon-constraints-*-}"
}


function hash_constraints () {
	local constraints
	expect_args constraints -- "$@"

	do_hash <<<"${constraints}" || die
}


function freeze_implicit_constraints () {
	local app_label source_dir
	expect_args app_label source_dir -- "$@"

	cabal_do "${source_dir}" --no-require-sandbox freeze --dry-run |
		read_dry_frozen_constraints |
		filter_correct_constraints "${app_label}" || die
}


function freeze_actual_constraints () {
	local app_label source_dir
	expect_args app_label source_dir -- "$@"

	sandboxed_cabal_do "${source_dir}" freeze --dry-run |
		read_dry_frozen_constraints |
		filter_correct_constraints "${app_label}" || die
}


function validate_full_constraint_file () {
	local tag constraint_file
	expect_args tag constraint_file -- "$@"

	local constraint_hash constraints candidate_hash
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	constraints=$( read_constraints <"${constraint_file}" ) || die
	candidate_hash=$( hash_constraints "${constraints}" ) || die
	if [ "${candidate_hash}" != "${constraint_hash}" ]; then
		return 1
	fi

	echo "${candidate_hash}"
}


function validate_partial_constraint_file () {
	local constraint_file
	expect_args constraint_file -- "$@"

	local file_name short_hash constraints candidate_hash
	file_name=$( basename "${constraint_file}" ) || die
	short_hash_etc=$( "${file_name#halcyon-constraints-}" ) || die
	short_hash=$( "${short_hash_etc%%-*}" ) || die
	constraints=$( read_constraints <"${constraint_file}" ) || die
	candidate_hash=$( hash_constraints "${constraints}" ) || die
	if [ "${candidate_hash:0:7}" != "${short_hash}" ]; then
		return 1
	fi

	echo "${candidate_hash}"
}


function locate_all_matching_sandbox_layers () {
	local tag
	expect_args tag -- "$@"

	local os ghc_version file_name constraint_prefix partial_pattern
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	file_name=$( format_constraint_file_name "${tag}" ) || die
	constraint_prefix=$( format_constraint_file_name_prefix ) || die
	partial_pattern=$( format_partial_constraint_file_name_pattern ) || die

	log 'Locating matching sandbox layers'

	local file_names
	if ! file_names=$(
		list_layer "${os}/ghc-${ghc_version}/${constraint_prefix}" |
		sed "s:${os}/ghc-${ghc_version}/::" |
		filter_matching "^${partial_pattern}$" |
		filter_not_matching "^${file_name}$" |
		sort_naturally |
		match_at_least_one
	); then
		log 'Cannot locate any matching sandbox layers'
		return 1
	fi

	echo "${file_names}"
}


function locate_first_full_sandbox_layer () {
	expect_vars HALCYON_CACHE_DIR

	local tag all_names
	expect_args tag all_names -- "$@"

	local os ghc_version full_pattern all_names full_names
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	full_pattern=$( format_full_constraint_file_name_pattern "${tag}" ) || die
	if ! full_names=$(
		filter_matching "^${full_pattern}$" <<<"${all_names}" |
		match_at_least_one
	); then
		log 'Cannot locate any fully matching sandbox layers'
		return 1
	fi

	log 'Examining fully matching sandbox layers'

	local full_name
	while read -r full_name; do
		local full_hash
		if ! [ -f "${HALCYON_CACHE_DIR}/${full_name}" ] ||
			! full_hash=$( validate_full_constraint_file "${tag}" "${HALCYON_CACHE_DIR}/${full_name}" )
		then
			rm -f "${HALCYON_CACHE_DIR}/${full_name}" || die
			if ! download_layer "${os}/ghc-${ghc_version}" "${full_name}" "${HALCYON_CACHE_DIR}"; then
				log_warning 'Cannot download fully matching sandbox layer constraints'
				continue
			fi

			if ! full_hash=$( validate_full_constraint_file "${tag}" "${HALCYON_CACHE_DIR}/${full_name}" ); then
				rm -f "${HALCYON_CACHE_DIR}/${full_name}" || die
				log_warning 'Cannot validate fully matching sandbox layer constraints'
				continue
			fi
		else
			touch -c "${HALCYON_CACHE_DIR}/${full_name}" || true
		fi

		local full_label full_tag
		full_label=$( map_constraint_file_name_to_app_label "${full_name}" ) || die
		full_tag=$( derive_matching_sandbox_tag "${tag}" "${full_label}" "${full_hash}" ) || die

		echo "${full_tag}"
		return 0
	done <<<"${full_names}"

	log 'Cannot use any fully matching sandbox layers'
	return 1
}


function locate_partial_sandbox_layers () {
	expect_vars HALCYON_CACHE_DIR

	local tag constraints all_names
	expect_args tag constraints all_names -- "$@"

	local os ghc_version full_pattern all_names partial_names
	os=$( get_tag_os "${tag}" ) || die
	ghc_version=$( get_tag_ghc_version "${tag}" ) || die
	full_pattern=$( format_full_constraint_file_name_pattern "${tag}" ) || die
	if ! partial_names=$(
		filter_not_matching "^${full_pattern}" <<<"${all_names}" |
		match_at_least_one
	); then
		log 'Cannot locate any partially matching sandbox layers'
		return 1
	fi

	log 'Examining partially matching sandbox layers'

	local partial_name
	while read -r partial_name; do
		local partial_hash
		if ! [ -f "${HALCYON_CACHE_DIR}/${partial_name}" ] ||
			! partial_hash=$( validate_partial_constraint_file "${HALCYON_CACHE_DIR}/${partial_name}" )
		then
			rm -f "${HALCYON_CACHE_DIR}/${partial_name}" || die
			if ! download_layer "${os}/ghc-${ghc_version}" "${partial_name}" "${HALCYON_CACHE_DIR}"; then
				log_warning 'Cannot download partially matching sandbox layer constraints'
				continue
			fi

			if ! partial_hash=$( validate_partial_constraint_file "${HALCYON_CACHE_DIR}/${partial_name}" ); then
				rm -f "${HALCYON_CACHE_DIR}/${partial_name}" || die
				log_warning 'Cannot validate partially matching sandbox layer constraints'
				continue
			fi
		else
			touch -c "${HALCYON_CACHE_DIR}/${partial_name}" || true
		fi

		local partial_label partial_tag
		partial_label=$( map_constraint_file_name_to_app_label "${partial_name}" ) || die
		partial_tag=$( derive_matching_sandbox_tag "${tag}" "${partial_label}" "${partial_hash}" ) || die

		echo "${partial_tag}"
	done <<<"${partial_names}"

	log 'Cannot use any partially matching sandbox layers'
	return 1
}


function select_best_partial_sandbox_layer () {
	expect_vars HALCYON_CACHE_DIR

	local constraints partial_tags
	expect_args constraints partial_tags -- "$@"

	local -A constraints_A
	local package version
	while read -r package version; do
		constraints_A["${package}"]="${version}"
	done <<<"${constraints}"

	log 'Selecting best partially matching sandbox layer'

	local -a results
	local partial_tag
	while read -r partial_tag; do
		local partial_name
		partial_name=$( format_constraint_file_name "${partial_tag}" ) || die
		if ! [ -f "${HALCYON_CACHE_DIR}/${partial_name}" ]; then
			continue
		fi

		local partial_constraints partial_hash
		partial_constraints=$( read_constraints <"${HALCYON_CACHE_DIR}/partial_name}" ) || die
		partial_hash=$( get_tag_constraint_hash "${partial_tag}" ) || die

		log_begin "Scoring ${partial_hash}..."

		local score partial_package partial_version
		score=0
		while read -r partial_package partial_version; do
			local version
			version="${constraints_A[${partial_package}]:-}"
			if [ -z "${version}" ]; then
				log_end '0'
				log_indent 'Unnecessary package:                     ' "${partial_package}-${partial_version}"

				score=
				break
			fi
			if "${partial_version}" != "${version}" ]; then
				log_end '0'
				log_indent 'Unusable package version:                ' "${partial_package}-${partial_version} ({version})"

				score=
				break
			fi

			score=$(( score + 1 ))
		done <<<"${partial_constraints}"
		if [ -n "${score}" ]; then
			log_end "${score}"
		fi

		results+=( "${score} ${partial_tag}" )
	done <<<"${partial_tags}"

	local result
	if ! result=$(
		( IFS=$'\n' && echo -n "${results[*]:-}" ) |
		filter_not_matching '^0 ' |
		sort_naturally |
		filter_last |
		match_exactly_one
	); then
		log 'Cannot select any partially matching sandbox layers'
		return 1
	fi

	echo "${result#* }"
}


function locate_best_matching_sandbox_layer () {
	local tag constraints
	expect_args tag constraints -- "$@"

	local all_names
	if ! all_names=$( locate_all_matching_sandbox_layers "${tag}" ); then
		return 1
	fi

	local full_tag
	if full_tag=$( locate_first_full_sandbox_layer "${tag}" "${all_names}" ); then
		echo "${full_tag}"
		return 0
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


function validate_actual_constraints () {
	local tag constraints actual_constraints
	expect_args tag constraints actual_constraints -- "$@"

	# NOTE: Cabal sometimes gives different results when freezing constraints before and after installation.
	# https://github.com/haskell/cabal/issues/1896
	# https://github.com/mietek/halcyon/issues/1

	local constraint_hash actual_hash
	constraint_hash=$( get_tag_constraint_hash "${tag}" ) || die
	actual_hash=$( hash_constraints "${actual_constraints}" ) || die
	if [ "${actual_hash}" = "${constraint_hash}" ]; then
		return 0
	fi

	log_warning 'Unexpected constraints difference'
	log_warning 'Please report this on https://github.com/mietek/halcyon/issues/1'
	log_indent "--- ${constraint_hash:0:7}/cabal.config"
	log_indent "+++ ${actual_constraint_hash:0:7}/cabal.config"
	diff -u <( echo "${constraints}" ) <( echo "${actual_constraints}" ) | tail -n +3 |& quote || true
}
