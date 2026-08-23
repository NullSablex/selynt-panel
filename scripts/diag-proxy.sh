#!/bin/bash
# diag-proxy.sh — Full diagnostic of the Selynt Panel proxy stack.
# Run as root.
set -u

PLUGIN_DIR="/usr/local/directadmin/plugins/selynt_panel"
STATE_BASE="/var/lib/selynt_panel"
DA_TPL_DIR="/usr/local/directadmin/data/templates/custom"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

# shellcheck source=lib/ols-paths.sh
. "$PLUGIN_DIR/scripts/lib/ols-paths.sh"
selynt_detect_ols || true
OLS_CONF_DIR="${OLS_CONF_DIR:-/usr/local/lsws/conf}"
OLS_MAIN="${OLS_MAIN_CONF:-$OLS_CONF_DIR/httpd_config.conf}"

PASS=0; FAILS=0; WARNS=0
pass() { sly_sub "$1" "$2"; PASS=$((PASS+1)); }
fail() { sly_err  "$1"; FAILS=$((FAILS+1)); }
warn() { sly_warn "$1"; WARNS=$((WARNS+1)); }

sly_header "Selynt Panel" "diagnostic — $(date '+%Y-%m-%d %H:%M:%S %Z')"

# ── Checking environment ──
sly_act "Checking" "environment"

if [ "$(id -u)" -eq 0 ]; then
    pass "user    " "root"
else
    warn "running as $(whoami) — some checks may be limited"
fi

if [ -x /usr/local/directadmin/directadmin ]; then
    DA_VER="$(/usr/local/directadmin/directadmin v 2>/dev/null || echo 'unknown')"
    pass "DA      " "$DA_VER"
else
    fail "DirectAdmin not found"
fi

if command -v lshttpd >/dev/null 2>&1; then
    LS_VER="$(lshttpd -v 2>/dev/null | head -1 || echo 'unknown')"
    pass "OLS/LSWS" "$LS_VER"
elif [ -d /etc/openlitespeed ] || [ -d /usr/local/lsws ]; then
    pass "OLS/LSWS" "$OLS_LAYOUT layout, conf at $OLS_CONF_DIR"
else
    fail "OLS/LSWS not found"
fi

if systemctl is-active lsws >/dev/null 2>&1; then
    pass "lsws svc" "active"
else
    fail "lsws service is not running"
fi

if [ -d "$PLUGIN_DIR" ]; then
    PLUGIN_VER="$(awk -F= '$1=="version"{print $2; exit}' "$PLUGIN_DIR/plugin.conf" 2>/dev/null | tr -d '[:space:]')"
    pass "plugin  " "v${PLUGIN_VER:-?}"
else
    fail "plugin not installed at $PLUGIN_DIR"
fi

BIN="$PLUGIN_DIR/bin/core-selynt"
if [ -x "$BIN" ]; then
    PERMS="$(stat -c '%a %U:%G' "$BIN" 2>/dev/null)"
    if stat -c '%a' "$BIN" 2>/dev/null | grep -q '^4'; then
        CORE_VER="$("$BIN" version 2>/dev/null || echo '')"
        pass "binary  " "OK (setuid, $PERMS)${CORE_VER:+ — $CORE_VER}"
    else
        fail "core-selynt missing setuid ($PERMS) — expected 4755 root:root"
    fi
else
    fail "core-selynt binary not found: $BIN"
fi

if command -v php >/dev/null 2>&1; then
    pass "PHP CLI " "$(php -v 2>/dev/null | head -1)"
else
    fail "PHP CLI not found"
fi

if command -v node >/dev/null 2>&1; then
    NODE_VER="$(node --version 2>/dev/null)"
    NODE_MAJOR="${NODE_VER#v}"; NODE_MAJOR="${NODE_MAJOR%%.*}"
    NODE_MINOR="${NODE_VER#*.}"; NODE_MINOR="${NODE_MINOR%%.*}"
    if [ "$NODE_MAJOR" -gt 20 ] 2>/dev/null || { [ "$NODE_MAJOR" -eq 20 ] && [ "$NODE_MINOR" -ge 6 ]; } 2>/dev/null; then
        pass "Node.js " "$NODE_VER (≥ 20.6)"
    else
        fail "Node.js $NODE_VER (< 20.6 — incompatible with --import loader)"
    fi
