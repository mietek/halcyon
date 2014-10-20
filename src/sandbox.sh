function echo_sandbox_tag () {
	expect_vars HALCYON_DIR

	local ghc_tag constraints_hash sandbox_magic_hash sandbox_label
	expect_args ghc_tag constraints_hash sandbox_magic_hash sandbox_label -- "$@"

	local os ghc_version ghc_magic_hash
	os=$( detect_os ) || die
	ghc_version=$( echo_ghc_version "${ghc_tag}" ) || die
	ghc_magic_hash=$( echo_ghc_magic_hash "${ghc_tag}" ) || die

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_magic_hash}\t${constraints_hash}\t${sandbox_magic_hash}\t${sandbox_label}"
}


function echo_sandbox_os () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${sandbox_tag}"
}


function echo_sandbox_constraints_hash () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $5 }' <<<"${sandbox_tag}"
}


function echo_sandbox_magic_hash () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $6 }' <<<"${sandbox_tag}"
}


function echo_sandbox_label () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $7 }' <<<"${sandbox_tag}"
}


function echo_sandbox_id () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local constraints_hash magic_hash
	constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die
	magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die

	echo "${constraints_hash:0:7}${magic_hash:+~${magic_hash:0:7}}"
}


function echo_sandbox_description () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local sandbox_id sandbox_label
	sandbox_id=$( echo_sandbox_id "${sandbox_tag}" ) || die
	sandbox_label=$( echo_sandbox_label "${sandbox_tag}" ) || die

	echo "${sandbox_id} (${sandbox_label})"
}


function echo_sandbox_archive_name () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id sandbox_id sandbox_label
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	sandbox_id=$( echo_sandbox_id "${sandbox_tag}" ) || die
	sandbox_label=$( echo_sandbox_label "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id}-${sandbox_id}-${sandbox_label}.tar.xz"
}


function echo_sandbox_constraints_name () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id sandbox_id sandbox_label
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	sandbox_id=$( echo_sandbox_id "${sandbox_tag}" ) || die
	sandbox_label=$( echo_sandbox_label "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id}-${sandbox_id}-${sandbox_label}.constraints"
}


function echo_short_hash_from_sandbox_constraints_name () {
	local constraints_name
	expect_args constraints_name -- "$@"

	local constraints_hash_etc
	constraints_hash_etc="${constraints_name#halcyon-sandbox-ghc-*-}"

	echo "${constraints_hash_etc%%[~-]*}"
}


function echo_label_from_sandbox_constraints_name () {
	local constraints_name
	expect_args constraints_name -- "$@"

	local sandbox_label_etc
	sandbox_label_etc="${constraints_name#halcyon-sandbox-ghc-*-*-}"

	echo "${sandbox_label_etc%.constraints}"
}


function echo_sandbox_constraints_name_prefix () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id}-"
}


function echo_fully_matched_sandbox_constraints_name_pattern () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id constraints_hash magic_hash
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die
	magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id//./\.}-${constraints_hash:0:7}${magic_hash:+~${magic_hash:0:7}}-.*\.constraints"
}


function echo_partially_matched_sandbox_constraints_name_pattern () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id magic_hash
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id//./\.}-[^~]*${magic_hash:+~${magic_hash:0:7}}-.*\.constraints"
}


function echo_sandbox_constraints () {
	awk 'BEGIN { printf "constraints:"; separator = " " }
		!/^$/ { printf "%s%s ==%s", separator, $1, $2; separator = ",\n             " }
		END { printf "\n" }'
}


function read_sandbox_constraints () {
	awk '/^ *[Cc]onstraints:/, !/[:,]/ { print }' |
		tr -d '\r' |
		sed 's/[Cc]onstraints://;s/[, ]//g;s/==/ /;/^$/d'
}


function filter_valid_sandbox_constraints () {
	local -A constraints_A
	local candidate_package candidate_version constraints
	constraints=$(
		while read -r candidate_package candidate_version; do
			if [ -n "${constraints_A[${candidate_package}]:+_}" ]; then
				die "Expected at most one ${candidate_package} constraint"
			fi
			constraints_A["${candidate_package}"]="${candidate_version}"

			echo "${candidate_package} ${candidate_version}"
		done
	) || die

	if ! filter_matching "^base " <<<"${constraints}" |
		match_exactly_one >'/dev/null'
	then
		die 'Expected base package constraint'
	fi

	sort_naturally <<<"${constraints}" || die
}


