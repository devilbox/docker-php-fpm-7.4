#!/usr/bin/env bash

set -e
set -u
set -o pipefail


###
### Run
###
function run() {
	local cmd="${1}"
	local to_stderr=0

	# Output to stderr instead?
	if [ "${#}" -eq "2" ]; then
		to_stderr="${2}"
	fi

	local red="\033[0;31m"
	local green="\033[0;32m"
	local yellow="\033[0;33m"
	local reset="\033[0m"

	if [ "${to_stderr}" -eq "0" ]; then
		printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)"
	else
		printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)" >&2
	fi

	if sh -c "LANG=C LC_ALL=C ${cmd}"; then
		if [ "${to_stderr}" -eq "0" ]; then
			printf "${green}[%s]${reset}\n" "OK"
		else
			printf "${green}[%s]${reset}\n" "OK" >&2
		fi
		return 0
	else
		if [ "${to_stderr}" -eq "0" ]; then
			printf "${red}[%s]${reset}\n" "ERROR"
		else
			printf "${red}[%s]${reset}\n" "ERROR" >&2
		fi
		return 1
	fi
}


###
### Get 15 character random word
###
function get_random_name() {
	local chr=(a b c d e f g h i j k l m o p q r s t u v w x y z)
	local len="${#chr[@]}"
	local name=

	for i in {1..15}; do
		rand="$( shuf -i 0-${len} -n 1 )"
		rand=$(( rand - 1 ))
		name="${name}${chr[$rand]}"
		i="${i}" # simply to get rid of shellcheck complaints
	done
	echo "${name}"
}


###
### Docker build
###
function docker_build() {
	local dockerfile="${1}"

	local buildpath=
	local name=
	local vend=
	local tag=
	local base=

	buildpath="$( dirname "${1}" )"
	name="$( grep     'image=".*"'    "${dockerfile}" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
	vend="$( grep -Eo 'vendor="(.*)"' "${dockerfile}" | awk -F'"' '{print $2}' )"
	tag="$(  grep -Eo 'tag="(.*)"'    "${dockerfile}" | awk -F'"' '{print $2}' )"
	base="$( grep 'FROM[[:space:]].*:.*' "${dockerfile}" | sed 's/FROM\s*//g' )"

	if echo "${base}" | grep -qE '^(debian|alpine)'; then
		run "docker pull ${base}"
	fi

	# Try to build a few times in case there a network-timeouts for fetching sources
	max=100
	i=0
	while [ $i -lt $max ]; do
		if run "docker build -t ${vend}/${name}:${tag} -f ${dockerfile} ${buildpath}/"; then
			break;
		else
			i=$((i+1));
		fi
	done
	if [ $i -gt 98 ]; then
		false
	fi
}


###
### Docker run
###
function docker_run() {
	local image_name="${1}"

	shift
	local args="${*}"

	# Returns docker-id
	did="$( run "docker run -d --name $( get_random_name ) ${args} ${image_name}" "1" )"
	sleep 5

	# Just checking if it is up
	docker exec -it ${did} ls >/dev/null 2>&1

	# Only get 8 digits of docker id
	echo "${did}" | grep -Eo '^[0-9a-zA-Z]{8}'
}




###
### Show Docker logs
###
function docker_logs() {
	local docker_id="${1}"

	run "docker logs ${docker_id}"
}

###
### Docker exec
###
function docker_exec() {
	local did="${1}"
	local cmd="${2}"
	shift
	shift
	local args="${*}"

	run "docker exec ${args} -it ${did} ${cmd}"
}


###
### Stop container
###
function docker_stop() {
	local did="${1}"
	local name=
	name="$( docker ps --no-trunc --format='{{.ID}} {{.Names}}' | grep "${did}" | head -1 | awk '{print $2}' )"
	# Stop
	run "docker stop ${did}"
	if docker ps | grep -q "${did}"; then
		run "docker kill ${did}" || true
	fi

	# Remove if still exist
	run "docker rm ${name} >/dev/null 2>&1 || true"
}
