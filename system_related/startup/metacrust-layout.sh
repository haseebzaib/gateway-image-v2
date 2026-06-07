#!/bin/bash
set -euo pipefail

BASE_DIR="/opt/metacrust"
PERSISTENT_DIR="/persistent/metacrust"

install -d -m 0755 "${BASE_DIR}" "${BASE_DIR}/bin" "${BASE_DIR}/etc"
install -d -m 0755 "${PERSISTENT_DIR}" "${PERSISTENT_DIR}/state" "${PERSISTENT_DIR}/log"
install -d -m 0700 "${PERSISTENT_DIR}/secrets"

ln -sfn "${PERSISTENT_DIR}/state" "${BASE_DIR}/state"
ln -sfn "${PERSISTENT_DIR}/log" "${BASE_DIR}/log"
ln -sfn "${PERSISTENT_DIR}/secrets" "${BASE_DIR}/secrets"