function filter_nonself_sandbox_constraints () {
	local app_dir
	expect_args app_dir -- "$@"

	# NOTE: An application should not be its own dependency.
	# https://github.com/haskell/cabal/issues/1908

	local app_name app_version
	app_name=$( detect_app_name "${app_dir}" ) || die
	app_version=$( detect_app_version "${app_dir}" ) || die

	filter_not_matching "^${app_name} ${app_version}$" || die
}


function detect_sandbox_constraints () {
	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}/cabal.config"

	read_sandbox_constraints <"${app_dir}/cabal.config" |
		filter_valid_sandbox_constraints |
		filter_nonself_sandbox_constraints "${app_dir}" || die
}


function derive_matched_sandbox_tag () {
	expect_vars HALCYON_DIR

	local ghc_tag sandbox_tag matched_hash matched_label
	expect_args ghc_tag sandbox_tag matched_hash matched_label -- "$@"

	local magic_hash
	magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die

	echo_sandbox_tag "${ghc_tag}" "${matched_hash}" "${magic_hash}" "${matched_label}"
}


function validate_sandbox_tag () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	if [ "${candidate_tag}" != "${sandbox_tag}" ]; then
		return 1
	fi
}


function validate_sandbox_constraints () {
	local constraints_hash
	expect_args constraints_hash -- "$@"

	local candidate_hash
	candidate_hash=$( read_sandbox_constraints | do_hash ) || die

	if [ "${candidate_hash}" != "${constraints_hash}" ]; then
		return 1
	fi
}


function validate_sandbox_constraints_name_with_short_hash () {
	local short_constraints_hash
	expect_args short_constraints_hash -- "$@"

	local candidate_hash
	candidate_hash=$( read_sandbox_constraints | do_hash ) || die

	if [ "${candidate_hash:0:7}" != "${short_constraints_hash}" ]; then
		return 1
	fi
}


function validate_sandbox_magic () {
	local magic_hash app_dir
	expect_args magic_hash app_dir -- "$@"

	local candidate_hash
	candidate_hash=$( hash_spaceless_recursively "${app_dir}/.halcyon-magic" -name 'sandbox-*' ) || die

	if [ "${candidate_hash}" != "${magic_hash}" ]; then
		return 1
	fi
}


function validate_sandbox () {
	expect_vars HALCYON_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local constraints_hash magic_hash
	constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die
	magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die

	if ! [ -f "${HALCYON_DIR}/sandbox/.halcyon-tag" ] ||
		! validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/.halcyon-tag" ||
		! validate_sandbox_constraints "${constraints_hash}" <"${HALCYON_DIR}/sandbox/.halcyon-sandbox.constraints" ||
		! validate_sandbox_magic "${magic_hash}" "${HALCYON_DIR}/sandbox"
	then
		return 1
	fi
}


function verify_sandbox_constraints () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local sandbox_tag app_dir
	expect_args sandbox_tag app_dir -- "$@"

	# NOTE: Frozen constraints should never differ before and after installation.
	# https://github.com/haskell/cabal/issues/1896
	# https://github.com/mietek/halcyon/issues/1

	local actual_constraints actual_constraints_hash constraints_hash
	actual_constraints=$( cabal_freeze_actual_constraints "${HALCYON_DIR}/sandbox" "${app_dir}" ) || die
	actual_constraints_hash=$( do_hash <<<"${actual_constraints}" ) || die
	constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die

	if [ "${actual_constraints_hash}" != "${constraints_hash}" ]; then
		local tmp_constraints_name constraints_name
		tmp_constraints_name=$( echo_tmp_file_name 'halcyon.verify_sandbox_constraints' ) || die
		constraints_name=$( echo_sandbox_constraints_name "${sandbox_tag}" ) || die
		expect_existing "${HALCYON_CACHE_DIR}/${constraints_name}"

		echo_sandbox_constraints <<<"${actual_constraints}" >"${tmp_constraints_name}" || die

		log_warning 'Unexpected constraints difference'
		log_warning 'Please report this on https://github.com/mietek/halcyon/issues/1'
		log_indent "--- ${constraints_hash:0:7}/cabal.config"
		log_indent "+++ ${actual_constraints_hash:0:7}/cabal.config"
		diff -u "${HALCYON_CACHE_DIR}/${constraints_name}" "${tmp_constraints_name}" | tail -n +3 |& quote || true

		rm -f "${tmp_constraints_name}" || die
	fi
}


