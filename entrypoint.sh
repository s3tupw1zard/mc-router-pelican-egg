#!/bin/bash
set -euo pipefail

cd /home/container

export TZ="${TZ:-UTC}"

if [[ -z "${STARTUP:-}" ]]; then
    STARTUP='PORT={{SERVER_PORT}} /usr/local/bin/mc-router'
fi

PARSED_STARTUP="$(printf '%s' "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')"

printf '\033[1m\033[33mcontainer~ \033[0m%s\n' "${PARSED_STARTUP}"

# Pelican startup commands can begin with environment assignments such as
# PORT=25565. Prefixing the parsed command with `env` lets those assignments
# be applied before replacing this shell with the actual process.
eval "exec env ${PARSED_STARTUP}"
