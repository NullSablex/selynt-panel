#!/bin/sh
# Selynt Panel — DirectAdmin plugin installer.
# Intentionally without `set -e`: the DA plugin install hook must never fail
# or the plugin won't be registered.
#
# Steps that decide whether the panel works go through `sly_try`, which warns
# and carries on. A bare `|| true` is reserved for genuinely optional work —
# an informational file, a log the code creates on demand, a cache nudge —
# where failing silently costs nothing.

PLUGIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

sly_header "Selynt Panel" "installing"

BIN="$PLUGIN_DIR/bin/core-selynt"
sly_try "creating etc/" mkdir -p "$PLUGIN_DIR/etc"

# ── Detecting environment ──
sly_act "Detecting" "environment"

DA_USER=""
if id diradmin >/dev/null 2>&1; then
    DA_USER="diradmin"
elif pgrep -x directadmin >/dev/null 2>&1; then
    DA_USER="$(ps -o user= -p "$(pgrep -x directadmin | head -1)" 2>/dev/null | tr -d ' ')"
fi
if [ -z "$DA_USER" ] && [ -f /usr/local/directadmin/directadmin ]; then
    DA_USER="$(stat -c '%U' /usr/local/directadmin/directadmin 2>/dev/null)"
fi
[ -z "$DA_USER" ] && DA_USER="diradmin"
DA_UID="$(id -u "$DA_USER" 2>/dev/null || echo "")"
sly_sub "DA user " "$DA_USER${DA_UID:+ (UID $DA_UID)}"
printf "%s\n" "$DA_USER" > "$PLUGIN_DIR/etc/da_user" 2>/dev/null \
    || sly_warn "could not write etc/da_user — admin commands will be refused"
printf "%s\n" "${DA_UID:-}"  > "$PLUGIN_DIR/etc/da_uid"  2>/dev/null || true

WEB_USER=""
for u in lsws www-data apache nginx nobody; do
    if id "$u" >/dev/null 2>&1; then
        WEB_USER="$u"
        break
    fi
done
if [ -n "$WEB_USER" ]; then
    printf "%s\n" "$WEB_USER" > "$PLUGIN_DIR/etc/ols_web_user" 2>/dev/null \
        || sly_warn "could not write etc/ols_web_user — socket ACLs will be skipped"
    sly_sub "Web user" "$WEB_USER"
else
    sly_warn "web server user not detected"
fi

# The account DirectAdmin runs plugin CGI as. This is *not* the web server
# user: DA serves plugin pages through its `legacy-handler` child process, which
# drops to `nobody` on a stock install. core-selynt checks the calling uid
# against this file, so getting it wrong makes every panel action fail with
# `admin_required`. Read it from the running handler rather than guessing.
CGI_USER=""
for pid in $(pgrep -f 'directadmin.*legacy-handler' 2>/dev/null); do
    u="$(ps -o user= -p "$pid" 2>/dev/null | tr -d ' ')"
    [ -n "$u" ] && [ "$u" != "root" ] && { CGI_USER="$u"; break; }
done
[ -z "$CGI_USER" ] && id nobody >/dev/null 2>&1 && CGI_USER="nobody"
if [ -n "$CGI_USER" ]; then
    printf "%s\n" "$CGI_USER" > "$PLUGIN_DIR/etc/da_cgi_user" 2>/dev/null \
        || sly_warn "could not write etc/da_cgi_user — panel actions will fail"
    sly_sub "CGI user" "$CGI_USER"
else
    sly_warn "DirectAdmin CGI user not detected — panel actions may fail"
fi

touch "$PLUGIN_DIR/etc/stderr.log" "$PLUGIN_DIR/etc/debug.log" 2>/dev/null || true

# ── Preparing state directory ──
sly_act "Preparing" "state directory"
SELYNT_DATA="/var/lib/selynt_panel"
sly_try "creating $SELYNT_DATA" mkdir -p "$SELYNT_DATA"
if [ -n "$DA_USER" ]; then
    sly_try "setting owner of $SELYNT_DATA" chown "$DA_USER:$DA_USER" "$SELYNT_DATA"
fi
sly_try "setting permissions on $SELYNT_DATA" chmod 711 "$SELYNT_DATA"
sly_sub "Path    " "$SELYNT_DATA"

