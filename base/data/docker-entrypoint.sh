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
## Entry Point
#############################################################

change_uid "NEW_UID" "${MY_USER}" "${DEBUG_COMMANDS}"
change_gid "NEW_GID" "${MY_GROUP}" "${DEBUG_COMMANDS}"


###
### Startup
###
log "info" "Starting $(php-fpm -v 2>&1 | head -1)"
exec /usr/local/sbin/php-fpm
