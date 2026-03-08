#!/usr/bin/env bash
set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "[gif-convert] ffmpeg is required. Install it first (e.g. brew install ffmpeg)."
  exit 1
fi

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/convert_video_to_gif.sh <input-video> <output-gif> [fps] [width]"
  echo "Example: scripts/convert_video_to_gif.sh assets/raw/file-system.mov assets/gifs/file-system-search.gif 12 1200"
  exit 1
fi

INPUT_VIDEO="$1"
OUTPUT_GIF="$2"
FPS="${3:-12}"
WIDTH="${4:-1200}"
PALETTE="$(mktemp /tmp/super-tree-palette-XXXXXX.png)"

ffmpeg -y -i "$INPUT_VIDEO" -vf "fps=$FPS,scale=$WIDTH:-1:flags=lanczos,palettegen" "$PALETTE"
ffmpeg -y -i "$INPUT_VIDEO" -i "$PALETTE" -lavfi "fps=$FPS,scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse" "$OUTPUT_GIF"

rm -f "$PALETTE"
echo "[gif-convert] Created $OUTPUT_GIF"
