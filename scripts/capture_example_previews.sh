#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$ROOT_DIR/example"

echo "[preview-capture] Running preview golden generation for Phase 1 examples..."
(
  cd "$EXAMPLE_DIR"
  flutter test test/generate_previews_test.dart --update-goldens
)

echo "[preview-capture] Generated screenshots:"
echo "  - assets/screenshots/file-system-search-macos.png"
echo "  - assets/screenshots/todo-tree-macos.png"
echo "[preview-capture] To sync wiki copies, run scripts/sync_preview_images_to_wiki.sh"
