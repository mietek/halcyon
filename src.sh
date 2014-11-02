export HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )

install_bashmenot () {
	local dir
	dir="${HALCYON_TOP_DIR}/lib/bashmenot"
	if [[ -d "${dir}" ]]; then
		if ! git -C "${dir}" fetch -q || ! git -C "${dir}" reset -q --hard '@{u}'; then
			echo '   *** ERROR: Cannot update bashmenot' >&2
			return 1
		fi
		return 0
	fi

	local urloid url branch
	urloid="${HALCYON_BASHMENOT_SOURCE_URL:-https://github.com/mietek/bashmenot.git}"
	url="${urloid%#*}"
	branch="${urloid#*#}"
	if ! git clone -q "${url}" "${dir}"; then
		echo "   *** ERROR: Cannot clone ${url}" >&2
		return 1
	fi
	if [[ "${url}" != "${branch}" ]] && ! git -C "${dir}" checkout -q "${branch}"; then
		echo "   *** ERROR: Cannot checkout bashmenot ${branch}" >&2
		return 1
	fi
}

install_bashmenot || exit 1

source "${HALCYON_TOP_DIR}/lib/bashmenot/src.sh"

source "${HALCYON_TOP_DIR}/src/app.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/constraints.sh"
source "${HALCYON_TOP_DIR}/src/deploy.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"
source "${HALCYON_TOP_DIR}/src/paths.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/slug.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/tag.sh"
source "${HALCYON_TOP_DIR}/src/vars.sh"
