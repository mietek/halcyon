#!/usr/bin/env bash


function echo_sandbox_tag () {
	expect_vars HALCYON_DIR

	local ghc_version app_label sandbox_digest
	expect_args ghc_version app_label sandbox_digest -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${HALCYON_DIR}\t${os}\tghc-${ghc_version}\t${app_label}\t${sandbox_digest}"
}


function echo_sandbox_tag_ghc_version () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk '{ print $3 }' <<<"${sandbox_tag}" | sed 's/^ghc-//'
}


function echo_sandbox_tag_app_label () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk '{ print $4 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_digest () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk '{ print $5 }' <<<"${sandbox_tag}"
}




function echo_sandbox_archive () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_version app_label sandbox_digest
	ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_version}-${app_label}-${sandbox_digest}.tar.gz"
}


function echo_sandbox_config () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_version app_label sandbox_digest
	ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_version}-${app_label}-${sandbox_digest}.cabal.config"
}




function echo_sandbox_config_ghc_version () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local config_part
	config_part="${sandbox_config#halcyon-sandbox-ghc-}"

	echo "${config_part%%-*}"
}


function echo_sandbox_config_app_label () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local config_part
	config_part="${sandbox_config#halcyon-sandbox-ghc-*-}"

	echo "${config_part%-*.cabal.config}"
}


function echo_sandbox_config_digest () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local config_part
	config_part="${sandbox_config##*-}"

	echo "${config_part%.cabal.config}"
}




function echo_sandbox_config_prefix () {
	local ghc_version
	expect_args ghc_version -- "$@"

	echo "halcyon-sandbox-ghc-${ghc_version}-"
}


function echo_sandbox_config_pattern () {
	local ghc_version
	expect_args ghc_version -- "$@"

	echo "halcyon-sandbox-ghc-${ghc_version//./\.}.*\.cabal\.config"
}




function echo_sandbox_description () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local app_label sandbox_digest
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	echo "sandbox ${sandbox_digest:0:7} (${app_label})"
}




function echo_tmp_sandbox_config () {
	mktemp -u "/tmp/halcyon-sandbox.cabal.config.XXXXXXXXXX"
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


function validate_sandbox () {
	local build_dir sandbox_tag sandbox_constraints
	expect_args build_dir sandbox_tag sandbox_constraints -- "$@"

	local sandbox_digest
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	# NOTE: Frozen constraints should never differ before and after installation.
	# https://github.com/haskell/cabal/issues/1896

	local actual_constraints actual_digest
	actual_constraints=$( freeze_actual_constraints "${build_dir}" ) || die
	actual_digest=$( echo_constraints_digest <<<"${actual_constraints}" ) || die

	if [ "${actual_digest}" = "${sandbox_digest}" ]; then
		return 0
	fi

	log_warning "Actual sandbox digest is ${actual_digest:0:7}"
	log_warning 'Unexpected constraints difference:'
	echo_constraints_difference "${sandbox_constraints}" "${actual_constraints}" | log_file_indent
}




function build_sandbox () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/ghc/tag" "${HALCYON_DIR}/cabal/tag"

	local build_dir sandbox_constraints unhappy_workaround sandbox_tag
	expect_args build_dir sandbox_constraints unhappy_workaround sandbox_tag -- "$@"
	expect "${build_dir}"

	local sandbox_description
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log "Building ${sandbox_description}"

	if ! [ -d "${HALCYON_DIR}/sandbox" ]; then
		cabal_create_sandbox "${HALCYON_DIR}/sandbox" || die
	fi
	cabal_install_deps "${build_dir}" "${unhappy_workaround}" || die

	rm -rf "${HALCYON_DIR}/sandbox/logs" "${HALCYON_DIR}/sandbox/share" || die

	echo_constraints <<<"${sandbox_constraints}" >"${HALCYON_DIR}/sandbox/cabal.config" || die
	echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/tag" || die

	local sandbox_size
	sandbox_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log "Built ${sandbox_description}, ${sandbox_size}"

	log "Validating ${sandbox_description}"

	validate_sandbox "${build_dir}" "${sandbox_tag}" "${sandbox_constraints}" || die
}


function strip_sandbox () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/sandbox/tag"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log_begin "Stripping ${sandbox_description}..."

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
	log_end "done, ${sandbox_size}"
}




