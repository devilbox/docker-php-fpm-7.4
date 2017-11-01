#!/bin/sh

set -e
set -u


############################################################
# Functions
############################################################

###
### Log to stdout/stderr
###
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


###
### Wrapper for run command
###
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		_debug="${2}"
	fi

	if [ "${_debug}" -gt "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	/bin/sh -c "LANG=C LC_ALL=C ${_cmd}"
}


###
### Is argument an integer?
###
isint() {
	echo "${1}" | grep -Eq '^([0-9]|[1-9][0-9]*)$'
}


###
### Is env variable set?
###
env_set() {
	_varname="${1}"

	if set | grep "^${_varname}=" >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}


###
### Get env variable by name
###
env_get() {
	_varname="${1}"

	if ! env_set "${1}"; then
		return 1
	fi

	_val="$( set | grep "^${_varname}=" | awk -F '=' '{for (i=2; i<NF; i++) printf $i "="; print $NF}' )"

	# Remove surrounding quotes
	_val="$( echo "${_val}" | sed "s/^'//g" )"
	_val="$( echo "${_val}" | sed 's/^"//g' )"

	_val="$( echo "${_val}" | sed "s/'$//g" )"
	_val="$( echo "${_val}" | sed 's/"$//g' )"

	echo "${_val}"
}



############################################################
# Sanity Checks
############################################################

if ! command -v grep >/dev/null 2>&1; then
	log "err" "grep not found, but required."
	exit 1
fi
if ! command -v sed >/dev/null 2>&1; then
	log "err" "sed not found, but required."
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
