function deploy_sandbox_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	log 'Deploying sandbox apps'

	local sandbox_apps sandbox_app
	sandbox_apps=( $( <"${source_dir}/.halcyon-magic/sandbox-apps" ) ) || die
	for sandbox_app in "${sandbox_apps[@]}"; do
		log_indent "${sandbox_app}"
	done

	if ! ( deploy --recursive --target-sandbox "${sandbox_apps[@]}" ) |& quote; then
		log_warning 'Cannot deploy sandbox apps'
		return 1
	fi
}


function deploy_extra_apps () {
	local source_dir
	expect_args source_dir -- "$@"

	log 'Deploying extra apps'

	local extra_apps extra_app
	extra_apps=( $( <"${source_dir}/.halcyon-magic/extra-apps" ) ) || die
	for extra_app in "${extra_apps[@]}"; do
		log_indent "${extra_app}"
	done

	if ! ( deploy --recursive "${sandbox_apps[@]}" ) |& quote; then
		log_warning 'Cannot deploy extra apps'
		return 1
	fi
}


function deploy_layers () {
	expect_vars HALCYON_DIR HALCYON_RECURSIVE HALCYON_NO_PREPARE_CACHE HALCYON_NO_GHC HALCYON_NO_CABAL HALCYON_NO_SANDBOX_OR_APP HALCYON_NO_APP HALCYON_NO_CLEAN_CACHE

	local tag constraints source_dir
	expect_args tag constraints source_dir -- "$@"

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache || die
	fi

	if ! (( HALCYON_NO_SANDBOX_OR_APP )) && ! (( HALCYON_NO_APP )) && ! (( HALCYON_FORCE_APP )); then
		log
		if restore_slug "${tag}"; then
			engage_slug || die
			return 0
		fi
	fi

	if ! (( HALCYON_RECURSIVE )); then
		if ! (( HALCYON_NO_GHC )); then
			log
			deploy_ghc_layer "${tag}" "${source_dir}" || return 1
		fi
		if ! (( HALCYON_NO_CABAL )); then
			log
			deploy_cabal_layer "${tag}" "${source_dir}" || return 1
		fi
	fi

	if ! (( HALCYON_NO_SANDBOX_OR_APP )); then
		local saved_sandbox saved_app
		saved_sandbox=$( get_tmp_dir 'halcyon.saved-sandbox' ) || die
		saved_app=$( get_tmp_dir 'halcyon.saved-app' ) || die

		if (( HALCYON_RECURSIVE )); then
			if [ -d "${HALCYON_DIR}/sandbox" ]; then
				mv "${HALCYON_DIR}/sandbox" "${saved_sandbox}" || die
			fi
			if ! (( HALCYON_NO_APP )) && [ -d "${HALCYON_DIR}/app" ]; then
				mv "${HALCYON_DIR}/app" "${saved_app}" || die
			fi
		fi

		log
		deploy_sandbox_layer "${tag}" "${constraints}" "${source_dir}" || return 1

		if ! (( HALCYON_NO_APP )); then
			log
			deploy_app_layer "${tag}" "${source_dir}" || return 1

			if [ -f "${source_dir}/.halcyon-magic/extra-apps" ]; then
				log
				deploy_extra_apps "${source_dir}" || return 1
			fi
		fi

		if (( HALCYON_RECURSIVE )); then
			if [ -d "${saved_sandbox}" ]; then
				rm -rf "${HALCYON_DIR}/sandbox" || die
				mv "${saved_sandbox}" "${HALCYON_DIR}/sandbox" || die
			fi
			if ! (( HALCYON_NO_APP )) && [ -d "${saved_app}" ]; then
				rm -rf "${HALCYON_DIR}/app" || die
				mv "${saved_app}" "${HALCYON_DIR}/app" || die
			fi
		fi

		if ! (( HALCYON_NO_APP )); then
			log
			build_slug || die
			archive_slug || die
			engage_slug || die
		fi
	fi

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache || die
	fi
}