function cache_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect "${HALCYON_DIR}/sandbox/tag"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log "Caching ${sandbox_description}"

	local sandbox_archive sandbox_config os
	sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die
	sandbox_config=$( echo_sandbox_config "${sandbox_tag}" ) || die
	os=$( detect_os ) || die

	rm -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_CACHE_DIR}/${sandbox_config}" || die
	tar_archive "${HALCYON_DIR}/sandbox" "${HALCYON_CACHE_DIR}/${sandbox_archive}" || die
	cp "${HALCYON_DIR}/sandbox/cabal.config" "${HALCYON_CACHE_DIR}/${sandbox_config}" || die
	upload_prepared "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${os}" || die
	upload_prepared "${HALCYON_CACHE_DIR}/${sandbox_config}" "${os}" || die
}


function restore_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local sandbox_description
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log "Restoring ${sandbox_description}"

	if [ -f "${HALCYON_DIR}/sandbox/tag" ] &&
		validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/tag"
	then
		return 0
	fi
	rm -rf "${HALCYON_DIR}/sandbox" || die

	local os sandbox_archive
	os=$( detect_os ) || die
	sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" ||
		! [ -f "${HALCYON_DIR}/sandbox/tag" ] ||
		! validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/tag"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" || die

		if ! download_prepared "${os}" "${sandbox_archive}" "${HALCYON_CACHE_DIR}"; then
			log_warning "${sandbox_description} is not prepared"
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" ||
			! [ -f "${HALCYON_DIR}/sandbox/tag" ] ||
			! validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/tag"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" || die
			log_warning "Restoring ${sandbox_archive} failed"
			return 1
		fi
	fi
}




function infer_sandbox_constraints () {
	local build_dir
	expect_args build_dir -- "$@"
	expect "${build_dir}"

	log 'Inferring sandbox constraints'

	local sandbox_constraints
	if [ -f "${build_dir}/cabal.config" ]; then
		sandbox_constraints=$( detect_constraints "${build_dir}" ) || die
	else
		sandbox_constraints=$( freeze_implicit_constraints "${build_dir}" ) || die
		if ! (( ${HALCYON_FAKE_BUILD:-0} )); then
			log_warning 'Expected cabal.config with explicit constraints'
			log
			log_add_config_help "${sandbox_constraints}"
			log
		else
			echo_constraints <<<"${sandbox_constraints}" >&2 || die
		fi
	fi

	echo "${sandbox_constraints}"
}


function infer_sandbox_digest () {
	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log_begin 'Inferring sandbox digest...'

	local sandbox_digest
	sandbox_digest=$( echo_constraints_digest <<<"${sandbox_constraints}" ) || die

	log_end "done, ${sandbox_digest:0:7}"

	echo "${sandbox_digest}"
}


function locate_matched_sandbox_tag () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect "${HALCYON_DIR}/ghc/tag"

	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log 'Locating matched sandboxes'

	local os ghc_tag config_prefix config_pattern
	os=$( detect_os ) || die
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	config_prefix=$( echo_sandbox_config_prefix "${ghc_version}" ) || die
	config_pattern=$( echo_sandbox_config_pattern "${ghc_version}" ) || die

	local matched_configs
	if ! matched_configs=$(
		list_prepared "${os}/${config_prefix}" |
		sed "s:${os}/::" |
		filter_matching "^${config_pattern}$" |
		sort_naturally |
		match_at_least_one
	); then
		log_warning 'No matched sandbox is prepared'
		return 1
	fi

	download_any_prepared "${os}" "${matched_configs}" "${HALCYON_CACHE_DIR}" || die

	log "Scoring matched sandboxes"

	local matched_scores
	if ! matched_scores=$(
		local config
		while read -r config; do
			local app_label digest tag
			app_label=$( echo_sandbox_config_app_label "${config}" ) || die
			digest=$( echo_sandbox_config_digest "${config}" ) || die
			tag=$( echo_sandbox_tag "${ghc_version}" "${app_label}" "${digest}" ) || die

			local score
			if ! score=$(
				read_constraints <"${HALCYON_CACHE_DIR}/${config}" |
				sort_naturally |
				filter_valid_constraints |
				score_constraints "${sandbox_constraints}" "${tag}"
			); then
				continue
			fi

			echo -e "${score} ${tag}"
		done <<<"${matched_configs}" |
			filter_not_matching '^0 ' |
			sort_naturally |
			match_at_least_one
	); then
		log_warning 'No sandbox is matched closely enough'
		return 1
	fi

	filter_last <<<"${matched_scores}" |
		match_exactly_one |
		sed 's/^.* //'
}




