#!/bin/bash
# sync-extprocessors.sh — Regenerate OLS extProcessors for every live app.
# Run by cron once per minute when /var/lib/selynt_panel/.sync_needed exists.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Detect OLS layout (new DA 1.690+ or legacy).
# shellcheck source=lib/ols-paths.sh
. "$PLUGIN_DIR/scripts/lib/ols-paths.sh"
selynt_detect_ols || true
OLS_CONF_DIR="${OLS_CONF_DIR:-/etc/openlitespeed}"

SELYNT_CONF="$OLS_CONF_DIR/selynt_extprocessors.conf"
STATE_BASE="/var/lib/selynt_panel"
LOCK_FILE="/var/lib/selynt_panel/.sync.lock"

[ "$(id -u)" -eq 0 ] || exit 1

# Exclusive lock — prevent concurrent runs.
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# Collect live apps: marker present + socket present.
declare -A ACTIVE=()
for marker in "$STATE_BASE"/*/.proxy/*; do
    [ -f "$marker" ] || continue
    host="$(basename "$marker")"
    user="$(basename "$(dirname "$(dirname "$marker")")")"
    socket="$STATE_BASE/$user/.sockets/$host"
    [ -S "$socket" ] || continue
    [[ "$host" =~ ^[A-Za-z0-9._-]+$ ]] || continue
    ACTIVE["$host"]="$user|$socket"
done

# Emit extProcessors atomically.
TMP="$(mktemp "${SELYNT_CONF}.XXXXXX")"
{
    printf "# Selynt Panel extProcessors — %s\n" "$(date -Iseconds)"
    printf "# DO NOT EDIT — generated automatically\n\n"

    for host in "${!ACTIVE[@]}"; do
        IFS='|' read -r user socket <<< "${ACTIVE[$host]}"

        # Name must match the DA template: selynt_proxy-|SDOMAIN|-|VH_PORT|
        for port in 80 443; do
            cat <<EOF
extProcessor selynt_proxy-${host}-${port} {
  type                    proxy
  address                 uds://$socket
  maxConns                35
  initTimeout             60
  retryTimeout            0
  persistConn             1
  respBuffer              0
  autoStart               0
  instances               1
  priority                0
}

EOF
        done
    done
} > "$TMP"

mv -f "$TMP" "$SELYNT_CONF"
chown lsadm:lsadm "$SELYNT_CONF" 2>/dev/null || chown root:root "$SELYNT_CONF" || true
chmod 640 "$SELYNT_CONF"

rm -f /var/lib/selynt_panel/.sync_needed

# Graceful reload.
systemctl restart lsws 2>/dev/null \
    || { command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; } \
    || true

exit 0
