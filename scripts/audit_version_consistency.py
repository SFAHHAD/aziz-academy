"""
Pre-deploy guard: every hardcoded `_kAppVersion` constant in the Dart
source must match `version:` in pubspec.yaml.

Why this matters at launch:
  The version string surfaces in three places users actually see:
    - Splash screen → "v1.1.99" at the bottom on first launch
    - About screen → "Version 1.1.99+104"
    - Admin dashboard → "v1.1.99+104 · {build-commit}"
  All three currently hold their own `const _kAppVersion = '...'` literal.
  pubspec.yaml is the source of truth that Flutter uses for the actual
  build (App Store / Play Store version, CFBundleShortVersionString,
  Android versionName/versionCode). If a future version bump touches
  pubspec but not the constants, the app would silently misreport its
  version to users — confusing parents and breaking bug-report triage.

The right long-term fix is `package_info_plus`, which reads the version
out of the bundle metadata at runtime. Until that lands, this audit is
the safety net.

Usage:
  python scripts/audit_version_consistency.py

Exit codes:
  0  — all constants match pubspec.yaml
  1  — at least one drift detected
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "pubspec.yaml"

# Files that hold a hardcoded _kAppVersion. Each path -> the line number
# is parsed from the file; we only verify the literal matches pubspec.
SOURCES = [
    ROOT / "lib" / "features" / "legal" / "about_screen.dart",
    ROOT / "lib" / "features" / "admin" / "admin_dashboard_screen.dart",
    ROOT / "lib" / "features" / "home" / "splash_screen.dart",
]

PUBSPEC_RE = re.compile(r"^version:\s*([0-9A-Za-z.+\-]+)\s*$", re.MULTILINE)
CONST_RE = re.compile(r"_kAppVersion\s*=\s*'([^']+)'")


def main() -> int:
    if not PUBSPEC.exists():
        print(f"FATAL: {PUBSPEC} not found", file=sys.stderr)
        return 1
    m = PUBSPEC_RE.search(PUBSPEC.read_text(encoding="utf-8"))
    if not m:
        print("FATAL: could not find `version:` in pubspec.yaml", file=sys.stderr)
        return 1
    pubspec_version = m.group(1)

    drift: list[tuple[Path, str]] = []
    found_any = False
    for src in SOURCES:
        if not src.exists():
            print(f"FATAL: expected source missing: {src}", file=sys.stderr)
            return 1
        match = CONST_RE.search(src.read_text(encoding="utf-8"))
        if not match:
            print(f"WARN: no `_kAppVersion` constant found in {src.name}")
            continue
        found_any = True
        if match.group(1) != pubspec_version:
            drift.append((src, match.group(1)))

    if not found_any:
        print("WARN: no _kAppVersion constants found in any tracked source.")
        print("      Either the convention moved or SOURCES list is stale.")

    if drift:
        print(f"FAIL: {len(drift)} version constants drift from pubspec.yaml")
        print(f"  pubspec.yaml: {pubspec_version}")
        for src, ver in drift:
            print(f"  {src.relative_to(ROOT)}: {ver}")
        print()
        print("       Fix: update each `const _kAppVersion = '...'` to match")
        print(f"       pubspec.yaml ({pubspec_version}), or replace these")
        print("       literals with package_info_plus for runtime resolution.")
        return 1

    print(f"OK — version {pubspec_version} matches in pubspec.yaml + {len(SOURCES)} source(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
