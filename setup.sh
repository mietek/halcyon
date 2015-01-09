source <( curl -sL 'https://github.com/mietek/bashmenot/raw/master/src/platform.sh' )

case $( detect_platform ) in
'linux-arch'*)
	sudo -k
	sudo pacman --sync --noconfirm base-devel git pigz zlib
	;;
'linux-centos-6'*)
	sudo -k
	sudo bash -c "yum groupinstall -y 'Development Tools' &&
		yum install -y git yum-plugin-downloadonly zlib-devel"
	;;
'linux-centos-7'*)
	sudo -k
	sudo bash -c "yum groupinstall -y 'Development Tools' &&
		yum install -y git zlib-devel"
	;;
'linux-debian-6'*)
	# NOTE: There is no sudo on Debian 6.

	apt-get update &&
		apt-get install -y build-essential git pigz zlib1g-dev
	echo 'export BASHMENOT_CURL_RETRIES=0' >>"${HOME}/.bash_profile"
	;;
'linux-debian-7'*)
	sudo -k
	sudo bash -c "apt-get update &&
		apt-get install -y build-essential git pigz zlib1g-dev"
	;;
'linux-fedora-19'*)
	sudo -k
	sudo bash -c "yum groupinstall -y 'Development Tools' &&
		yum install -y git pigz zlib-devel"
	;;
'linux-fedora-2'[01]*)
	sudo -k
	sudo bash -c "yum groupinstall -y 'Development Tools' &&
		yum install -y git patch pigz tar zlib-devel &&
		systemctl disable firewalld &&
		systemctl stop firewalld"
	;;
'linux-ubuntu-10'*)
	sudo -k
	sudo bash -c "apt-get update &&
		apt-get install -y build-essential git-core pigz zlib1g-dev &&
		apt-get install -y --reinstall ca-certificates"
	;;
'linux-ubuntu-12'*)
	sudo -k
	sudo bash -c "apt-get update &&
		apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev"
	;;
'linux-ubuntu-14'*)
	sudo -k
	sudo bash -c "apt-get update &&
		apt-get install -y build-essential git pigz zlib1g-dev"
	;;
*)
	echo '	 *** ERROR: Unexpected platform' >&2
	exit 1
esac

git clone 'https://github.com/mietek/halcyon' "${HOME}/halcyon"

echo 'source <( "${HOME}/halcyon/halcyon" paths )' >>"${HOME}/.bash_profile"
source <( "${HOME}/halcyon/halcyon" paths )
