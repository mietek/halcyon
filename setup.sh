prepare_platform () {
	source <( curl -sL 'https://github.com/mietek/bashmenot/raw/master/src/platform.sh' ) || return 1

	case $( detect_platform ) in
	'linux-arch'*)
		sudo -k || return 1
		sudo pacman --sync --noconfirm base-devel git pigz zlib || return 1
		;;
	'linux-centos-6'*)
		sudo -k || return 1
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git yum-plugin-downloadonly zlib-devel" || return 1
		;;
	'linux-centos-7'*)
		sudo -k || return 1
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git zlib-devel" || return 1
		;;
	'linux-debian-6'*)
		# NOTE: There is no sudo on Debian 6, and curl considers HTTP 40*
		# errors to be transient, which makes retrying impractical.
		apt-get update || return 1
		apt-get install -y build-essential git pigz zlib1g-dev || return 1
		echo 'export BASHMENOT_CURL_RETRIES=0' >>"${HOME}/.bash_profile" || return 1
		export BASHMENOT_CURL_RETRIES=0
		;;
	'linux-debian-7'*)
		sudo -k || return 1
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git pigz zlib1g-dev" || return 1
		;;
	'linux-fedora-19'*)
		sudo -k || return 1
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git pigz zlib-devel" || return 1
		;;
	'linux-fedora-2'[01]*)
		sudo -k || return 1
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git patch pigz tar zlib-devel &&
			systemctl disable firewalld &&
			systemctl stop firewalld" || return 1
		;;
	'linux-ubuntu-10'*)
		sudo -k || return 1
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git-core pigz zlib1g-dev &&
			apt-get install -y --reinstall ca-certificates" || return 1
		;;
	'linux-ubuntu-12'*)
		sudo -k || return 1
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev" || return 1
		;;
	'linux-ubuntu-14'*)
		sudo -k || return 1
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git pigz zlib1g-dev" || return 1
		;;
	*)
		echo '	 *** ERROR: Unexpected platform' >&2
		return 1
	esac
}


install_halcyon () {
	if [[ -d "${HOME}/halcyon" ]]; then
		source <( "${HOME}/halcyon/halcyon" paths ) || return 1
		return 0
	fi

	prepare_platform || return 1

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
		git clone -q "${base_url}" "${HOME}/halcyon" >'/dev/null' 2>&1 &&
		cd "${HOME}/halcyon" &&
		git checkout -q "${branch}" >'/dev/null' 2>&1 &&
		git log -n 1 --pretty='format:%h'
	); then
		echo 'error' >&2
		return 1
	fi
	echo " done, ${commit_hash:0:7}" >&2

	echo 'source <( "${HOME}/halcyon/halcyon" paths )' >>"${HOME}/.bash_profile" || return 1
	source <( HALCYON_NO_SELF_UPDATE=1 \
		"${HOME}/halcyon/halcyon" paths ) || return 1
}


if ! install_halcyon; then
	echo '   *** ERROR: Failed to install Halcyon' >&2
	exit 1
fi
