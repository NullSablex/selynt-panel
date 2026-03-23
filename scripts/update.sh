#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

[ "$(id -u)" -eq 0 ] || { echo "[erro] Execute como root." >&2; exit 1; }

echo "==> Atualizando permissões..."

# Binário principal (setuid root)
BIN="$PLUGIN_DIR/bin/core_selynt"
if [ -f "$BIN" ]; then
    chown root:root "$BIN"
    chmod 4755 "$BIN"
fi

# CGI executáveis (755)
find "$PLUGIN_DIR/user" "$PLUGIN_DIR/admin" -type f \( -name "*.html" -o -name "*.raw" \) -exec chmod 755 {} \;

# Shell scripts (755)
find "$PLUGIN_DIR/scripts" -name "*.sh" -exec chmod 755 {} \;

# Hooks
chmod 755 "$PLUGIN_DIR/hooks/user_httpd_write_post.sh" 2>/dev/null || true
chmod 644 "$PLUGIN_DIR/hooks/user_txt.html" "$PLUGIN_DIR/hooks/admin_txt.html" 2>/dev/null || true

# Config e dados (644)
chmod 644 "$PLUGIN_DIR/plugin.conf"
chmod 644 "$PLUGIN_DIR/images/"*.json 2>/dev/null || true
chmod 644 "$PLUGIN_DIR/lib/common.php" "$PLUGIN_DIR/lib/node-loader.js"
find "$PLUGIN_DIR/images/assets" -type f -exec chmod 644 {} \; 2>/dev/null || true

# Ownership
chown -R diradmin:diradmin "$PLUGIN_DIR"

echo "==> Atualização concluída."
