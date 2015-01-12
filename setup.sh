set -o pipefail


install_os_packages () {
	case "$1" in
	'linux-arch'*)
		sudo pacman --sync --noconfirm base-devel git pigz zlib || return 1
		;;
	'linux-centos-6'*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git yum-plugin-downloadonly zlib-devel" || return 1
		;;
	'linux-centos-7'*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git zlib-devel" || return 1
		;;
	'linux-debian-6'*)
		# NOTE: There is no sudo on Debian 6.
		apt-get update || return 1
		apt-get install -y build-essential git pigz zlib1g-dev || return 1
		;;
	'linux-debian-7'*)
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git pigz zlib1g-dev" || return 1
		;;
	'linux-fedora-19'*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git pigz zlib-devel" || return 1
		;;
	'linux-fedora-2'[01]*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git patch pigz tar zlib-devel" || return 1
		;;
	'linux-ubuntu-10'*)
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git-core pigz zlib1g-dev &&
			apt-get install -y --reinstall ca-certificates" || return 1
		;;
	'linux-ubuntu-12'*)
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev" || return 1
		;;
	'linux-ubuntu-14'*)
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git pigz zlib1g-dev" || return 1
		;;
	*)
		echo '	 *** ERROR: Unexpected platform' >&2
		return 1
	esac
}


install_halcyon () {
	local base dir
	base="${HALCYON_BASE:-/app}"
	dir="${HALCYON_DIR:-${base}/halcyon}"
	if [[ -d "${dir}" ]]; then
		return 0
	fi

	echo '-----> Welcome to Halcyon' >&2

	if [[ -e "${base}" ]]; then
		echo "   *** ERROR: Unexpected existing ${base}" >&2
		return 1
	fi
	if [[ -e "${dir}" ]]; then
		echo "   *** ERROR: Unexpected existing ${dir}" >&2
		return 1
	fi

	source <( curl -sL 'https://github.com/mietek/bashmenot/raw/master/src/platform.sh' ) || return 1

	local platform user group
	platform=$( detect_platform )
	user=$( id -nu ) || return 1
	group=$( id -ng ) || return 1

	if [[ "${platform}" =~ 'linux-debian-6'* ]]; then
		# NOTE: There is no sudo on Debian 6, and curl considers
		# HTTP 40* errors to be transient, which makes retrying
		# impractical.
		echo "   *** WARNING: Cannot create base directory" >&2
		echo "	 *** WARNING: Ensure ${base} is owned by ${user}:${group}" >&2
		export BASHMENOT_CURL_RETRIES=0
	else
		if sudo -k mkdir -p "${base}" &&
			sudo chown "${user}:${group}" "${base}"
		then
			echo "-----> Creating base directory: ${base}" >&2
		else
			echo "   *** ERROR: Failed to create base directory" >&2
			return 1
		fi
	fi

	echo '-----> Installing OS packages' >&2

	if ! install_os_packages "${platform}" 2>&1 | sed 's/^/       /' >&2; then
		echo '   *** ERROR: Failed to install OS packages' >&2
		return 1
	fi

	local url base_url branch
	url="${HALCYON_URL:-https://github.com/mietek/halcyon}"
	base_url="${url%#*}"
	branch="${url#*#}"
	if [[ "${branch}" == "${base_url}" ]]; then
		branch='master'
	fi

	echo >&2
	echo -n "-----> Installing Halcyon in ${dir}..." >&2

	local commit_hash
	if ! commit_hash=$(
		git clone -q "${base_url}" "${dir}" >'/dev/null' 2>&1 &&
		cd "${dir}" &&
		git checkout -q "${branch}" >'/dev/null' 2>&1 &&
		git log -n 1 --pretty='format:%h'
	); then
		echo 'error' >&2
		return 1
	fi
	echo " done, ${commit_hash:0:7}" >&2

	source <( HALCYON_NO_SELF_UPDATE=1 "${dir}/halcyon" paths ) || return 1

	if ! (( ${HALCYON_NO_MODIFY_HOME:-0} )); then
		echo '-----> Extending .bash_profile' >&2

		if [[ "${platform}" =~ 'linux-debian-6'* ]]; then
			echo 'export BASHMENOT_CURL_RETRIES=0' >>"${HOME}/.bash_profile" || return 1
		fi
		if [[ "${base}" != '/app' ]]; then
			echo "export HALCYON_BASE=${base}" >>"${HOME}/.bash_profile" || return 1
		fi
		echo "source <( HALCYON_NO_SELF_UPDATE=1 \"${dir}/halcyon\" paths )" >>"${HOME}/.bash_profile" || return 1
	else
		echo "   *** WARNING: Cannot extend ${HOME}/.bash_profile" >&2
		echo >&2
		echo '       To activate Halcyon manually:'

		if [[ "${platform}" =~ 'linux-debian-6'* ]]; then
			echo '       $ export BASHMENOT_CURL_RETRIES=0' >&2
		fi
		if [[ "${base}" != '/app' ]]; then
			echo "       $ export HALCYON_BASE=\"${base}\"" >&2
		fi
		echo "       $ source <( \"${dir}/halcyon\" paths )" >&2
	fi
}


if ! install_halcyon; then
	echo '   *** ERROR: Failed to install Halcyon' >&2
fi
