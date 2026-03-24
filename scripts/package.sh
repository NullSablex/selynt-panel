#!/bin/bash
# package.sh — Compila o Core Selynt e empacota o plugin para DirectAdmin.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_DIR="$PROJECT_ROOT/selynt_panel"
CORE_DIR="$PROJECT_ROOT/core-selynt"
BIN_DEST="$PLUGIN_DIR/bin/core-selynt"

VERSION="$(awk -F= '$1=="version"{print $2; exit}' "$PLUGIN_DIR/plugin.conf" 2>/dev/null | tr -d '[:space:]')"
VERSION="${VERSION:-0.0.0}"

OUT_DIR="$PROJECT_ROOT"
[ "${1:-}" = "--out" ] && [ -n "${2:-}" ] && OUT_DIR="$2"
PACKAGE="$OUT_DIR/selynt_panel.tar.gz"

# ── Cores e helpers ──
G="\033[0;32m"; B="\033[0;36m"; D="\033[0;90m"; N="\033[0m"; BOLD="\033[1m"
ok()   { printf "${G}  ✓${N} %s\n" "$1"; }
info() { printf "${D}    %s${N}\n" "$1"; }
step() { printf "\n${BOLD}${B}── %s ──${N}\n" "$1"; }

printf "\n${BOLD}Selynt Panel${N} — Package v${VERSION}\n"

# Build — musl para binário estático (sem dependência de glibc do host)
TARGET="x86_64-unknown-linux-musl"
step "Build"
cargo build --release --target "$TARGET" --manifest-path "$CORE_DIR/Cargo.toml"
cp "$CORE_DIR/target/$TARGET/release/core-selynt" "$BIN_DEST"
chmod 755 "$BIN_DEST"
ok "Core Selynt compilado ($(du -sh "$BIN_DEST" | cut -f1))"

# Permissões (root:root 755)
find "$PLUGIN_DIR" -type d -exec chmod 755 {} \;
find "$PLUGIN_DIR" -type f -exec chmod 755 {} \;

# Empacotar — DA espera plugin.conf na RAIZ do tar (sem subdiretório)
step "Empacotamento"
tar -czf "$PACKAGE" \
    --exclude='*.tmp' \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='*.tar.gz' \
    -C "$PLUGIN_DIR" \
    .

ok "$PACKAGE ($(du -sh "$PACKAGE" | cut -f1))"
printf "\n"
