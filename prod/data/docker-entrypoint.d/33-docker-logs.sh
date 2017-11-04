#!/bin/sh

set -e
set -u


############################################################
# Functions
############################################################

###
### Change UID
###
set_docker_logs() {
	_env_varname="${1}"
	_log_dir="${2}"
	_fpm_error_log_conf="${3}"
	_fpm_access_log_conf="${4}"
	_user="${5}"
	_group="${6}"
	_debug="${7}"

	if ! env_set "${_env_varname}"; then
		log "info" "\$${_env_varname} not set." "${_debug}"
		log "info" "Logging to docker logs stdout and stderr" "${_debug}"
	else
		_docker_logs="$( env_get "${_env_varname}" )"

		if [ "${_docker_logs}" = "0" ]; then
			log "info" "\$${_env_varname} set to 0. Logging to files under: ${_log_dir}" "${_debug}"
			log "info" "Make sure to mount this directory in order to view logs" "${_debug}"

			# Validation
			if [ ! -f "${_fpm_error_log_conf}" ]; then
				log "err" "PHP-FPM Error log config file does not exist in: ${_fpm_error_log_conf}" "${_debug}"
				exit 1
			fi
			if [ ! -f "${_fpm_access_log_conf}" ]; then
				log "err" "PHP-FPM Access log config file does not exist in: ${_fpm_access_log_conf}" "${_debug}"
				exit 1
			fi

			if ! grep -Eq '^error_log.*$' "${_fpm_error_log_conf}"; then
				log "err" "PHP-FPM Error log config file has no error logging directive" "${_debug}"
				exit 1
			fi
			if ! grep -Eq '^access\.log.*$' "${_fpm_access_log_conf}"; then
				log "err" "PHP-FPM Access log config file has no access logging directive" "${_debug}"
				exit 1
			fi

			if [ ! -d "${_log_dir}" ]; then
				run "mkdir -p ${_log_dir}" "${_debug}"
			fi

			run "chown -R ${_user}:${_group} ${_log_dir}" "${_debug}"
			run "sed -i'' 's|^error_log.*$|error_log = ${_log_dir}/php-fpm.error|g' ${_fpm_error_log_conf}" "${_debug}"
			run "sed -i'' 's|^access\.log.*$|access.log = ${_log_dir}/php-fpm.access|g' ${_fpm_access_log_conf}" "${_debug}"

		elif [ "${_docker_logs}" = "1" ]; then
			log "info" "\$${_env_varname} set to 1. Logging to docker logs stdout and stderr." "${_debug}"
		else
			log "err" "Invalid value for \$${_env_varname}. Can only be 0 or 1. Provided: ${_docker_logs}" "${_debug}"
			exit 1
		fi
	fi
}


############################################################
# Sanity Checks
############################################################

if ! command -v sed >/dev/null 2>&1; then
	echo "sed not found, but required."
	exit 1
fi
