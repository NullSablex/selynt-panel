#!/bin/bash
# sync-extprocessors.sh — Regenera extProcessors do OLS para todos os apps ativos.
# Executado via cron a cada minuto quando /var/lib/selynt_panel/.sync_needed existe.
set -euo pipefail

OLS_CONF_DIR="/usr/local/lsws/conf"
SELYNT_CONF="$OLS_CONF_DIR/selynt_extprocessors.conf"
STATE_BASE="/var/lib/selynt_panel"
LOCK_FILE="/var/lib/selynt_panel/.sync.lock"

[ "$(id -u)" -eq 0 ] || exit 1

# Lock exclusivo para evitar runs concorrentes
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# Coleta apps ativos: marker existe + socket existe
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

# Gera extProcessors atomicamente
TMP="$(mktemp "${SELYNT_CONF}.XXXXXX")"
{
    printf "# Selynt Panel extProcessors — %s\n" "$(date -Iseconds)"
    printf "# NAO EDITE — gerado automaticamente\n\n"

    for host in "${!ACTIVE[@]}"; do
        IFS='|' read -r user socket <<< "${ACTIVE[$host]}"

        # Nome sem sanitização — deve coincidir com o template DA:
        # http://selynt_proxy-|SDOMAIN|-|VH_PORT|
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

# Reload graceful
systemctl restart lsws 2>/dev/null \
    || { command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; } \
    || true

exit 0
