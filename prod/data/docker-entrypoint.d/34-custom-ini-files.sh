#!/bin/sh

set -e
set -u


############################################################
# Functions
############################################################

###
### Copy *.ini files from source to destination with prefix
###
copy_ini_files() {
	_src="${1}"
	_dst="${2}"
	_debug="${3}"

	if [ ! -d "${_src}" ]; then
		run "mkdir -p ${_src}" "${_debug}"
	fi
	_files="$( find "${_src}" -type f -iname '*.ini' )"

	# loop over them line by line
	IFS='
	'
	for _f in ${_files}; do
		_name="$( basename "${_f}" )"
		log "info" "PHP.ini: ${_name} -> ${_dst}/devilbox-${_name}" "${_debug}"
		run "cp ${_f} ${_dst}/devilbox-${_name}" "${_debug}"
	done
	run "find ${_dst} -type f -iname '*.ini' -exec chmod 0644 \"{}\" \;" "${_debug}"
}


############################################################
# Sanity Checks
############################################################

if ! command -v find >/dev/null 2>&1; then
	echo "find not found, but required."
	exit 1
fi
if ! command -v basename >/dev/null 2>&1; then
	echo "basename not found, but required."
	exit 1
fi
