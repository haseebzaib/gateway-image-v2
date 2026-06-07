#!/bin/bash
set -euo pipefail

: "${TS_HOSTNAME_PREFIX:=metacrust}"
: "${TS_FUNNEL_ENABLE:=false}"
: "${TS_FUNNEL_PORT:=8000}"
: "${TS_ROUTE_WAIT_SECONDS:=120}"

log() {
  logger -t metacrust-tailscale "$*" || true
  printf '%s\n' "$*"
}

hostname_from_mac() {
  local iface mac clean
  for iface in eth0 eth1 wlan0; do
    if [ -r "/sys/class/net/${iface}/address" ]; then
      mac="$(cat "/sys/class/net/${iface}/address")"
      clean="${mac//:/}"
      clean="${clean,,}"
      if [ "${#clean}" = 12 ] && [ "${clean}" != "000000000000" ]; then
        printf '%s-%s\n' "${TS_HOSTNAME_PREFIX}" "${clean}"
        return 0
      fi
    fi
  done
  printf '%s-unknown\n' "${TS_HOSTNAME_PREFIX}"
}

wait_for_route() {
  local waited=0
  while [ "${waited}" -lt "${TS_ROUTE_WAIT_SECONDS}" ]; do
    if ip route get 1.1.1.1 >/dev/null 2>&1 || ip -6 route get 2606:4700:4700::1111 >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

command -v tailscale >/dev/null 2>&1 || {
  log "tailscale command missing"
  exit 1
}

systemctl start tailscaled.service

if ! wait_for_route; then
  log "no default route yet; leaving tailscale bootstrap for retry"
  exit 1
fi

if ! tailscale status >/dev/null 2>&1; then
  if [ -z "${TS_AUTHKEY:-}" ]; then
    log "TS_AUTHKEY empty; tailscaled running but device is not authenticated"
    exit 0
  fi
  tailscale up --auth-key="${TS_AUTHKEY}" --hostname="${TS_HOSTNAME:-$(hostname_from_mac)}"
fi

if [ "${TS_FUNNEL_ENABLE}" = "true" ]; then
  tailscale funnel --bg "${TS_FUNNEL_PORT}"
fi

log "tailscale ready"
