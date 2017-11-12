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
### 08. MYSQL_
###
if [ "${TYPE}" = "work" ]; then

	MYSQL_ROOT_PASSWORD="toor"
	CONT_NAME_MYSQL=mysql


	###
	### 01. Uid/Gid same as host
	###

	# MySQL Backup directory
	MOUNTPOINT="$( mktemp --directory )"

	mdid="$( run "docker run --name ${CONT_NAME_MYSQL} -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} -d mysql:5.6" "1" )"

	did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e NEW_UID=$(id -u) -e NEW_GID=$(id -g) -e FORWARD_PORTS_TO_LOCALHOST=3306:${CONT_NAME_MYSQL}:3306 -e MYSQL_BACKUP_USER=root -e MYSQL_BACKUP_PASS=${MYSQL_ROOT_PASSWORD} -e MYSQL_BACKUP_HOST=127.0.0.1 -v ${MOUNTPOINT}:/shared/backups --link ${CONT_NAME_MYSQL}" )"

	# Give mysql container some time for intialization
	run "sleep 10"

	if [ ! -d "${MOUNTPOINT}/mysql" ]; then
		echo "MySQL backup dir does not exist: ${MOUNTPOINT}/mysql"
		ls -lap ${MOUNTPOINT}/
		false
	fi

	if ! docker_exec "${did}" "mysqldump-secure"; then
		run "docker logs ${did}"
		run "docker logs ${mdid}"
		false
	fi

	run "ls -lap ${MOUNTPOINT}/mysql/ | grep -E 'mysql\.sql\.gz'"
	run "ls -lap ${MOUNTPOINT}/mysql/ | grep -E 'mysql\.sql\.gz\.info'"

	docker_stop "${did}"
	docker_stop "${mdid}"
	run "rm -rf ${MOUNTPOINT}" || true



	###
	### 02. Uid/Gid different from host
	###

	# MySQL Backup directory
	MOUNTPOINT="$( mktemp --directory )"

	mdid="$( run "docker run --name ${CONT_NAME_MYSQL} -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} -d mysql:5.6" "1" )"

	did="$( docker_run "${IMAGE}:${TYPE}-${FLAVOUR}" "-e DEBUG_ENTRYPOINT=2 -e NEW_UID=1007 -e NEW_GID=1007 -e FORWARD_PORTS_TO_LOCALHOST=3306:${CONT_NAME_MYSQL}:3306 -e MYSQL_BACKUP_USER=root -e MYSQL_BACKUP_PASS=${MYSQL_ROOT_PASSWORD} -e MYSQL_BACKUP_HOST=127.0.0.1 -v ${MOUNTPOINT}:/shared/backups --link ${CONT_NAME_MYSQL}" )"

	# Give mysql container some time for intialization
	run "sleep 10"

	if [ ! -d "${MOUNTPOINT}/mysql" ]; then
		echo "MySQL backup dir does not exist: ${MOUNTPOINT}/mysql"
		ls -lap ${MOUNTPOINT}/
		false
	fi

	if ! docker_exec "${did}" "mysqldump-secure"; then
		run "docker logs ${did}"
		run "docker logs ${mdid}"
		false
	fi

	run "ls -lap ${MOUNTPOINT}/mysql/ | grep -E 'mysql\.sql\.gz'"
	run "ls -lap ${MOUNTPOINT}/mysql/ | grep -E 'mysql\.sql\.gz\.info'"

	docker_stop "${did}"
	docker_stop "${mdid}"
	run "rm -rf ${MOUNTPOINT}" || true


fi
