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
source "${HALCYON_TOP_DIR}/src/transfer.sh"
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
	export HALCYON_NO_ARCHIVE="${HALCYON_NO_ARCHIVE:-0}"
	export HALCYON_NO_UPLOAD="${HALCYON_NO_UPLOAD:-0}"
	export HALCYON_DEPENDENCIES_ONLY="${HALCYON_DEPENDENCIES_ONLY:-0}"
	export HALCYON_PREBUILT_ONLY="${HALCYON_PREBUILT_ONLY:-0}"
	export HALCYON_NO_PREBUILT="${HALCYON_NO_PREBUILT:-0}"
	export HALCYON_NO_PREBUILT_GHC="${HALCYON_NO_PREBUILT_GHC:-0}"
	export HALCYON_NO_PREBUILT_CABAL="${HALCYON_NO_PREBUILT_CABAL:-0}"
	export HALCYON_NO_PREBUILT_SANDBOX="${HALCYON_NO_PREBUILT_SANDBOX:-0}"
	export HALCYON_NO_PREBUILT_APP="${HALCYON_NO_PREBUILT_APP:-0}"
	export HALCYON_FORCE_GHC_VERSION="${HALCYON_FORCE_GHC_VERSION:-}"
	export HALCYON_FORCE_CABAL_VERSION="${HALCYON_FORCE_CABAL_VERSION:-}"
	export HALCYON_FORCE_CABAL_UPDATE="${HALCYON_FORCE_CABAL_UPDATE:-0}"
	export HALCYON_TRIM_GHC="${HALCYON_TRIM_GHC:-0}"
	export HALCYON_CUSTOM_SCRIPT="${HALCYON_CUSTOM_SCRIPT:-}"
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
	expect_vars HALCYON_DEPENDENCIES_ONLY

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
		'--no-archive')
			export HALCYON_NO_ARCHIVE=1;;
		'--no-upload')
			export HALCYON_NO_UPLOAD=1;;

		'--dependencies-only');&
		'--dep-only');&
		'--only-dependencies');&
		'--only-dep')
			export HALCYON_DEPENDENCIES_ONLY=1;;
		'--prebuilt-only');&
		'--pre-only');&
		'--only-prebuilt');&
		'--only-pre')
			export HALCYON_PREBUILT_ONLY=1;;

		'--no-prebuilt');&
		'--no-pre')
			export HALCYON_NO_PREBUILT=1;;
		'--no-prebuilt-ghc');&
		'--no-pre-ghc')
			export HALCYON_NO_PREBUILT_GHC=1;;
		'--no-prebuilt-cabal');&
		'--no-pre-cabal')
			export HALCYON_NO_PREBUILT_CABAL=1;;
		'--no-prebuilt-sandbox');&
		'--no-pre-sandbox')
			export HALCYON_NO_PREBUILT_SANDBOX=1;;
		'--no-prebuilt-app');&
		'--no-pre-app')
			export HALCYON_NO_PREBUILT_APP=1;;

		'--force-ghc-version='*)
			export HALCYON_FORCE_GHC_VERSION="${1#*=}";;
		'--force-cabal-version='*)
			export HALCYON_FORCE_CABAL_VERSION="${1#*=}";;
		'--force-cabal-update')
			export HALCYON_FORCE_CABAL_UPDATE=1;;

		'--trim-ghc')
			export HALCYON_TRIM_GHC=1;;
		'--custom-script='*)
			export HALCYON_CUSTOM_SCRIPT="${1#*=}";;

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

	install_cabal || return 1
	log

	if (( ${HALCYON_FAKE_APP} )); then
		app_dir=$( fake_app_dir "${app_label}" ) || die
	fi

	install_sandbox "${app_dir}" || return 1
	log

	if (( ${HALCYON_FAKE_APP} )); then
		rm -rf "${app_dir}" || die
	elif ! (( ${HALCYON_DEPENDENCIES_ONLY} )); then
		install_app "${app_dir}" || die
		log
	fi

	clean_cache "${app_dir}" || die
	log

	log "Installed ${app_label}"
}
