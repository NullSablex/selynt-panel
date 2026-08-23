#!/bin/bash
# update.sh — Reapply Selynt Panel permissions after a DA upgrade.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

[ "$(id -u)" -eq 0 ] || { sly_err "must run as root"; exit 1; }

BIN="$PLUGIN_DIR/bin/core-selynt"

sly_act "Refreshing" "ownership and permissions"

# Must mirror install.sh exactly. A blanket `chmod 755` here used to undo the
# hardening applied at install time — after a DA upgrade every file went back
# to world-executable, and the tree kept whatever owner the upgrade left it
# with.
if ! chown -R root:root "$PLUGIN_DIR"; then
    sly_warn "Failed to set root ownership on $PLUGIN_DIR"
fi

sly_try "setting directory permissions" find "$PLUGIN_DIR" -type d -exec chmod 755 {} \;
sly_try "setting file permissions" find "$PLUGIN_DIR" -type f -exec chmod 644 {} \;
sly_try "making .raw endpoints executable" find "$PLUGIN_DIR" -type f -name '*.raw' -exec chmod 755 {} \;
sly_try "making .html pages executable" find "$PLUGIN_DIR" -type f -name '*.html' -exec chmod 755 {} \;
sly_try "making scripts executable" find "$PLUGIN_DIR/scripts" -type f -name '*.sh' -exec chmod 755 {} \;
sly_try "making hooks executable" find "$PLUGIN_DIR/hooks" -type f -exec chmod 755 {} \;

# plugin.conf: DA rewrites it as 600; force 644 so diradmin can read it.
chmod 644 "$PLUGIN_DIR/plugin.conf" 2>/dev/null || true

# Last, and reported: chown clears the setuid bit, so the order matters and a
# silent failure here breaks every privileged action.
if [ -f "$BIN" ]; then
    if chown root:root "$BIN" && chmod 4755 "$BIN"; then
        sly_sub "Binary  " "setuid root applied"
    else
        sly_warn "Failed to apply setuid root to $BIN — privileged actions will fail"
    fi
else
    sly_warn "Core Selynt binary missing: $BIN"
fi

sly_finished "update"
