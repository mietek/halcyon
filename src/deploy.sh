function validate_env () {
	local tag
	expect_args tag -- "$@"

	if ! validate_ghc_layer "${tag}"; then
		log_warning 'Cannot validate GHC layer'
		return 1
	fi
	if ! validate_updated_cabal_layer "${tag}"; then
		log_warning 'Cannot validate updated Cabal layer'
		return 1
	fi
}


function save_sandbox_and_app_layers () {
	local saved_sandbox saved_app
	expect_args saved_sandbox saved_app -- "$@"

	if [ -d "${HALCYON_DIR}/sandbox" ]; then
		mv "${HALCYON_DIR}/sandbox" "${saved_sandbox}" || die
	fi
	if [ -d "${HALCYON_DIR}/app" ]; then
		mv "${HALCYON_DIR}/app" "${saved_app}" || die
	fi
}


function reset_sandbox_and_app_layers () {
	local saved_sandbox saved_app
	expect_args saved_sandbox saved_app -- "$@"

	if [ -d "${saved_sandbox}" ]; then
		rm -rf "${HALCYON_DIR}/sandbox" || die
		mv "${saved_sandbox}" "${HALCYON_DIR}/sandbox" || die
	fi
	if [ -d "${saved_app}" ]; then
		rm -rf "${HALCYON_DIR}/app" || die
		mv "${saved_app}" "${HALCYON_DIR}/app" || die
	fi
}


function deploy_sandbox_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	log 'Deploying sandbox extra apps'

	local sandbox_apps
	sandbox_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) ) || die
	if ! ( deploy --recursive --target='sandbox' "${sandbox_apps[@]}" ) |& quote; then
		log_warning 'Cannot deploy sandbox extra apps'
		return 1
	fi
}


function deploy_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	log 'Deploying extra apps'

	local extra_apps
	extra_apps=( $( <"${source_dir}/.halcyon-magic/extra-apps" ) ) || die
	if ! ( deploy --recursive "${extra_apps[@]}" ) |& quote; then
		log_warning 'Cannot deploy extra apps'
		return 1
	fi
}


function deploy_layers () {
	expect_vars HALCYON_DIR HALCYON_RECURSIVE HALCYON_ONLY_ENV HALCYON_NO_PREPARE_CACHE HALCYON_NO_CLEAN_CACHE

	local tag constraints source_dir
	expect_args tag constraints source_dir -- "$@"

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache || die
	fi

	if ! (( HALCYON_ONLY_ENV )) && ! (( HALCYON_REBUILD_APP )) && ! (( HALCYON_NO_SLUG_ARCHIVE ));  then
		log
		if restore_slug "${tag}"; then
			engage_slug || die
			return 0
		fi
	fi

	if ! (( HALCYON_RECURSIVE )); then
		log
		deploy_ghc_layer "${tag}" "${source_dir}" || return 1
		log
		deploy_cabal_layer "${tag}" "${source_dir}" || return 1
	else
		validate_env "${tag}" || return 1
	fi

	if ! (( HALCYON_ONLY_ENV )); then
		local saved_sandbox saved_app
		saved_sandbox=$( get_tmp_dir 'halcyon.saved-sandbox' ) || die
		saved_app=$( get_tmp_dir 'halcyon.saved-app' ) || die

		if (( HALCYON_RECURSIVE )); then
			save_sandbox_and_app_layers "${saved_sandbox}" "${saved_app}" || die
		fi
		log
		deploy_sandbox_layer "${tag}" "${constraints}" "${source_dir}" || return 1
		log
		deploy_app_layer "${tag}" "${source_dir}" || return 1
		if [ -f "${source_dir}/.halcyon-magic/extra-apps" ]; then
			log
			deploy_extra_apps "${source_dir}" || return 1
		fi
		if (( HALCYON_RECURSIVE )); then
			reset_sandbox_and_app_layers "${saved_sandbox}" "${saved_app}" || die
		fi

		log
		build_slug || die
		if ! (( HALCYON_NO_SLUG_ARCHIVE )); then
			archive_slug || die
		fi
		engage_slug || die
	fi

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache || die
	fi
}


function validate_storage () {
	if has_private_storage; then
		log_indent 'Storage:                                 ' "${HALCYON_S3_BUCKET}"
		if (( HALCYON_PUBLIC_STORAGE )); then
			log_warning 'Cannot use private and public storage together'
		fi
	elif (( HALCYON_PUBLIC_STORAGE )); then
		log_indent 'Storage:                                 ' 'public'
	else
		log_error 'Expected private or public storage'
		log
		help_configure_storage
		log
		return 1
	fi
}


