function make_sandbox_tag () {
	expect_vars HALCYON_DIR

	local ghc_tag sandbox_constraints_hash sandbox_magic_hash app_label
	expect_args ghc_tag sandbox_constraints_hash sandbox_magic_hash app_label -- "$@"

	local os
	os=$( detect_os ) || die

	local ghc_os ghc_halcyon_dir ghc_version ghc_magic_hash
	ghc_os=$( echo_ghc_tag_os "${ghc_tag}" ) || die
	ghc_halcyon_dir=$( echo_ghc_tag_halcyon_dir "${ghc_tag}" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	ghc_magic_hash=$( echo_ghc_tag_magic_hash "${ghc_tag}" ) || die

	if [ "${os}" != "${ghc_os}" ]; then
		die "Unexpected OS in GHC tag: ${ghc_os}"
	fi
	if [ "${HALCYON_DIR}" != "${ghc_halcyon_dir}" ]; then
		die "Unexpected HALCYON_DIR in GHC tag: ${ghc_halcyon_dir}"
	fi

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_magic_hash}\t${sandbox_constraints_hash}\t${sandbox_magic_hash}\t${app_label}"
}


function make_matched_sandbox_tag () {
	expect_vars HALCYON_DIR

	local sandbox_tag matched_constraints_hash matched_app_label
	expect_args sandbox_tag matched_constraints_hash matched_app_label -- "$@"

	local os
	os=$( detect_os ) || die

	local sandbox_os sandbox_halcyon_dir ghc_version ghc_magic_hash sandbox_magic_hash
	sandbox_os=$( echo_sandbox_tag_os "${sandbox_tag}" ) || die
	sandbox_halcyon_dir=$( echo_sandbox_tag_halcyon_dir "${sandbox_tag}" ) || die
	ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	ghc_magic_hash=$( echo_sandbox_tag_ghc_magic_hash "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_tag_magic_hash "${sandbox_tag}" ) || die

	if [ "${os}" != "${sandbox_os}" ]; then
		die "Unexpected OS in sandbox tag: ${sandbox_os}"
	fi
	if [ "${HALCYON_DIR}" != "${sandbox_halcyon_dir}" ]; then
		die "Unexpected HALCYON_DIR in sandbox tag: ${sandbox_halcyon_dir}"
	fi

	echo -e "${os}\t${HALCYON_DIR}\tghc-${ghc_version}\t${ghc_magic_hash}\t${matched_constraints_hash}\t${sandbox_magic_hash}\t${matched_app_label}"
}


function echo_sandbox_tag_os () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $1 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_halcyon_dir () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $2 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_ghc_version () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $3 }' <<<"${sandbox_tag}" | sed 's/^ghc-//'
}


function echo_sandbox_tag_ghc_magic_hash () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $4 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_constraints_hash () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $5 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_magic_hash () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $6 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_app_label () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk -F$'\t' '{ print $7 }' <<<"${sandbox_tag}"
}


function echo_sandbox_id () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local sandbox_constraints_hash sandbox_magic_hash
	sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_tag_magic_hash "${sandbox_tag}" ) || die

	echo "${sandbox_constraints_hash:0:7}${sandbox_magic_hash:+~${sandbox_magic_hash:0:7}}"
}


function echo_sandbox_description () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local sandbox_id app_label
	sandbox_id=$( echo_sandbox_id "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die

	echo "${sandbox_id} (${app_label})"
}


function echo_sandbox_archive () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id sandbox_id app_label
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	sandbox_id=$( echo_sandbox_id "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id}-${sandbox_id}-${app_label}.tar.xz"
}


function echo_sandbox_config () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id sandbox_id app_label
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	sandbox_id=$( echo_sandbox_id "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id}-${sandbox_id}-${app_label}.cabal.config"
}


function echo_sandbox_config_constraints_hash_short () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local sandbox_constraints_hash_etc
	sandbox_constraints_hash_etc="${sandbox_config#halcyon-sandbox-ghc-*-}"

	echo "${sandbox_constraints_hash_etc%%[~-]*}"
}


