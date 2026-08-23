#!/bin/bash
# package.sh — Build the Core Selynt binary and package the plugin tarball.
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

# shellcheck source=lib/output.sh
. "$PLUGIN_DIR/scripts/lib/output.sh"

sly_header "Selynt Panel" "package v${VERSION}"

TARGET="x86_64-unknown-linux-musl"

sly_act "Compiling" "core-selynt ($TARGET)"
cargo build --release --target "$TARGET" --manifest-path "$CORE_DIR/Cargo.toml"
cp "$CORE_DIR/target/$TARGET/release/core-selynt" "$BIN_DEST"
chmod 755 "$BIN_DEST"
sly_sub "Binary  " "$(du -sh "$BIN_DEST" | cut -f1) → $BIN_DEST"

find "$PLUGIN_DIR" -type d -exec chmod 755 {} \;
find "$PLUGIN_DIR" -type f -exec chmod 755 {} \;

sly_act "Packaging" "$PACKAGE"
# Exclusion list mirrors .github/workflows/release.yml so the local package
# matches what CI produces.
tar -czf "$PACKAGE" \
    --exclude='node_modules' \
    --exclude='assets-src' \
    --exclude='package.json' \
    --exclude='package-lock.json' \
    --exclude='build-assets.mjs' \
    --exclude='assets.manifest.json' \
    --exclude='packages.md' \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='.gitignore' \
    --exclude='version' \
    --exclude='./install.sh' \
    --exclude='README.md' \
    --exclude='CHANGELOG.md' \
    --exclude='docs' \
    --exclude='notes' \
    --exclude='mkdocs.yml' \
    --exclude='scripts/package.sh' \
    --exclude='scripts/fetch-core-selynt.sh' \
    --exclude='*.tmp' \
    --exclude='*.tar.gz' \
    -C "$PLUGIN_DIR" \
    .
sly_sub "Archive " "$(du -sh "$PACKAGE" | cut -f1)"

sly_finished "package v${VERSION}"
