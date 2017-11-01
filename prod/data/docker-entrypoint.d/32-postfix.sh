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
	_user="${2}"
	_group="${3}"
	_debug=0

	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "4" ]; then
		_debug="${4}"
	fi

	if ! env_set "${_env_mail_varname}"; then
		log "info" "\$${_env_mail_varname} not set."
		log "info" "Disabling sending of emails"
	else
		_mail="$( env_get "${_env_mail_varname}" )"
		if [ "${_mail}" = "1" ]; then
			log "info" "Enabling sending of emails"

			# Add Mail file if it does not exist
			if [ ! -f "/var/mail/${_user}" ]; then
				run "touch /var/mail/${_user}" "${_debug}"
			fi

			# Fix mail user permissions after mount
			run "chmod 0644 /var/mail/${_user}" "${_debug}"
			run "chown ${_user}:${_group} /var/mail/${_user}" "${_debug}"

			# Postfix configuration
			run "postconf -e 'inet_protocols=ipv4'" "${_debug}"
			run "postconf -e 'virtual_alias_maps=pcre:/etc/postfix/virtual'" "${_debug}"
			run "echo '/.*@.*/ ${_user}' >> /etc/postfix/virtual" "${_debug}"

			run "newaliases" "${_debug}"

		elif [ "${_mail}" = "0" ]; then
			log "info" "Disabling sending of emails."

		else
			log "err" "Invalid value for \$${_env_mail_varname}"
			log "err" "Only 1 (for on) or 0 (for off) are allowed"
			exit 1
		fi
	fi
}


############################################################
# Sanity Checks
############################################################

if ! command -v postconf >/dev/null 2>&1; then
	log "err" "postconf not found, but required."
	exit 1
fi