function activate_sandbox () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/sandbox/tag"

	local build_dir
	expect_args build_dir -- "$@"
	expect "${build_dir}"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log_begin "Activating ${sandbox_description}..."

	if [ -e "${build_dir}/cabal.sandbox.config" ] && ! [ -h "${build_dir}/cabal.sandbox.config" ]; then
		die "Expected no custom ${build_dir}/cabal.sandbox.config"
	fi

	rm -f "${build_dir}/cabal.sandbox.config" || die
	ln -s "${HALCYON_DIR}/sandbox/cabal.sandbox.config" "${build_dir}/cabal.sandbox.config" || die

	log_end 'done'
}


function deactivate_sandbox () {
	expect_vars HALCYON_DIR
	expect "${HALCYON_DIR}/sandbox/tag"

	local build_dir
	expect_args build_dir -- "$@"
	expect "${build_dir}"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log_begin "Deactivating ${sandbox_description}..."

	if [ -e "${build_dir}/cabal.sandbox.config" ] && ! [ -h "${build_dir}/cabal.sandbox.config" ]; then
		die "Expected no custom ${build_dir}/cabal.sandbox.config"
	fi

	rm -f "${build_dir}/cabal.sandbox.config" || die

	log_end 'done'
}




function install_extended_sandbox () {
	expect_vars HALCYON_DIR

	local build_dir sandbox_constraints unhappy_workaround sandbox_tag matched_tag
	expect_args build_dir sandbox_constraints unhappy_workaround sandbox_tag matched_tag -- "$@"

	if ! restore_sandbox "${matched_tag}"; then
		return 1
	fi

	local sandbox_digest sandbox_description
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	local matched_digest matched_description
	matched_digest=$( echo_sandbox_tag_digest "${matched_tag}" ) || die
	matched_description=$( echo_sandbox_description "${matched_tag}" ) || die

	if [ "${matched_digest}" = "${sandbox_digest}" ]; then
		log "Using matched ${matched_description} as ${sandbox_description}"

		echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/tag" || die
		cache_sandbox || die
		activate_sandbox "${build_dir}" || die
		return 0
	fi

	log "Extending matched ${matched_description} to ${sandbox_description}"

	rm -f "${HALCYON_DIR}/sandbox/tag" "${HALCYON_DIR}/sandbox/cabal.config" || die

	build_sandbox "${build_dir}" "${sandbox_constraints}" "${unhappy_workaround}" "${sandbox_tag}" || die
	strip_sandbox || die
	cache_sandbox || die
	activate_sandbox "${build_dir}" || die
}


function install_sandbox () {
	expect_vars HALCYON_DIR HALCYON_PREPARED_ONLY
	expect "${HALCYON_DIR}/ghc/tag"

	local build_dir
	expect_args build_dir -- "$@"

	local ghc_tag
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die

	local sandbox_constraints sandbox_digest
	sandbox_constraints=$( infer_sandbox_constraints "${build_dir}" ) || die
	sandbox_digest=$( infer_sandbox_digest "${sandbox_constraints}" ) || die

	local unhappy_workaround
	unhappy_workaround=0
	if filter_matching '^(language-javascript|haskell-src-exts|pandoc|bytestring-lexing) ' <<<"${sandbox_constraints}" |
		match_at_least_one >'/dev/null'
	then
		unhappy_workaround=1
	fi

	local app_label sandbox_tag
	app_label=$( detect_app_label "${build_dir}" ) || die
	sandbox_tag=$( echo_sandbox_tag "${ghc_version}" "${app_label}" "${sandbox_digest}" ) || die

	if restore_sandbox "${sandbox_tag}"; then
		activate_sandbox "${build_dir}" || die
		return 0
	fi

	! (( ${HALCYON_PREPARED_ONLY} )) || return 1

	local matched_tag
	if matched_tag=$( locate_matched_sandbox_tag "${sandbox_constraints}" ) &&
		install_extended_sandbox "${build_dir}" "${sandbox_constraints}" "${unhappy_workaround}" "${sandbox_tag}" "${matched_tag}"
	then
		return 0
	fi

	build_sandbox "${build_dir}" "${sandbox_constraints}" "${unhappy_workaround}" "${sandbox_tag}" || die
	strip_sandbox || die
	cache_sandbox || die
	activate_sandbox "${build_dir}" || die
}
