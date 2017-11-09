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



############################################################
# Tests
############################################################

###
### 04. TIMEZONE
###
if [ "${TYPE}" = "prod" ] || [ "${TYPE}" = "work" ]; then

	did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e TIMEZONE=Europe/Berlin" )"
	if ! run "docker logs ${did} 2>&1 | grep -q 'Europe/Berlin'"; then
		docker_logs "${did}"
		false
	fi
	if ! docker_exec "${did}" "date | grep -E 'CE(S)*T'"; then
		docker_exec "${did}" "date"
		false
	fi
	if ! docker_exec "${did}" "php -i | grep -E 'date\.timezone' | grep 'Europe/Berlin'"; then
		docker_exec "${did}" "php -i"
		false
	fi
	docker_stop "${did}"

fi
