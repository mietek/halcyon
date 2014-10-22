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


function prepare_helper_apps () {
	local sources_dir
	expect_args sources_dir -- "$@"

	if has_vars HALCYON_WITH_HELPER_APPS; then
		mkdir -p "${sources_dir}/.halcyon-magic" || die
		echo "${HALCYON_WITH_HELPER_APPS}" >"${sources_dir}/.halcyon-magic/helper-apps" || die
	fi
}


function prepare_build_tools () {
	local sources_dir
	expect_args sources_dir -- "$@"

	if has_vars HALCYON_WITH_BUILD_TOOLS; then
		mkdir -p "${sources_dir}/.halcyon-magic" || die
		echo "${HALCYON_WITH_BUILD_TOOLS}" >"${sources_dir}/.halcyon-magic/build-tools" || die
	fi
}


function deploy_helper_apps () {
	local sources_dir
	expect_args sources_dir -- "$@"

	if ! [ -f "${sources_dir}/.halcyon-magic/helper-apps" ]; then
		return 0
	fi

	log
	log 'Deploying helper apps'

	local helper_apps
	helper_apps=$( <"${sources_dir}/.halcyon-magic/helper-apps" ) || die
	for helper_app in ${helper_apps}; do
		log_indent "${helper_app}"
	done

	if ! ( deploy --recursive ${helper_apps} ) |& quote; then
		log_warning 'Cannot deploy helper apps'
		return 1
	fi
}


function deploy_build_tools () {
	local sources_dir
	expect_args sources_dir -- "$@"

	if ! [ -f "${sources_dir}/.halcyon-magic/build-tools" ]; then
		return 0
	fi

	log
	log 'Deploying build tools'

	local build_tools
	build_tools=$( <"${sources_dir}/.halcyon-magic/build-tools" ) || die
	for build_tool in ${build_tools}; do
		log_indent "${build_tool}"
	done

	if ! ( deploy --as-build-tool --recursive ${build_tools} ) |& quote; then
		log_warning 'Cannot deploy build tools'
		return 1
	fi
}


function deploy_layers () {
	expect_vars HALCYON_DIR HALCYON_TMP_SLUG_DIR \
		HALCYON_RECURSIVE \
		HALCYON_NO_INSTALL_GHC HALCYON_NO_INSTALL_CABAL HALCYON_NO_INSTALL_SANDBOX HALCYON_NO_INSTALL_APP \
		HALCYON_NO_PREPARE_CACHE HALCYON_NO_CLEAN_CACHE

	local sources_dir
	expect_args sources_dir -- "$@"

	local saved_sandbox saved_app
	saved_sandbox=$( echo_tmp_dir_name 'halcyon.deploy_layers.sandbox' ) || die
	saved_app=$( echo_tmp_dir_name 'halcyon.deploy_layers.app' ) || die

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_PREPARE_CACHE )); then
		log
		prepare_cache || die
	fi
	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_INSTALL_GHC )); then
		log
		install_ghc "${sources_dir}" || return 1
	fi
	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_INSTALL_CABAL )); then
		log
		install_cabal "${sources_dir}" || return 1
	fi

	if (( HALCYON_RECURSIVE )); then
		if [ -d "${HALCYON_DIR}/sandbox" ]; then
			mv "${HALCYON_DIR}/sandbox" "${saved_sandbox}" || die
		fi

		if [ -d "${HALCYON_DIR}/app" ]; then
			mv "${HALCYON_DIR}/app" "${saved_app}" || die
		fi
	fi

	if ! (( HALCYON_NO_INSTALL_SANDBOX )) && ! (( HALCYON_NO_INSTALL_APP )); then
		prepare_helper_apps "${sources_dir}" || die
		deploy_helper_apps "${sources_dir}" || return 1
	fi

	if [ -f "${sources_dir}/.halcyon-magic/helper-hook" ]; then
		log
		log 'Running helper hook'
		( "${sources_dir}/.halcyon-magic/helper-hook" ) |& quote || die
	fi

	if ! (( HALCYON_NO_INSTALL_SANDBOX )); then
		prepare_build_tools "${sources_dir}" || die
		install_sandbox "${sources_dir}" || return 1
	fi
	if ! (( HALCYON_NO_INSTALL_APP )); then
		log
		install_app "${sources_dir}" || return 1
	fi

	if (( HALCYON_RECURSIVE )); then
		if [ -d "${saved_sandbox}" ]; then
			rm -rf "${HALCYON_DIR}/sandbox" || die
			mv "${saved_sandbox}" "${HALCYON_DIR}/sandbox" || die
		fi
		if [ -d "${saved_app}" ]; then
			rm -rf "${HALCYON_DIR}/app" || die
			mv "${saved_app}" "${HALCYON_DIR}/app" || die
		fi
	fi

	if ! (( HALCYON_RECURSIVE )) && ! (( HALCYON_NO_CLEAN_CACHE )); then
		log
		clean_cache || die
	fi

	if [ -d "${HALCYON_TMP_SLUG_DIR}" ]; then
		# NOTE: Cannot use -p on a read-only file system.

		cp -R "${HALCYON_TMP_SLUG_DIR}/." '/' || die
		rm -rf "${HALCYON_TMP_SLUG_DIR}" || die
	fi
}


