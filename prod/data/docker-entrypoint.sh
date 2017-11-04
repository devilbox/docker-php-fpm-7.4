#!/bin/sh

set -e
set -u


###
### Variables
###
MY_USER="devilbox"
MY_GROUP="devilbox"

PHP_INI_PATH="/usr/local/etc/php.ini"
FPM_ERROR_LOG_CFG="/usr/local/etc/php-fpm.conf"
FPM_ACCESS_LOG_CFG="/usr/local/etc/php-fpm.d/zzz-docker.conf"
FPM_LOG_DIR="/var/log/php"


###
### Source libs
###
init="$( find /docker-entrypoint.d -name '*.sh' -type f | sort -u )"
for f in ${init}; do
	# shellcheck disable=SC1090
	. "${f}"
done


###
### Set Debug level
###
DEBUG_LEVEL="$( get_debug_level "DEBUG_ENTRYPOINT" "0" )"
log "info" "Debug level: ${DEBUG_LEVEL}" "${DEBUG_LEVEL}"



#############################################################
## Sanity checks
#############################################################

if ! command -v socat >/dev/null 2>&1; then
	log "err" "socat not found, but required." "${DEBUG_LEVEL}"
	exit 1
fi



#############################################################
## Entry Point
#############################################################

###
### Change uid/gid
###
change_uid "NEW_UID" "${MY_USER}" "${DEBUG_LEVEL}"
change_gid "NEW_GID" "${MY_GROUP}" "${DEBUG_LEVEL}"


###
### Set timezone
###
set_timezone "TIMEZONE" "${PHP_INI_PATH}" "${DEBUG_LEVEL}"


###
### Set Logging
###

set_docker_logs \
	"DOCKER_LOGS" \
	"${FPM_LOG_DIR}" \
	"${FPM_ERROR_LOG_CFG}" \
	"${FPM_ACCESS_LOG_CFG}" \
	"${MY_USER}" \
	"${MY_GROUP}" \
	"${DEBUG_LEVEL}"


###
### Setup postfix
###
set_postfix "ENABLE_MAIL" "${MY_USER}" "${MY_GROUP}" "${DEBUG_LEVEL}"


###
### Validate socat port forwards
###
if ! port_forward_validate "FORWARD_PORTS_TO_LOCALHOST" "${DEBUG_LEVEL}"; then
	exit 1
fi


###
### Supervisor services
###
for line in $( port_forward_get_lines "FORWARD_PORTS_TO_LOCALHOST" ); do
	lport="$( port_forward_get_lport "${line}" )"
	rhost="$( port_forward_get_rhost "${line}" )"
	rport="$( port_forward_get_rport "${line}" )"
	supervisor_add_service "socat-${lport}-${rhost}-${rport}" "/usr/bin/socat tcp-listen:${lport},reuseaddr,fork tcp:${rhost}:${rport}"
done

if [ "$(env_get "ENABLE_MAIL")" = "1" ]; then
	supervisor_add_service "rsyslogd" "/usr/sbin/rsyslogd -n" "1"
	supervisor_add_service "postfix"  "/usr/local/sbin/postfix.sh"
fi
supervisor_add_service "php-fpm"  "/usr/local/sbin/php-fpm"


###
### Start
###
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf