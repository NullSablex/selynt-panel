#!/bin/sh
# boot-recover.sh — Restore apps that were running before the last reboot.
#
# Invoked by selynt-panel.service after boot. Walks the state dir, finds apps
# with a `.enabled` marker and restarts them if they aren't already alive.
# Apps the user explicitly stopped have no marker and stay stopped.
#
# Runs as root (the binary is setuid root and drops to the user via USERNAME).
set -u

STATE_BASE="/var/lib/selynt_panel"
BIN="/usr/local/directadmin/plugins/selynt_panel/bin/core-selynt"
LOG="/usr/local/directadmin/plugins/selynt_panel/etc/boot-recover.log"

[ -x "$BIN" ] || exit 0
[ -d "$STATE_BASE" ] || exit 0

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '[%s] %s\n' "$(ts)" "$*" >>"$LOG" 2>/dev/null || true; }

log "boot-recover: scanning $STATE_BASE"

for user_dir in "$STATE_BASE"/*/; do
    [ -d "$user_dir/.run" ] || continue
    username=$(basename "$user_dir")
    id "$username" >/dev/null 2>&1 || { log "skip: user '$username' does not exist"; continue; }

    for marker in "$user_dir/.run"/*.enabled; do
        [ -f "$marker" ] || continue
        name=$(basename "$marker" .enabled)

        pid_file="$user_dir/.run/$name.pid"
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file" 2>/dev/null || true)
            if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
                log "skip: $username/$name already running (pid=$pid)"
                continue
            fi
            rm -f "$pid_file"
        fi

        log "start: $username/$name"
        if USERNAME="$username" "$BIN" start "$name" >>"$LOG" 2>&1; then
            log "ok: $username/$name"
        else
            log "fail: $username/$name (exit $?)"
        fi
    done
done

log "boot-recover: done"
exit 0
