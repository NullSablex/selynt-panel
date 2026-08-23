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
