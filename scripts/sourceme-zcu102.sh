#!/usr/bin/env bash

# Source this file from your shell:
#   source scripts/sourceme-zcu102.sh
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This script must be sourced: source scripts/sourceme-zcu102.sh"
  exit 1
fi

CY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/opt/Xilinx/2025.1/Vivado/settings64.sh}"

source "${CY_DIR}/env.sh"

if [[ ! -f "${VIVADO_SETTINGS}" ]]; then
  echo "Vivado settings script not found: ${VIVADO_SETTINGS}"
  return 1
fi

# shellcheck disable=SC1090
source "${VIVADO_SETTINGS}"

echo "Loaded Chipyard env and Vivado from ${VIVADO_SETTINGS}"
echo "RISCV=${RISCV}"
echo "vivado=$(command -v vivado || echo missing)"
