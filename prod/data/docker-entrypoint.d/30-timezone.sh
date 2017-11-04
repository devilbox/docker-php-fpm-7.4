#!/bin/sh

set -e
set -u


############################################################
# Functions
############################################################

###
### Change UID
###
set_timezone() {
	_env_varname="${1}"
	_php_ini="${2}"
	_debug="${3}"

	if ! env_set "${_env_varname}"; then
		log "info" "\$${_env_varname} not set." "${_debug}"
		log "info" "Setting PHP: timezone=UTC" "${_debug}"
		run "sed -i'' 's|^[[:space:]]*;*[[:space:]]*date\.timezone[[:space:]]*=.*$|date.timezone = UTF|g' ${_php_ini}" "${_debug}"
	else
		_timezone="$( env_get "${_env_varname}" )"
		if [ -f "/usr/share/zoneinfo/${_timezone}" ]; then
			# Unix Time
			log "info" "Setting container timezone to: ${_timezone}" "${_debug}"
			run "rm /etc/localtime" "${_debug}"
			run "ln -s /usr/share/zoneinfo/${_timezone} /etc/localtime" "${_debug}"

			# PHP Time
			log "info" "Setting PHP: timezone=${_timezone}" "${_debug}"
			run "sed -i'' 's|^[[:space:]]*;*[[:space:]]*date\.timezone[[:space:]]*=.*$|date.timezone = ${_timezone}|g' ${_php_ini}" "${_debug}"
		else
			log "err" "Invalid timezone for \$${_env_varname}." "${_debug}"
			log "err" "\$TIMEZONE: '${_timezone}' does not exist." "${_debug}"
			exit 1
		fi
	fi
	log "info" "Docker date set to: $(date)" "${_debug}"
}


############################################################
# Sanity Checks
############################################################

if ! command -v sed >/dev/null 2>&1; then
	echo "sed not found, but required."
	exit 1
fi