function echo_sandbox_config_app_label () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local app_label_etc
	app_label_etc="${sandbox_config#halcyon-sandbox-ghc-*-*-}"

	echo "${app_label_etc%.cabal.config}"
}


function echo_sandbox_config_prefix () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id}-"
}


function echo_fully_matched_sandbox_config_pattern () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id sandbox_constraints_hash sandbox_magic_hash
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_tag_magic_hash "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id//./\.}-${sandbox_constraints_hash:0:7}${sandbox_magic_hash:+~${sandbox_magic_hash:0:7}}-.*\.cabal\.config"
}


function echo_partially_matched_sandbox_config_pattern () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_id sandbox_magic_hash
	ghc_id=$( echo_ghc_id "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_tag_magic_hash "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_id//./\.}-[^~]*${sandbox_magic_hash:+~${sandbox_magic_hash:0:7}}-.*\.cabal\.config"
}


function determine_sandbox_constraints () {
	expect_vars HALCYON_NO_WARN_CONSTRAINTS

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	log 'Determining sandbox constraints'

	local sandbox_constraints
	if [ -f "${app_dir}/cabal.config" ]; then
		sandbox_constraints=$( detect_constraints "${app_dir}" ) || die
	else
		sandbox_constraints=$( cabal_freeze_implicit_constraints "${app_dir}" ) || die
		if ! (( ${HALCYON_NO_WARN_CONSTRAINTS} )); then
			log_warning 'Using newest available versions of all packages'
			log_warning 'Expected cabal.config with explicit constraints'
			log
			help_add_constraints "${sandbox_constraints}"
			log
		fi
	fi

	echo "${sandbox_constraints}"
}


function determine_sandbox_constraints_hash () {
	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log_begin 'Determining sandbox constraints hash...'

	local sandbox_constraints_hash
	sandbox_constraints_hash=$( hash_constraints <<<"${sandbox_constraints}" ) || die

	log_end "${sandbox_constraints_hash:0:7}"

	echo "${sandbox_constraints_hash}"
}


function hash_sandbox_magic () {
	local app_dir
	expect_args app_dir -- "$@"

	local magic
	if ! magic=$( cat "${app_dir}/.halcyon-magic/sandbox-"* 2>'/dev/null' ); then
		return 0
	fi

	openssl sha1 <<<"${magic}" | sed 's/^.* //'
}


function determine_sandbox_magic_hash () {
	local app_dir
	expect_args app_dir -- "$@"

	log_begin 'Determining sandbox magic hash...'

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${app_dir}" ) || die

	if [ -z "${sandbox_magic_hash}" ]; then
		log_end '(none)'
	else
		log_end "${sandbox_magic_hash:0:7}"
	fi

	echo "${sandbox_magic_hash}"
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


function validate_sandbox_config () {
	local sandbox_constraints_hash
	expect_args sandbox_constraints_hash -- "$@"

	local candidate_constraints_hash
	candidate_constraints_hash=$( read_constraints | hash_constraints ) || die

	if [ "${candidate_constraints_hash}" != "${sandbox_constraints_hash}" ]; then
		return 1
	fi
}


function validate_sandbox_config_short () {
	local sandbox_constraints_hash_short
	expect_args sandbox_constraints_hash_short -- "$@"

	local candidate_constraints_hash
	candidate_constraints_hash=$( read_constraints | hash_constraints ) || die

	if [ "${candidate_constraints_hash:0:7}" != "${sandbox_constraints_hash_short}" ]; then
		return 1
	fi
}


function validate_sandbox_magic () {
	local sandbox_magic_hash app_dir
	expect_args sandbox_magic_hash app_dir -- "$@"

	local candidate_magic_hash
	candidate_magic_hash=$( hash_sandbox_magic "${app_dir}" ) || die

	if [ "${candidate_magic_hash}" != "${sandbox_magic_hash}" ]; then
		return 1
	fi
}


function validate_sandbox () {
	expect_vars HALCYON_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local sandbox_constraints_hash sandbox_magic_hash
	sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_tag_magic_hash "${sandbox_tag}" ) || die

	if ! [ -f "${HALCYON_DIR}/sandbox/.halcyon-tag" ] ||
		! validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/.halcyon-tag" ||
		! validate_sandbox_config "${sandbox_constraints_hash}" <"${HALCYON_DIR}/sandbox/.halcyon-cabal.config" ||
		! validate_sandbox_magic "${sandbox_magic_hash}" "${HALCYON_DIR}/sandbox"
	then
		return 1
	fi
}


