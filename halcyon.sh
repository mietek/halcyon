declare HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

if [ -d "${HALCYON_TOP_DIR}/bashmenot" ]; then
	source "${HALCYON_TOP_DIR}/bashmenot/bashmenot.sh"
elif [ -d "${HALCYON_TOP_DIR}/../bashmenot" ]; then
	source "${HALCYON_TOP_DIR}/../bashmenot/bashmenot.sh"
elif [ -d "${HALCYON_TOP_DIR}/bower_components/bashmenot" ]; then
	source "${HALCYON_TOP_DIR}/bower_components/bashmenot/bashmenot.sh"
elif [ -d "${HALCYON_TOP_DIR}/../bower_components/bashmenot" ]; then
	source "${HALCYON_TOP_DIR}/../bower_components/bashmenot/bashmenot.sh"
else
	echo '   *** ERROR: Failed to locate the bashmenot directory' >&2
	exit 1
fi

source "${HALCYON_TOP_DIR}/src/cache.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/constraints.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/app.sh"


function set_default_vars () {
	export HALCYON_AWS_ACCESS_KEY_ID="${HALCYON_AWS_ACCESS_KEY_ID:-}"
	export HALCYON_AWS_SECRET_ACCESS_KEY="${HALCYON_AWS_SECRET_ACCESS_KEY:-}"
	export HALCYON_S3_BUCKET="${HALCYON_S3_BUCKET:-}"
	export HALCYON_S3_ACL="${HALCYON_S3_ACL:-private}"

	export HALCYON_DIR="${HALCYON_DIR:-/app/.halcyon}"

	export HALCYON_CACHE_DIR="${HALCYON_CACHE_DIR:-/var/tmp/halcyon/cache}"
	export HALCYON_PURGE_CACHE="${HALCYON_PURGE_CACHE:-0}"

	export HALCYON_NO_BUILD="${HALCYON_NO_BUILD:-0}"
	export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
	export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"
	export HALCYON_NO_APP="${HALCYON_NO_APP:-0}"

	export HALCYON_FORCE_BUILD_ALL="${HALCYON_FORCE_BUILD_ALL:-0}"
	export HALCYON_FORCE_BUILD_GHC="${HALCYON_FORCE_BUILD_GHC:-0}"
	export HALCYON_FORCE_BUILD_CABAL="${HALCYON_FORCE_BUILD_CABAL:-0}"
	export HALCYON_FORCE_BUILD_SANDBOX="${HALCYON_FORCE_BUILD_SANDBOX:-0}"
	export HALCYON_FORCE_BUILD_APP="${HALCYON_FORCE_BUILD_APP:-0}"

	export HALCYON_FORCE_GHC_VERSION="${HALCYON_FORCE_GHC_VERSION:-}"
	export HALCYON_FORCE_CABAL_VERSION="${HALCYON_FORCE_CABAL_VERSION:-}"
	export HALCYON_FORCE_CABAL_UPDATE="${HALCYON_FORCE_CABAL_UPDATE:-0}"

	export HALCYON_QUIET="${HALCYON_QUIET:-0}"

	export PATH="${HALCYON_DIR}/ghc/bin:${PATH}"
	export PATH="${HALCYON_DIR}/cabal/bin:${PATH}"
	export PATH="${HALCYON_DIR}/sandbox/bin:${PATH}"
	export PATH="${HALCYON_DIR}/app/bin:${PATH}"

	export LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LIBRARY_PATH:-}"
	export LD_LIBRARY_PATH="${HALCYON_DIR}/ghc/lib:${LD_LIBRARY_PATH:-}"

	export LANG="${LANG:-en_US.UTF-8}"
}


function halcyon_install () {
	expect_vars HALCYON_NO_APP

	while (( $# )); do
		case "$1" in
		'--aws-access-key-id='*)
			export HALCYON_AWS_ACCESS_KEY_ID="${1#*=}";;
		'--aws-secret-access-key='*)
			export HALCYON_AWS_SECRET_ACCESS_KEY="${1#*=}";;
		'--s3-bucket='*)
			export HALCYON_S3_BUCKET="${1#*=}";;
		'--s3-acl='*)
			export HALCYON_S3_ACL="${1#*=}";;

		'--halcyon-dir='*)
			export HALCYON_DIR="${1#*=}";;

		'--cache-dir='*)
			export HALCYON_CACHE_DIR="${1#*=}";;
		'--purge-cache')
			export HALCYON_PURGE_CACHE=1;;

		'--no-build')
			export HALCYON_NO_BUILD=1;;
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;
		'--no-app')
			export HALCYON_NO_APP=1;;

		'--force-build-all')
			export HALCYON_FORCE_BUILD_ALL=1;;
		'--force-build-ghc')
			export HALCYON_FORCE_BUILD_GHC=1;;
		'--force-build-cabal')
			export HALCYON_FORCE_BUILD_CABAL=1;;
		'--force-build-sandbox')
			export HALCYON_FORCE_BUILD_SANDBOX=1;;
		'--force-build-app')
			export HALCYON_FORCE_BUILD_APP=1;;

		'--force-ghc-version='*)
			export HALCYON_FORCE_GHC_VERSION="${1#*=}";;
		'--force-cabal-version='*)
			export HALCYON_FORCE_CABAL_VERSION="${1#*=}";;
		'--force-cabal-update')
			export HALCYON_FORCE_CABAL_UPDATE=1;;

		'--quiet')
			export HALCYON_QUIET=1;;

		'-'*)
			die "Unexpected option: $1";;
		*)
			break
		esac
		shift
	done

	local app_dir app_label
	if ! (( $# )); then
		export HALCYON_FAKE_APP=0
		app_dir='.'
		app_label=$( detect_app_label "${app_dir}" ) || die
	elif [ -d "$1" ]; then
		export HALCYON_FAKE_APP=0
		app_dir="$1"
		app_label=$( detect_app_label "${app_dir}" ) || die
	else
		export HALCYON_FAKE_APP=1
		app_label="$1"
		app_dir=''
	fi

	log "Installing ${app_label}"
	log

	prepare_cache || die
	log

	install_ghc "${app_dir}" || return 1
	log

	install_cabal "${app_dir}" || return 1
	log

	if (( ${HALCYON_FAKE_APP} )); then
		app_dir=$( fake_app_dir "${app_label}" ) || die
	fi

	install_sandbox "${app_dir}" || return 1
	log

	if (( ${HALCYON_FAKE_APP} )); then
		rm -rf "${app_dir}" || die
	elif ! (( ${HALCYON_NO_APP} )); then
		install_app "${app_dir}" || die
		log
	fi

	clean_cache "${app_dir}" || die
	log

	log "Installed ${app_label}"
}