function deploy_only_env () {
	expect_vars HALCYON_NO_WARN_IMPLICIT

	log 'Deploying environment'

	local ghc_version
	if has_vars HALCYON_GHC_VERSION; then
		ghc_version="${HALCYON_GHC_VERSION}"
	else
		ghc_version=$( get_default_ghc_version ) || die
	fi

	local cabal_version cabal_repo
	if has_vars HALCYON_CABAL_VERSION; then
		cabal_version="${HALCYON_CABAL_VERSION}"
	else
		cabal_version=$( get_default_cabal_version ) || die
	fi
	if has_vars HALCYON_CABAL_REPO; then
		cabal_repo="${HALCYON_CABAL_REPO}"
	else
		cabal_repo=$( get_default_cabal_repo ) || die
	fi

	log_indent 'GHC version:                             ' "${ghc_version}"
	log_indent 'Cabal version:                           ' "${cabal_version}"
	log_indent 'Cabal repository:                        ' "${cabal_repo%%:*}"

	validate_storage || return 1

	local tag
	tag=$(
		create_tag '' ''                                 \
			'' ''                                    \
			"${ghc_version}" ''                      \
			"${cabal_version}" '' "${cabal_repo}" '' \
			'' ''
	) || die

	HALCYON_ONLY_ENV=1 \
		deploy_layers "${tag}" '' '/dev/null' || return 1
}


function prepare_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	if has_vars HALCYON_SANDBOX_EXTRA_APPS; then
		mkdir -p "${source_dir}/.halcyon-magic" || die
		echo "${HALCYON_SANDBOX_EXTRA_APPS}" >"${source_dir}/.halcyon-magic/sandbox-extra-apps" || die
	fi
	if has_vars HALCYON_EXTRA_APPS; then
		mkdir -p "${source_dir}/.halcyon-magic" || die
		echo "${HALCYON_EXTRA_APPS}" >"${source_dir}/.halcyon-magic/extra-apps" || die
	fi
}


function deploy_app () {
	expect_vars HALCYON_TARGET HALCYON_NO_WARN_IMPLICIT

	local app_label source_dir
	expect_args app_label source_dir -- "$@"
	expect_existing "${source_dir}"

	log 'Deploying app:                           ' "${app_label}"

	local source_hash constraints constraints_hash warn_constraints
	warn_constraints=0
	source_hash=$( hash_spaceless_recursively "${source_dir}" ) || die
	if [ -f "${source_dir}/cabal.config" ]; then
		if ! constraints=$( detect_constraints "${app_label}" "${source_dir}" ); then
			log_warning 'Cannot detect constraints'
			return 1
		fi
	else
		constraints=$( freeze_implicit_constraints "${app_label}" "${source_dir}" ) || die
		warn_constraints=1
	fi
	constraint_hash=$( hash_constraints "${constraints}" ) || die

	local ghc_version ghc_magic_hash
	if has_vars HALCYON_GHC_VERSION; then
		ghc_version="${HALCYON_GHC_VERSION}"
	else
		ghc_version=$( map_constraints_to_ghc_version "${constraints}" ) || die
	fi
	ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || die

	local cabal_version cabal_magic_hash cabal_repo
	if has_vars HALCYON_CABAL_VERSION; then
		cabal_version="${HALCYON_CABAL_VERSION}"
	else
		cabal_version=$( get_default_cabal_version ) || die
	fi
	cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || die
	if has_vars HALCYON_CABAL_REPO; then
		cabal_repo="${HALCYON_CABAL_REPO}"
	else
		cabal_repo=$( get_default_cabal_repo ) || die
	fi

	local sandbox_magic_hash app_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die
	app_magic_hash=$( hash_app_magic "${source_dir}" ) || die

	if [ "${HALCYON_TARGET}" != 'slug' ]; then
		if [ "${HALCYON_TARGET}" != 'sandbox' ]; then
			die "Unexpected target: ${HALCYON_TARGET}"
		fi
		log_indent 'Target:                                  ' 'sandbox'
	fi
	log_indent 'Source hash:                             ' "${source_hash:0:7}"
	log_indent 'Constraint hash:                         ' "${constraint_hash:0:7}"

	if ! (( HALCYON_RECURSIVE )); then
		log_indent 'GHC version:                             ' "${ghc_version}"
		if [ -n "${ghc_magic_hash}" ]; then
			log_indent 'GHC magic hash:                          ' "${ghc_magic_hash:0:7}"
		fi
		log_indent 'Cabal version:                           ' "${cabal_version}"
		if [ -n "${cabal_magic_hash}" ]; then
			log_indent 'Cabal magic hash:                        ' "${cabal_magic_hash:0:7}"
		fi
		log_indent 'Cabal repository:                        ' "${cabal_repo%%:*}"
	fi

	if [ -n "${sandbox_magic_hash}" ]; then
		log_indent 'Sandbox magic hash:                      ' "${sandbox_magic_hash:0:7}"
	fi
	if [ -f "${source_dir}/.halcyon-magic/sandbox-extra-apps" ]; then
		local sandbox_apps
		sandbox_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-extra-apps" ) )
		log_indent 'Sandbox extra apps:                      ' "${sandbox_apps[*]:-}"
	fi
	if [ -n "${app_magic_hash}" ]; then
		log_indent 'App magic hash:                          ' "${app_magic_hash:0:7}"
	fi
	if [ -f "${source_dir}/.halcyon-magic/extra-apps" ]; then
		local extra_apps
		extra_apps=( $( <"${source_dir}/.halcyon-magic/extra-apps" ) )
		log_indent 'Extra apps:                              ' "${extra_apps[*]:-}"
	fi

	validate_storage || return 1

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_WARN_IMPLICIT )) && (( warn_constraints )); then
		log_warning 'Using implicit constraints'
		log_warning 'Expected cabal.config with explicit constraints'
		log
		help_add_explicit_constraints "${constraints}"
		log
	fi

	local tag
	tag=$(
		create_tag "${app_label}" "${HALCYON_TARGET}"                       \
			"${source_hash}" "${constraint_hash}"                       \
			"${ghc_version}" "${ghc_magic_hash}"                        \
			"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
			"${sandbox_magic_hash}" "${app_magic_hash}"
	) || die

	deploy_layers "${tag}" "${constraints:-}" "${source_dir}" || return 1
}


