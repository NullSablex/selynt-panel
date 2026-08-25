#!/bin/bash
# Selynt Panel — uninstaller.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

BIN="$PLUGIN_DIR/bin/core-selynt"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

[ "$(id -u)" -eq 0 ] || { sly_err "must run as root"; exit 1; }

sly_header "Selynt Panel" "uninstalling"

# ── Undoing the server-side configuration ──
# The binary owns this: removing a block from a template is done by the code
# that wrote it.
sly_act "Removing" "server configuration"
if [ -x "$BIN" ]; then
    if OUT="$("$BIN" teardown 2>&1)"; then
        STOPPED="$(printf '%s' "$OUT" | sed -n 's/.*"apps_stopped":\([0-9]*\).*/\1/p')"
        [ -n "$STOPPED" ] && sly_sub "Apps    " "$STOPPED stopped"
        case "$OUT" in
            *'"vhosts_rebuilt":true'*) sly_sub "Vhosts  " "rebuilt" ;;
            *) sly_warn "vhosts not rebuilt — run: cd /usr/local/directadmin/custombuild && ./build rewrite_confs" ;;
        esac
    else
        sly_warn "teardown failed: $OUT"
    fi
else
    sly_warn "Core Selynt binary missing — server configuration left in place"
fi

# ── Removing cron job ──
# Leftovers only — the proxy sync moved into the binary. Both spellings,
# because it used to be a shell script.
if crontab -l 2>/dev/null | grep -qE "sync-extprocessors\.sh|core-selynt sync-proxy"; then
    sly_act "Removing" "cron job"
    # A filter that removes every line is a normal outcome, not an error.
    { crontab -l 2>/dev/null \
        | grep -vE "sync-extprocessors\.sh|core-selynt sync-proxy" || true
    } | crontab - 2>/dev/null || true
fi

sly_finished "uninstall"
exit 0
