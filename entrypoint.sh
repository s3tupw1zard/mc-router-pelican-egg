#!/bin/bash
set -euo pipefail

cd /home/container

export TZ="${TZ:-UTC}"

if [[ -z "${STARTUP:-}" ]]; then
    STARTUP='PORT={{SERVER_PORT}} /usr/local/bin/mc-router'
fi

PARSED_STARTUP="$(printf '%s' "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')"

printf '\033[1m\033[33mcontainer~ \033[0m%s\n' "${PARSED_STARTUP}"

# Pelican startup commands intentionally support environment variable expansion.
# shellcheck disable=SC2086
eval "exec ${PARSED_STARTUP}"
