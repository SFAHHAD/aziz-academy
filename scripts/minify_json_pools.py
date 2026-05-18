#!/usr/bin/env python3
"""
Strip whitespace from every JSON file under build/web/assets/assets/data/.

Why: pubspec ships pretty-printed JSON pools (~14 MB total) so they're
human-editable. The browser doesn't care about indentation — minifying
saves ~30-40% raw and a bit more after brotli on the wire.

Source files are untouched. Only the deployed copies get minified.
Run AFTER `flutter build web`.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path("build/web/assets/assets/data")


def main() -> int:
    if not ROOT.exists():
        print(f"FATAL: {ROOT} not found", file=sys.stderr)
        return 1
    files = sorted(ROOT.glob("*.json"))
    if not files:
        print(f"FATAL: no JSON files under {ROOT}", file=sys.stderr)
        return 1

    total_before = 0
    total_after = 0
    failed: list[tuple[Path, str]] = []

    for f in files:
        try:
            raw = f.read_bytes()
            total_before += len(raw)
            obj = json.loads(raw)
            # `separators=(",", ":")` removes the default `, ` and `: ` spaces.
            # ensure_ascii=False keeps Arabic text as-is (smaller than \u escapes).
            mini = json.dumps(obj, separators=(",", ":"), ensure_ascii=False)
            mini_bytes = mini.encode("utf-8")
            f.write_bytes(mini_bytes)
            total_after += len(mini_bytes)
        except Exception as e:  # noqa: BLE001
            failed.append((f, str(e)))

    saved = total_before - total_after
    pct = (saved / total_before * 100) if total_before else 0
    print(f"Minified {len(files) - len(failed)} JSON files.")
    print(f"  before: {total_before:,} bytes")
    print(f"  after:  {total_after:,} bytes")
    print(f"  saved:  {saved:,} bytes ({pct:.1f}%)")
    if failed:
        print(f"  {len(failed)} files failed:")
        for f, e in failed:
            print(f"    - {f}: {e}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
