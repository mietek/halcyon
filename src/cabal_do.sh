function cabal_do () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/.halcyon-tag"

	local work_dir
	expect_args work_dir -- "$@"
	shift
	expect_existing "${work_dir}"

	if ! (
		cd "${work_dir}" &&
		cabal --config-file="${HALCYON_DIR}/cabal/.halcyon-cabal.config" "$@"
	); then
		local cabal_tag cabal_id
		cabal_tag=$( <"${HALCYON_DIR}/cabal/.halcyon-tag" ) || die
		cabal_description=$( echo_cabal_description "${cabal_tag}" ) || die

		die "Failed to run Cabal ${cabal_description}:" "$@"
	fi
}


function sandboxed_cabal_do () {
	local sandbox_dir work_dir
	expect_args sandbox_dir work_dir -- "$@"
	shift 2
	expect_existing "${sandbox_dir}"

	# NOTE: Specifying a sandbox config file should not change where Cabal looks
	# for a config file.
	# https://github.com/haskell/cabal/issues/1915

	local saved_config
	saved_config=''
	if [ -f "${sandbox_dir}/cabal.config" ]; then
		saved_config=$( echo_tmp_sandbox_config ) || die
		mv "${sandbox_dir}/cabal.config" "${saved_config}" || die
	fi
	if [ -f "${work_dir}/cabal.config" ]; then
		cp "${work_dir}/cabal.config" "${sandbox_dir}/cabal.config" || die
	fi

	local status
	status=0
	if ! cabal_do "${work_dir}"                                         \
		--sandbox-config-file="${sandbox_dir}/cabal.sandbox.config" \
		"$@"
	then
		status=1
	fi

	rm -f "${sandbox_dir}/cabal.config" || die
	if [ -n "${saved_config}" ]; then
		mv "${saved_config}" "${sandbox_dir}/cabal.config" || die
	fi

	return "${status}"
}


function cabal_update () {
	expect_vars HALCYON_QUIET

	quote_quietly "${HALCYON_QUIET}" cabal_do '.' update || die
}


function cabal_list_latest_package_version () {
	local package_name
	expect_args package_name -- "$@"

	cabal_do '.' --no-require-sandbox list --simple-output "${package_name}" |
		filter_matching "^${package_name} " |
		sort_naturally |
		filter_last |
		match_exactly_one |
		sed 's/^.* //'
}


function cabal_create_sandbox () {
	expect_vars HALCYON_QUIET

	local sandbox_dir
	expect_args sandbox_dir -- "$@"
	expect_no_existing "${sandbox_dir}"

	mkdir -p "${sandbox_dir}" || die
	quote_quietly "${HALCYON_QUIET}" cabal_do "${sandbox_dir}" sandbox init --sandbox '.' || die
}


# NOTE: Listing executable-only packages in build-tools causes Cabal to
# expect the executables to be installed, but not to install the packages.
# https://github.com/haskell/cabal/issues/220

# NOTE: Listing executable-only packages in build-depends causes Cabal to
# install the packages, and to fail to recognise the packages have been
# installed.
# https://github.com/haskell/cabal/issues/779


function cabal_install () {
	expect_vars HALCYON_QUIET

	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"

	quote_quietly "${HALCYON_QUIET}" sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" install "$@" || die
}


function cabal_install_deps () {
	expect_vars HALCYON_QUIET

	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"

	quote_quietly "${HALCYON_QUIET}" sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" install --dependencies-only || die
}


function cabal_configure_app () {
	expect_vars HALCYON_DIR HALCYON_QUIET

	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"

	quote_quietly "${HALCYON_QUIET}" sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" configure --prefix="${HALCYON_DIR}/app" || die
}


function cabal_build_app () {
	expect_vars HALCYON_QUIET

	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"

	quote_quietly "${HALCYON_QUIET}" sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" build || die
}


function cabal_install_app () {
	expect_vars HALCYON_QUIET

	local sandbox_dir app_dir
	expect_args sandbox_dir app_dir -- "$@"

	quote_quietly "${HALCYON_QUIET}" sandboxed_cabal_do "${sandbox_dir}" "${app_dir}" copy || die
}