function build_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/cabal/.halcyon-tag"

	local sandbox_tag extending_sandbox app_dir
	expect_args sandbox_tag extending_sandbox app_dir -- "$@"
	if (( extending_sandbox )); then
		expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-sandbox.constraints"
	else
		expect_no_existing "${HALCYON_DIR}/sandbox"
	fi
	expect_existing "${app_dir}"

	local ghc_tag constraints_name
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	constraints_name=$( echo_sandbox_constraints_name "${sandbox_tag}" ) || die
	expect_existing "${HALCYON_CACHE_DIR}/${constraints_name}"

	log 'Starting to build sandbox layer'

	if ! (( extending_sandbox )); then
		log 'Creating sandbox'

		cabal_create_sandbox "${HALCYON_DIR}/sandbox" || die
		mv "${HALCYON_DIR}/sandbox/cabal.sandbox.config" "${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" || die
	fi

	# TODO: insert build-time deps here

	if [ -f "${app_dir}/.halcyon-magic/sandbox-prebuild-hook" ]; then
		log 'Running sandbox pre-build hook'
		( "${app_dir}/.halcyon-magic/sandbox-prebuild-hook" "${ghc_tag}" "${sandbox_tag}" "${extending_sandbox}" "${app_dir}" ) |& quote || die
	fi

	log 'Building sandbox'

	cabal_install_deps "${HALCYON_DIR}/sandbox" "${app_dir}" || die
	cp "${HALCYON_CACHE_DIR}/${constraints_name}" "${HALCYON_DIR}/sandbox/.halcyon-sandbox.constraints" || die

	if [ -f "${app_dir}/.halcyon-magic/sandbox-postbuild-hook" ]; then
		log 'Running sandbox post-build hook'
		( "${app_dir}/.halcyon-magic/sandbox-postbuild-hook" "${ghc_tag}" "${sandbox_tag}" "${extending_sandbox}" "${app_dir}" ) |& quote || die
	fi

	if find_spaceless_recursively "${app_dir}/.halcyon-magic" -name 'sandbox-*' |
		match_at_least_one >'/dev/null'
	then
		mkdir -p "${HALCYON_DIR}/cabal/.halcyon-magic" || die
		cp "${app_dir}/.halcyon-magic/sandbox-"* "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
	fi

	echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die

	local sandbox_size
	sandbox_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log "Finished building sandbox layer, ${sandbox_size}"

	verify_sandbox_constraints "${sandbox_tag}" "${app_dir}" || die
}


function strip_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local sandbox_tag
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die

	log_begin "Stripping sandbox layer..."

	find "${HALCYON_DIR}/sandbox"       \
			-type f        -and \
			\(                  \
			-name '*.so'   -or  \
			-name '*.so.*' -or  \
			-name '*.a'         \
			\)                  \
			-print0 |
		strip0 --strip-unneeded

	local sandbox_size
	sandbox_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log_end "${sandbox_size}"
}


function archive_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag"

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	local sandbox_tag os sandbox_archive constraints_name
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	os=$( echo_sandbox_os "${sandbox_tag}" ) || die
	sandbox_archive=$( echo_sandbox_archive_name "${sandbox_tag}" ) || die
	constraints_name=$( echo_sandbox_constraints_name "${sandbox_tag}" ) || die
	expect_existing "${HALCYON_CACHE_DIR}/${constraints_name}"

	log 'Archiving sandbox layer'

	rm -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" || die
	tar_archive "${HALCYON_DIR}/sandbox" "${HALCYON_CACHE_DIR}/${sandbox_archive}" || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${os}"; then
		log_warning 'Cannot upload sandbox layer archive'
	fi
	if ! upload_layer "${HALCYON_CACHE_DIR}/${constraints_name}" "${os}"; then
		log_warning 'Cannot upload sandbox layer constraints'
	fi
}


function restore_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local os sandbox_archive
	os=$( echo_sandbox_os "${sandbox_tag}" ) || die
	sandbox_archive=$( echo_sandbox_archive_name "${sandbox_tag}" ) || die

	if validate_sandbox "${sandbox_tag}"; then
		touch -c "${HALCYON_CACHE_DIR}/${sandbox_archive}" || true
		log 'Using installed sandbox layer'
		return 0
	fi
	rm -rf "${HALCYON_DIR}/sandbox" || die

	log 'Restoring sandbox layer'

	if ! [ -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" ||
		! validate_sandbox "${sandbox_tag}"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" || die

		if ! download_layer "${os}" "${sandbox_archive}" "${HALCYON_CACHE_DIR}"; then
			log 'Cannot download sandbox layer archive'
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" ||
			! validate_sandbox "${sandbox_tag}"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" || die
			log_warning 'Cannot extract sandbox layer archive'
			return 1
		fi
	else
		touch -c "${HALCYON_CACHE_DIR}/${sandbox_archive}" || true
	fi
}


