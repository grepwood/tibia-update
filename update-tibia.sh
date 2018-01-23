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
	return 0
}

function download_tibia {
	local result=0
	printf "Downloading client... "
	if [ "${download_program}" = "curl" ]; then
		curl -L ${cipsoft_tibia_download_url}/${tibia_tarball} > ${tibia_tarball} 2>/dev/null
		result=$?
	else
		if [ "${download_program}" = "wget" ]; then
			wget ${cipsoft_tibia_download_url}/${tibia_tarball} -O ${tibia_tarball}
			result=$?
		else
			echo "not possible"
			echo "Could not find download program. Aborting"
			exit -4
		fi
	fi
	echo "done"
	return $result
}

function patch_tibia {
	local result=0
	printf "Extracting... "
	tar -xf ${tibia_tarball}
	result=$?
	if [ $result -ne 0 ]; then
		echo "unpacking failed with code $result"
		exit $result
	fi
	echo "done"
	local tmpdir=$(tar -tf ${tibia_tarball} | head -n1)
	if [ "$tmpdir" = "" ]; then
		echo "Could not find root directory inside the tarball"
		exit -8
	fi
	pushd ${tmpdir} >/dev/null
		printf "Patching... "
		cp -rfp * ..
		result=$?
		if [ $result -ne 0 ]; then
			echo "failed with code ${result}"
			exit ${result}
		fi
		echo "done"
	popd >/dev/null
	printf "Cleaning up... "
	rm -rf ${tibia_tarball} ${tmpdir}
	result=$?
	if [ ${result} -ne 0 ]; then
		echo "failed with code $result"
		exit $result
	fi
	echo "done"
	return $result
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

function generate_result_token {
	local result=$1
	local system=$(lsb_release -is)
	local kernel=$(uname -s)
	local kernel_version=$(uname -r | sed 's/\-.*$//')
	local wget_present=$(if [ $(command -v wget >/dev/null 2>/dev/null; echo $?) -eq 0 ]; then echo Y; else echo N; fi)
	local curl_present=$(if [ $(command -v curl >/dev/null 2>/dev/null; echo $?) -eq 0 ]; then echo Y; else echo N; fi)
	local tar_family=""
	local tar_version=""
	local return_code=0
	if [ $(tar --version | head -n1 | grep ^tar\ \(GNU | wc -l) -eq 1 ]; then
		tar_family=GNU
		tar_version=$(tar --version | head -n1 | awk '{print $4}')
	fi
	if [ $(tar --version | head -n1 | grep ^bsdtar | wc -l) -eq 1 ]; then
		tar_family=BSD
		tar_version=$(tar --version | head -n1 | awk '{print $2}')
	fi
	if [ "$tar_family" = "" ]; then
		tar_family=UNKNOWN
		tar_version=UNKNOWN
	fi
	if [ ${result} -eq 0 ]; then
		result=Y
	else
		result=N
		return_code=1
	fi
	echo "Here is your result token:"
	printf "${system}\t${kernel}\t${kernel_version}\t${tar_family}\t${tar_version}\t${curl_present}\t${wget_present}\t${result}\n"
	return ${return_code}
}

function main {
	local result=0
	getopts $@
	sanity_check
	result=$(((${result} + $?)))
	download_tibia
	result=$(((${result} + $?)))
	patch_tibia
	result=$(((${result} + $?)))
	generate_result_token ${result}
	echo "Starting Tibia"
	./start-tibia.sh &
}

main $@
