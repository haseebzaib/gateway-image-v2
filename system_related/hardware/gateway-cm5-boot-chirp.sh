#!/bin/bash
set -euo pipefail

IOCTL_BIN="/opt/metacrust/scripts/gateway-cm5-ioctl"

sleep 1
"${IOCTL_BIN}" buzzer chirp