function activate_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag"

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	if [ -e "${app_dir}/cabal.sandbox.config" ] && ! [ -h "${app_dir}/cabal.sandbox.config" ]; then
		die "Expected no foreign ${app_dir}/cabal.sandbox.config"
	fi

	rm -f "${app_dir}/cabal.sandbox.config" || die
	ln -s "${HALCYON_DIR}/sandbox/.halcyon-sandbox.config" "${app_dir}/cabal.sandbox.config" || die

	log "Sandbox layer installed:"
	log_indent "${sandbox_description}"
}


function deactivate_sandbox () {
	expect_vars HALCYON_DIR

	local app_dir
	expect_args app_dir -- "$@"

	if [ -e "${app_dir}/cabal.sandbox.config" ] && ! [ -h "${app_dir}/cabal.sandbox.config" ]; then
		die "Expected no foreign ${app_dir}/cabal.sandbox.config"
	fi

	rm -rf "${HALCYON_DIR}/sandbox" "${app_dir}/cabal.sandbox.config" || die
}


function determine_sandbox_tag () {
	expect_vars HALCYON_DIR HALCYON_NO_WARN_IMPLICIT
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	log_begin 'Determining sandbox constraints hash...'

	local constraints constraints_hash
	if [ -f "${app_dir}/cabal.config" ]; then
		constraints=$( detect_sandbox_constraints "${app_dir}" ) || die
		constraints_hash=$( do_hash <<<"${constraints}" ) || die

		log_end "${constraints_hash:0:7}"
	else
		constraints=$( cabal_freeze_implicit_constraints "${app_dir}" ) || die
		constraints_hash=$( do_hash <<<"${constraints}" ) || die

		log_end "${constraints_hash:0:7}"
		if ! (( HALCYON_NO_WARN_IMPLICIT )); then
			log_warning 'Using newest available versions of all packages'
			log_warning 'Expected cabal.config with explicit constraints'
			log
			help_add_explicit_constraints "${constraints}"
			log
		fi
	fi

	log_begin 'Determining sandbox magic hash...'

	local magic_hash
	magic_hash=$( hash_spaceless_recursively "${app_dir}/.halcyon-magic" -name 'sandbox-*' ) || die
	if [ -z "${magic_hash}" ]; then
		log_end '(none)'
	else
		log_end "${magic_hash:0:7}"
	fi

	log_begin 'Determining sandbox label...'

	local sandbox_label
	sandbox_label=$( detect_app_label "${app_dir}" ) || die

	log_end "${sandbox_label}"

	local ghc_tag sandbox_tag constraints_name
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_tag=$( echo_sandbox_tag "${ghc_tag}" "${constraints_hash}" "${magic_hash}" "${sandbox_label}" ) || die
	constraints_name=$( echo_sandbox_constraints_name "${sandbox_tag}" ) || die

	echo_sandbox_constraints <<<"${constraints}" >"${HALCYON_CACHE_DIR}/${constraints_name}" || die

	echo "${sandbox_tag}"
}


function score_partially_matched_sandbox_constraints () {
	local sandbox_tag part_description
	expect_args sandbox_tag part_description -- "$@"

	local constraints_name
	constraints_name=$( echo_sandbox_constraints_name "${sandbox_tag}" ) || die
	expect_existing "${HALCYON_CACHE_DIR}/${constraints_name}"

	local constraints
	constraints=$( read_sandbox_constraints <"${HALCYON_CACHE_DIR}/${constraints_name}" ) || die

	local -A constraints_A
	local package version
	while read -r package version; do
		constraints_A["${package}"]="${version}"
	done <<<"${constraints}"

	local part_score part_package part_version
	part_score=0
	while read -r part_package part_version; do
		local version
		version="${constraints_A[${part_package}]:-}"
		if [ -z "${version}" ]; then
			log_indent "Ignoring ${part_description} as ${part_package} is not needed"
			echo 0
			return 0
		fi
		if [ "${part_version}" != "${version}" ]; then
			log_indent "Ignoring ${part_description} as ${part_package}-${part_version} is not ${version}"
			echo 0
			return 0
		fi

		part_score=$(( part_score + 1 ))
	done

	log_indent "${part_score}"$'\t'"${part_description}"

	echo "${part_score}"
}


