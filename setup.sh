source <( curl -sL https://github.com/mietek/bashmenot/raw/master/src/platform.sh )

case $( detect_platform ) in
'linux-arch'*)
	pacman --sync --noconfirm base-devel git pigz zlib vim
	;;
'linux-centos-6'*)
	yum groupinstall -y 'Development Tools'
	yum install -y git zlib-devel yum-plugin-downloadonly vim
	;;
'linux-centos-7'*)
	yum groupinstall -y 'Development Tools'
	yum install -y git zlib-devel vim
	;;
'linux-debian-6'*)
	apt-get update
	apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev vim
	echo 'export BASHMENOT_CURL_RETRIES=0' >>"${HOME}/.bash_profile"
	;;
'linux-debian-7'*|'linux-ubuntu-14'*)
	apt-get update
	apt-get install -y build-essential git pigz zlib1g-dev vim
	;;
'linux-fedora-19'*)
	yum groupinstall -y 'Development Tools'
	yum install -y git pigz zlib-devel vim
	;;
'linux-fedora-20'*|'linux-fedora-21'*)
	yum groupinstall -y 'Development Tools'
	yum install -y git patch pigz tar zlib-devel vim
	systemctl disable firewalld
	systemctl stop firewalld
	;;
'linux-ubuntu-10'*)
	apt-get update
	apt-get install -y build-essential git-core libgmp3c2 pigz zlib1g-dev vim
	apt-get install -y --reinstall ca-certificates
	;;
'linux-ubuntu-12'*)
	apt-get update
	apt-get install -y build-essential git libgmp3c2 pigz zlib1g-dev vim
	;;
*)
	echo '	 *** ERROR: Unexpected platform' >&2
	exit 1
esac

git clone https://github.com/mietek/halcyon

echo 'source <( halcyon/halcyon paths )' >>"${HOME}/.bash_profile"
source <( halcyon/halcyon paths )
