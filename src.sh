set -o pipefail

export HALCYON_TOP_DIR
HALCYON_TOP_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )


quote () {
	sed 's/^/       /' >&2 || return 0
}


halcyon_source_bashmenot () {
	local no_autoupdate
	no_autoupdate="${HALCYON_NO_AUTOUPDATE:-0}"
	if (( ${HALCYON_RECURSIVE:-0} )); then
		no_autoupdate=1
	fi

	if [[ -d "${HALCYON_TOP_DIR}/lib/bashmenot" ]]; then
		BASHMENOT_NO_AUTOUPDATE="${no_autoupdate}" \
			source "${HALCYON_TOP_DIR}/lib/bashmenot/src.sh" || return 1
		return 0
	fi

	local urloid url branch
	urloid="${BASHMENOT_URL:-https://github.com/mietek/bashmenot.git}"
	url="${urloid%#*}"
	branch="${urloid#*#}"
	if [[ "${branch}" == "${url}" ]]; then
		branch='master'
	fi

	echo '-----> Installing bashmenot' >&2

	git clone "${url}" "${HALCYON_TOP_DIR}/lib/bashmenot" |& quote || return 1
	( cd "${HALCYON_TOP_DIR}/lib/bashmenot" && git checkout "${branch}" |& quote ) || return 1

	BASHMENOT_NO_AUTOUPDATE=1 \
		source "${HALCYON_TOP_DIR}/lib/bashmenot/src.sh" || return 1
}


if ! halcyon_source_bashmenot; then
	echo '   *** ERROR: Cannot source bashmenot' >&2
fi


source "${HALCYON_TOP_DIR}/src/paths.sh"
source "${HALCYON_TOP_DIR}/src/vars.sh"
source "${HALCYON_TOP_DIR}/src/deploy.sh"
source "${HALCYON_TOP_DIR}/src/storage.sh"
source "${HALCYON_TOP_DIR}/src/tag.sh"
source "${HALCYON_TOP_DIR}/src/ghc.sh"
source "${HALCYON_TOP_DIR}/src/cabal.sh"
source "${HALCYON_TOP_DIR}/src/constraints.sh"
source "${HALCYON_TOP_DIR}/src/app.sh"
source "${HALCYON_TOP_DIR}/src/sandbox.sh"
source "${HALCYON_TOP_DIR}/src/slug.sh"
source "${HALCYON_TOP_DIR}/src/help.sh"


halcyon_autoupdate () {
	if (( ${HALCYON_NO_AUTOUPDATE:-0} )) || (( ${HALCYON_RECURSIVE:-0} )); then
		return 0
	fi

	if [[ ! -d "${HALCYON_TOP_DIR}/.git" ]]; then
		return 1
	fi

	local urloid url branch
	urloid="${HALCYON_URL:-https://github.com/mietek/halcyon.git}"
	url="${urloid%#*}"
	branch="${urloid#*#}"
	if [[ "${branch}" == "${url}" ]]; then
		branch='master'
	fi

	local git_url must_update
	must_update=0
	git_url=$( cd "${HALCYON_TOP_DIR}" && git config --get 'remote.origin.url' ) || return 1
	if [[ "${git_url}" != "${url}" ]]; then
		( cd "${HALCYON_TOP_DIR}" && git remote set-url 'origin' "${url}" |& quote ) || return 1
		must_update=1
	fi

	if ! (( must_update )); then
		local mark_time current_time
		mark_time=$( get_modification_time "${HALCYON_TOP_DIR}" ) || return 1
		current_time=$( date +'%s' ) || return 1
		if (( mark_time > current_time - 60 )); then
			return 0
		fi
	fi

	log 'Auto-updating Halcyon'

	( cd "${HALCYON_TOP_DIR}" && git fetch 'origin' |& quote ) || return 1
	( cd "${HALCYON_TOP_DIR}" && git reset --hard "origin/${branch}" |& quote ) || return 1

	HALCYON_NO_AUTOUPDATE=1 \
		source "${HALCYON_TOP_DIR}/src.sh" || return 1
}


if ! halcyon_autoupdate; then
	log_warning 'Cannot auto-update Halcyon'
fi