function match_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	log 'Locating matched sandbox layers'

	local os ghc_tag constraints_prefix part_pattern full_pattern constraints_name
	os=$( echo_sandbox_os "${sandbox_tag}" ) || die
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	constraints_prefix=$( echo_sandbox_constraints_name_prefix "${sandbox_tag}" ) || die
	part_pattern=$( echo_partially_matched_sandbox_constraints_name_pattern "${sandbox_tag}" ) || die
	full_pattern=$( echo_fully_matched_sandbox_constraints_name_pattern "${sandbox_tag}" ) || die
	constraints_name=$( echo_sandbox_constraints_name "${sandbox_tag}" ) || die

	local constraints_names
	if ! constraints_names=$(
		list_layer "${os}/${constraints_prefix}" |
		sed "s:${os}/::" |
		filter_matching "^${part_pattern}$" |
		filter_not_matching "^${constraints_name}$" |
		sort_naturally |
		match_at_least_one
	); then
		log 'Cannot locate any matched sandbox layer'
		return 1
	fi

	local full_names
	if full_names=$(
		filter_matching "^${full_pattern}$" <<<"${constraints_names}" |
		match_at_least_one
	); then
		local constraints_hash
		constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die

		log 'Examining fully matched sandbox layers'

		local full_name
		while read -r full_name; do
			if ! [ -f "${HALCYON_CACHE_DIR}/${full_name}" ] ||
				! validate_sandbox_constraints "${constraints_hash}" <"${HALCYON_CACHE_DIR}/${full_name}"
			then
				rm -f "${HALCYON_CACHE_DIR}/${full_name}" || die
				if ! download_layer "${os}" "${full_name}" "${HALCYON_CACHE_DIR}"; then
					log_warning 'Cannot download fully matched sandbox layer constraints'
					continue
				fi

				if ! validate_sandbox_constraints "${constraints_hash}" <"${HALCYON_CACHE_DIR}/${full_name}"; then
					rm -f "${HALCYON_CACHE_DIR}/${full_name}" || die
					log_warning 'Cannot validate fully matched sandbox layer constraints'
					continue
				fi
			else
				touch -c "${HALCYON_CACHE_DIR}/${full_name}" || true
			fi

			local full_label full_tag
			full_label=$( echo_label_from_sandbox_constraints_name "${full_name}" ) || die
			full_tag=$( derive_matched_sandbox_tag "${ghc_tag}" "${sandbox_tag}" "${constraints_hash}" "${full_label}" ) || die

			echo "full ${full_tag}"
			return 0
		done <<<"${full_names}"

		log 'Cannot use any fully matched sandbox layer'
	else
		log 'Cannot locate any fully matched sandbox layer'
	fi

	local part_names
	if ! part_names=$(
		filter_not_matching "^${full_pattern}$" <<<"${constraints_names}" |
		match_at_least_one
	); then
		log 'Cannot locate any partially matched sandbox layer'
		return 1
	fi

	log 'Examining partially matched sandbox layers'

	local part_name
	while read -r part_name; do
		local short_constraints_hash
		short_constraints_hash=$( echo_short_hash_from_sandbox_constraints_name "${part_name}" ) || die

		if ! [ -f "${HALCYON_CACHE_DIR}/${part_name}" ] ||
			! validate_sandbox_constraints_name_with_short_hash "${short_constraints_hash}" <"${HALCYON_CACHE_DIR}/${part_name}"
		then
			rm -f "${HALCYON_CACHE_DIR}/${part_name}" || die
			if ! download_layer "${os}" "${part_name}" "${HALCYON_CACHE_DIR}"; then
				log_warning 'Cannot download partially matched sandbox layer constraints'
				continue
			fi

			if ! validate_sandbox_constraints_name_with_short_hash "${short_constraints_hash}" <"${HALCYON_CACHE_DIR}/${part_name}"; then
				rm -f "${HALCYON_CACHE_DIR}/${part_name}" || die
				log_warning 'Cannot validate partially matched sandbox layer constraints'
				continue
			fi
		else
			touch -c "${HALCYON_CACHE_DIR}/${part_name}" || true
		fi
	done <<<"${part_names}"

	log 'Scoring partially matched sandbox layers'

	local scores
	if ! scores=$(
		local part_name
		while read -r part_name; do
			if ! [ -f "${HALCYON_CACHE_DIR}/${part_name}" ]; then
				continue
			fi

			local part_hash part_label part_tag part_description
			part_hash=$( read_sandbox_constraints <"${HALCYON_CACHE_DIR}/${part_name}" | do_hash ) || die
			part_label=$( echo_label_from_sandbox_constraints_name "${part_name}" ) || die
			part_tag=$( derive_matched_sandbox_tag "${ghc_tag}" "${sandbox_tag}" "${part_hash}" "${part_label}" ) || die
			part_description=$( echo_sandbox_description "${part_tag}" ) || die

			local score
			if ! score=$(
				read_sandbox_constraints <"${HALCYON_CACHE_DIR}/${part_name}" |
				sort_naturally |
				filter_valid_sandbox_constraints |
				score_partially_matched_sandbox_constraints "${sandbox_tag}" "${part_description}"
			); then
				continue
			fi

			echo -e "${score} ${part_tag}"
		done <<<"${part_names}" |
			filter_not_matching '^0 ' |
			sort_naturally |
			match_at_least_one
	); then
		log 'Cannot extend any partially matched sandbox layer'
		return 1
	fi

	filter_last <<<"${scores}" |
		match_exactly_one |
		sed 's/^.* /part /'
}


