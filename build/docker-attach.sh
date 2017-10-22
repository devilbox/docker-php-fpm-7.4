#!/bin/sh -eu


###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."


###
### Funcs
###
run() {
	_cmd="${1}"
	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


###
### Checks
###

# Check Dockerfile
if [ ! -f "${CWD}/Dockerfile" ]; then
	echo "Dockerfile not found in: ${CWD}/Dockerfile."
	exit 1
fi

# Test Docker name
if ! grep -q 'image=".*"' "${CWD}/Dockerfile" > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi

# Test Docker vendor
if ! grep -q 'vendor=".*"' "${CWD}/Dockerfile" > /dev/null 2>&1; then
	echo "No 'vendor' LABEL found"
	exit
fi

# Retrieve values
NAME="$( grep 'image=".*"' "${CWD}/Dockerfile" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
VEND="$( grep -Eo 'vendor="(.*)"' "${CWD}/Dockerfile" | awk -F'"' '{print $2}' )"
COUNT="$( docker ps | grep -c "${VEND}/${NAME}" || true)"
if [ "${COUNT}" != "1" ]; then
	echo "${COUNT} '${VEND}/${NAME}' container running. Unable to attach."
	exit 1
fi


###
### Attach
###
DID="$(docker ps | grep "${VEND}/${NAME}" | awk '{print $1}')"

echo "Attaching to: ${VEND}/${NAME}"
run "docker exec -it ${DID} env TERM=xterm /bin/bash -l"
