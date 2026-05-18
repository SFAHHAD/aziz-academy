#!/usr/bin/env bash
# Post-build cleanup for Flutter web → Vercel deploys.
# Strips CanvasKit variants we don't ship, debug symbol files, and any other
# bytes that won't be needed at runtime. Run after `flutter build web --release`.
set -euo pipefail

WEB_DIR="${1:-build/web}"
if [[ ! -d "$WEB_DIR" ]]; then
  echo "post_build_strip: directory not found: $WEB_DIR" >&2
  exit 1
fi

cd "$WEB_DIR"

# 1. CanvasKit: keep the parent canvaskit.js + canvaskit.wasm. Remove the
#    chromium-specific variant (~6.8 MB) and all extra renderer variants.
rm -rf canvaskit/chromium 2>/dev/null || true
rm -f canvaskit/skwasm.{wasm,js,js.symbols} 2>/dev/null || true
rm -f canvaskit/skwasm_heavy.{wasm,js,js.symbols} 2>/dev/null || true
rm -f canvaskit/wimp.{wasm,js,js.symbols} 2>/dev/null || true
rm -f canvaskit/canvaskit.js.symbols 2>/dev/null || true

# 2. flutter_map's logo asset is not needed for our kid-facing UI.
rm -f assets/packages/flutter_map/lib/assets/flutter_map_logo.png 2>/dev/null || true

# 3. Trim any stray .map source maps that snuck through.
find . -type f -name '*.js.map' -delete

echo "post_build_strip: done in $WEB_DIR"
ls -lh canvaskit/ 2>/dev/null | head -8 || true