function install_matched_sandbox () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD

	local sandbox_tag matched_tag app_dir
	expect_args sandbox_tag matched_tag app_dir -- "$@"

	if ! restore_sandbox "${matched_tag}"; then
		return 1
	fi

	local constraints_hash magic_hash matched_constraints_hash matched_magic_hash matched_description
	constraints_hash=$( echo_sandbox_constraints_hash "${sandbox_tag}" ) || die
	magic_hash=$( echo_sandbox_magic_hash "${sandbox_tag}" ) || die
	matched_constraints_hash=$( echo_sandbox_constraints_hash "${matched_tag}" ) || die
	matched_magic_hash=$( echo_sandbox_magic_hash "${matched_tag}" ) || die
	matched_description=$( echo_sandbox_description "${matched_tag}" ) || die

	if [ "${matched_constraints_hash}" = "${constraints_hash}" ] && [ "${matched_magic_hash}" = "${magic_hash}" ]; then
		log 'Using fully matched sandbox layer:'
		log_indent "${matched_description}"

		echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die

		archive_sandbox || die
		activate_sandbox "${app_dir}" || die
		return 0
	fi

	if ! (( HALCYON_BUILD_SANDBOX )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build sandbox layer'
		return 1
	fi

	log 'Extending partially matched sandbox layer:'
	log_indent "${matched_description}"

	local extending_sandbox=1
	build_sandbox "${sandbox_tag}" "${extending_sandbox}" "${app_dir}" || die
	strip_sandbox || die
	archive_sandbox || die
	activate_sandbox "${app_dir}" || die
}


function install_sandbox () {
	expect_vars HALCYON_BUILD_SANDBOX HALCYON_NO_BUILD

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local sandbox_tag sandbox_description
	sandbox_tag=$( determine_sandbox_tag "${app_dir}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	if ! (( HALCYON_BUILD_SANDBOX )) && restore_sandbox "${sandbox_tag}"; then
		activate_sandbox "${app_dir}" || die
		return 0
	fi

	local match_result
	if ! (( HALCYON_BUILD_SANDBOX )) && match_result=$( match_sandbox "${sandbox_tag}" ); then
		local match_class match_tag
		match_class="${match_result%% *}"
		matched_tag="${match_result#* }"

		case "${match_class}" in
		'full')
			if install_matched_sandbox "${sandbox_tag}" "${matched_tag}" "${app_dir}"; then
				return 0
			fi
			;;
		'part')
			if ! (( HALCYON_BUILD_SANDBOX )) && (( HALCYON_NO_BUILD )); then
				log_warning 'Cannot build sandbox layer'
				return 1
			fi
			if install_matched_sandbox "${sandbox_tag}" "${matched_tag}" "${app_dir}"; then
				return 0
			fi
			;;
		*)
			die "Unexpected match class: ${match_class}"
		esac
	fi

	if ! (( HALCYON_BUILD_SANDBOX )) && (( HALCYON_NO_BUILD )); then
		log_warning 'Cannot build sandbox layer'
		return 1
	fi

	local extending_sandbox=0
	deactivate_sandbox "${app_dir}" || die
	build_sandbox "${sandbox_tag}" "${extending_sandbox}" "${app_dir}" || die
	strip_sandbox || die
	archive_sandbox || die
	activate_sandbox "${app_dir}" || die
}
