#!/bin/bash
# Selynt Panel — Uninstaller (chamado pelo uninstall.sh raiz do plugin)
set -euo pipefail

PLUGIN_ID="selynt_panel"
OLS_MAIN_CONF="/usr/local/lsws/conf/httpd_config.conf"
SELYNT_CONF="/usr/local/lsws/conf/selynt_extprocessors.conf"
DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"
BEGIN_MARK="# BEGIN SELYNT_PANEL"
END_MARK="# END SELYNT_PANEL"

[ "$(id -u)" -eq 0 ] || { echo "[erro] Execute como root." >&2; exit 1; }

# ── Remove DA custom templates ──
for tpl in openlitespeed_vhost.conf.CUSTOM.5.pre openlitespeed_vhost.conf.CUSTOM.7.pre; do
    TPL_FILE="$DA_TPL_DIR/$tpl"
    [ -f "$TPL_FILE" ] || continue
    CLEAN="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
        $0==b {inside=1; next}
        $0==e {inside=0; next}
        !inside {print}
    ' "$TPL_FILE")"
    if [ -z "$(echo "$CLEAN" | tr -d '[:space:]')" ]; then
        rm -f "$TPL_FILE"
        echo "    Template $tpl removido."
    else
        printf "%s\n" "$CLEAN" > "$TPL_FILE"
        echo "    Bloco Selynt removido de $tpl."
    fi
done

# ── Remove include do OLS ──
if [ -f "$OLS_MAIN_CONF" ] && grep -qF "selynt_extprocessors" "$OLS_MAIN_CONF" 2>/dev/null; then
    sed -i '/selynt_panel extProcessors include/d;/selynt_extprocessors\.conf/d' "$OLS_MAIN_CONF"
    echo "    Include removido do config do OLS."
fi
rm -f "$SELYNT_CONF" "$SELYNT_CONF.tmp".*

# ── Remove cron job ──
if crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    crontab -l 2>/dev/null | grep -vF "sync-extprocessors.sh" | crontab - 2>/dev/null || true
    echo "    Cron job removido."
fi

# ── Para todos os apps, limpa runtime, preserva config ──
SELYNT_DATA="/var/lib/selynt_panel"
if [ -d "$SELYNT_DATA" ]; then
    # Mata processos com PID files ativos
    for pidfile in "$SELYNT_DATA"/*/.run/*.pid; do
        [ -f "$pidfile" ] || continue
        pid="$(cat "$pidfile" 2>/dev/null)"
        [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
        [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null || true
    done

    rm -rf "$SELYNT_DATA"
    echo "    State dir removido: $SELYNT_DATA"
fi

# ── Rebuild vhosts (remove rewrite rules dos vhosts) ──
if [ -x /usr/local/directadmin/custombuild/build ]; then
    (cd /usr/local/directadmin/custombuild && ./build rewrite_confs) >/dev/null 2>&1 || true
fi

# ── Reload OLS ──
/usr/local/lsws/bin/lswsctrl reload 2>/dev/null || true

echo "    Desinstalação concluída."
exit 0
