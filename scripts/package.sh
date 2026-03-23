#!/bin/bash
# package.sh — Compila o core Rust e empacota o plugin para DirectAdmin.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_DIR="$PROJECT_ROOT/selynt_panel"
CORE_DIR="$PROJECT_ROOT/core_selynt"
BIN_DEST="$PLUGIN_DIR/bin/core_selynt"

VERSION="$(awk -F= '$1=="version"{print $2; exit}' "$PLUGIN_DIR/plugin.conf" 2>/dev/null | tr -d '[:space:]')"
VERSION="${VERSION:-0.0.0}"

OUT_DIR="$PROJECT_ROOT"
[ "${1:-}" = "--out" ] && [ -n "${2:-}" ] && OUT_DIR="$2"
PACKAGE="$OUT_DIR/selynt_panel.tar.gz"

# Build — musl para binário estático (sem dependência de glibc do host)
TARGET="x86_64-unknown-linux-musl"
echo "==> Compilando core_selynt (release, $TARGET)..."
cargo build --release --target "$TARGET" --manifest-path "$CORE_DIR/Cargo.toml"
cp "$CORE_DIR/target/$TARGET/release/core_selynt" "$BIN_DEST"
chmod 755 "$BIN_DEST"
echo "    OK ($(du -sh "$BIN_DEST" | cut -f1))"

# Permissões
find "$PLUGIN_DIR/user" "$PLUGIN_DIR/admin" \( -name "*.html" -o -name "*.raw" \) -exec chmod 755 {} \;
find "$PLUGIN_DIR/scripts" -name "*.sh" -exec chmod 755 {} \;
chmod 644 "$PLUGIN_DIR/plugin.conf"
chmod 644 "$PLUGIN_DIR/hooks/user_txt.html" "$PLUGIN_DIR/hooks/admin_txt.html" 2>/dev/null || true
chmod 755 "$PLUGIN_DIR/hooks/user_httpd_write_post.sh" 2>/dev/null || true
chmod 644 "$PLUGIN_DIR/images/"*.json 2>/dev/null || true
chmod 755 "$PLUGIN_DIR/install.sh" "$PLUGIN_DIR/uninstall.sh"

# Empacotar — DA espera plugin.conf na RAIZ do tar (sem subdiretório)
echo "==> Empacotando v${VERSION}..."
tar -czf "$PACKAGE" \
    --exclude='*.tmp' \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='*.tar.gz' \
    -C "$PLUGIN_DIR" \
    .

echo "    $PACKAGE ($(du -sh "$PACKAGE" | cut -f1))"
