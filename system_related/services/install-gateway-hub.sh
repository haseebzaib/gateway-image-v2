#!/bin/bash
set -euo pipefail

ROOTFS="${1:?usage: install-gateway-hub.sh ROOTFS}"
SRCROOT="${SRCROOT:?SRCROOT must point at gateway-image-v2}"
HUB_SRC="${SRCROOT}/../../../metacrust_gateway_v2/gateway_hub"

if [ ! -d "${HUB_SRC}" ]; then
  echo "gateway_hub source not found: ${HUB_SRC}" >&2
  exit 1
fi

# No build step: main.py runs directly against the apt/pip packages already
# installed by metacrust-base (fastapi/jinja2/uvicorn/paho-mqtt/sqlcipher3),
# picking up the sibling packages (web_console, gateway_ipc, ...) via
# sys.path[0] since ExecStart runs it with WorkingDirectory=/opt/metacrust/gateway_hub.
install -d -m 0755 "${ROOTFS}/opt/metacrust/gateway_hub"

rsync -a --delete \
  --exclude '.git' \
  --exclude '__pycache__' \
  --exclude '*.egg-info' \
  --exclude '.pytest_cache' \
  --exclude '.venv' \
  --exclude 'build' \
  "${HUB_SRC}/" "${ROOTFS}/opt/metacrust/gateway_hub/"

find "${ROOTFS}/opt/metacrust/gateway_hub" -type d -exec chmod 0755 {} +
find "${ROOTFS}/opt/metacrust/gateway_hub" -type f -exec chmod 0644 {} +
