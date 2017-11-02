#!/bin/sh

set -e
set -u


############################################################
# Functions
############################################################

###
### Change UID
###
change_uid() {
	_env_uid_varname="${1}"
	_username="${2}"
	_debug="${3}"

	if ! env_set "${_env_uid_varname}"; then
		log "info" "\$${_env_uid_varname} not set. Keeping default uid for '${_username}'." "${_debug}"
	else
		_uid="$( env_get "${_env_uid_varname}" )"

		if ! isint "${_uid}"; then
			log "err" "\$${_env_uid_varname} is not an integer: '${_uid}'" "${_debug}"
			exit 1
		else
			if _user_line="$( getent passwd "${_uid}" )"; then
				_name="$( echo "${_user_line}" | awk -F ':' '{print $1}' )"
				if [ "${_name}" != "${_username}" ]; then
					log "warn" "User with ${_uid} already exists: ${_name}" "${_debug}"
					log "info" "Changing UID of ${_name} to 9999" "${_debug}"
					run "usermod -u 9999 ${_name}" "${_debug}"
				fi
			fi
			log "info" "Changing user '${_username}' uid to: ${_uid}" "${_debug}"
			run "usermod -u ${_uid} ${_username}" "${_debug}"
		fi
	fi
}


###
### Change GID
###
change_gid() {
	_env_gid_varname="${1}"
	_groupname="${2}"
	_debug="${3}"

	if ! env_set "${_env_gid_varname}"; then
		log "info" "\$${_env_gid_varname} not set. Keeping default gid for '${_groupname}'." "${_debug}"
	else
		# Retrieve the value from env
		_gid="$( env_get "${_env_gid_varname}" )"

		if ! isint "${_gid}"; then
			log "err" "\$${_env_gid_varname} is not an integer: '${_gid}'" "${_debug}"
			exit 1
		else
			if _group_line="$( getent group "${_gid}" )"; then
				_name="$( echo "${_group_line}" | awk -F ':' '{print $1}' )"
				if [ "${_name}" != "${_groupname}" ]; then
					log "warn" "Group with ${_gid} already exists: ${_name}" "${_debug}"
					log "info" "Changing GID of ${_name} to 9999" "${_debug}"
					run "groupmod -g 9999 ${_name}" "${_debug}"
				fi
			fi
			log "info" "Changing group '${_groupname}' gid to: ${_gid}" "${_debug}"
			run "groupmod -g ${_gid} ${_groupname}" "${_debug}"
		fi
	fi
}


############################################################
# Sanity Checks
############################################################

if ! command -v usermod >/dev/null 2>&1; then
	log "err" "usermod not found, but required."
	exit 1
fi
if ! command -v groupmod >/dev/null 2>&1; then
	log "err" "groupmod not found, but required."
	exit 1
fi
