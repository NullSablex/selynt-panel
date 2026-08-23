#!/bin/bash
# setup-ols.sh — Wire Selynt Panel into OpenLiteSpeed + DirectAdmin.
# Must run as root (invoked by install.sh).
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

# Detect OLS layout: new (DA 1.690+) under /etc/openlitespeed, legacy under
# /usr/local/lsws/conf. Sets OLS_CONF_DIR and OLS_MAIN_CONF.
# shellcheck source=lib/ols-paths.sh
. "$PLUGIN_DIR/scripts/lib/ols-paths.sh"
selynt_detect_ols || true
OLS_CONF_DIR="${OLS_CONF_DIR:-/etc/openlitespeed}"
OLS_MAIN_CONF="${OLS_MAIN_CONF:-$OLS_CONF_DIR/httpd_config.conf}"

DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"
BEGIN_MARK="# BEGIN SELYNT_PANEL"
END_MARK="# END SELYNT_PANEL"

[ "$(id -u)" -eq 0 ] || { sly_err "must run as root"; exit 1; }

if [ "$OLS_PRESENT" != "1" ] || [ ! -f "$OLS_MAIN_CONF" ]; then
    sly_err "OpenLiteSpeed not found"
    exit 1
fi

sly_header "Selynt Panel" "OLS setup (${OLS_LAYOUT}: ${OLS_CONF_DIR})"

# upsert_template — replace or insert a marker-delimited block in a file.
upsert_template() {
    local file="$1" content="$2"
    if [ -f "$file" ]; then
        local clean
        clean="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
            $0==b {inside=1; next}
            $0==e {inside=0; next}
            !inside {print}
        ' "$file")"
        if [ -z "$(echo "$clean" | tr -d '[:space:]')" ]; then
            printf "%s\n" "$content" > "$file"
        else
            printf "%s\n%s\n" "$content" "$clean" > "$file"
        fi
    else
        printf "%s\n" "$content" > "$file"
    fi
    chmod 755 "$file"
}

# Two-layer proxy mechanism:
# CUSTOM.7 — per-vhost extProcessor pointing to the app's Unix socket
# CUSTOM.5 — RewriteCond that activates the proxy only when .proxy/|SDOMAIN|
#            marker exists; otherwise the request falls through to PHP/static.

if [ -d /usr/local/directadmin/data/templates ]; then
    mkdir -p "$DA_TPL_DIR"
    rm -f "$DA_TPL_DIR"/cust_openlitespeed.CUSTOM.*.pre 2>/dev/null || true

    sly_act "Installing" "DirectAdmin templates"

    upsert_template "$DA_TPL_DIR/openlitespeed_vhost.conf.CUSTOM.7.pre" "$(cat <<'EOF'
# BEGIN SELYNT_PANEL
extprocessor selynt_proxy-|SDOMAIN|-|VH_PORT| {
  type                    proxy
  address                 uds:///var/lib/selynt_panel/|USER|/.sockets/|SDOMAIN|
  maxConns                35
  initTimeout             60
  retryTimeout            0
  persistConn             1
  respBuffer              0
  autoStart               0
  instances               1
}
# END SELYNT_PANEL
EOF
)"
    sly_sub "CUSTOM.7" "extProcessor block"

    upsert_template "$DA_TPL_DIR/openlitespeed_vhost.conf.CUSTOM.5.pre" "$(cat <<'EOF'
# BEGIN SELYNT_PANEL
RewriteCond /var/lib/selynt_panel/|USER|/.proxy/|SDOMAIN| -f
RewriteRule ^(.*)$ http://selynt_proxy-|SDOMAIN|-|VH_PORT|/$1 [P,L,E=PROXY-HOST:|HTTP_HOST|]
# END SELYNT_PANEL
EOF
)"
    sly_sub "CUSTOM.5" "rewrite proxy block"

    sly_act "Building" "vhosts (rewrite_confs)"
    if [ -x /usr/local/directadmin/custombuild/build ]; then
        (cd /usr/local/directadmin/custombuild && ./build rewrite_confs) >/dev/null 2>&1 \
            || sly_warn "vhost rebuild failed"
    elif command -v da >/dev/null 2>&1; then
        da build rewrite_confs >/dev/null 2>&1 \
            || sly_warn "vhost rebuild failed"
    else
        sly_warn "rebuild manually: cd /usr/local/directadmin/custombuild && ./build rewrite_confs"
    fi
else
    sly_warn "DirectAdmin templates directory not found"
fi

# Ensure the base state dir is world-traversable so the web server can reach
# the per-user sockets and markers.
chmod 711 /var/lib/selynt_panel 2>/dev/null || true

# ── Detecting web server user ──
sly_act "Detecting" "web server user"
WEB_USER=""
if [ -r "$OLS_MAIN_CONF" ]; then
    WEB_USER="$(awk 'tolower($1)=="user"{print $2; exit}' "$OLS_MAIN_CONF" 2>/dev/null || true)"
    WEB_USER="${WEB_USER%\"}"; WEB_USER="${WEB_USER#\"}"
fi
if [ -z "$WEB_USER" ]; then
    for u in apache lsws www-data nginx nobody; do
        if id "$u" >/dev/null 2>&1; then WEB_USER="$u"; break; fi
    done
fi
if [ -n "$WEB_USER" ]; then
    mkdir -p "$PLUGIN_DIR/etc"
    printf "%s\n" "$WEB_USER" > "$PLUGIN_DIR/etc/ols_web_user"
    chmod 755 "$PLUGIN_DIR/etc/ols_web_user"
    sly_sub "Web user" "$WEB_USER"
fi

# ── Installing cron job ──
SYNC_SCRIPT="$PLUGIN_DIR/scripts/sync-extprocessors.sh"
CRON_LINE="* * * * * [ -f /var/lib/selynt_panel/.sync_needed ] && $SYNC_SCRIPT"
if ! crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then
    sly_act "Installing" "cron job"
    ( crontab -l 2>/dev/null; printf "%s\n" "$CRON_LINE" ) | crontab -
else
    sly_act "Skipping" "cron job (already present)"
fi

# ── Restarting lsws ──
sly_act "Restarting" "lsws"
if systemctl restart lsws 2>/dev/null; then
    :
elif command -v lswsctrl >/dev/null 2>&1 && lswsctrl restart 2>/dev/null; then
    :
else
    sly_warn "web server restart failed"
fi

sly_finished "OLS setup"
exit 0
