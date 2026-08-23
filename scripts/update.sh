#!/bin/bash
# update.sh — Reapply Selynt Panel permissions after a DA upgrade.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

[ "$(id -u)" -eq 0 ] || { sly_err "must run as root"; exit 1; }

BIN="$PLUGIN_DIR/bin/core-selynt"

sly_act "Refreshing" "permissions"
find "$PLUGIN_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
find "$PLUGIN_DIR" -type f -exec chmod 755 {} \; 2>/dev/null || true

# plugin.conf: DA rewrites it as 600; force 644 so diradmin can read it.
chmod 644 "$PLUGIN_DIR/plugin.conf" 2>/dev/null || true

if [ -f "$BIN" ]; then
    chown root:root "$BIN"
    chmod 4755 "$BIN"
    sly_sub "Binary  " "setuid root applied"
fi

sly_finished "update"
