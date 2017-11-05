#!/bin/sh
#
# Available global variables:
#   + MY_USER
#   + MY_GROUP

set -e
set -u


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
log "info" "Debug level: ${DEBUG_LEVEL}"



#############################################################
## Entry Point
#############################################################

###
### Change uid/gid
###
set_uid "NEW_UID"
set_gid "NEW_GID"


###
### Startup
###
log "info" "Starting $(php-fpm -v 2>&1 | head -1)"
exec /usr/local/sbin/php-fpm
