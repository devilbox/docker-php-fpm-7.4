#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
FLAVOUR="${2}"
TYPE="${3}"

# shellcheck disable=SC1090
. "${CWD}/.lib.sh"


###
### Compare PHP Modules
###

# Extract newly build php modules and
# compare against modules set in README.md
did="$( run "docker run -d --rm -t ${IMAGE}:${TYPE}-${FLAVOUR}" "1" )"
mod="$( docker exec "${did}" php -m )"
docker_stop "${did}"

# Prepare modules to be inserted into README.md
mod="$( echo "${mod}" | sed 's/\[PHP Modules\]//g' )"  # remove empty lines
mod="$( echo "${mod}" | sed 's/\[Zend Modules\]//g' )" # remove empty lines
mod="$( echo "${mod}" | sort -fu )"                    # Unique
mod="$( echo "${mod}" | sed '/^\s*$/d' )"              # remove empty lines
mod="$( echo "${mod}" | tr '\n' ',' )"                 # newlines to commas
mod="$( echo "${mod}" | sed 's/,$//g' )"               # remove trailing comma
mod="$( echo "${mod}" | sed 's/,/, /g' )"              # Add space to comma

# Replace modules into README.md
run "sed -i'' 's|<td id=\"mod-${TYPE}-${FLAVOUR}\">.*<\/td>|<td id=\"mod-${TYPE}-${FLAVOUR}\">${mod}<\/td>|g' ${CWD}/../README.md"

diff="$( run "git status --porcelain" "1" )"
if [ -n "${diff}" ]; then
	run "git --no-pager diff"
	false
fi
