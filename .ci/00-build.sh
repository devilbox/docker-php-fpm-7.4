#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

#IMAGE="${1}"
FLAVOUR="${2}"
TYPE="${3}"

# shellcheck disable=SC1090
. "${CWD}/.lib.sh"


###
### Build container
###
DOCKERFILE="Dockerfile.${FLAVOUR}"
if [ "${TYPE}" = "work" ]; then
	docker_build "${CWD}/../base/${DOCKERFILE}"
	docker_build "${CWD}/../mods/${DOCKERFILE}"
	docker_build "${CWD}/../prod/${DOCKERFILE}"
	docker_build "${CWD}/../work/${DOCKERFILE}"
elif [ "${TYPE}" = "prod" ]; then
	docker_build "${CWD}/../base/${DOCKERFILE}"
	docker_build "${CWD}/../mods/${DOCKERFILE}"
	docker_build "${CWD}/../prod/${DOCKERFILE}"
elif [ "${TYPE}" = "mods" ]; then
	docker_build "${CWD}/../base/${DOCKERFILE}"
	docker_build "${CWD}/../mods/${DOCKERFILE}"
elif [ "${TYPE}" = "base" ]; then
	docker_build "${CWD}/../base/${DOCKERFILE}"
else
	echo "error"
	exit 1
fi
