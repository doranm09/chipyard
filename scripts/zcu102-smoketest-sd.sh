#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Build and flash the ZCU102 hello-world SD payload used by sdboot.

Usage:
  scripts/zcu102-smoketest-sd.sh --target /dev/sdX [--seek-sectors 34] [--write]
  scripts/zcu102-smoketest-sd.sh --target /dev/sdX1 --seek-sectors 0 [--write]

Options:
  --target PATH         Block device path to write (required).
  --seek-sectors N      Sector offset for dd (default: 34).
  --write               Perform the write. Without this flag, only print plan.
  --no-build            Skip rebuilding hello.bin.
  -h, --help            Show this help.

Notes:
  - sdboot copies from sector 34 by default (BBL_PARTITION_START_SECTOR).
  - sdboot expects an 8 KiB payload (PAYLOAD_SIZE_B in sdboot/sd.c).
EOF
}

TARGET=""
SEEK_SECTORS=34
DO_WRITE=0
DO_BUILD=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --seek-sectors)
      SEEK_SECTORS="${2:-}"
      shift 2
      ;;
    --write)
      DO_WRITE=1
      shift
      ;;
    --no-build)
      DO_BUILD=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  echo "--target is required." >&2
  usage
  exit 1
fi

if [[ ! "${SEEK_SECTORS}" =~ ^[0-9]+$ ]]; then
  echo "--seek-sectors must be a non-negative integer." >&2
  exit 1
fi

CY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELLO_DIR="${CY_DIR}/fpga/src/main/resources/zcu102/tests"
HELLO_BIN="${HELLO_DIR}/build/hello.bin"
PAYLOAD_MAX_BYTES=8192

if [[ "${DO_BUILD}" -eq 1 ]]; then
  if ! command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    if [[ -f "${CY_DIR}/env.sh" ]]; then
      # shellcheck disable=SC1091
      source "${CY_DIR}/env.sh"
    fi
  fi
  if ! command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    echo "riscv64-unknown-elf-gcc not found. Source env.sh first." >&2
    exit 1
  fi

  make -C "${HELLO_DIR}" clean bin
fi

if [[ ! -f "${HELLO_BIN}" ]]; then
  echo "Missing payload binary: ${HELLO_BIN}" >&2
  exit 1
fi

BIN_SIZE="$(stat -c %s "${HELLO_BIN}")"
if (( BIN_SIZE > PAYLOAD_MAX_BYTES )); then
  echo "Payload is ${BIN_SIZE} bytes, but sdboot expects <= ${PAYLOAD_MAX_BYTES} bytes." >&2
  echo "Adjust payload size or update PAYLOAD_SIZE_B in fpga/src/main/resources/zcu102/sdboot/sd.c." >&2
  exit 1
fi

echo "Payload: ${HELLO_BIN}"
echo "Payload size: ${BIN_SIZE} bytes"
echo "Target: ${TARGET}"
echo "dd seek (sectors): ${SEEK_SECTORS}"
echo
echo "Command:"
echo "  sudo dd if=\"${HELLO_BIN}\" of=\"${TARGET}\" bs=512 seek=${SEEK_SECTORS} conv=fsync,notrunc status=progress"

if [[ "${DO_WRITE}" -eq 0 ]]; then
  echo
  echo "Dry run only. Re-run with --write to flash."
  exit 0
fi

if [[ ! -b "${TARGET}" ]]; then
  echo "Target is not a block device: ${TARGET}" >&2
  exit 1
fi

if command -v lsblk >/dev/null 2>&1; then
  echo
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT "${TARGET}" || true
fi

echo
echo "WARNING: This will overwrite data on ${TARGET}."
read -r -p "Type YES to continue: " CONFIRM
if [[ "${CONFIRM}" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

sudo dd if="${HELLO_BIN}" of="${TARGET}" bs=512 seek="${SEEK_SECTORS}" conv=fsync,notrunc status=progress
sync

echo
echo "Flash complete."
echo "Expected UART output after boot includes:"
echo "  INIT"
echo "  LOADING ..."
echo "  BOOT"
echo "  Hello from payload at 0x80000000!"
