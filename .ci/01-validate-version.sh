#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
FLAVOUR="${2}"
TYPE="${3}"

# shellcheck disable=SC1090
. "${CWD}/.lib.sh"


###
### Validate PHP version
###
VERSION="$( echo "${IMAGE}" | grep -oE '[.0-9]+' )"

# Correct Image name specified in Dockerfile
run "grep 'image=\"php-fpm-${VERSION}\"' ${CWD}/../${TYPE}/Dockerfile.${FLAVOUR}"

# Correct PHP version build
did="$( run "docker run -d --rm -t ${IMAGE}:${TYPE}-${FLAVOUR}" "1" )"
php="$( docker exec "${did}" php -v | grep -oE 'PHP\s*[.0-9]+' | grep -oE '[.0-9]+' )"
run "echo '${php}' | grep '${VERSION}'"
docker_stop "${did}"
