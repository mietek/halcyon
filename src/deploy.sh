function echo_fake_base_package () {
	local base_version
	expect_args base_version -- "$@"

	cat <<-EOF
		name:           halcyon-fake-base
		version:        ${base_version}
		build-type:     Simple
		cabal-version:  >= 1.2

		executable halcyon-fake-base
		  build-depends:  base == ${base_version}
EOF
}


function deploy_layers () {
	expect_vars HALCYON_DIR HALCYON_AS_BUILDTIME_DEP HALCYON_AS_RUNTIME_DEP HALCYON_NO_INSTALL_GHC HALCYON_NO_INSTALL_CABAL HALCYON_NO_INSTALL_SANDBOX HALCYON_NO_INSTALL_APP HALCYON_NO_PREPARE_CACHE HALCYON_NO_CLEAN_CACHE

	local app_dir
	expect_args app_dir -- "$@"

	local tmp_cache_dir tmp_sandbox_dir tmp_app_dir
	tmp_cache_dir=$( echo_tmp_dir_name 'halcyon.deploy_layers.cache' ) || die
	tmp_sandbox_dir=$( echo_tmp_dir_name 'halcyon.deploy_layers.sandbox' ) || die
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.deploy_layers.app' ) || die

	if ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache "${tmp_cache_dir}" || die
	fi

	if ! (( HALCYON_NO_INSTALL_GHC )); then
		log
		install_ghc "${app_dir}" || return 1
	fi
	if ! (( HALCYON_NO_INSTALL_CABAL )); then
		log
		install_cabal "${app_dir}" || return 1
	fi

	if (( HALCYON_AS_BUILDTIME_DEP )) || (( HALCYON_AS_RUNTIME_DEP )); then
		if [ -d "${HALCYON_DIR}/sandbox}" ]; then
			mv "${HALCYON_DIR}/sandbox" "${tmp_sandbox_dir}" || die
		fi
	fi
	if ! (( HALCYON_NO_INSTALL_SANDBOX )); then
		log
		install_sandbox "${app_dir}" || return 1
	fi
	if ! (( HALCYON_NO_INSTALL_APP )); then
		log
		install_app_1 "${app_dir}" "${tmp_app_dir}" || return 1
	fi
	if (( HALCYON_AS_BUILDTIME_DEP )) || (( HALCYON_AS_RUNTIME_DEP )); then
		if [ -d "${tmp_sandbox_dir}" ]; then
			rm -rf "${HALCYON_DIR}/sandbox" || die
			mv "${tmp_sandbox_dir}" "${HALCYON_DIR}" || die
		fi
	fi
	if ! (( HALCYON_NO_INSTALL_APP )); then
		install_app_2 "${app_dir}" "${tmp_app_dir}" || return 1
	fi

	if ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache "${tmp_cache_dir}" || die
	fi

	rm -rf "${tmp_cache_dir}" "${tmp_sandbox_dir}" "${tmp_app_dir}"
}


function deploy_local_app () {
	local app_dir
	expect_args app_dir -- "$@"

	local name
	name=$( echo_dir_name "${app_dir}" ) || die

	log_delimiter
	log 'Deploying local app:'
	log_indent "${name}"

	if ! deploy_layers "${app_dir}"; then
		log_warning 'Cannot deploy local app'
		return 1
	fi
}


function deploy_cloned_app () {
	local url
	expect_args url -- "$@"

	local name tmp_app_dir
	name=$( basename "${url}" ) || die
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.deploy_cloned_app' ) || die

	log_delimiter
	log 'Deploying cloned app:'
	log_indent "${name%.git}"

	if ! git clone --depth=1 --quiet "${url}" "${tmp_app_dir}"; then
		die 'Cannot deploy cloned app'
	fi
	if ! deploy_layers "${tmp_app_dir}"; then
		log_warning 'Cannot deploy cloned app'
		return 1
	fi

	rm -rf "${tmp_app_dir}" || die
}


