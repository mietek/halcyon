set -o pipefail


install_os_packages () {
	local platform uid
	platform="$1"
	uid="$2"

	case "${platform}" in
	'linux-arch'*)
		sudo bash -c "pacman --sync --refresh &&
			pacman --sync --needed --noconfirm base-devel git pigz zlib" || return 1
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
		if ! (( uid )); then
			apt-get update || return 1
			apt-get install -y build-essential git pigz zlib1g-dev || return 1
		else
			echo '   *** WARNING: Cannot install OS packages' >&2
			echo >&2
			echo '       Ensure the following OS packages are installed:' >&2
			echo '       $ apt-get update' >&2
			echo '       $ apt-get install -y build-essential git pigz zlib1g-dev' >&2
		fi
		;;
	'linux-debian-7'*)
		# NOTE: When run as root, sudo asks for password
		# on Debian 7.
		if ! (( uid )); then
			apt-get update || return 1
			apt-get install -y build-essential git pigz zlib1g-dev || return 1
		else
			sudo bash -c "apt-get update &&
				apt-get install -y build-essential git pigz zlib1g-dev" || return 1
		fi
		;;
	'linux-fedora-19'*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git pigz zlib-devel" || return 1
		;;
	'linux-fedora-20'*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git patch pigz tar zlib-devel" || return 1
		;;
	'linux-fedora-21'*)
		sudo bash -c "yum groupinstall -y 'Development Tools' &&
			yum install -y git patch openssl pigz tar which zlib-devel" || return 1
		;;
	'linux-ubuntu-10'*)
		# NOTE: When run as root, sudo asks for password
		# on Ubuntu 10.
		if ! (( uid )); then
			apt-get install -y build-essential git-core pigz zlib1g-dev || return 1
			apt-get install -y --reinstall ca-certificates || return 1
		else
			sudo bash -c "apt-get update &&
				apt-get install -y build-essential git-core pigz zlib1g-dev &&
				apt-get install -y --reinstall ca-certificates" || return 1
		fi
		;;
	'linux-ubuntu-12'*)
		# NOTE: When run as root, sudo asks for password
		# on Ubuntu 12.
		if ! (( uid )); then
			apt-get update || return 1
			apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev || return 1
		else
			sudo bash -c "apt-get update &&
				apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev" || return 1
		fi
		;;
	'linux-ubuntu-14'*)
		sudo bash -c "apt-get update &&
			apt-get install -y build-essential git pigz zlib1g-dev" || return 1
		;;
	'osx-'*)
		echo '   *** WARNING: Cannot install OS packages' >&2
		echo >&2
		echo '       Ensure the following OS packages are installed:' >&2
		echo '       $ brew update' >&2
		echo '       $ brew install bash coreutils git pigz' >&2
		;;
	*)
		echo "	 *** ERROR: Unexpected platform: ${platform}" >&2
		return 1
	esac
}


install_halcyon () {
	local base dir
	base="${HALCYON_BASE:-/app}"
	dir="${HALCYON_DIR:-${base}/halcyon}"

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

	local platform uid user group
	platform=$( detect_platform )
	uid=$( id -u ) || return 1
	user=$( id -nu ) || return 1
	group=$( id -ng ) || return 1

	echo "-----> Creating base directory: ${base}" >&2


	case "${platform}" in
	'linux-debian-6'*)
		# NOTE: There is no sudo on Debian 6.
		if ! (( uid )); then
			mkdir -p "${base}" || return 1
			chown "${user}:${group}" "${base}" || return 1
		else
			echo '   *** WARNING: Cannot create base directory' >&2
			echo
			echo "       Ensure ${base} is owned by ${user}:${group}:" >&2
			echo "       $ mkdir -p \"${base}\"" >&2
			echo "       $ chown ${user}:${group} \"${base}\"" >&2
		fi
		;;
	'linux-debian-7'*|'linux-ubuntu-10'*|'linux-ubuntu-12'*)
		# NOTE: When run as root, sudo asks for password
		# on Debian 7, Ubuntu 10, and Ubuntu 12.
		if ! (( uid )); then
			mkdir -p "${base}" || return 1
			chown "${user}:${group}" "${base}" || return 1
		else
			sudo -k mkdir -p "${base}" || return 1
			sudo chown "${user}:${group}" "${base}" || return 1
		fi
		;;
	*)
		sudo -k mkdir -p "${base}" || return 1
		sudo chown "${user}:${group}" "${base}" || return 1
	esac

	echo '-----> Installing OS packages' >&2

	if ! install_os_packages "${platform}" "${uid}" 2>&1 | sed 's/^/       /' >&2; then
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

	source <( HALCYON_NO_SELF_UPDATE=1 "${dir}/halcyon" paths ) || return 1

	if ! (( ${HALCYON_NO_MODIFY_HOME:-0} )); then
		echo '-----> Extending .bash_profile' >&2

		if [[ "${base}" != '/app' ]]; then
			echo "export HALCYON_BASE=${base}" >>"${HOME}/.bash_profile" || return 1
		fi
		echo "source <( HALCYON_NO_SELF_UPDATE=1 \"${dir}/halcyon\" paths )" >>"${HOME}/.bash_profile" || return 1
	else
		echo "   *** WARNING: Cannot extend ${HOME}/.bash_profile" >&2
		echo >&2
		echo '       To activate Halcyon manually:'

		if [[ "${base}" != '/app' ]]; then
			echo "       $ export HALCYON_BASE=\"${base}\"" >&2
		fi
		echo "       $ source <( \"${dir}/halcyon\" paths )" >&2
	fi
}


if ! install_halcyon; then
	echo '   *** ERROR: Failed to install Halcyon' >&2
fi
