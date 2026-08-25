#!/bin/bash
# Selynt Panel — one-shot installer.
# Run as root:
#   bash <(curl -fsSL https://raw.githubusercontent.com/NullSablex/selynt-panel/master/install.sh)
set -euo pipefail

PLUGIN_DIR="/usr/local/directadmin/plugins/selynt_panel"
REPO="NullSablex/selynt-panel"
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/selynt_panel.tar.gz"

# Inline cargo-style helpers — this script runs before the plugin is installed,
# so it cannot source scripts/lib/output.sh.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    R=$'\033[0;31m'; G=$'\033[0;32m'; Y=$'\033[0;33m'; D=$'\033[0;90m'
    B=$'\033[1m'; N=$'\033[0m'
else
    R=""; G=""; Y=""; D=""; B=""; N=""
fi
header()  { printf '\n%s%s%s %s%s%s\n\n' "$B" "$1" "$N" "$D" "${2:-}" "$N"; }
act()     { printf '%s%12s%s %s\n' "$G$B" "$1" "$N" "${2:-}"; }
warn()    { printf '%s%12s%s %s\n' "$Y$B" "warning:" "$N" "$1" >&2; }
err()     { printf '%s%12s%s %s\n' "$R$B" "error:"   "$N" "$1" >&2; }
finished(){ printf '%s%12s%s %s\n' "$G$B" "Finished" "$N" "${1:-}"; }

header "Selynt Panel" "installer"

[ "$(id -u)" -eq 0 ] || { err "must run as root"; exit 1; }
command -v directadmin >/dev/null 2>&1 \
    || [ -x /usr/local/directadmin/directadmin ] \
    || { err "DirectAdmin not found"; exit 1; }

# ── Checking prerequisites ──
# Only what the panel cannot work without. Anything optional is reported by the
# diagnostic after the install, where it can name the specific problem.
act "Checking" "prerequisites"

# The proxy is built out of OpenLiteSpeed's extProcessors, and DirectAdmin only
# generates the vhost templates it hooks into when OLS is the web server.
# LiteSpeed Enterprise reads Apache's configuration instead, so those templates
# are never applied there.
if [ ! -f /etc/openlitespeed/httpd_config.conf ] \
    && [ ! -f /usr/local/lsws/conf/httpd_config.conf ]; then
    err "OpenLiteSpeed not found — the panel routes traffic through it"
    printf '             %sTested with:%s OpenLiteSpeed 1.9.2, DirectAdmin 1.708\n' "$D" "$N"
    exit 1
fi
if grep -q '^webserver=litespeed$' \
    /usr/local/directadmin/custombuild/options.conf 2>/dev/null; then
    err "LiteSpeed Enterprise is not supported — it uses Apache's configuration"
    exit 1
fi

# Apps are placed in their own systemd scope, which is where their memory limit
# is enforced; cgroup v2 is what makes that limit real.
command -v systemctl >/dev/null 2>&1 || { err "systemd not found"; exit 1; }
[ -d /sys/fs/cgroup/system.slice ] \
    || { err "cgroup v2 not available — memory limits cannot be enforced"; exit 1; }

# The web server reaches an app's socket through a POSIX ACL, not ownership.
command -v setfacl >/dev/null 2>&1 \
    || { err "setfacl not found — install acl"; exit 1; }

# PHP renders the panel pages and the CGI endpoints.
PHP_BIN="/usr/local/bin/php"
[ -x "$PHP_BIN" ] || PHP_BIN="$(command -v php 2>/dev/null || true)"
[ -n "$PHP_BIN" ] || { err "PHP CLI not found"; exit 1; }
"$PHP_BIN" -r 'exit(PHP_VERSION_ID >= 80000 ? 0 : 1);' 2>/dev/null \
    || { err "PHP 8.0 or newer required (found $("$PHP_BIN" -r 'echo PHP_VERSION;' 2>/dev/null))"; exit 1; }

# Isolation is optional: without bubblewrap the panel refuses to turn it on,
# rather than pretending apps are separated when they are not.
if ! command -v bwrap >/dev/null 2>&1; then
    warn "bubblewrap not installed — isolation between apps will be unavailable"
fi

act "Downloading" "latest release from github.com/${REPO}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RELEASE_URL" -o "$TMP"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP" "$RELEASE_URL"
else
    err "curl or wget required"; exit 1
fi

act "Extracting" "to $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
tar -xzf "$TMP" -C "$PLUGIN_DIR"

bash "$PLUGIN_DIR/scripts/install.sh"
bash "$PLUGIN_DIR/scripts/update.sh"

act "Restarting" "directadmin"
if systemctl restart directadmin 2>/dev/null || service directadmin restart 2>/dev/null; then
    :
else
    warn "restart directadmin manually"
fi

finished "install"
printf '             %sAccess:%s https://your-server:2222/CMD_PLUGINS_ADMIN/selynt_panel\n\n' "$D" "$N"
