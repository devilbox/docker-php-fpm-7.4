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
### 07. DOCKER_LOGS
###
if [ "${TYPE}" = "prod" ] || [ "${TYPE}" = "work" ]; then

	did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e FORWARD_PORTS_TO_LOCALHOST=3306:mysql:3306" )"
	if ! run "docker logs ${did} 2>&1 | grep 'Forwarding mysql:3306'"; then
		docker_logs "${did}"
	fi
	docker_stop "${did}"

fi
