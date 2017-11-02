#!/bin/sh

set -e
set -u



############################################################
# Functions
############################################################

###
### Setup Postfix for catch-all
###
set_postfix() {
	_env_mail_varname="${1}"
	_dvl_user="${2}"
	_dvl_group="${3}"
	_debug="${4}"

	if ! env_set "${_env_mail_varname}"; then
		log "info" "\$${_env_mail_varname} not set." "${_debug}"
		log "info" "Disabling sending of emails" "${_debug}"
	else
		_mail="$( env_get "${_env_mail_varname}" )"
		if [ "${_mail}" = "1" ]; then
			log "info" "Enabling sending of emails" "${_debug}"

			# Add Mail file if it does not exist
			if [ ! -f "/var/mail/${_dvl_user}" ]; then
				run "touch /var/mail/${_dvl_user}" "${_debug}"
			fi

			# Fix mail user permissions after mount
			run "chmod 0644 /var/mail/${_dvl_user}" "${_debug}"
			run "chown ${_dvl_user}:${_dvl_group} /var/mail/${_dvl_user}" "${_debug}"

			# Postfix configuration
			run "postconf -e 'inet_protocols=ipv4'" "${_debug}"
			run "postconf -e 'virtual_alias_maps=pcre:/etc/postfix/virtual'" "${_debug}"
			run "echo '/.*@.*/ ${_dvl_user}' >> /etc/postfix/virtual" "${_debug}"

			run "newaliases" "${_debug}"

		elif [ "${_mail}" = "0" ]; then
			log "info" "Disabling sending of emails." "${_debug}"

		else
			log "err" "Invalid value for \$${_env_mail_varname}" "${_debug}"
			log "err" "Only 1 (for on) or 0 (for off) are allowed" "${_debug}"
			exit 1
		fi
	fi
}


############################################################
# Sanity Checks
############################################################

if ! command -v postconf >/dev/null 2>&1; then
	echo "postconf not found, but required."
	exit 1
fi
