#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SMUX_BIN="${HOME}/.smux/bin"
SMUX_CONF="${HOME}/.smux/maestro-council.conf"

mkdir -p "${SMUX_BIN}" "${HOME}/.smux"
ln -sf "${SCRIPT_DIR}/bin/council" "${SMUX_BIN}/council"
ln -sf "${SCRIPT_DIR}/bin/council-round" "${SMUX_BIN}/council-round"
ln -sf "${SCRIPT_DIR}/bin/council" "${SMUX_BIN}/maestro-council"
cp "${SCRIPT_DIR}/tmux/maestro-council.conf" "${SMUX_CONF}"

cat <<EOF
Installed:
  ${SMUX_BIN}/council -> ${SCRIPT_DIR}/bin/council
  ${SMUX_BIN}/council-round -> ${SCRIPT_DIR}/bin/council-round
  ${SMUX_BIN}/maestro-council -> ${SCRIPT_DIR}/bin/council
  ${SMUX_CONF}

Add this line to ~/.smux/tmux.conf or ~/.config/tmux/tmux.conf:
  source-file ~/.smux/maestro-council.conf
EOF
