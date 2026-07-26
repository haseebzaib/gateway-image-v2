#!/bin/bash
set -euo pipefail

ROOTFS="${1:?usage: build-install-gateway-core.sh ROOTFS}"
SRCROOT="${SRCROOT:?SRCROOT must point at gateway-image-v2}"
CORE_SRC="${SRCROOT}/../../../metacrust_gateway_v2/gateway_core"

if [ ! -d "${CORE_SRC}" ]; then
  echo "gateway_core source not found: ${CORE_SRC}" >&2
  exit 1
fi

BUILD_ROOT="${ROOTFS}/tmp/gateway-build/gateway_core"
SRC_COPY="${BUILD_ROOT}/src"

cleanup() {
  rm -rf "${BUILD_ROOT}"
}
trap cleanup EXIT

rm -rf "${BUILD_ROOT}"
install -d -m 0755 "${SRC_COPY}"

rsync -a --delete \
  --exclude '.git' \
  --exclude 'build' \
  --exclude 'cmake-build-*' \
  --exclude '.cache' \
  "${CORE_SRC}/" "${SRC_COPY}/"

find "${BUILD_ROOT}" -type d -exec chmod 0777 {} +

# CMake target is named "apps" (see gateway_core/apps/CMakeLists.txt) even
# though the shipped/service-expected binary name is "gateway-core" — rename
# on install below rather than touching the CMake project.
uchroot "${ROOTFS}" bash <<'EOCHROOT'
set -euo pipefail

cmake \
  -S /tmp/gateway-build/gateway_core/src \
  -B /tmp/gateway-build/gateway_core/build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release

cmake --build /tmp/gateway-build/gateway_core/build --parallel

find /tmp/gateway-build/gateway_core/build -maxdepth 3 -type f -name apps -exec strip {} + || true
EOCHROOT

BIN_PATH="$(find "${BUILD_ROOT}/build" -maxdepth 3 -type f -name apps -perm -u+x | head -n1)"
if [ -z "${BIN_PATH}" ]; then
  echo "gateway_core build did not produce an 'apps' executable under ${BUILD_ROOT}/build" >&2
  exit 1
fi

install -D -m 0755 "${BIN_PATH}" "${ROOTFS}/opt/metacrust/gateway_core/gateway-core"
