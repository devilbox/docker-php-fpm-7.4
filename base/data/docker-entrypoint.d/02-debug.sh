#!/bin/sh

set -e
set -u


############################################################
# Functions
############################################################

###
### Debug level
###
get_debug_level() {
	_env_varname="${1}"
	_default="${2}"

	if ! env_set "${_env_varname}"; then
		echo "${_default}"
	else
		env_get "${_env_varname}"
	fi
}