function deploy_base_package () {
	expect_vars HALCYON_DIR

	local arg
	expect_args arg -- "$@"

	local tmp_app_dir
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.deploy_base_package' ) || die

	log_delimiter
	log 'Deploying base package:'
	log_indent "${arg}"

	if !                                 \
		HALCYON_NO_INSTALL_CABAL=1   \
		HALCYON_NO_INSTALL_SANDBOX=1 \
		HALCYON_NO_INSTALL_APP=1     \
		HALCYON_NO_CLEAN_CACHE=1     \
		HALCYON_NO_WARN_IMPLICIT=1   \
		deploy_layers '/dev/null'
	then
		log_warning 'Cannot deploy base package'
		return 1
	fi

	log
	log_begin 'Determining base package version...'

	local base_version
	if [ "${arg}" != 'base' ]; then
		base_version="${arg#base-}"

		log_end "${base_version} (explicit)"
	else
		base_version=$( ghc_detect_base_package_version ) || die

		log_end "${base_version} (implicit)"
		log_warning 'Using implicit base package version'
		log_warning 'Expected base package name with explicit version'
	fi

	mkdir -p "${tmp_app_dir}" || die
	echo_fake_base_package "${base_version}" >"${tmp_app_dir}/halcyon-fake-base.cabal" || die

	if !                               \
		HALCYON_NO_PREPARE_CACHE=1 \
		HALCYON_NO_INSTALL_GHC=1   \
		HALCYON_NO_INSTALL_APP=1   \
		HALCYON_NO_WARN_IMPLICIT=1 \
		deploy_layers "${tmp_app_dir}"
	then
		log_warning 'Cannot deploy base package'
		return 1
	fi

	rm -rf "${tmp_app_dir}" || die
}


function deploy_unpacked_app () {
	expect_vars HALCYON_DIR

	local arg
	expect_args arg -- "$@"

	local tmp_app_dir
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.deploy_unpacked_app' ) || die

	log_delimiter
	log "Deploying unpacked app:"
	log_indent "${arg}"

	if !                                 \
		HALCYON_NO_INSTALL_SANDBOX=1 \
		HALCYON_NO_INSTALL_APP=1     \
		HALCYON_NO_CLEAN_CACHE=1     \
		HALCYON_NO_WARN_IMPLICIT=1   \
		deploy_layers '/dev/null'
	then
		log_warning 'Cannot deploy unpacked app'
		return 1
	fi

	log
	log_begin 'Determining unpacked app version...'

	mkdir -p "${tmp_app_dir}" || die

	local label
	if ! label=$(
		cabal_do "${tmp_app_dir}" unpack "${arg}" |
			filter_last |
			match_exactly_one |
			sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		log_end '(unknown)'
		log_warning 'Cannot deploy unpacked app'
		return 1
	fi

	local name version
	name="${label%-*}"
	version="${label##*-}"
	if [ "${label}" = "${arg}" ]; then
		log_end "${version} (explicit)"
	else
		log_end "${version} (implicit)"
		log_warning "Using newest available version of ${name}"
		log_warning 'Expected app name with explicit version'
	fi

	if !                               \
		HALCYON_NO_PREPARE_CACHE=1 \
		HALCYON_NO_INSTALL_GHC=1   \
		HALCYON_NO_INSTALL_CABAL=1 \
		HALCYON_NO_WARN_IMPLICIT=1 \
		deploy_layers "${tmp_app_dir}/${label}"
	then
		log_warning 'Cannot deploy unpacked app'
		return 1
	fi

	rm -rf "${tmp_app_dir}" || die
}


function deploy_app () {
	local arg
	expect_args arg -- "$@"

	case "${arg}" in
	'base');&
	'base-'[0-9]*)
		if ! deploy_base_package "${arg}"; then
			return 1
		fi
		;;
	'https://'*);&
	'ssh://'*);&
	'git@'*);&
	'file://'*);&
	'http://'*);&
	'git://'*)
		if ! deploy_cloned_app "${arg}"; then
			return 1
		fi
		;;
	*)
		if [ -d "${arg}" ]; then
			if ! deploy_local_app "${arg%/}"; then
				return 1
			fi
		else
			if ! deploy_unpacked_app "${arg}"; then
				return 1
			fi
		fi
	esac
}