else
    warn "Node.js not found on PATH"
fi

NV_FILE="$PLUGIN_DIR/etc/node_versions"
if [ -f "$NV_FILE" ]; then
    NV_COUNT="$(wc -l < "$NV_FILE" | tr -d '[:space:]')"
    pass "nodes   " "$NV_COUNT configured"
    while IFS= read -r line; do
        path="$(echo "$line" | awk '{print $1}')"
        ver="$(echo "$line" | awk '{print $2}')"
        if [ -x "$path" ]; then
            sly_sub "  $ver" "$path"
        else
            warn "$ver → $path (missing)"
        fi
    done < "$NV_FILE"
else
    sly_note "no Node.js versions configured (uses system default)"
fi

# ── Inspecting DA templates ──
sly_act "Inspecting" "DirectAdmin templates"

for f in openlitespeed_vhost.conf.CUSTOM.7.pre openlitespeed_vhost.conf.CUSTOM.5.pre; do
    TPL="$DA_TPL_DIR/$f"
    if [ -f "$TPL" ]; then
        if grep -q "SELYNT_PANEL" "$TPL" 2>/dev/null; then
            pass "$(printf '%-9s' "${f##*CUSTOM.}")" "block present"
        else
            fail "$f exists but does not contain a SELYNT_PANEL block"
        fi
    else
        fail "$f missing — fix: bash $PLUGIN_DIR/scripts/setup-ols.sh"
    fi
done

for old in "$DA_TPL_DIR"/cust_openlitespeed.CUSTOM.*.pre; do
    [ -f "$old" ] || continue
    warn "legacy template found: $(basename "$old") — remove manually"
done

# ── Inspecting generated vhosts ──
sly_act "Inspecting" "generated vhosts"

VHOST_CHECKED=0
VHOST_WITH_PROXY=0
VHOST_DIRS=("$OLS_CONF_DIR/vhosts" "/usr/local/lsws/conf/vhosts" "/usr/local/directadmin/data/users")
for vdir in "${VHOST_DIRS[@]}"; do
    [ -d "$vdir" ] || continue
    while IFS= read -r vconf; do
        [ -f "$vconf" ] || continue
        VHOST_CHECKED=$((VHOST_CHECKED+1))
        grep -q "selynt_proxy" "$vconf" 2>/dev/null && VHOST_WITH_PROXY=$((VHOST_WITH_PROXY+1))
    done < <(find "$vdir" -name "*.conf" -path "*openlitespeed*" -o -name "vhost.conf" 2>/dev/null | head -50)
done

if [ "$VHOST_CHECKED" -gt 0 ]; then
    pass "vhosts  " "$VHOST_CHECKED inspected, $VHOST_WITH_PROXY with selynt_proxy"
    if [ "$VHOST_WITH_PROXY" -eq 0 ]; then
        warn "no vhost contains selynt_proxy — rebuild required"
        sly_note "cd /usr/local/directadmin/custombuild && ./build rewrite_confs"
    fi
else
    warn "no vhosts found to inspect"
fi

# ── Inspecting OLS configuration ──
sly_act "Inspecting" "OLS configuration"

WEB_USER=""
WEB_USER_FILE="$PLUGIN_DIR/etc/ols_web_user"
if [ -f "$WEB_USER_FILE" ]; then
    WEB_USER="$(head -n1 "$WEB_USER_FILE" | tr -d '[:space:]')"
    if [ -n "$WEB_USER" ] && id "$WEB_USER" >/dev/null 2>&1; then
        pass "web user" "$WEB_USER"
    elif [ -n "$WEB_USER" ]; then
        fail "web user $WEB_USER does not exist on system"
    else
        fail "ols_web_user file is empty"
    fi
else
    fail "web user not configured (fix: bash $PLUGIN_DIR/scripts/setup-ols.sh)"
fi

DA_USER_FILE="$PLUGIN_DIR/etc/da_user"
if [ -f "$DA_USER_FILE" ]; then
    pass "DA user " "$(head -n1 "$DA_USER_FILE" | tr -d '[:space:]')"
else
    warn "da_user file not found"
fi

SELYNT_CONF="$OLS_CONF_DIR/selynt_extprocessors.conf"
if [ -f "$SELYNT_CONF" ]; then
    EP_COUNT=$(grep -c "^extProcessor" "$SELYNT_CONF" 2>/dev/null || echo 0)
    LAST_SYNC="$(head -1 "$SELYNT_CONF" 2>/dev/null | sed 's/.*— //')"
    pass "extProc " "$EP_COUNT defined (last sync: $LAST_SYNC)"
else
    sly_note "selynt_extprocessors.conf not present (created by sync when apps are live)"
fi

CRON_FOUND=false
if crontab -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then CRON_FOUND=true
elif crontab -u root -l 2>/dev/null | grep -qF "sync-extprocessors.sh"; then CRON_FOUND=true
elif [ -f /var/spool/cron/root ] && grep -qF "sync-extprocessors.sh" /var/spool/cron/root 2>/dev/null; then CRON_FOUND=true
elif [ -f /var/spool/cron/crontabs/root ] && grep -qF "sync-extprocessors.sh" /var/spool/cron/crontabs/root 2>/dev/null; then CRON_FOUND=true
fi
if $CRON_FOUND; then
    pass "cron    " "present"
else
    fail "cron job missing (fix: bash $PLUGIN_DIR/scripts/setup-ols.sh)"
fi

if [ -f "$STATE_BASE/.sync_needed" ]; then
    warn ".sync_needed flag present — sync pending"
fi

# ── Inspecting state and apps ──
sly_act "Inspecting" "state directory and apps"

TOTAL_APPS=0; RUNNING_APPS=0; STOPPED_APPS=0; ORPHAN_PIDS=0

if [ -d "$STATE_BASE" ]; then
    STATE_PERMS="$(stat -c '%a %U:%G' "$STATE_BASE")"
    STATE_MODE="$(stat -c '%a' "$STATE_BASE")"
    if [ "$STATE_MODE" = "711" ]; then
        pass "stateDir" "$STATE_BASE ($STATE_PERMS)"
    else
        warn "state dir $STATE_BASE ($STATE_PERMS) — expected 711"
    fi

    for udir in "$STATE_BASE"/*/; do
        [ -d "$udir" ] || continue
        user="$(basename "$udir")"
        USER_APPS=0

        for app_file in "$udir".run/*.app; do
            [ -f "$app_file" ] || continue
            TOTAL_APPS=$((TOTAL_APPS+1))
            USER_APPS=$((USER_APPS+1))
            app="$(basename "$app_file" .app)"
            host="$(grep '^host=' "$app_file" 2>/dev/null | cut -d= -f2- || echo '?')"
            type="$(grep '^type=' "$app_file" 2>/dev/null | cut -d= -f2- || echo '?')"

            pidfile="$udir.run/$app.pid"
            marker="$udir.proxy/$host"
            socket="$udir.sockets/$host"
            status="STOPPED"; pid=""

            if [ -f "$pidfile" ]; then
                pid="$(cat "$pidfile" 2>/dev/null)"
                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    status="RUNNING"; RUNNING_APPS=$((RUNNING_APPS+1))
                else
                    status="DEAD"; ORPHAN_PIDS=$((ORPHAN_PIDS+1))
                fi
            else
                STOPPED_APPS=$((STOPPED_APPS+1))
            fi

            case "$status" in
                RUNNING) STATUS_FMT="${_SLY_G}${_SLY_B}running${_SLY_N}" ;;
                DEAD)    STATUS_FMT="${_SLY_R}${_SLY_B}dead${_SLY_N}" ;;
                *)       STATUS_FMT="${_SLY_D}stopped${_SLY_N}" ;;
            esac
            sly_sub "$user/$app" "[$type] $host — $(printf '%b' "$STATUS_FMT")${pid:+ (pid $pid)}"

            if [ "$status" = "RUNNING" ]; then
                if [ -S "$socket" ]; then
                    if command -v getfacl >/dev/null 2>&1 && [ -n "${WEB_USER:-}" ]; then
                        if getfacl -p "$socket" 2>/dev/null | grep -q "user:${WEB_USER}:rw"; then
                            pass "  ACL   " "$WEB_USER rw on socket"
                        else
                            fail "$WEB_USER cannot access socket (fix: setfacl -m u:${WEB_USER}:rw- $socket)"
                        fi
                    fi
                else
                    fail "socket missing: $socket"
                fi

                if [ -f "$marker" ]; then
                    pass "  marker" "present"
                else
                    fail "marker missing — proxy inactive while app runs"
                fi

                if [ -S "$socket" ] && command -v curl >/dev/null 2>&1; then
                    HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --unix-socket "$socket" http://localhost/ --max-time 3 2>/dev/null || echo '000')"
                    if [ "$HTTP_CODE" != "000" ]; then
                        pass "  probe " "HTTP $HTTP_CODE via socket"
                    else
                        warn "socket did not respond (app may not be listening yet)"
                    fi
                fi
            elif [ "$status" = "DEAD" ]; then
                fail "PID $pid not alive — orphan pidfile (fix: rm $pidfile)"
            fi
        done

        if [ "$USER_APPS" -gt 0 ] && command -v getfacl >/dev/null 2>&1 && [ -n "${WEB_USER:-}" ]; then
            for subdir in .sockets .proxy; do
                dir="$udir$subdir"
                [ -d "$dir" ] || continue
                if getfacl -p "$dir" 2>/dev/null | grep -q "user:${WEB_USER}"; then
                    pass "  ACL[$subdir]" "$WEB_USER ok"
                else
                    warn "ACL [$user/$subdir]: $WEB_USER missing (fix: setfacl -m u:${WEB_USER}:--x $dir)"
                fi
            done
        fi
    done

    sly_sub "total   " "$TOTAL_APPS apps — ${_SLY_G}$RUNNING_APPS running${_SLY_N}, ${_SLY_D}$STOPPED_APPS stopped${_SLY_N}${ORPHAN_PIDS:+, ${_SLY_R}$ORPHAN_PIDS dead${_SLY_N}}"
else
    fail "state dir not found: $STATE_BASE (fix: bash $PLUGIN_DIR/scripts/install.sh)"
fi

# ── Auditing plugin permissions ──
sly_act "Auditing" "plugin permissions"

if [ -d "$PLUGIN_DIR" ]; then
    PC="$PLUGIN_DIR/plugin.conf"
    if [ -f "$PC" ]; then
        PC_PERMS="$(stat -c '%a' "$PC")"
        if [ "$PC_PERMS" = "600" ]; then
            if chmod 644 "$PC" 2>/dev/null; then
                pass "plugin.conf" "corrected 600 → 644"
            else
                fail "plugin.conf $PC_PERMS (DA cannot read it; needs root to fix)"
            fi
        else
            pass "plugin.conf" "$PC_PERMS"
        fi
    fi

    BAD_PERMS=0; FIXED=0
    while IFS= read -r f; do
        [ "$f" = "$BIN" ] && continue
        [ "$f" = "$PC" ] && continue
        FPERMS="$(stat -c '%a' "$f" 2>/dev/null)"
        if [ "$FPERMS" != "755" ]; then
            if chmod 755 "$f" 2>/dev/null; then
                FIXED=$((FIXED+1))
            else
                BAD_PERMS=$((BAD_PERMS+1))
            fi
        fi
    done < <(find "$PLUGIN_DIR" -type f 2>/dev/null)
    [ "$FIXED" -gt 0 ] && pass "perms   " "fixed $FIXED files to 755"
    if [ "$BAD_PERMS" -eq 0 ]; then
        pass "files   " "all 755"
    else
        fail "$BAD_PERMS files not 755 (needs root)"
    fi

    [ -f "$PLUGIN_DIR/hooks/user_httpd_write_post.sh" ] \
        && pass "hook    " "user_httpd_write_post.sh present" \
        || fail "hook user_httpd_write_post.sh missing"

    [ -f "$PLUGIN_DIR/lib/node-loader.js" ] \
        && pass "loader  " "node-loader.js present" \
        || fail "node-loader.js missing"
fi

# ── Scanning recent logs ──
sly_act "Scanning" "recent logs"

OLS_ERRLOG="/var/log/openlitespeed/error_log"
if [ -f "$OLS_ERRLOG" ]; then
    RELEVANT="$(grep -i "selynt\|proxy\|extprocessor\|rewrite\|uds://" "$OLS_ERRLOG" 2>/dev/null | tail -5)"
    if [ -n "$RELEVANT" ]; then
        warn "OLS error log has relevant entries:"
        echo "$RELEVANT" | while IFS= read -r line; do sly_note "$line"; done
    else
        pass "OLS log " "no selynt/proxy mentions"
    fi
else
    sly_note "OLS log not found: $OLS_ERRLOG"
fi

PLUGIN_ERR="$PLUGIN_DIR/etc/stderr.log"
if [ -f "$PLUGIN_ERR" ] && [ -s "$PLUGIN_ERR" ]; then
    LINES="$(wc -l < "$PLUGIN_ERR" | tr -d '[:space:]')"
    warn "plugin stderr.log: $LINES lines"
    tail -3 "$PLUGIN_ERR" | while IFS= read -r line; do sly_note "$line"; done
else
    pass "stderr  " "plugin log is clean"
fi

DA_ERRLOG="/var/log/directadmin/error.log"
if [ -f "$DA_ERRLOG" ]; then
    TODAY="$(date '+%Y:%m:%d')"
    YESTERDAY="$(date -d '1 day ago' '+%Y:%m:%d' 2>/dev/null || date -v-1d '+%Y:%m:%d' 2>/dev/null || echo '')"
    DA_RELEVANT="$(grep -i "selynt_panel\|timeout.*plugin" "$DA_ERRLOG" 2>/dev/null | grep -E "^($TODAY|$YESTERDAY)" 2>/dev/null | sed 's/<[^>]*>//g' | tail -3)"
    if [ -n "$DA_RELEVANT" ]; then
        warn "recent selynt_panel entries in DA log:"
        echo "$DA_RELEVANT" | while IFS= read -r line; do sly_note "$line"; done
    fi
fi

# ── Probing connectivity ──
sly_act "Probing" "DA connectivity"
if command -v curl >/dev/null 2>&1; then
    DA_PORT="$(grep '^port=' /usr/local/directadmin/conf/directadmin.conf 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')"
    DA_PORT="${DA_PORT:-2222}"
    HTTP_CODE="$(curl -sk -o /dev/null -w '%{http_code}' "https://127.0.0.1:${DA_PORT}/CMD_PLUGINS/selynt_panel" --max-time 5 2>/dev/null || echo '000')"
    case "$HTTP_CODE" in
        200|301|302) pass "DA      " "HTTP $HTTP_CODE" ;;
        401|403)     pass "DA      " "auth required, HTTP $HTTP_CODE" ;;
        000)         warn "could not connect to DA on port $DA_PORT" ;;
        *)           warn "unexpected reply from DA: HTTP $HTTP_CODE" ;;
    esac
else
    sly_note "curl unavailable — connectivity test skipped"
fi

# ── Summary ──
if [ "$FAILS" -gt 0 ]; then
    sly_err "$PASS passed, $WARNS warnings, $FAILS failures"
    printf '             %sCommon fixes:%s\n' "$_SLY_D" "$_SLY_N"
    printf '               bash %s/scripts/setup-ols.sh\n' "$PLUGIN_DIR"
    printf '               cd /usr/local/directadmin/custombuild && ./build rewrite_confs\n'
    printf '               systemctl restart lsws\n'
    exit 1
elif [ "$WARNS" -gt 0 ]; then
    sly_finished "diagnostic — $PASS passed, $WARNS warnings"
else
    sly_finished "diagnostic — $PASS passed, no issues"
fi
exit 0
