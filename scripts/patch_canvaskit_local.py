#!/usr/bin/env python3
"""
Patch flutter_bootstrap.js so the loader serves CanvasKit from our own
/canvaskit/ directory instead of www.gstatic.com.

Why: by default the Flutter bootstrap fetches canvaskit.js + canvaskit.wasm
from gstatic.com per session — which means a TLS handshake + a separate cache
silo every time. Self-hosting routes that fetch through Vercel where our
vercel.json gives /canvaskit/* `Cache-Control: max-age=31536000, immutable`,
so after the first visit the browser never re-fetches it.

Run this AFTER `flutter build web`. Idempotent — running twice is a no-op.
"""

from __future__ import annotations

import sys
from pathlib import Path

BOOTSTRAP = Path("build/web/flutter_bootstrap.js")
NEEDLE = "_flutter.loader.load();"
# `canvasKitVariant: "full"` is critical: without it, Chrome/Edge will try
# to fetch /canvaskit/chromium/canvaskit.{js,wasm} (a browser-specific
# smaller variant) — and our post-build strip removes the chromium/
# subdirectory to save disk. Forcing "full" tells Flutter to use the
# files we actually ship: /canvaskit/canvaskit.js + canvaskit.wasm.
REPLACEMENT = (
    '_flutter.loader.load({'
    'config:{'
    'canvasKitBaseUrl:"/canvaskit/",'
    'canvasKitVariant:"full"'
    '}});'
)


def main() -> int:
    if not BOOTSTRAP.exists():
        print(f"FATAL: {BOOTSTRAP} not found", file=sys.stderr)
        return 1
    src = BOOTSTRAP.read_text(encoding="utf-8")
    if REPLACEMENT in src:
        print("Already patched. Skipping.")
        return 0
    if NEEDLE not in src:
        print(f"FATAL: needle not found in {BOOTSTRAP}", file=sys.stderr)
        print("       Flutter may have changed the bootstrap shape.", file=sys.stderr)
        return 1
    out = src.replace(NEEDLE, REPLACEMENT, 1)
    BOOTSTRAP.write_text(out, encoding="utf-8")
    print(f"Patched {BOOTSTRAP}: CanvasKit now loads from /canvaskit/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
