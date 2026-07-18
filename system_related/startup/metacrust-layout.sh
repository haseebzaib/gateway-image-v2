#!/bin/bash
set -euo pipefail

BASE_DIR="/opt/metacrust"
PERSISTENT_DIR="/persistent/metacrust"

install -d -m 0755 "${BASE_DIR}" "${BASE_DIR}/scripts" "${BASE_DIR}/gateway_core" "${BASE_DIR}/gateway_hub"
install -d -m 0755 "${PERSISTENT_DIR}"
install -d -m 0700 "${PERSISTENT_DIR}/secrets"
install -d -m 0700 "${PERSISTENT_DIR}/data" "${PERSISTENT_DIR}/data/edge_server"
install -d -m 0755 "${PERSISTENT_DIR}/config" "${PERSISTENT_DIR}/log" "${PERSISTENT_DIR}/state"

ln -sfn "${PERSISTENT_DIR}/secrets" "${BASE_DIR}/secrets"
ln -sfn "${PERSISTENT_DIR}/data" "${BASE_DIR}/data"
ln -sfn "${PERSISTENT_DIR}/config" "${BASE_DIR}/config"
ln -sfn "${PERSISTENT_DIR}/log" "${BASE_DIR}/log"
ln -sfn "${PERSISTENT_DIR}/state" "${BASE_DIR}/state"

hub_env="${PERSISTENT_DIR}/secrets/gateway-hub.env"
if [ ! -f "${hub_env}" ]; then
  umask 077
  key="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
  printf 'METACRUST_EDGE_DB_KEY=%s\n' "${key}" > "${hub_env}"
fi
chmod 0600 "${hub_env}"
