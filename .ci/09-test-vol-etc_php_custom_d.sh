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
### 09. Test /etc/php-custom.d *.ini overwrite
###
if [ "${TYPE}" = "prod" ] || [ "${TYPE}" = "work" ]; then

	###
	### 01 Preparation
	###

	# Volume mounts
	DIR_INI="$( mktemp --directory )"
	DIR_WWW="$( mktemp --directory )"

	DOCROOT="/var/www/default/htdocs"

	# HTTPD Docker image name
	HTTPD_IMAGE="devilbox/nginx-stable"

	# Custom PHP config
	echo "post_max_size = 17M" > "${DIR_INI}/post.ini"

	# index.php
	echo "<?php echo 'hello world';" > "${DIR_WWW}/index.php"
	# phpinfo.php
	echo "<?php phpinfo();" > "${DIR_WWW}/phpinfo.php"


	# Start PHP-FPM container
	p_id="$( run "docker run -d --name php -e DEBUG_ENTRYPOINT=2 -e NEW_UID=$(id -u) -e NEW_GID=$(id -g) -v ${DIR_INI}:/etc/php-custom.d -v ${DIR_WWW}:${DOCROOT} -t ${IMAGE}:${TYPE}-${FLAVOUR}" "1" )"

	# Start HTTPD container
	h_id="$( run "docker run -d --name httpd -e DEBUG_ENTRYPOINT=2 -e DEBUG_RUNTIME=1 -e NEW_UID=$(id -u) -e NEW_GID=$(id -g) -e PHP_FPM_ENABLE=1 -e PHP_FPM_SERVER_ADDR=php -e PHP_FPM_SERVER_PORT=9000 -v ${DIR_WWW}:${DOCROOT} -p 80:80 --link php -t ${HTTPD_IMAGE}" "1" )"

	# Wait for containers to come up
	run "sleep 10"
	run "docker logs ${p_id}"
	run "docker logs ${h_id}"


	###
	### 02 Test
	###

	# php.ini was copied
	if ! docker_logs "${p_id}" | grep "post.ini"; then
		docker_logs "${p_id}"
		false
	fi

	# vhost is working
	if ! run "curl -qL localhost/index.php | grep 'hello world'"; then
		run "curl -L localhost/index.php"
		docker_logs "${p_id}"
		docker_logs "${h_id}"
		false
	fi

	# Check default php.ini
	if ! docker_exec "${p_id}" "php -r \"echo ini_get('upload_max_filesize');\" | grep '2M'"; then
		docker_exec "${p_id}" "php -r \"echo ini_get('upload_max_filesize');\""
		docker_logs "${p_id}"
		docker_logs "${h_id}"
		false
	fi
	if ! run "curl -qL localhost/phpinfo.php | grep upload_max_filesize | grep '2M'"; then
		run "curl -L localhost/phpinfo.php | grep upload_max_filesize"
		docker_logs "${p_id}"
		docker_logs "${h_id}"
		false
	fi

	# Check modified php.ini
	if ! docker_exec "${p_id}" "php -r \"echo ini_get('post_max_size');\" | grep '17M'"; then
		docker_exec "${p_id}" "php -r \"echo ini_get('post_max_size');\""
		docker_logs "${p_id}"
		docker_logs "${h_id}"
		false
	fi
	if ! run "curl -qL localhost/phpinfo.php | grep post_max_size | grep '17M'"; then
		run "curl -L localhost/phpinfo.php | grep post_max_size"
		docker_logs "${p_id}"
		docker_logs "${h_id}"
		false
	fi


	###
	### 03 Clean-up
	###

	docker_stop "${h_id}"
	docker_stop "${p_id}"

	run "rm -rf ${DIR_WWW}" || true
	run "rm -rf ${DIR_INI}" || true

fi