function build_sandbox () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_SANDBOX
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/cabal/.halcyon-tag"

	local sandbox_constraints sandbox_tag extending_sandbox app_dir
	expect_args sandbox_constraints sandbox_tag extending_sandbox app_dir -- "$@"
	if (( ${extending_sandbox} )); then
		expect_existing "${HALCYON_DIR}/sandbox/.halcyon-tag" "${HALCYON_DIR}/sandbox/.halcyon-cabal.config"
	else
		expect_no_existing "${HALCYON_DIR}/sandbox"
	fi
	expect_existing "${app_dir}"

	local ghc_tag sandbox_constraints_hash
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die

	if (( ${HALCYON_FORCE_BUILD_ALL} )) || (( ${HALCYON_FORCE_BUILD_SANDBOX} )); then
		log 'Starting to build sandbox layer (forced)'
	else
		log 'Starting to build sandbox layer'
	fi

	if ! (( ${extending_sandbox} )) && [ -f "${app_dir}/.halcyon-magic/sandbox-precreate-hook" ]; then
		log 'Running sandbox pre-create hook'
		( "${app_dir}/.halcyon-magic/sandbox-precreate-hook" "${ghc_tag}" "${sandbox_tag}" "${app_dir}" ) || die
		mkdir -p "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
		cp "${app_dir}/.halcyon-magic/sandbox-precreate-hook" "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
	fi

	if ! (( ${extending_sandbox} )) && ! [ -d "${HALCYON_DIR}/sandbox" ]; then
		cabal_create_sandbox "${HALCYON_DIR}/sandbox" || die
	fi

	if ! (( ${extending_sandbox} )) && [ -f "${app_dir}/.halcyon-magic/sandbox-postcreate-hook" ]; then
		log 'Running sandbox post-create hook'
		( "${app_dir}/.halcyon-magic/sandbox-postcreate-hook" "${ghc_tag}" "${sandbox_tag}" "${app_dir}" ) || die
		mkdir -p "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
		cp "${app_dir}/.halcyon-magic/sandbox-postcreate-hook" "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
	fi

	if [ -f "${app_dir}/.halcyon-magic/sandbox-prebuild-hook" ]; then
		log 'Running sandbox pre-build hook'
		( "${app_dir}/.halcyon-magic/sandbox-prebuild-hook" "${ghc_tag}" "${sandbox_tag}" "${app_dir}" ) || die
		mkdir -p "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
		cp "${app_dir}/.halcyon-magic/sandbox-prebuild-hook" "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
	fi

	log 'Building sandbox'

	cabal_install_deps "${HALCYON_DIR}/sandbox" "${app_dir}" || die

	echo_constraints <<<"${sandbox_constraints}" >"${HALCYON_DIR}/sandbox/.halcyon-cabal.config" || die

	if [ -f "${app_dir}/.halcyon-magic/sandbox-postbuild-hook" ]; then
		log 'Running sandbox post-build hook'
		( "${app_dir}/.halcyon-magic/sandbox-postbuild-hook" "${ghc_tag}" "${sandbox_tag}" "${app_dir}" ) || die
		mkdir -p "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
		cp "${app_dir}/.halcyon-magic/sandbox-postbuild-hook" "${HALCYON_DIR}/sandbox/.halcyon-magic" || die
	fi

	echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die

	local sandbox_size
	sandbox_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log "Finished building sandbox layer, ${sandbox_size}"

	if (( ${HALCYON_NO_WARN_CONSTRAINTS} )); then
		return 0
	fi

	# NOTE: Frozen constraints should never differ before and after installation.
	# https://github.com/haskell/cabal/issues/1896

	local actual_constraints actual_constraints_hash
	actual_constraints=$( cabal_freeze_actual_constraints "${HALCYON_DIR}/sandbox" "${app_dir}" ) || die
	actual_constraints_hash=$( hash_constraints <<<"${actual_constraints}" ) || die

	if [ "${actual_constraints_hash}" != "${sandbox_constraints_hash}" ]; then
		log_warning 'Unexpected constraints difference'
		log_warning 'Please report this on https://github.com/mietek/halcyon/issues/1'
		echo_constraints_difference "${sandbox_constraints}" "${actual_constraints}" | quote
	fi
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

	if (( ${HALCYON_NO_ARCHIVE} )); then
		return 0
	fi

	local sandbox_tag os sandbox_archive sandbox_config
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/.halcyon-tag" ) || die
	os=$( echo_sandbox_tag_os "${sandbox_tag}" ) || die
	sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die
	sandbox_config=$( echo_sandbox_config "${sandbox_tag}" ) || die

	log 'Archiving sandbox layer'

	rm -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_CACHE_DIR}/${sandbox_config}" || die
	tar_archive "${HALCYON_DIR}/sandbox" "${HALCYON_CACHE_DIR}/${sandbox_archive}" || die
	cp "${HALCYON_DIR}/sandbox/.halcyon-cabal.config" "${HALCYON_CACHE_DIR}/${sandbox_config}" || die
	if ! upload_layer "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${os}"; then
		die 'Cannot upload sandbox layer archive'
	fi
	if ! upload_layer "${HALCYON_CACHE_DIR}/${sandbox_config}" "${os}"; then
		die 'Cannot upload sandbox layer config'
	fi
}


