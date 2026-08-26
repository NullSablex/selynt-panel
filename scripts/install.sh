#!/bin/sh
# Selynt Panel — DirectAdmin plugin installer.
#
# No `set -e` on purpose: the DA install hook must exit 0 or the plugin is never
# registered. Steps that decide whether the panel works go through `sly_try`,
# which warns and carries on; a bare `|| true` is for genuinely optional work.

PLUGIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

sly_header "Selynt Panel" "installing"

# Says plainly that it did nothing, rather than reporting success after every
# privileged step was refused.
if [ "$(id -u)" -ne 0 ]; then
    sly_err "must run as root — nothing was installed"
    exit 0
fi

BIN="$PLUGIN_DIR/bin/core-selynt"
INSTALL_FAILED=0
sly_try "creating etc/" mkdir -p "$PLUGIN_DIR/etc"

# ── Preparing the environment ──
# The binary owns this — it records the accounts, creates the state directory
# and installs the vhost templates. It is what reads those files back, so
# detecting them here too would be a second answer free to drift.
sly_act "Preparing" "environment"
if [ -x "$BIN" ]; then
    if SETUP_OUT="$("$BIN" setup 2>&1)"; then
        for field in da_user cgi_user web_user; do
            value="$(printf '%s' "$SETUP_OUT" \
                | sed -n "s/.*\"$field\":\"\([^\"]*\)\".*/\1/p")"
            [ -n "$value" ] && sly_sub "$(printf '%-8s' "$field")" "$value"
        done
        case "$SETUP_OUT" in
            *'"vhosts_rebuilt":true'*)
                sly_sub "vhosts  " "rebuilt"
                ;;
            *'"ols":{"ok":false'*)
                sly_warn "web server not configured — the panel will not route traffic"
                ;;
            *)
                sly_warn "vhosts not rebuilt — run: cd /usr/local/directadmin/custombuild && ./build rewrite_confs"
                ;;
        esac
    else
        sly_err "environment setup failed: $SETUP_OUT"
        INSTALL_FAILED=1
    fi
else
    sly_err "Core Selynt binary missing: $BIN"
    INSTALL_FAILED=1
fi

touch "$PLUGIN_DIR/etc/stderr.log" "$PLUGIN_DIR/etc/debug.log" 2>/dev/null || true

# ── Verifying the install ──
# Asks the binary for the same diagnostic the admin panel runs.
if [ -x "$BIN" ]; then
    sly_act "Verifying" "installation"
    # Not root: the binary refuses it as a target, and that error used to be
    # read as success.
    DA_USER="$(cat "$PLUGIN_DIR/etc/da_user" 2>/dev/null || echo diradmin)"
    DIAG="$(USERNAME="$DA_USER" "$BIN" admin diagnose 2>/dev/null)"
    # Positive evidence that the checks ran: looking only for failures read a
    # refused diagnostic as everything being fine.
    if ! printf '%s' "$DIAG" | grep -q '"level":"pass"'; then
        sly_err "diagnostic did not run — check with: $BIN admin diagnose"
        INSTALL_FAILED=1
    elif printf '%s' "$DIAG" | grep -q '"level":"fail"'; then
        sly_err "installation has problems — run: $BIN admin diagnose"
        INSTALL_FAILED=1
    elif printf '%s' "$DIAG" | grep -q '"level":"warn"'; then
        sly_warn "installation has warnings — run: $BIN admin diagnose"
    else
        sly_sub "Checks  " "all passed"
    fi
fi

# Refresh DA menu cache.
echo "action=cache&value=showall" >> /usr/local/directadmin/data/task.queue 2>/dev/null || true

if [ "$INSTALL_FAILED" -eq 1 ]; then
    sly_err "install incomplete — the panel will not work until this is resolved"
    exit 0
fi
sly_finished "install"
exit 0
