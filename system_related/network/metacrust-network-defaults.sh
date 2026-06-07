#!/bin/bash
set -euo pipefail

systemctl start systemd-networkd.service systemd-resolved.service || true
systemctl start ModemManager.service || true

for iface in eth0 eth1 wlan0 wwan0; do
  if ip link show "${iface}" >/dev/null 2>&1; then
    ip link set dev "${iface}" up || true
  fi
done
