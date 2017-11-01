#!/bin/sh

set -e
set -u

PHP_INI_PATH="/usr/local/etc/php.ini"


############################################################
# Functions
############################################################

###
### Change UID
###
set_timezone() {
	_env_tz_varname="${1}"
	_debug=0

	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		_debug="${2}"
	fi

	if ! env_set "${_env_tz_varname}"; then
		log "info" "\$${_env_tz_varname} not set."
		log "info" "Setting PHP: timezone=UTC"
		run "sed -i'' 's|^[[:space:]]*;?[[:space:]]*date\.timezone[[:space:]]*=.*$|date.timezone = UTF|g' ${PHP_INI_PATH}" "${_debug}"
	else
		_timezone="$( env_get "${_env_tz_varname}" )"
		if [ -f "/usr/share/zoneinfo/${_timezone}" ]; then
			# Unix Time
			log "info" "Setting container timezone to: ${_timezone}"
			run "rm /etc/localtime" "${_debug}"
			run "ln -s /usr/share/zoneinfo/${_timezone} /etc/localtime" "${_debug}"

			# PHP Time
			log "info" "Setting PHP: timezone=${_timezone}"
			run "sed -i'' 's|^[[:space:]]*;?[[:space:]]*date\.timezone[[:space:]]*=.*$|date.timezone = ${_timezone}|g' ${PHP_INI_PATH}" "${_debug}"
		else
			log "err" "Invalid timezone for \$${_env_tz_varname}."
			log "err" "\$TIMEZONE: '${_timezone}' does not exist."
			exit 1
		fi
	fi
	log "info" "Docker date set to: $(date)"
}


############################################################
# Sanity Checks
############################################################

if ! command -v sed >/dev/null 2>&1; then
	log "err" "sed not found, but required."
	exit 1
fi
