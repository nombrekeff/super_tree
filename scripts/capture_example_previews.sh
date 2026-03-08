#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$ROOT_DIR/example"

echo "[preview-capture] Running preview golden generation for all examples..."
(
  cd "$EXAMPLE_DIR"
  flutter test test/generate_previews_test.dart --update-goldens
)

echo "[preview-capture] Generated screenshots:"
echo "  - assets/screenshots/async-lazy-loading-macos.png"
echo "  - assets/screenshots/checkbox-state-macos.png"
echo "  - assets/screenshots/complex-node-ui-macos.png"
echo "  - assets/screenshots/file-system-search-macos.png"
echo "  - assets/screenshots/integrity-guardrails-macos.png"
echo "  - assets/screenshots/minimal-file-system-macos.png"
echo "  - assets/screenshots/todo-tree-macos.png"
echo "[preview-capture] To sync wiki copies, run scripts/sync_preview_images_to_wiki.sh"
