#!/bin/bash
# Not 'set -e': a single systemctl hiccup must never kill the whole monitor,
# since its entire job is to keep signalling health even when things go wrong.
set -uo pipefail

IOCTL_BIN="${IOCTL_BIN:-/opt/metacrust/scripts/gateway-cm5-ioctl}"
POLL_S="${POLL_S:-1}"
# How long a single restart keeps the fault pattern showing, so a crash that
# happens between two polls (and recovers before the next one) still reads as
# an issue for a while instead of flashing invisibly for under a second.
FAULT_LATCH_S="${FAULT_LATCH_S:-30}"

CORE_UNIT="metacrust-core.service"
HUB_UNIT="metacrust-hub.service"

declare -A last_restarts=()
declare -A fault_until=()
declare -A current_pattern=()
declare -A blink_pid=()

now_s() { date +%s; }

# Echoes one of: off | heartbeat | fault
status_for() {
  local unit="$1" now="$2" active restarts

  if ! systemctl list-unit-files "${unit}" >/dev/null 2>&1; then
    echo off
    return
  fi

  if systemctl is-failed --quiet "${unit}" 2>/dev/null; then
    echo fault
    return
  fi

  active="$(systemctl is-active "${unit}" 2>/dev/null || true)"
  if [ "${active}" != "active" ]; then
    echo off
    return
  fi

  restarts="$(systemctl show -p NRestarts --value "${unit}" 2>/dev/null || echo 0)"
  case "${restarts}" in ''|*[!0-9]*) restarts=0 ;; esac
  if [ -n "${last_restarts[${unit}]:-}" ] && [ "${restarts}" -gt "${last_restarts[${unit}]}" ]; then
    fault_until[${unit}]=$(( now + FAULT_LATCH_S ))
  fi
  last_restarts[${unit}]="${restarts}"

  if [ -n "${fault_until[${unit}]:-}" ] && [ "${now}" -lt "${fault_until[${unit}]}" ]; then
    echo fault
    return
  fi
  echo heartbeat
}

apply_pattern() {
  local led="$1" pattern="$2"
  if [ "${current_pattern[${led}]:-}" = "${pattern}" ]; then
    # Pattern unchanged: normally nothing to do, but if the background blink
    # loop died on its own (e.g. a transient pinctrl error) the LED would
    # otherwise freeze at whatever level it was left in forever, since
    # nothing else would ever re-trigger this branch. Restart it if so.
    if [ "${pattern}" = "off" ] || { [ -n "${blink_pid[${led}]:-}" ] && kill -0 "${blink_pid[${led}]}" 2>/dev/null; }; then
      return
    fi
  fi

  if [ -n "${blink_pid[${led}]:-}" ] && kill -0 "${blink_pid[${led}]}" 2>/dev/null; then
    kill "${blink_pid[${led}]}" 2>/dev/null || true
    wait "${blink_pid[${led}]}" 2>/dev/null || true
  fi

  if [ "${pattern}" = "off" ]; then
    "${IOCTL_BIN}" "${led}" blink off >/dev/null 2>&1 || true
    blink_pid[${led}]=""
  else
    "${IOCTL_BIN}" "${led}" blink "${pattern}" >/dev/null 2>&1 &
    blink_pid[${led}]=$!
  fi
  current_pattern[${led}]="${pattern}"
}

cleanup() {
  for led in user1 user2; do
    if [ -n "${blink_pid[${led}]:-}" ] && kill -0 "${blink_pid[${led}]}" 2>/dev/null; then
      kill "${blink_pid[${led}]}" 2>/dev/null || true
    fi
    "${IOCTL_BIN}" "${led}" off >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT INT TERM

while true; do
  now="$(now_s)"
  apply_pattern user1 "$(status_for "${CORE_UNIT}" "${now}")"
  apply_pattern user2 "$(status_for "${HUB_UNIT}" "${now}")"
  sleep "${POLL_S}"
done
