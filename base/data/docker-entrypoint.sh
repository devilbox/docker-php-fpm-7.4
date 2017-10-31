#!/bin/sh

set -e
set -u


############################################################
# Default Variables
############################################################

DEBUG_COMMANDS=1

MY_USER="devilbox"
MY_GROUP="devilbox"



############################################################
# Functions
############################################################

run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	/bin/sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}

isint() {
	echo "${1}" | grep -Eq '^([0-9]|[1-9][0-9]*)$'
}



############################################################
# Sanity Checks
############################################################

if ! command -v grep >/dev/null 2>&1; then
	log "err" "grep not found, but required."
	exit 1
fi
if ! command -v awk >/dev/null 2>&1; then
	log "err" "awk not found, but required."
	exit 1
fi
if ! command -v getent >/dev/null 2>&1; then
	log "err" "getent not found, but required."
	exit 1
fi
if ! command -v usermod >/dev/null 2>&1; then
	log "err" "usermod not found, but required."
	exit 1
fi
if ! command -v groupmod >/dev/null 2>&1; then
	log "err" "groupmod not found, but required."
	exit 1
fi



############################################################
# Entry Point
############################################################

###
### Change UID
###
if ! set | grep '^NEW_UID=' >/dev/null 2>&1; then
	log "info" "\$NEW_UID not set. Keeping default uid of '${MY_USER}'."
else
	if ! isint "${NEW_UID}"; then
		log "err" "\$NEW_UID is not an integer: '${NEW_UID}'"
		exit 1
	else
		if _user_line="$( getent passwd "${NEW_UID}" )"; then
			_user_name="$( echo "${_user_line}" | awk -F ':' '{print $1}' )"
			if [ "${_user_name}" != "${MY_USER}" ]; then
				log "warn" "User with ${NEW_UID} already exists: ${_user_name}"
				log "info" "Changing UID of ${_user_name} to 9999"
				run "usermod -u 9999 ${_user_name}"
			fi
		fi
		log "info" "Changing user '${MY_USER}' uid to: ${NEW_UID}"
		run "usermod -u ${NEW_UID} ${MY_USER}"
	fi
fi


###
### Change GID
###
if ! set | grep '^NEW_GID=' >/dev/null 2>&1; then
	log "info" "\$NEW_GID not set. Keeping default uid of '${MY_GROUP}'."
else
	if ! isint "${NEW_GID}"; then
		log "err" "\$NEW_GID is not an integer: '${NEW_GID}'"
		exit 1
	else
		if _group_line="$( getent group "${NEW_GID}" )"; then
			_group_name="$( echo "${_group_line}" | awk -F':' '{print $1}' )"
			if [ "${_group_name}" != "${MY_GROUP}" ]; then
				log "warn" "Group with ${NEW_GID} already exists: ${_group_name}"
				log "info" "Changing GID of ${_group_name} to 9999"
				run "groupmod -g 9999 ${_group_name}"
			fi
		fi

		log "info" "Changing group '${MY_GROUP}' gid to: ${NEW_GID}"
		run "groupmod -g ${NEW_GID} ${MY_GROUP}"
	fi
fi


###
### Startup
###
log "info" "Starting $(php-fpm -v 2>&1 | head -1)"
exec /usr/local/sbin/php-fpm
