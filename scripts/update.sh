#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

G="\033[0;32m"; R="\033[0;31m"; B="\033[0;36m"; N="\033[0m"; BOLD="\033[1m"
ok()   { printf "${G}  ✓${N} %s\n" "$1"; }
erro() { printf "${R}  ✗${N} %s\n" "$1" >&2; }

[ "$(id -u)" -eq 0 ] || { erro "Execute como root."; exit 1; }

printf "\n${BOLD}${B}── Atualizando permissões ──${N}\n"

BIN="$PLUGIN_DIR/bin/core-selynt"

# Permissões (root:root 755)
find "$PLUGIN_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
find "$PLUGIN_DIR" -type f -exec chmod 755 {} \; 2>/dev/null || true

# plugin.conf: DA reescreve com 600, forçar 644 para leitura pelo diradmin
chmod 644 "$PLUGIN_DIR/plugin.conf" 2>/dev/null || true

# Binário: setuid root (4755)
if [ -f "$BIN" ]; then
    chown root:root "$BIN"
    chmod 4755 "$BIN"
fi

ok "Permissões atualizadas"
printf "\n"
