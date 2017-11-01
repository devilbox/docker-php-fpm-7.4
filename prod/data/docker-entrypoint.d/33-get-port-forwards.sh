#!/bin/sh

set -e
set -u



############################################################
# Helper Functions
############################################################

###
### Helper functions
###
isip() {
	# IP is not in correct format
	if ! echo "${1}" | grep -Eq '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$'; then
		return 1
	fi

	# Get each octet
	o1="$( echo "${1}" | awk -F'.' '{print $1}' )"
	o2="$( echo "${1}" | awk -F'.' '{print $2}' )"
	o3="$( echo "${1}" | awk -F'.' '{print $3}' )"
	o4="$( echo "${1}" | awk -F'.' '{print $4}' )"

	# Cannot start with 0 and all must be below 256
	if [ "${o1}" -lt "1" ] || \
		[ "${o1}" -gt "255" ] || \
		[ "${o2}" -gt "255" ] || \
		[ "${o3}" -gt "255" ] || \
		[ "${o4}" -gt "255" ]; then
		return 1
	fi

	# All tests passed
	return 0
}
ishostname() {
	# Does not have correct character class
	if ! echo "${1}" | grep -Eq '^[-.0-9a-zA-Z]+$'; then
		return 1
	fi

	# first and last character
	f_char="$( echo "${1}" | cut -c1-1 )"
	l_char="$( echo "${1}" | sed -e 's/.*\(.\)$/\1/' )"

	# Dot at beginning or end
	if [ "${f_char}" = "." ] || [ "${l_char}" = "." ]; then
		return 1
	fi
	# Dash at beginning or end
	if [ "${f_char}" = "-" ] || [ "${l_char}" = "-" ]; then
		return 1
	fi
	# Multiple dots next to each other
	if echo "${1}" | grep -Eq '[.]{2,}'; then
		return 1
	fi
	# Dash next to dot
	if echo "${1}" | grep -Eq '(\.-)|(-\.)'; then
		return 1
	fi

	# All tests passed
	return 0
}



############################################################
# Functions
############################################################

###
###
###
port_forward_get_lines() {
	_env_varname="${1}"

	if env_set "${_env_varname}"; then
		_env_value="$( env_get "${_env_varname}" )"

		# Transform into newline separated forwards:
		#   local-port:host:remote-port\n
		#   local-port:host:remote-port\n
		_forwards="$( echo "${_env_value}" | sed 's/[[:space:]]*//g' | sed 's/,/\n/g' )"

		# loop over them line by line
		IFS='
		'
		for _forward in ${_forwards}; do
			echo "${_forward}"
		done
	fi
}

port_forward_get_lport() {
	# local-port:host:remote-port\n
	echo "${1}" | awk -F':' '{print $1}'
}
port_forward_get_rhost() {
	# local-port:host:remote-port\n
	echo "${1}" | awk -F':' '{print $2}'
}
port_forward_get_rport() {
	# local-port:host:remote-port\n
	echo "${1}" | awk -F':' '{print $3}'
}



port_forward_validate() {
	_env_varname="${1}"

	if ! env_set "${_env_varname}"; then
		log "info" "\$${_env_varname} not set."
		log "info" "Not ports from other machines will be forwarded to 127.0.0.1 inside this docker"
	else
		_env_value="$( env_get "${_env_varname}" )"

		# Loop over forwards in order to validate them
		for forward in $( port_forward_get_lines "${_env_varname}" ); do
			_lport="$( port_forward_get_lport "${forward}" )"
			_rhost="$( port_forward_get_rhost "${forward}" )"
			_rport="$( port_forward_get_rport "${forward}" )"

			if ! isint "${_lport}"; then
				log "err" "Port forwarding error: local port is not an integer: ${_lport}"
				log "err" "Line: ${forward}"
				exit 1
			fi
			if ! isip "${_rhost}" && ! ishostname "${_rhost}"; then
				log "err" "Port forwarding error: remote host is not a valid IP and not a valid hostname: ${_rhost}"
				log "err" "Line: ${forward}"
				log "err" ""
				exit 1
			fi
			if ! isint "${_rport}"; then
				log "err" "Port forwarding error: remote port is not an integer: ${_rport}"
				log "err" "Line: ${forward}"
				log "err" ""
				exit 1
			fi

			log "info" "Forwarding ${_rhost}:${_rport} to 127.0.0.1:${_lport} inside this docker."
		done
	fi
}
