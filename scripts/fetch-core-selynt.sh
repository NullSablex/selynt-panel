#!/bin/sh
# fetch-core-selynt.sh — Download the latest Core Selynt binary release into
# `bin/core-selynt` (the bin/ directory is git-ignored).
#
# Usage:
#   bash scripts/fetch-core-selynt.sh           # latest tag
#   bash scripts/fetch-core-selynt.sh v1.1.0    # specific tag
#
# Requires `gh` (authenticated) or `curl` (anonymous, subject to rate limits).
set -eu

REPO="NullSablex/core-selynt"
TAG="${1:-}"
DEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/bin"

mkdir -p "$DEST_DIR"

if command -v gh >/dev/null 2>&1; then
    if [ -z "$TAG" ]; then
        TAG="$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName')"
    fi
    [ -n "$TAG" ] || { echo "No release found in $REPO." >&2; exit 1; }
    echo "Downloading core-selynt $TAG via gh..."
    gh release download "$TAG" \
        --repo "$REPO" \
        --pattern 'core-selynt' \
        --pattern 'core-selynt.sha256' \
        --dir "$DEST_DIR" \
        --clobber
else
    command -v curl >/dev/null 2>&1 || { echo "Need 'gh' or 'curl'." >&2; exit 1; }
    if [ -z "$TAG" ]; then
        TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | \
               sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
    fi
    [ -n "$TAG" ] || { echo "Could not resolve tag." >&2; exit 1; }
    echo "Downloading core-selynt $TAG via curl..."
    BASE="https://github.com/$REPO/releases/download/$TAG"
    curl -fsSL "$BASE/core-selynt"        -o "$DEST_DIR/core-selynt"
    curl -fsSL "$BASE/core-selynt.sha256" -o "$DEST_DIR/core-selynt.sha256"
fi

(cd "$DEST_DIR" && sha256sum -c core-selynt.sha256)
rm -f "$DEST_DIR/core-selynt.sha256"
chmod +x "$DEST_DIR/core-selynt"

echo "OK — $DEST_DIR/core-selynt ($TAG, $(stat -c%s "$DEST_DIR/core-selynt" 2>/dev/null || stat -f%z "$DEST_DIR/core-selynt") bytes)"
