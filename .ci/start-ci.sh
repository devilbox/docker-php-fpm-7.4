#!/usr/bin/env bash

###
### Settings
###

# Be strict
set -e
set -u
set -o pipefail

# Loop over newlines instead of spaces
IFS=$'\n'


###
### Variables
###

# Current directory
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Array of tests to run
declare -a TESTS=()


###
### Source libs
###
# shellcheck disable=SC1090
. "${CWD}/.lib.sh"


###
### Sanity check
###
if [ "${#}" -ne "3" ]; then
	echo "Usage: start.ci <image> <flavour> <type>"
	exit 1
fi


###
### Entry point
###

# Get all [0-9]+.sh test files
FILES="$( find ${CWD} -regex "${CWD}/[0-9].+.*\.sh" | sort -u )"
for f in ${FILES}; do
	TESTS+=("${f}")
done

for i in "${TESTS[@]}"; do
	printf "\n\n\033[0;33m%s\033[0m\n" "################################################################################"
	printf "\033[0;33m%s %s\033[0m\n"  "#" "${i}"
	printf "\033[0;33m%s\033[0m\n\n"   "################################################################################"
	run "${i} ${1} ${2} ${3}"
done
