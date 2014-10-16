declare HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

if ! [ -d "${HALCYON_TOP_DIR}/../bashmenot" ]; then
	echo '   *** ERROR: Locating bashmenot failed' >&2
	exit 1
fi

source "${HALCYON_TOP_DIR}/../bashmenot/bashmenot.sh"
source "${HALCYON_TOP_DIR}/src/cache.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/constraints.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/app.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"


function set_default_vars () {
	export HALCYON_DIR="${HALCYON_DIR:-/app/.halcyon}"

	export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
	export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
	export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
	export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"
	export HALCYON_PUBLIC="${HALCYON_PUBLIC:-0}"

	export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon/cache}"
	export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"

	export HALCYON_FORCE_BUILD_ALL="${HALCYON_FORCE_BUILD_ALL:-0}"
	export HALCYON_FORCE_GHC_VERSION="${HALCYON_FORCE_GHC_VERSION:-}"
	export HALCYON_FORCE_BUILD_GHC="${HALCYON_FORCE_BUILD_GHC:-0}"
	export HALCYON_FORCE_CABAL_VERSION="${HALCYON_FORCE_CABAL_VERSION:-}"
	export HALCYON_FORCE_BUILD_CABAL="${HALCYON_FORCE_BUILD_CABAL:-0}"
	export HALCYON_FORCE_UPDATE_CABAL="${HALCYON_FORCE_UPDATE_CABAL:-0}"
	export HALCYON_FORCE_BUILD_SANDBOX="${HALCYON_FORCE_BUILD_SANDBOX:-0}"
	export HALCYON_FORCE_BUILD_APP="${HALCYON_FORCE_BUILD_APP:-0}"

	export HALCYON_NO_APP="${HALCYON_NO_APP:-0}"
	export HALCYON_NO_BUILD="${HALCYON_NO_BUILD:-0}"
	export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
	export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"

	export HALCYON_NO_WARN_CONSTRAINTS="${HALCYON_NO_WARN_CONSTRAINTS:-0}"

	export HALCYON_QUIET="${HALCYON_QUIET:-0}"

	export PATH="${HALCYON_DIR}/ghc/bin:${PATH}"
	export PATH="${HALCYON_DIR}/cabal/bin:${PATH}"
	export PATH="${HALCYON_DIR}/sandbox/bin:${PATH}"
	export PATH="${HALCYON_DIR}/app/bin:${PATH}"

	export LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LD_LIBRARY_PATH:-}"

	export LANG="${LANG:-en_US.UTF-8}"
}


function hash_hooks () {
	local hooks
	if ! hooks=$( cat "$@" 2>'/dev/null' ); then
		return 0
	fi

	openssl sha1 <<<"${hooks}" | sed 's/^.* //'
}


function echo_fake_app_package () {
	local app_label
	expect_args app_label -- "$@"

	local app_name app_version build_depends
	if [ "${app_label}" = 'base' ]; then
		app_name='base'
		app_version=$( detect_base_version ) || die
		build_depends='base'
	else
		app_name="${app_label}"
		if ! app_version=$( cabal_list_latest_package_version "${app_label}" ); then
			app_name="${app_label%-*}"
			app_version="${app_label##*-}"
		fi
		build_depends="base, ${app_name} == ${app_version}"
	fi

	cat <<-EOF
		name:           halcyon-fake-${app_name}
		version:        ${app_version}
		build-type:     Simple
		cabal-version:  >= 1.2

		executable halcyon-fake-${app_name}
		  build-depends:  ${build_depends}
EOF
}


function prepare_fake_app_dir () {
	local app_label
	expect_args app_label -- "$@"

	local app_dir
	app_dir=$( echo_tmp_app_dir ) || die

	mkdir -p "${app_dir}" || die
	echo_fake_app_package "${app_label}" >"${app_dir}/${app_label}.cabal" || die

	if [ -d '.halcyon-hooks' ]; then
		cp -R '.halcyon-hooks' "${app_dir}"
	fi

	echo "${app_dir}"
}


function halcyon_install () {
	expect_vars HALCYON_NO_APP

	while (( $# )); do
		case "$1" in
		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;

		'--aws-access-key-id='*)
			export HALCYON_AWS_ACCESS_KEY_ID="${1#*=}";;
		'--aws-secret-access-key='*)
			export HALCYON_AWS_SECRET_ACCESS_KEY="${1#*=}";;
		'--s3-bucket='*)
			export HALCYON_S3_BUCKET="${1#*=}";;
		'--s3-acl='*)
			export HALCYON_S3_ACL="${1#*=}";;

		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;
		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;

		'--force-build-all')
			export HALCYON_FORCE_BUILD_ALL=1;;
		'--force-ghc-version='*)
			export HALCYON_FORCE_GHC_VERSION="${1#*=}";;
		'--force-build-ghc');&
		'--force-ghc-build')
			export HALCYON_FORCE_BUILD_GHC=1;;
		'--force-cabal-version='*)
			export HALCYON_FORCE_CABAL_VERSION="${1#*=}";;
		'--force-build-cabal');&
		'--force-cabal-build')
			export HALCYON_FORCE_BUILD_CABAL=1;;
		'--force-update-cabal');&
		'--force-cabal-update')
			export HALCYON_FORCE_UPDATE_CABAL=1;;
		'--force-build-sandbox');&
		'--force-sandbox-build')
			export HALCYON_FORCE_BUILD_SANDBOX=1;;
		'--force-build-app');&
		'--force-app-build')
			export HALCYON_FORCE_BUILD_APP=1;;

		'--no-app')
			export HALCYON_NO_APP=1;;
		'--no-build')
			export HALCYON_NO_BUILD=1;;
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;

		'--quiet')
			export HALCYON_QUIET=1;;

		'-'*)
			die "Unexpected option: $1";;
		*)
			break
		esac
		shift
	done

	local fake_app app_dir app_label
	if ! (( $# )) || [ -d "$1" ]; then
		fake_app=0
		if (( $# )) && [ -d "$1" ]; then
			app_dir="$1"
		else
			app_dir='.'
		fi
		app_label=$( detect_app_label "${app_dir}" ) || die
		log "Installing ${app_label}"
		log
	else
		fake_app=1
		app_label="$1"
		app_dir=''
		export HALCYON_NO_WARN_CONSTRAINTS=1
	fi

	prepare_cache || die
	log

	install_ghc "${app_dir}" || return 1
	log

	install_cabal "${app_dir}" || return 1
	log

	if (( ${fake_app} )); then
		app_dir=$( prepare_fake_app_dir "${app_label}" ) || die
	fi

	install_sandbox "${app_dir}" || return 1
	log

	if (( ${fake_app} )); then
		rm -rf "${app_dir}" || die
	elif ! (( ${HALCYON_NO_APP} )); then
		install_app "${app_dir}" || return 1
		log
	fi

	clean_cache "${app_dir}" || die
}
