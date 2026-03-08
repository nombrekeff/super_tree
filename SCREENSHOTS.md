# Screenshot and GIF Workflow

This document describes how to capture and maintain preview media used in `README.md` and the wiki.

## Scope

The screenshot workflow currently captures all examples listed in `example/lib/main.dart`.

## Prerequisites

- Flutter SDK available on PATH
- Dependencies installed (`flutter pub get` at repo root)
- Optional for GIF conversion: `ffmpeg`

## Generate Screenshots

From repository root:

```bash
scripts/capture_example_previews.sh
```

This runs `example/test/generate_previews_test.dart` with `--update-goldens` and writes PNG files to:

- `assets/screenshots/async-lazy-loading-macos.png`
- `assets/screenshots/checkbox-state-macos.png`
- `assets/screenshots/complex-node-ui-macos.png`
- `assets/screenshots/file-system-search-macos.png`
- `assets/screenshots/integrity-guardrails-macos.png`
- `assets/screenshots/minimal-file-system-macos.png`
- `assets/screenshots/todo-tree-macos.png`

The preview test preloads app fonts and Material icons (via `loadAppFonts`) so generated images render readable text and icons.

## Sync to Wiki

```bash
scripts/sync_preview_images_to_wiki.sh
```

This copies the screenshots to:

- `super_tree.wiki/images/async-lazy-loading-macos.png`
- `super_tree.wiki/images/checkbox-state-macos.png`
- `super_tree.wiki/images/complex-node-ui-macos.png`
- `super_tree.wiki/images/file-system-search-macos.png`
- `super_tree.wiki/images/integrity-guardrails-macos.png`
- `super_tree.wiki/images/minimal-file-system-macos.png`
- `super_tree.wiki/images/todo-tree-macos.png`

## Optional GIF Conversion

Record a short `.mov` or `.mp4` interaction clip manually, then convert it:

```bash
scripts/convert_video_to_gif.sh <input-video> <output-gif> [fps] [width]
```

Example:

```bash
scripts/convert_video_to_gif.sh assets/raw/file-system.mov assets/gifs/file-system-search.gif 12 1200
```

## Extend or Update Examples

If example IDs/screens change in `example/lib/main.dart`, keep `example/test/generate_previews_test.dart`, `scripts/capture_example_previews.sh`, and `scripts/sync_preview_images_to_wiki.sh` in sync with the same screenshot file names.