function restore_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local os sandbox_archive
	os=$( echo_sandbox_tag_os "${sandbox_tag}" ) || die
	sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die

	if validate_sandbox "${sandbox_tag}"; then
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
	fi
}


function match_sandbox_tag () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local sandbox_constraints sandbox_tag
	expect_args sandbox_constraints sandbox_tag -- "$@"

	log 'Locating matched sandbox layers'

	local os config_prefix partial_config_pattern full_config_pattern
	os=$( echo_sandbox_tag_os "${sandbox_tag}" ) || die
	config_prefix=$( echo_sandbox_config_prefix "${sandbox_tag}" ) || die
	partial_config_pattern=$( echo_partially_matched_sandbox_config_pattern "${sandbox_tag}" ) || die
	full_config_pattern=$( echo_fully_matched_sandbox_config_pattern "${sandbox_tag}" ) || die

	local configs
	if ! configs=$(
		list_layer "${os}/${config_prefix}" |
		sed "s:${os}/::" |
		filter_matching "^${partial_config_pattern}$" |
		sort_naturally |
		match_at_least_one
	); then
		log 'Cannot locate any matched sandbox layer'
		return 1
	fi

	local full_configs
	if full_configs=$(
		filter_matching "^${full_config_pattern}$" <<<"${configs}" |
		match_at_least_one
	); then
		local sandbox_constraints_hash
		sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die

		log 'Examining fully matched sandbox layers'

		local full_config
		while read -r full_config; do
			if ! [ -f "${HALCYON_CACHE_DIR}/${full_config}" ] ||
				! validate_sandbox_config "${sandbox_constraints_hash}" <"${HALCYON_CACHE_DIR}/${full_config}"
			then
				rm -f "${HALCYON_CACHE_DIR}/${full_config}" || die

				if ! download_layer "${os}" "${full_config}" "${HALCYON_CACHE_DIR}"; then
					log_warning 'Cannot download fully matched sandbox layer config'
					continue
				fi

				if ! validate_sandbox_config "${sandbox_constraints_hash}" <"${HALCYON_CACHE_DIR}/${full_config}"; then
					rm -f "${HALCYON_CACHE_DIR}/${full_config}" || die
					log_warning 'Cannot validate fully matched sandbox layer config'
					continue
				fi
			fi

			echo "full ${full_config}"
			return 0
		done <<<"${full_configs}"

		log 'Cannot use any fully matched sandbox layer'
	else
		log 'Cannot locate any fully matched sandbox layer'
	fi

	local partial_configs
	if ! partial_configs=$(
		filter_not_matching "^${full_config_pattern}$" <<<"${configs}" |
		match_at_least_one
	); then
		log 'Cannot locate any partially matched sandbox layer'
		return 1
	fi

	log 'Examining partially matched sandbox layers'

	local partial_config
	while read -r partial_config; do
		local constraints_hash_short
		constraints_hash_short=$( echo_sandbox_config_constraints_hash_short "${partial_config}" ) || die

		if ! [ -f "${HALCYON_CACHE_DIR}/${partial_config}" ] ||
			! validate_sandbox_config_short "${constraints_hash_short}" <"${HALCYON_CACHE_DIR}/${partial_config}"
		then
			rm -f "${HALCYON_CACHE_DIR}/${partial_config}" || die

			if ! download_layer "${os}" "${partial_config}" "${HALCYON_CACHE_DIR}"; then
				log_warning 'Cannot download partially matched sandbox layer config'
				continue
			fi

			if ! validate_sandbox_config_short "${constraints_hash_short}" <"${HALCYON_CACHE_DIR}/${partial_config}"; then
				rm -f "${HALCYON_CACHE_DIR}/${partial_config}" || die
				log_warning 'Cannot validate partially matched sandbox layer config'
				continue
			fi
		fi
	done <<<"${partial_configs}"

	log 'Scoring partially matched sandbox layers'

	local scores
	if ! scores=$(
		local partial_config
		while read -r partial_config; do
			if ! [ -f "${HALCYON_CACHE_DIR}/${partial_config}" ]; then
				continue
			fi

			local constraints_hash app_label tag description
			constraints_hash=$(
				read_constraints <"${HALCYON_CACHE_DIR}/${partial_config}" |
				hash_constraints
			) || die
			app_label=$( echo_sandbox_config_app_label "${partial_config}" ) || die
			tag=$( make_matched_sandbox_tag "${sandbox_tag}" "${constraints_hash}" "${app_label}" ) || die
			description=$( echo_sandbox_description "${tag}" ) || die

			local score
			if ! score=$(
				read_constraints <"${HALCYON_CACHE_DIR}/${partial_config}" |
				sort_naturally |
				filter_valid_constraints |
				score_constraints "${sandbox_constraints}" "${description}"
			); then
				continue
			fi

			echo -e "${score} ${tag}"
		done <<<"${partial_configs}" |
			filter_not_matching '^0 ' |
			sort_naturally |
			match_at_least_one
	); then
		log 'Cannot extend any partially matched sandbox layer'
		return 1
	fi

	filter_last <<<"${scores}" |
		match_exactly_one |
		sed 's/^.* /partial /'
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
	ln -s "${HALCYON_DIR}/sandbox/cabal.sandbox.config" "${app_dir}/cabal.sandbox.config" || die

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


