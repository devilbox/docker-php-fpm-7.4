#!/bin/sh -eu


###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."
FLAVOUR="alpine"
TYPE="base"


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
if [ ! -f "${CWD}/Dockerfile.${FLAVOUR}" ]; then
	echo "Dockerfile not found in: ${CWD}/Dockerfile.${FLAVOUR}."
	exit 1
fi

# Test Docker name
if ! grep -q 'image=".*"' "${CWD}/Dockerfile.${FLAVOUR}" > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi

# Test Docker vendor
if ! grep -q 'vendor=".*"' "${CWD}/Dockerfile.${FLAVOUR}" > /dev/null 2>&1; then
	echo "No 'vendor' LABEL found"
	exit
fi

# Test Docker tag
if ! grep -q 'tag=".*"' "${CWD}/Dockerfile.${FLAVOUR}" > /dev/null 2>&1; then
	echo "No 'tag' LABEL found"
	exit
fi


# Retrieve values
NAME="$( grep     'image=".*"'    "${CWD}/Dockerfile.${FLAVOUR}" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
VEND="$( grep -Eo 'vendor="(.*)"' "${CWD}/Dockerfile.${FLAVOUR}" | awk -F'"' '{print $2}' )"
TAG="$(  grep -Eo 'tag="(.*)"'    "${CWD}/Dockerfile.${FLAVOUR}" | awk -F'"' '{print $2}' )"
DATE="$( date '+%Y-%m-%d' )"


###
### Update Base
###
MY_BASE="$( grep 'FROM[[:space:]].*:.*' "${CWD}/Dockerfile.${FLAVOUR}" | sed 's/FROM\s*//g' )"
run "docker pull ${MY_BASE}"


###
### Build
###

# Update build date
run "sed -i'' 's/build-date=\".*\"/build-date=\"${DATE}\"/g' ${CWD}/Dockerfile.${FLAVOUR}"

# Build Docker
run "docker build -t ${VEND}/${NAME}:${TAG} -f Dockerfile.${FLAVOUR} ${CWD}"


###
### Retrieve information afterwards and Update README.md
###
docker run -d --rm --name my_tmp_${NAME} -t ${VEND}/${NAME}:${TAG}
PHP_MODULES="$( docker exec my_tmp_${NAME} php -m )"
PHP_VERSION="$( docker exec my_tmp_${NAME} php -v | sed 's/\s*$//g' )"
docker stop "$( docker ps | grep "my_tmp_${NAME}" | awk '{print $1}')" > /dev/null

PHP_MODULES="$( echo "${PHP_MODULES}" | sed '/^\s*$/d' )"       # remove empty lines
PHP_MODULES="$( echo "${PHP_MODULES}" | tr '\n' ',' )"          # newlines to commas
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/],/]\n\n/g' )"   # extra line for [foo]
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,\[/\n\n\[/g' )" # extra line for [foo]
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,$//g' )"        # remove trailing comma
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/,/, /g' )"       # Add space to comma
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/]/]**/g' )"      # Markdown bold
PHP_MODULES="$( echo "${PHP_MODULES}" | sed 's/\[/**\[/g' )"    # Markdown bold

echo "${PHP_MODULES}"

sed -i'' '/##[[:space:]]Modules/q' "${CWD}/doc/PHP-FPM-${FLAVOUR}-${TYPE}.md"
(
	echo
	echo "**[Version]**"
	echo
	echo "${PHP_VERSION}"
	echo
	echo "${PHP_MODULES}"
) >> ${CWD}/doc/PHP-FPM-${FLAVOUR}-${TYPE}.md
