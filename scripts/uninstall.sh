#!/bin/bash
# Selynt Panel — Uninstaller
set -euo pipefail

PLUGIN_ID="selynt_panel"
OLS_MAIN_CONF="/usr/local/lsws/conf/httpd_config.conf"
SELYNT_CONF="/usr/local/lsws/conf/selynt_extprocessors.conf"
DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"
BEGIN_MARK="# BEGIN SELYNT_PANEL"
END_MARK="# END SELYNT_PANEL"

# ── Cores e helpers ──
R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"; B="\033[0;36m"; D="\033[0;90m"; N="\033[0m"; BOLD="\033[1m"
ok()   { printf "${G}  ✓${N} %s\n" "$1"; }
erro() { printf "${R}  ✗${N} %s\n" "$1" >&2; }
warn() { printf "${Y}  ⚠${N} %s\n" "$1"; }
info() { printf "${D}    %s${N}\n" "$1"; }
step() { printf "\n${BOLD}${B}── %s ──${N}\n" "$1"; }

[ "$(id -u)" -eq 0 ] || { erro "Execute como root."; exit 1; }

printf "\n${BOLD}Selynt Panel${N} — Desinstalação\n"

# ── Remove DA custom templates ──
step "Templates"
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
        ok "Template $tpl removido"
    else
        printf "%s\n" "$CLEAN" > "$TPL_FILE"
        ok "Bloco Selynt removido de $tpl"
    fi
done

# ── Remove include do OLS ──
step "Configuração OLS"
if [ -f "$OLS_MAIN_CONF" ] && grep -qF "selynt_extprocessors" "$OLS_MAIN_CONF" 2>/dev/null; then
    sed -i '/selynt_panel extProcessors include/d;/selynt_extprocessors\.conf/d' "$OLS_MAIN_CONF"
    ok "Include removido do config do OLS"
fi
rm -f "$SELYNT_CONF" "$SELYNT_CONF.tmp".*

# ── Remove cron job ──
step "Cron"
if crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    crontab -l 2>/dev/null | grep -vF "sync-extprocessors.sh" | crontab - 2>/dev/null || true
    ok "Cron job removido"
fi

# ── Para todos os apps, limpa runtime, preserva config ──
step "Aplicações"
SELYNT_DATA="/var/lib/selynt_panel"
if [ -d "$SELYNT_DATA" ]; then
    # Mata processos e seus filhos (group kill)
    for pidfile in "$SELYNT_DATA"/*/.run/*.pid; do
        [ -f "$pidfile" ] || continue
        pid="$(cat "$pidfile" 2>/dev/null)"
        [ -z "$pid" ] && continue
        # SIGTERM no grupo de processos
        kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
        sleep 1
        # SIGKILL para garantir
        kill -9 -- -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    done

    rm -rf "$SELYNT_DATA"
    ok "State dir removido: $SELYNT_DATA"
fi

# ── Rebuild vhosts (remove rewrite rules dos vhosts) ──
step "Rebuild"
if [ -x /usr/local/directadmin/custombuild/build ]; then
    if (cd /usr/local/directadmin/custombuild && ./build rewrite_confs) >/dev/null 2>&1; then
        ok "Vhosts reconstruídos"
    else
        warn "Rebuild de vhosts falhou"
    fi
fi

# ── Restart servidor web ──
step "Reload"
if systemctl restart lsws 2>/dev/null; then
    ok "Servidor web reiniciado"
elif command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; then
    ok "Servidor web reiniciado (lswsctrl)"
else
    warn "Restart do servidor web falhou"
fi

printf "\n${G}${BOLD}  ✓ Desinstalação concluída${N}\n\n"
exit 0
