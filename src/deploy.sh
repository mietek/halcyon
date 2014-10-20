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
	expect_vars HALCYON_DIR HALCYON_NO_PREPARE_CACHE HALCYON_NO_GHC HALCYON_NO_CABAL HALCYON_NO_SANDBOX HALCYON_NO_APP HALCYON_NO_CLEAN_CACHE

	local app_dir
	expect_args app_dir -- "$@"

	if ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache || die
	fi

	if ! (( HALCYON_NO_GHC )); then
		log
		install_ghc "${app_dir}" || return 1
	fi

	if ! (( HALCYON_NO_CABAL )); then
		log
		install_cabal "${app_dir}" || return 1
	fi

	local tmp_protected_sandbox
	tmp_protected_sandbox=''
	if (( HALCYON_PROTECT_SANDBOX )) && [ -f "${HALCYON_DIR}/sandbox" ]; then
		log 'Covering protected sandbox'

		tmp_protected_sandbox=$( echo_tmp_dir_name 'halcyon.protected-sandbox' ) || die
		mv "${HALCYON_DIR}/sandbox" "${tmp_protected_sandbox}" || die
	fi
	if ! (( HALCYON_NO_SANDBOX )); then
		log
		install_sandbox "${app_dir}" || return 1
	fi

	local tmp_install_dir
	tmp_install_dir=$( echo_tmp_dir_name 'halcyon.install' ) || die
	if ! (( HALCYON_NO_APP )); then
		log
		install_app_1 "${app_dir}" "${tmp_install_dir}" || return 1
	fi
	if (( HALCYON_PROTECT_SANDBOX )) && [ -n "${tmp_protected_sandbox}" ]; then
		log 'Uncovering protected sandbox'

		rm -rf "${HALCYON_DIR}/sandbox" || die
		mv "${tmp_protected_sandbox}/sandbox" "${HALCYON_DIR}" || die
	fi
	if ! (( HALCYON_NO_APP )); then
		install_app_2 "${app_dir}" "${tmp_install_dir}" || return 1
	fi

	if ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache || die
	fi
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

	log_delimiter
	log 'Deploying cloned app:'
	log_indent "${url}"

	local tmp_app_dir
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.cloned-app' ) || die

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

	log_delimiter
	log 'Deploying base package:'
	log_indent "${arg}"

	if !                                  \
		HALCYON_NO_WARN_CONSTRAINTS=1 \
		HALCYON_NO_CABAL=1            \
		HALCYON_NO_SANDBOX=1          \
		HALCYON_NO_APP=1              \
		HALCYON_NO_CLEAN_CACHE=1      \
		deploy_layers '/dev/null'
	then
		log_warning 'Cannot deploy base package'
		return 1
	fi
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag"

	log
	log_begin 'Determining base package version...'
	local base_version
	if [ "${arg}" != 'base' ]; then
		base_version="${arg#base-}"
		log_end "${base_version} (explicit)"
	else
		base_version=$( detect_base_package_version ) || die
		log_end "${base_version} (implicit)"
		log_warning 'Using implicit base package version'
		log_warning 'Expected base package name with explicit version'
	fi

	local tmp_app_dir
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.base-package' ) || die

	mkdir -p "${tmp_app_dir}" || die
	echo_fake_base_package "${base_version}" >"${tmp_app_dir}/halcyon-fake-base.cabal" || die

	if !                                   \
		HALCYON_NO_WARN_CONSTRAINTS=1  \
		HALCYON_NO_PREPARE_CACHE=1     \
		HALCYON_NO_GHC=1               \
		HALCYON_NO_APP=1               \
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

	log_delimiter
	log "Deploying unpacked app:"
	log_indent "${arg}"

	if !                                  \
		HALCYON_NO_WARN_CONSTRAINTS=1 \
		HALCYON_NO_INSTALL_SANDBOX=1  \
		HALCYON_NO_INSTALL_APP=1      \
		HALCYON_NO_CLEAN_CACHE=1      \
		deploy_layers '/dev/null'
	then
		log_warning 'Cannot deploy unpacked app'
		return 1
	fi
	expect_existing "${HALCYON_DIR}/ghc/.halcyon-tag" "${HALCYON_DIR}/cabal/.halcyon-tag"

	local tmp_app_dir
	tmp_app_dir=$( echo_tmp_dir_name 'halcyon.unpacked_app' ) || die

	mkdir -p "${tmp_app_dir}" || die

	log_begin 'Determining unpacked app version...'
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

	if !                                  \
		HALCYON_NO_WARN_CONSTRAINTS=1 \
		HALCYON_NO_PREPARE_CACHE=1    \
		HALCYON_NO_GHC=1              \
		HALCYON_NO_CABAL=1            \
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
		deploy_base_package "${arg}" || return 1
		;;
	'https://'*);&
	'ssh://'*);&
	'git@'*);&
	'file://'*);&
	'http://'*);&
	'git://'*)
		deploy_cloned_app "${arg}" || return 1
		;;
	*)
		if [ -d "${arg}" ]; then
			deploy_local_app "${arg%/}" || return 1
		else
			deploy_unpacked_app "${arg}" || return 1
		fi
	esac
}
