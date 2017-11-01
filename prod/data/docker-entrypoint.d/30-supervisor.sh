#!/bin/sh

set -e
set -u


SUPERVISOR_CONF="/etc/supervisor/conf.d"


############################################################
# Functions
############################################################

###
### Add service to supervisord
###
supervisor_add_service() {
	_name="${1}"
	_command="${2}"
	_priority=

	if [ "${#}" -gt "2" ]; then
		_priority="${3}"
	fi

	{
		echo "[program:${_name}]";
		echo "command=${_command}";
		if [ -n "${_priority}" ]; then
			echo "priority=${_priority}";
		fi
		echo "autostart=true";
		echo "autorestart=true";
		echo "stdout_logfile=/dev/stdout";
		echo "stdout_logfile_maxbytes=0";
		echo "stderr_logfile=/dev/stderr";
		echo "stderr_logfile_maxbytes=0";
		echo "stdout_events_enabled=true";
		echo "stderr_events_enabled=true";
	} > "${SUPERVISOR_CONF}/${_name}.conf"

}


############################################################
# Sanity Checks
############################################################

if [ ! -d "${SUPERVISOR_CONF}" ]; then
	log "err" "supervisor config dir does not exist: ${SUPERVISOR_CONF}"
	exit 1
fi
