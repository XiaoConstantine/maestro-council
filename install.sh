#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SMUX_BIN="${HOME}/.smux/bin"
SMUX_CONF="${HOME}/.smux/maestro-council.conf"

if ! command -v tmux-bridge >/dev/null 2>&1 && [[ ! -x "${SMUX_BIN}/tmux-bridge" ]]; then
  cat >&2 <<EOF
error: smux is required before installing council.

Install smux first:
  curl -fsSL https://raw.githubusercontent.com/XiaoConstantine/smux/main/install.sh | bash

Then rerun:
  ./install.sh
EOF
  exit 1
fi

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

if [[ ":${PATH}:" != *":${SMUX_BIN}:"* ]]; then
  cat <<EOF

Add ${SMUX_BIN} to your shell PATH if it is not already there:
  export PATH="${SMUX_BIN}:\$PATH"
EOF
fi
