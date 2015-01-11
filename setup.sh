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
			yum install -y git patch pigz tar zlib-devel &&
			systemctl disable firewalld &&
			systemctl stop firewalld" || return 1
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
	dir="${1:-${base}/halcyon}"
	if [[ -d "${dir}" ]]; then
		source <( "${dir}/halcyon" paths ) || return 1
		return 0
	fi

	if [[ -e "${base}" ]]; then
		echo "   *** ERROR: Unexpected existing ${base}" >&2
		return 1
	fi
	if [[ -e "${dir}" ]]; then
		echo "   *** ERROR: Unexpected existing ${dir}" >&2
		return 1
	fi

	source <( curl -sL 'https://github.com/mietek/bashmenot/raw/master/src/platform.sh' ) || return 1

	local platform
	platform=$( detect_platform )

	if [[ "${platform}" =~ 'linux-debian-6'* ]]; then
		# NOTE: There is no sudo on Debian 6, and curl considers HTTP 40*
		# errors to be transient, which makes retrying impractical.
		echo 'export BASHMENOT_CURL_RETRIES=0' >>"${HOME}/.bash_profile" || return 1
		export BASHMENOT_CURL_RETRIES=0
	else
		local uid gid
		uid=$( id -u ) || return 1
		gid=$( id -g ) || return 1

		sudo -k mkdir -p "${base}" "${dir}" || return 1
		sudo chown "${uid}":"${gid}" "${base}" "${dir}" || return 1
	fi

	install_os_packages "${platform}" || return 1

	local url base_url branch
	url="${HALCYON_URL:-https://github.com/mietek/halcyon}"
	base_url="${url%#*}"
	branch="${url#*#}"
	if [[ "${branch}" == "${base_url}" ]]; then
		branch='master'
	fi

	echo -n '-----> Installing Halcyon...' >&2

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

	echo "source <( \"${dir}/halcyon\" paths )" >>"${HOME}/.bash_profile" || return 1
	source <( HALCYON_NO_SELF_UPDATE=1 \
		"${dir}/halcyon" paths ) || return 1
}


if ! install_halcyon "$@"; then
	echo '   *** ERROR: Failed to install Halcyon' >&2
	exit 1
fi