function deploy_local_app () {
	local local_dir
	expect_args local_dir -- "$@"

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die
	copy_entire_contents "${local_dir}" "${source_dir}" || die

	local app_label
	if ! app_label=$( detect_app_label "${source_dir}" ); then
		log_error 'Cannot detect app label'
		return 1
	fi

	if ! deploy_app "${app_label}" "${source_dir}"; then
		log_error 'Cannot deploy app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_cloned_app () {
	local url
	expect_args url -- "$@"

	log 'Cloning app'

	local source_dir
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die
	if ! git clone --depth=1 --quiet "${url}" "${source_dir}"; then
		log_error 'Cannot clone app'
		return 1
	fi

	local app_label
	if ! app_label=$( detect_app_label "${source_dir}" ); then
		log_error 'Cannot detect app label'
		return 1
	fi

	if ! deploy_app "${app_label}" "${source_dir}"; then
		log_error 'Cannot deploy app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_published_app () {
	expect_vars HALCYON_DIR HALCYON_NO_PREPARE_CACHE

	local thing
	expect_args thing -- "$@"

	local no_prepare_cache
	no_prepare_cache="${HALCYON_NO_PREPARE_CACHE}"
	if ! (( HALCYON_RECURSIVE )); then
		if ! HALCYON_NO_CLEAN_CACHE=1      \
			HALCYON_NO_WARN_IMPLICIT=1 \
			deploy_only_env
		then
			log_error 'Cannot deploy environment'
			return 1
		fi
		log
		no_prepare_cache=1
	fi

	log 'Unpacking app'

	local unpack_dir source_dir
	unpack_dir=$( get_tmp_dir 'halcyon.unpack' ) || die
	source_dir=$( get_tmp_dir 'halcyon.app' ) || die

	mkdir -p "${unpack_dir}" || die

	local app_label
	if ! app_label=$(
		cabal_do "${unpack_dir}" unpack "${thing}" 2>'/dev/null' |
		filter_last |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		log_error 'Cannot unpack app'
		return 1
	fi

	if ! (( HALCYON_NO_WARN_IMPLICIT )) && [ "${thing}" != "${app_label}" ]; then
		log_warning "Using newest available version of ${app_label%-*}"
		log_warning 'Expected app label with explicit version'
	fi

	mv "${unpack_dir}/${app_label}" "${source_dir}" || die
	rm -rf "${unpack_dir}" || die

	if ! HALCYON_NO_PREPARE_CACHE="${no_prepare_cache}" \
		HALCYON_NO_WARN_IMPLICIT=1                  \
		deploy_app "${app_label}" "${source_dir}"
	then
		log_error 'Cannot deploy app'
		return 1
	fi

	rm -rf "${source_dir}" || die
}


function deploy_thing () {
	local thing
	expect_args thing -- "$@"

	case "${thing}" in
	'base');&
	'base-'[0-9]*)
		deploy_base_package "${thing}" || return 1
		;;
	'https://'*);&
	'ssh://'*);&
	'git@'*);&
	'file://'*);&
	'http://'*);&
	'git://'*)
		deploy_cloned_app "${thing}" || return 1
		;;
	*)
		if [ -d "${thing}" ]; then
			deploy_local_app "${thing%/}" || return 1
		else
			deploy_published_app "${thing}" || return 1
		fi
	esac
}
