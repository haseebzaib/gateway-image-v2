#!/bin/bash
set -Eeuo pipefail

log() {
  logger -t metacrust-grow-rootfs "$*" || true
  printf '%s\n' "$*"
}

bytes_or_zero() {
  "$@" 2>/dev/null || printf '0\n'
}

root_source="$(findmnt -n -o SOURCE --target / 2>/dev/null || true)"
root_dev="$(readlink -f "${root_source}" 2>/dev/null || true)"
root_fs="$(findmnt -n -o FSTYPE --target / 2>/dev/null || true)"

if [ -z "${root_dev}" ] || [ ! -b "${root_dev}" ]; then
  log "skipping: root block device not found"
  exit 0
fi

if [ "${root_fs}" != "ext4" ]; then
  log "skipping: unsupported root filesystem ${root_fs}"
  exit 0
fi

if ! command -v growpart >/dev/null 2>&1; then
  log "skipping: growpart command missing"
  exit 0
fi

parent_name="$(lsblk -no PKNAME "${root_dev}" 2>/dev/null | head -n1 | tr -d '[:space:]')"
part_num="$(lsblk -no PARTN "${root_dev}" 2>/dev/null | head -n1 | tr -d '[:space:]')"

if [ -z "${parent_name}" ] || [ -z "${part_num}" ]; then
  log "skipping: could not identify root disk/partition for ${root_dev}"
  exit 0
fi

disk="/dev/${parent_name}"
before_part="$(bytes_or_zero blockdev --getsize64 "${root_dev}")"
before_fs="$(df -B1 --output=size / 2>/dev/null | awk 'NR == 2 {print $1}')"
before_fs="${before_fs:-0}"

log "expanding ${root_dev} on ${disk} partition ${part_num}"

set +e
grow_output="$(growpart "${disk}" "${part_num}" 2>&1)"
grow_rc=$?
set -e

if [ "${grow_rc}" -ne 0 ] && ! printf '%s\n' "${grow_output}" | grep -qi 'NOCHANGE'; then
  log "growpart failed: ${grow_output}"
  exit 0
fi

log "growpart result: ${grow_output:-ok}"
partprobe "${disk}" >/dev/null 2>&1 || true
partx -u "${disk}" >/dev/null 2>&1 || true
udevadm settle >/dev/null 2>&1 || true

if resize2fs "${root_dev}" >/tmp/metacrust-grow-rootfs-resize2fs.log 2>&1; then
  after_part="$(bytes_or_zero blockdev --getsize64 "${root_dev}")"
  after_fs="$(df -B1 --output=size / 2>/dev/null | awk 'NR == 2 {print $1}')"
  after_fs="${after_fs:-0}"
  log "complete: partition ${before_part}->${after_part} bytes, filesystem ${before_fs}->${after_fs} bytes"
else
  log "resize2fs failed: $(tr '\r\n' '  ' </tmp/metacrust-grow-rootfs-resize2fs.log | cut -c1-300)"
fi
