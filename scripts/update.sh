#!/bin/bash
# update.sh — Reapply Selynt Panel permissions after a DA upgrade.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

[ "$(id -u)" -eq 0 ] || { sly_err "must run as root"; exit 1; }

BIN="$PLUGIN_DIR/bin/core-selynt"

sly_act "Refreshing" "ownership and permissions"

# The binary applies this, from the same rules the diagnostic checks against —
# two copies of the permission table is how they stop agreeing.
if [ -x "$BIN" ]; then
    if OUT="$("$BIN" setup 2>&1)"; then
        sly_sub "Binary  " "setuid root applied"
    else
        sly_warn "refresh failed: $OUT"
    fi
else
    sly_warn "Core Selynt binary missing: $BIN"
fi

sly_finished "update"
