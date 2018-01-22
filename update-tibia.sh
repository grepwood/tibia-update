#!/usr/bin/env bash
function set_global_variables {
	download_program=""
	tibia_tarball="tibia.x64.tar.gz"
	cipsoft_tibia_download_url="http://download.tibia.com"
}

function sanity_check {
	if [ $(command -v curl 1>/dev/null 2>/dev/null; echo $?) -ne 0 ]; then
		printf "Cannot find curl. Trying wget..."
		if [ $(command -v wget 1>/dev/null 2>/dev/null; echo $?) -ne 0 ]; then
			echo "nope. We have no program to download the client with."
			exit -1
		else
			download_program="wget"
		fi
	else
		download_program="curl"
	fi
	if [ $(command -v tar 1>/dev/null 2>/dev/null; echo $?) -ne 0 ]; then
		echo "tar is not installed. Tibia cannot be patched."
		exit -2
	fi
}

function download_tibia {
	printf "Downloading client... "
	if [ "${download_program}" = "curl" ]; then
		curl -L ${cipsoft_tibia_download_url}/${tibia_tarball} > ${tibia_tarball} 2>/dev/null
	else
		if [ "${download_program}" = "wget" ]; then
			wget ${cipsoft_tibia_download_url}/${tibia_tarball} -O ${tibia_tarball}
		else
			echo "not possible"
			echo "Could not find download program. Aborting"
			exit -4
		fi
	fi
	echo "done"
}

function patch_tibia {
	printf "Extracting... "
	tar -xf ${tibia_tarball}
	echo "done"
	local tmpdir=$(tar -tf ${tibia_tarball} | head -n1)
	pushd ${tmpdir} >/dev/null
		printf "Patching... "
		cp -rfp * ..
		echo "done"
	popd >/dev/null
	printf "Cleaning up... "
	rm -rf ${tibia_tarball} ${tmpdir}
	echo "done"
}

function introduce_yourself {
	local VERSION="1.0"
	local NAME="update-tibia.sh"
	local LICENSE="GPLv3"
	local AUTHOR="moog621@gmail.com"
	echo "$NAME $VERSION by $AUTHOR licensed under $LICENSE"
	echo "If you are not okay with this license, we can agree upon releasing a copy for you under a different license."
}

function rtfm {
	introduce_yourself
	echo "Usage: $0 "'[-f|--flags]'
	echo '  -h|--help        displays this message'
	echo '  -v|--verbose     turns on Bash execution trace during normal run'
	exit 0
}

function getopts {
	local array=($@)
	local counter=0
	for((counter=0; counter < ${#array[@]}; counter++)); do
		if [ "${array[$counter]}" = "-h" ] || [ "${array[$counter]}" = "--help" ]; then
			rtfm $@
		fi
		if [ "${array[$counter]}" = "-v" ] || [ "${array[$counter]}" == "--verbose" ]; then
			set -x
		fi
	done
	set_global_variables
}

function main {
	getopts $@
	sanity_check
	download_tibia
	patch_tibia
	echo "Starting Tibia"
	./start-tibia.sh &
}

main $@
