#!/bin/sh

set -e
set -u


###
### Variables
###
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


###
### Set Debug level
###
DEBUG_LEVEL="$( get_debug_level "DEBUG_ENTRYPOINT" "0" )"
log "info" "Debug level: ${DEBUG_LEVEL}" "${DEBUG_LEVEL}"



#############################################################
## Entry Point
#############################################################

###
### Change uid/gid
###
change_uid "NEW_UID" "${MY_USER}" "${DEBUG_LEVEL}"
change_gid "NEW_GID" "${MY_GROUP}" "${DEBUG_LEVEL}"


###
### Startup
###
log "info" "Starting $(php-fpm -v 2>&1 | head -1)" "${DEBUG_LEVEL}"
exec /usr/local/sbin/php-fpm