# ── Configuring OLS (templates, extProcessors, cron) ──
# OLS may live in /etc/openlitespeed (DA 1.690+ via CustomBuild) or in
# /usr/local/lsws/conf (older installs). Accept either.
OLS_SETUP="$PLUGIN_DIR/scripts/setup-ols.sh"
if [ -f "$OLS_SETUP" ] && { [ -d /etc/openlitespeed ] || [ -d /usr/local/lsws ]; }; then
    "$OLS_SETUP" 2>&1 || sly_warn "OLS configuration failed (check manually)"
fi

# ── Setting ownership and permissions ──
sly_act "Setting" "ownership and permissions"

# Everything under the plugin dir must belong to root. DirectAdmin's Plugin
# Manager extracts the tarball as whatever user it happens to run the upload as,
# which on stock images leaves the tree owned by an unprivileged account (e.g.
# `almalinux`, uid 1000). That account could then rewrite the CGI scripts that
# the panel executes — and edit `scripts/install.sh`, which runs as root on the
# next update. Reclaiming ownership here closes that window and is also what
# stops admins from having to fix things by hand in a shell afterwards.
if ! chown -R root:root "$PLUGIN_DIR"; then
    sly_warn "Failed to set root ownership on $PLUGIN_DIR — the plugin tree stays writable by another user"
fi

# 0755 dirs / 0644 files: the CGI scripts need the execute bit, everything else
# only needs to be readable. Blanket 755 on every file was handing the world an
# execute bit on JSON, CSS and dictionaries for no reason.
sly_try "setting directory permissions" find "$PLUGIN_DIR" -type d -exec chmod 755 {} \;
sly_try "setting file permissions" find "$PLUGIN_DIR" -type f -exec chmod 644 {} \;
sly_try "making .raw endpoints executable" find "$PLUGIN_DIR" -type f -name '*.raw' -exec chmod 755 {} \;
sly_try "making .html pages executable" find "$PLUGIN_DIR" -type f -name '*.html' -exec chmod 755 {} \;
sly_try "making scripts executable" find "$PLUGIN_DIR/scripts" -type f -name '*.sh' -exec chmod 755 {} \;
sly_try "making hooks executable" find "$PLUGIN_DIR/hooks" -type f -exec chmod 755 {} \;
chmod 644 "$PLUGIN_DIR/plugin.conf" 2>/dev/null || true
if [ -f "$BIN" ]; then
    # Report what actually happened: without setuid root every privileged
    # action fails at runtime with `root_required`, and silently claiming
    # success here sends people hunting through the panel instead of the
    # install log.
    if chown root:root "$BIN" && chmod 4755 "$BIN"; then
        sly_sub "Binary  " "setuid root applied"
    else
        sly_warn "Failed to apply setuid root to $BIN — privileged actions will fail"
    fi
else
    sly_warn "Core Selynt binary missing: $BIN"
fi

# ── Enabling boot-recovery service ──
SERVICE_SRC="$PLUGIN_DIR/scripts/selynt-panel.service"
SERVICE_DST="/etc/systemd/system/selynt-panel.service"
RECOVER_SH="$PLUGIN_DIR/scripts/boot-recover.sh"
if [ -d /etc/systemd/system ] && command -v systemctl >/dev/null 2>&1 && [ -f "$SERVICE_SRC" ]; then
    sly_act "Enabling" "boot-recovery service"
    sly_try "installing the boot-recovery unit" cp -f "$SERVICE_SRC" "$SERVICE_DST"
    chmod 644 "$SERVICE_DST" 2>/dev/null || true
    [ -f "$RECOVER_SH" ] && chmod 755 "$RECOVER_SH" 2>/dev/null || true
    sly_try "reloading systemd" systemctl daemon-reload
    systemctl enable selynt-panel.service >/dev/null 2>&1 \
        || sly_warn "failed to enable selynt-panel.service"
else
    sly_warn "systemd unavailable — apps will not restart after reboot"
fi

# Refresh DA menu cache.
echo "action=cache&value=showall" >> /usr/local/directadmin/data/task.queue 2>/dev/null || true

sly_finished "install"
exit 0
