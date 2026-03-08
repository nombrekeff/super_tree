#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI_DIR="$ROOT_DIR.wiki"

if [[ ! -d "$WIKI_DIR" ]]; then
  echo "[preview-sync] Wiki directory not found at $WIKI_DIR"
  exit 1
fi

mkdir -p "$WIKI_DIR/images"
cp "$ROOT_DIR/assets/screenshots/file-system-search-macos.png" "$WIKI_DIR/images/"
cp "$ROOT_DIR/assets/screenshots/todo-tree-macos.png" "$WIKI_DIR/images/"

echo "[preview-sync] Synced screenshots to $WIKI_DIR/images"
