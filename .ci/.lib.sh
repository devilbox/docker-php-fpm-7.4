#!/usr/bin/env bash

set -e
set -u
set -o pipefail


###
### Run
###
function run() {
	local cmd="${1}"

	local red="\033[0;31m"
	local green="\033[0;32m"
	local yellow="\033[0;33m"
	local reset="\033[0m"

	printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)"
	sh -c "LANG=C LC_ALL=C ${cmd}"
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
docker_build() {
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

	run "docker build --no-cache=true -t ${vend}/${name}:${tag} -f ${dockerfile} ${buildpath}/"
}