function deploy_app () {
	expect_vars HALCYON_PUBLIC HALCYON_TARGET_SANDBOX HALCYON_NO_GHC HALCYON_NO_CABAL HALCYON_NO_SANDBOX_OR_APP HALCYON_NO_APP HALCYON_NO_WARN_IMPLICIT

	local app_label source_dir
	expect_args app_label source_dir -- "$@"

	local slug_dir source_hash constraints constraint_hash
	if ! (( HALCYON_NO_SANDBOX_OR_APP )); then
		if ! [ -d "${source_dir}" ]; then
			die 'Expected existing source directory'
		fi

		if has_vars HALCYON_SANDBOX_APPS; then
			mkdir -p "${source_dir}/.halcyon-magic" || die
			echo "${HALCYON_SANDBOX_APPS}" >"${source_dir}/.halcyon-magic/sandbox-apps" || die
		fi
		if ! (( HALCYON_NO_APP )) && has_vars HALCYON_EXTRA_APPS; then
			mkdir -p "${source_dir}/.halcyon-magic" || die
			echo "${HALCYON_EXTRA_APPS}" >"${source_dir}/.halcyon-magic/extra-apps" || die
		fi

		log_indent 'App label:                               ' "${app_label}"

		if ! (( HALCYON_NO_APP )); then
			if ! (( HALCYON_TARGET_SANDBOX )); then
				slug_dir="${HALCYON_DIR}/slug"
			else
				slug_dir="${HALCYON_DIR}/sandbox"
				log_indent 'Target:                                  ' 'sandbox'
			fi
			source_hash=$( hash_spaceless_recursively "${source_dir}" ) || die
			log_indent 'Source hash:                             ' "${source_hash:0:7}"
		fi

		local warn_constraints
		warn_constraints=0
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

		log_indent 'Constraint hash:                         ' "${constraint_hash:0:7}"
		if (( warn_constraints )) && ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_WARN_IMPLICIT )); then
			log_warning 'Using implicit constraints'
			log_warning 'Expected cabal.config with explicit constraints'
			log
			help_add_explicit_constraints "${constraints}"
			log
		fi
	fi

	local ghc_version ghc_magic_hash warn_ghc_version
	warn_ghc_version=0
	if has_vars HALCYON_GHC_VERSION; then
		ghc_version="${HALCYON_GHC_VERSION}"
	elif ! (( HALCYON_NO_SANDBOX_OR_APP )); then
		ghc_version=$( map_constraints_to_ghc_version "${constraints}" ) || die
	else
		ghc_version=$( get_default_ghc_version ) || die
		warn_ghc_version=1
	fi
	ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || die

	if ! (( HALCYON_RECURSIVE )); then
		log_indent 'GHC version:                             ' "${ghc_version}"
		if [ -n "${ghc_magic_hash}" ]; then
			log_indent 'GHC magic hash:                          ' "${ghc_magic_hash:0:7}"
		fi
		if (( warn_ghc_version )) && ! (( HALCYON_NO_WARN_IMPLICIT )); then
			log_warning 'Using default version of GHC'
		fi
	fi

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
	log_indent 'Cabal version:                           ' "${cabal_version}"
	if [ -n "${cabal_magic_hash}" ]; then
		log_indent 'Cabal magic hash:                        ' "${cabal_magic_hash:0:7}"
	fi
	log_indent 'Cabal repository:                        ' "${cabal_repo%%:*}"

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || die
	if [ -n "${sandbox_magic_hash}" ]; then
		log_indent 'Sandbox magic hash:                      ' "${sandbox_magic_hash:0:7}"
	fi

	local app_magic_hash
	app_magic_hash=$( hash_app_magic "${source_dir}" ) || die
	if [ -n "${app_magic_hash}" ]; then
		log_indent 'App magic hash:                          ' "${app_magic_hash:0:7}"
	fi

	if has_private_storage; then
		log_indent 'Storage:                                 ' "${HALCYON_S3_BUCKET}"
		if (( HALCYON_PUBLIC )); then
			log_warning 'Cannot use both private and public storage'
		fi
	elif (( HALCYON_PUBLIC )); then
		log_indent 'Storage:                                 ' 'public'
	else
		log_error 'Expected private or public storage'
		log
		help_configure_storage
		log
		return 1
	fi

	local tag
	tag=$(
		create_tag "${app_label}" "${slug_dir:-}" "${source_hash:-}" "${constraint_hash:-}" \
			"${ghc_version:-}" "${ghc_magic_hash:-}"                                    \
			"${cabal_version:-}" "${cabal_magic_hash:-}" "${cabal_repo:-}" ''           \
			"${sandbox_magic_hash:-}"                                                   \
			"${app_magic_hash:-}"
	) || die

	if ! deploy_layers "${tag}" "${constraints:-}" "${source_dir}"; then
		return 1
	fi
}
