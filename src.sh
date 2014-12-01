set -o pipefail

export HALCYON_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )


halcyon_source_bashmenot () {
	local no_update
	no_update="${HALCYON_NO_SELF_UPDATE:-0}"
	if (( ${HALCYON_INTERNAL_RECURSIVE:-0} )); then
		no_update=1
	fi

	if [[ -d "${HALCYON_DIR}/lib/bashmenot" ]]; then
		BASHMENOT_NO_SELF_UPDATE="${no_update}" \
			source "${HALCYON_DIR}/lib/bashmenot/src.sh" || return 1
		return 0
	fi

	local url base_url branch
	url="${BASHMENOT_URL:-https://github.com/mietek/bashmenot}"
	base_url="${url%#*}"
	branch="${url#*#}"
	if [[ "${branch}" == "${base_url}" ]]; then
		branch='master'
	fi

	echo -n '-----> Installing bashmenot...' >&2

	local commit_hash
	commit_hash=$(
		git clone -q "${base_url}" "${HALCYON_DIR}/lib/bashmenot" &>'/dev/null' &&
		cd "${HALCYON_DIR}/lib/bashmenot" &&
		git checkout -q "${branch}" &>'/dev/null' &&
		git log -n 1 --pretty='format:%h'
	) || return 1
	echo " done, ${commit_hash:0:7}" >&2

	BASHMENOT_NO_SELF_UPDATE=1 \
		source "${HALCYON_DIR}/lib/bashmenot/src.sh" || return 1
}


if ! halcyon_source_bashmenot; then
	echo '   *** ERROR: Cannot source bashmenot' >&2
fi


source "${HALCYON_DIR}/src/paths.sh"
source "${HALCYON_DIR}/src/main.sh"
source "${HALCYON_DIR}/src/tag.sh"
source "${HALCYON_DIR}/src/deploy.sh"
source "${HALCYON_DIR}/src/storage.sh"
source "${HALCYON_DIR}/src/constraints.sh"
source "${HALCYON_DIR}/src/ghc.sh"
source "${HALCYON_DIR}/src/cabal.sh"
source "${HALCYON_DIR}/src/sandbox.sh"
source "${HALCYON_DIR}/src/build.sh"
source "${HALCYON_DIR}/src/install.sh"
source "${HALCYON_DIR}/src/help.sh"


halcyon_self_update () {
	if (( ${HALCYON_NO_SELF_UPDATE:-0} )) || (( ${HALCYON_INTERNAL_RECURSIVE:-0} )); then
		return 0
	fi

	if [[ ! -d "${HALCYON_DIR}/.git" ]]; then
		return 1
	fi

	local url
	url="${HALCYON_URL:-https://github.com/mietek/halcyon}"

	log_begin 'Self-updating Halcyon...'

	local commit_hash
	if ! commit_hash=$( git_update_into "${url}" "${HALCYON_DIR}" ); then
		log_end 'error'
		return 1
	fi
	log_end "done, ${commit_hash:0:7}"

	HALCYON_NO_SELF_UPDATE=1 \
		source "${HALCYON_DIR}/src.sh" || return 1
}


if ! halcyon_self_update; then
	log_warning 'Cannot self-update Halcyon'
fi
