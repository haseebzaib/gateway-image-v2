#!/bin/bash
set -euo pipefail

BASE_DIR="/opt/metacrust"
PERSISTENT_DIR="/persistent/metacrust"

install -d -m 0755 "${BASE_DIR}" "${BASE_DIR}/scripts" "${BASE_DIR}/gateway_core" "${BASE_DIR}/gateway_hub"
install -d -m 0755 "${PERSISTENT_DIR}"
install -d -m 0700 "${PERSISTENT_DIR}/secrets"

ln -sfn "${PERSISTENT_DIR}/secrets" "${BASE_DIR}/secrets"
