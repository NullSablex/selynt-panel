#!/bin/bash
# Selynt Panel — uninstaller.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PLUGIN_ID="selynt_panel"
DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"
BEGIN_MARK="# BEGIN SELYNT_PANEL"
END_MARK="# END SELYNT_PANEL"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

# shellcheck source=lib/ols-paths.sh
. "$PLUGIN_DIR/scripts/lib/ols-paths.sh"
selynt_detect_ols || true
OLS_CONF_DIR="${OLS_CONF_DIR:-/etc/openlitespeed}"
OLS_MAIN_CONF="${OLS_MAIN_CONF:-$OLS_CONF_DIR/httpd_config.conf}"
SELYNT_CONF="$OLS_CONF_DIR/selynt_extprocessors.conf"
SELYNT_CONF_LEGACY="/usr/local/lsws/conf/selynt_extprocessors.conf"

[ "$(id -u)" -eq 0 ] || { sly_err "must run as root"; exit 1; }

sly_header "Selynt Panel" "uninstalling"

# ── Removing DA templates ──
sly_act "Removing" "DirectAdmin templates"
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
        sly_sub "$tpl" "removed"
    else
        printf "%s\n" "$CLEAN" > "$TPL_FILE"
        sly_sub "$tpl" "stripped Selynt block"
    fi
done

# ── Removing OLS include ──
sly_act "Cleaning" "OLS configuration"
if [ -f "$OLS_MAIN_CONF" ] && grep -qF "selynt_extprocessors" "$OLS_MAIN_CONF" 2>/dev/null; then
    sed -i '/selynt_panel extProcessors include/d;/selynt_extprocessors\.conf/d' "$OLS_MAIN_CONF"
fi
rm -f "$SELYNT_CONF" "$SELYNT_CONF.tmp".*
rm -f "$SELYNT_CONF_LEGACY" "$SELYNT_CONF_LEGACY.tmp".*

# ── Removing cron job ──
if crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    sly_act "Removing" "cron job"
    crontab -l 2>/dev/null | grep -vF "sync-extprocessors.sh" | crontab - 2>/dev/null || true
fi

# ── Disabling systemd boot-recovery ──
if command -v systemctl >/dev/null 2>&1; then
    sly_act "Disabling" "boot-recovery service"
    systemctl disable selynt-panel.service >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/selynt-panel.service
    systemctl daemon-reload 2>/dev/null || true
fi

# ── Stopping apps and cleaning state ──
sly_act "Stopping" "running apps"
SELYNT_DATA="/var/lib/selynt_panel"
if [ -d "$SELYNT_DATA" ]; then
    for pidfile in "$SELYNT_DATA"/*/.run/*.pid; do
        [ -f "$pidfile" ] || continue
        pid="$(cat "$pidfile" 2>/dev/null)"
        [ -z "$pid" ] && continue
        kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
        sleep 1
        kill -9 -- -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    done
    rm -rf "$SELYNT_DATA"
    sly_sub "State   " "removed $SELYNT_DATA"
fi

# ── Rebuilding vhosts ──
if [ -x /usr/local/directadmin/custombuild/build ]; then
    sly_act "Building" "vhosts (rewrite_confs)"
    (cd /usr/local/directadmin/custombuild && ./build rewrite_confs) >/dev/null 2>&1 \
        || sly_warn "vhost rebuild failed"
fi

# ── Restarting web server ──
sly_act "Restarting" "lsws"
if systemctl restart lsws 2>/dev/null; then
    :
elif command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; then
    :
else
    sly_warn "web server restart failed"
fi

sly_finished "uninstall"
exit 0
