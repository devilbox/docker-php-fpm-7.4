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
### 02. NEW_UID
###
did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e NEW_UID=1005" )"
if ! run "docker logs ${did} 2>&1 | grep -q '1005'"; then
	docker_logs "${did}"
	false
fi
if ! docker_exec "${did}" "id | grep 'uid=1005'" "--user=devilbox"; then
	docker_logs "${did}"
	false
fi
docker_stop "${did}"
