#!/bin/sh -eu


if [ "${#}" -ne "2" ]; then
	echo "Usage: ${0} <flavor> <type>"
	echo
	echo "Example: ${0} base debian"
	echo "Example: ${0} mods debian"
	echo "Example: ${0} prod debian"
	echo "Example: ${0} work debian"
	echo
	echo "Example: ${0} base alpine"
	echo "Example: ${0} mods alpine"
	echo "Example: ${0} prod alpine"
	echo "Example: ${0} work alpine"
	exit 1
fi

###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
TYPE="${1}"
FLAVOUR="${2}"


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
if [ ! -f "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" ]; then
	echo "Dockerfile not found in: ${CWD}/${TYPE}/Dockerfile.${FLAVOUR}."
	exit 1
fi

# Test Docker name
if ! grep -q 'image=".*"' "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi

# Test Docker vendor
if ! grep -q 'vendor=".*"' "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" > /dev/null 2>&1; then
	echo "No 'vendor' LABEL found"
	exit
fi

# Test Docker tag
if ! grep -q 'tag=".*"' "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" > /dev/null 2>&1; then
	echo "No 'tag' LABEL found"
	exit
fi


###
### Extract Infos
###
NAME="$( grep     'image=".*"'    "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
VEND="$( grep -Eo 'vendor="(.*)"' "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" | awk -F'"' '{print $2}' )"
TAG="$(  grep -Eo 'tag="(.*)"'    "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" | awk -F'"' '{print $2}' )"


###
### Update Base
###
MY_BASE="$( grep 'FROM[[:space:]].*:.*' "${CWD}/${TYPE}/Dockerfile.${FLAVOUR}" | sed 's/FROM\s*//g' )"
if echo "${MY_BASE}" | grep -qE '^(debian|alpine)'; then
	run "docker pull ${MY_BASE}"
fi

###
### Build
###

# Build Docker
run "docker build --no-cache -t ${VEND}/${NAME}:${TAG} -f ${TYPE}/Dockerfile.${FLAVOUR} ${CWD}/${TYPE}/"


###
### Retrieve information afterwards and Update README.md
###
docker run -d --rm --name my_tmp_${NAME} -t ${VEND}/${NAME}:${TAG}
PHP_MODULES="$( docker exec my_tmp_${NAME} php -m )"
docker stop "$( docker ps | grep "my_tmp_${NAME}" | awk '{print $1}')" > /dev/null

PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/\[PHP Modules\]//g' )"  # Remove PHP Modules headlines
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/\[Zend Modules\]//g' )" # Remove Zend Modules headline
PHP_MODULES="$( echo "${PHP_MODULES}" | sort -fu )"                    # Unique
PHP_MODULES="$( echo "${PHP_MODULES}" | sed '/^\s*$/d' )"              # Remove empty lines
PHP_MODULES="$( echo "${PHP_MODULES}" | tr '\n' ',' )"                 # Newlines to commas
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,$//g' )"               # Remove trailing comma
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,/, /g' )"              # Add space to comma

echo "${PHP_MODULES}"

run "sed -i'' 's|<td id=\"mod-${TYPE}-${FLAVOUR}\">.*<\/td>|<td id=\"mod-${TYPE}-${FLAVOUR}\">${PHP_MODULES}<\/td>|g' ${CWD}/README.md"