function deploy_local_app () {
	local local_dir
	expect_args local_dir -- "$@"

	local name sources_dir
	name=$( echo_dir_name "${local_dir}" ) || die
	sources_dir=$( echo_tmp_dir_name 'halcyon.deploy_local_app' ) || die

	log 'Deploying local app:'
	log_indent "${name}"

	copy_entire_contents "${local_dir}" "${sources_dir}" || die

	if ! deploy_layers "${sources_dir}"; then
		log_warning 'Cannot deploy local app'
		return 1
	fi

	rm -rf "${sources_dir}" || die
}


function deploy_cloned_app () {
	local url
	expect_args url -- "$@"

	local name sources_dir
	name=$( basename "${url}" ) || die
	sources_dir=$( echo_tmp_dir_name 'halcyon.deploy_cloned_app' ) || die

	log 'Deploying cloned app:'
	log_indent "${name%.git}"

	if ! git clone --depth=1 --quiet "${url}" "${sources_dir}"; then
		die 'Cannot deploy cloned app'
	fi
	if ! deploy_layers "${sources_dir}"; then
		log_warning 'Cannot deploy cloned app'
		return 1
	fi

	rm -rf "${sources_dir}" || die
}


function deploy_base_package () {
	expect_vars HALCYON_DIR

	local arg
	expect_args arg -- "$@"

	local sources_dir
	sources_dir=$( echo_tmp_dir_name 'halcyon.deploy_base_package' ) || die

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
	log_begin 'Determining base package version...      '

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

	mkdir -p "${sources_dir}" || die
	echo_fake_base_package "${base_version}" >"${sources_dir}/halcyon-fake-base.cabal" || die

	if !                               \
		HALCYON_NO_PREPARE_CACHE=1 \
		HALCYON_NO_INSTALL_GHC=1   \
		HALCYON_NO_INSTALL_APP=1   \
		HALCYON_NO_WARN_IMPLICIT=1 \
		deploy_layers "${sources_dir}"
	then
		log_warning 'Cannot deploy base package'
		return 1
	fi

	rm -rf "${sources_dir}" || die
}


function deploy_published_app () {
	expect_vars HALCYON_DIR

	local arg
	expect_args arg -- "$@"

	local sources_dir
	sources_dir=$( echo_tmp_dir_name 'halcyon.deploy_published_app' ) || die

	log "Deploying published app:"
	log_indent "${arg}"

	if !                                 \
		HALCYON_NO_INSTALL_SANDBOX=1 \
		HALCYON_NO_INSTALL_APP=1     \
		HALCYON_NO_CLEAN_CACHE=1     \
		HALCYON_NO_WARN_IMPLICIT=1   \
		deploy_layers '/dev/null'
	then
		log_warning 'Cannot deploy published app'
		return 1
	fi

	log
	log_begin 'Determining published app version...     '

	mkdir -p "${sources_dir}" || die

	local label
	if ! label=$(
		cabal_do "${sources_dir}" unpack "${arg}" 2>'/dev/null' |
			filter_last |
			match_exactly_one |
			sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		log_end '(unknown)'
		log_warning 'Cannot deploy published app'
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
		deploy_layers "${sources_dir}/${label}"
	then
		log_warning 'Cannot deploy published app'
		return 1
	fi

	rm -rf "${sources_dir}" || die
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
			if ! deploy_published_app "${arg}"; then
				return 1
			fi
		fi
	esac
}
