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
### 05. DOCKER_LOGS
###
if [ "${TYPE}" = "prod" ] || [ "${TYPE}" = "work" ]; then

	MOUNTPOINT="$( mktemp --directory )"

	did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e NEW_UID=$(id -u) -e NEW_GID=$(id -g) -e DOCKER_LOGS=0 -v ${MOUNTPOINT}:/var/log/php" )"

	run "sleep 10"

	if [ ! -f "${MOUNTPOINT}/php-fpm.access" ]; then
		echo "Access log does not exist: ${MOUNTPOINT}/php-fpm.access"
		ls -lap ${MOUNTPOINT}/
		false
	fi
	if [ ! -r "${MOUNTPOINT}/php-fpm.access" ]; then
		echo "Access log is not readable"
		ls -lap ${MOUNTPOINT}/
		false
	fi

	if [ ! -f "${MOUNTPOINT}/php-fpm.error" ]; then
		echo "Error log does not exist: ${MOUNTPOINT}/php-fpm.error"
		ls -lap ${MOUNTPOINT}/
		false
	fi
	if [ ! -r "${MOUNTPOINT}/php-fpm.error" ]; then
		echo "Error log is not readable"
		ls -lap ${MOUNTPOINT}/
		false
	fi

	run "ls -lap ${MOUNTPOINT}/"
	run "cat ${MOUNTPOINT}/*"

	docker_stop "${did}"
	run "rm -rf ${MOUNTPOINT}" || true

fi
