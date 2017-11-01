#!/bin/sh

set -e
set -u


###
### Variables
###
DEBUG_COMMANDS=1

MY_USER="devilbox"
MY_GROUP="devilbox"


###
### Source libs
###
init="$( find /docker-entrypoint.d -name '*.sh' -type f | sort -u )"
for f in ${init}; do
	# shellcheck disable=SC1090
	. "${f}"
done



#############################################################
## Sanity checks
#############################################################

if ! command -v socat >/dev/null 2>&1; then
	log "err" "socat not found, but required."
	exit 1
fi



#############################################################
## Entry Point
#############################################################

###
### Change uid/gid
###
change_uid "NEW_UID" "${MY_USER}" "${DEBUG_COMMANDS}"
change_gid "NEW_GID" "${MY_GROUP}" "${DEBUG_COMMANDS}"

###
### Set timezone
###
set_timezone "TIMEZONE" "${DEBUG_COMMANDS}"

###
### Setup postfix
###
set_postfix "ENABLE_MAIL" "${MY_USER}" "${MY_GROUP}" "${DEBUG_COMMANDS}"


###
### Validate socat port forwards
###
if ! port_forward_validate "FORWARD_PORTS_TO_LOCALHOST"; then
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

supervisor_add_service "rsyslogd" "/usr/sbin/rsyslogd -n" "1"
supervisor_add_service "postfix"  "/usr/local/sbin/postfix.sh"
supervisor_add_service "php-fpm"  "/usr/local/sbin/php-fpm"


###
### Start
###
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