function install_matched_sandbox () {
	expect_vars HALCYON_DIR HALCYON_NO_BUILD

	local sandbox_constraints sandbox_tag matched_tag app_dir
	expect_args sandbox_constraints sandbox_tag matched_tag app_dir -- "$@"

	if ! restore_sandbox "${matched_tag}"; then
		return 1
	fi

	local sandbox_constraints_hash sandbox_magic_hash
	sandbox_constraints_hash=$( echo_sandbox_tag_constraints_hash "${sandbox_tag}" ) || die
	sandbox_magic_hash=$( echo_sandbox_tag_magic_hash "${sandbox_tag}" ) || die

	local matched_constraints_hash matched_magic_hash matched_description
	matched_constraints_hash=$( echo_sandbox_tag_constraints_hash "${matched_tag}" ) || die
	matched_magic_hash=$( echo_sandbox_tag_magic_hash "${matched_tag}" ) || die
	matched_description=$( echo_sandbox_description "${matched_tag}" ) || die

	if [ "${matched_constraints_hash}" = "${sandbox_constraints_hash}" ] &&
		[ "${matched_magic_hash}" = "${sandbox_magic_hash}" ]
	then
		log 'Using fully matched sandbox layer:'
		log_indent "${matched_description}"

		echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/.halcyon-tag" || die
		archive_sandbox || die
		activate_sandbox "${app_dir}" || die
		return 0
	fi

	if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
		! (( ${HALCYON_FORCE_BUILD_SANDBOX} )) &&
		(( ${HALCYON_NO_BUILD} ))
	then
		log 'Cannot build sandbox layer'
		return 1
	fi

	log 'Extending partially matched sandbox layer:'
	log_indent "${matched_description}"

	local extending_sandbox=1
	build_sandbox "${sandbox_constraints}" "${sandbox_tag}" "${extending_sandbox}" "${app_dir}" || die
	strip_sandbox || die
	archive_sandbox || die
	activate_sandbox "${app_dir}" || die
}


function install_sandbox () {
	expect_vars HALCYON_DIR HALCYON_FORCE_BUILD_ALL HALCYON_FORCE_BUILD_SANDBOX HALCYON_NO_BUILD
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	local app_dir
	expect_args app_dir -- "$@"

	local ghc_tag sandbox_constraints sandbox_constraints_hash sandbox_magic_hash app_label sandbox_tag sandbox_description
	ghc_tag=$( <"${HALCYON_DIR}/ghc/.halcyon-tag" ) || die
	sandbox_constraints=$( determine_sandbox_constraints "${app_dir}" ) || die
	sandbox_constraints_hash=$( determine_sandbox_constraints_hash "${sandbox_constraints}" ) || die
	sandbox_magic_hash=$( determine_sandbox_magic_hash "${app_dir}" ) || die
	app_label=$( detect_app_label "${app_dir}" ) || die
	sandbox_tag=$( make_sandbox_tag "${ghc_tag}" "${sandbox_constraints_hash}" "${sandbox_magic_hash}" "${app_label}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
		! (( ${HALCYON_FORCE_BUILD_SANDBOX} )) &&
		restore_sandbox "${sandbox_tag}"
	then
		activate_sandbox "${app_dir}" || die
		return 0
	fi

	local match_result
	if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
		! (( ${HALCYON_FORCE_BUILD_SANDBOX} )) &&
		match_result=$( match_sandbox_tag "${sandbox_constraints}" "${sandbox_tag}" )
	then
		local match_class match_tag
		match_class="${match_result%% *}"
		matched_tag="${match_result#* }"

		case "${match_class}" in
		'full')
			if install_matched_sandbox "${sandbox_constraints}" "${sandbox_tag}" "${matched_tag}" "${app_dir}"; then
				return 0
			fi
			;;
		'partial')
			if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
				! (( ${HALCYON_FORCE_BUILD_SANDBOX} )) &&
				(( ${HALCYON_NO_BUILD} ))
			then
				log 'Cannot build sandbox layer'
				return 1
			fi

			if install_matched_sandbox "${sandbox_constraints}" "${sandbox_tag}" "${matched_tag}" "${app_dir}"; then
				return 0
			fi
			;;
		*)
			die "Unexpected match class: ${match_class}"
		esac
	fi

	if ! (( ${HALCYON_FORCE_BUILD_ALL} )) &&
		! (( ${HALCYON_FORCE_BUILD_SANDBOX} )) &&
		(( ${HALCYON_NO_BUILD} ))
	then
		log 'Cannot build sandbox layer'
		return 1
	fi

	local extending_sandbox=0
	deactivate_sandbox "${app_dir}" || die
	build_sandbox "${sandbox_constraints}" "${sandbox_tag}" "${extending_sandbox}" "${app_dir}" || die
	strip_sandbox || die
	archive_sandbox || die
	activate_sandbox "${app_dir}" || die
}
