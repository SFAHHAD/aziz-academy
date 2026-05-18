"""
Pre-deploy guard: every Unicode character that appears in rendered JSON
content must be covered by one of our bundled fonts (Cairo, Amiri,
NotoColorEmoji), or the build fails.

We've shipped two production incidents on this:
  1. CanvasKit cannot render NotoColorEmoji's CBDT/CBLC bitmap variant —
     it claims cmap coverage, then bitmap rendering fails.
  2. Cairo only carries ~700 code points and misses Arabic Presentation
     Forms (ﷺ), Latin Extended Additional (ḥ ʿ), arrows, and Greek.
     Each missing glyph triggers a `Could not find a set of Noto fonts`
     warning that loops once per frame, locking the renderer.

This script reads every JSON pool under assets/data/, collects the set
of non-ASCII characters used in *rendered* fields (everything except
known data-only fields like flag_emoji), and fails if any aren't in the
combined font cmap. Run it before every deploy; wire it into
deploy_web.ps1 if you want it to gate.

Usage:
  python scripts/audit_font_coverage.py
  python scripts/audit_font_coverage.py --strict  # fail also on rare chars

Exit codes:
  0  — all rendered content covered
  1  — uncovered glyphs found
"""
from __future__ import annotations

import argparse
import json
import os
import struct
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FONTS_DIR = ROOT / "assets" / "fonts"
JSON_DIR = ROOT / "assets" / "data"
ARB_DIR = ROOT / "lib" / "l10n"

# Known data-only fields that never reach a Text widget. Their values are
# parsed into Dart strings but never displayed, so missing-glyph warnings
# from these fields would be false positives.
DATA_ONLY_FIELDS = {"flag_emoji", "flagEmoji", "iso", "code", "id", "key"}

# Regional indicators (U+1F1E6..U+1F1FF) live in flag_emoji and aren't
# rendered anywhere — bake the exclusion in.
REGIONAL_INDICATOR_RANGE = range(0x1F1E6, 0x1F200)

# Format characters that don't render as glyphs themselves. The text engine
# uses them as hints (e.g. VS-16 forces emoji presentation on the preceding
# dual-presentation char) but never tries to draw a glyph for them, so a
# missing cmap entry is a false-positive.
ZERO_WIDTH_FORMAT_CHARS = frozenset({
    *range(0x200B, 0x2010),   # ZWSP / ZWNJ / ZWJ / LRM / RLM / Hairline space
    *range(0x202A, 0x202F),   # LRE / RLE / PDF / LRO / RLO
    *range(0x2066, 0x206A),   # LRI / RLI / FSI / PDI
    *range(0xFE00, 0xFE10),   # Variation selectors VS-1..VS-16
    0xFEFF,                   # ZWNBSP / BOM
})


def read_cmap(path: Path) -> set[int]:
    with path.open("rb") as f:
        data = f.read()
    n = struct.unpack(">H", data[4:6])[0]
    cmap_off = None
    for i in range(n):
        rec = data[12 + i * 16: 12 + (i + 1) * 16]
        if rec[:4] == b"cmap":
            cmap_off = struct.unpack(">I", rec[8:12])[0]
            break
    if cmap_off is None:
        return set()
    num_sub = struct.unpack(">H", data[cmap_off + 2: cmap_off + 4])[0]
    cps: set[int] = set()
    for i in range(num_sub):
        rec = data[cmap_off + 4 + i * 8: cmap_off + 4 + (i + 1) * 8]
        _plat, _enc, off = struct.unpack(">HHI", rec)
        sub = cmap_off + off
        fmt = struct.unpack(">H", data[sub: sub + 2])[0]
        if fmt == 12:
            ng = struct.unpack(">I", data[sub + 12: sub + 16])[0]
            for g in range(ng):
                go = sub + 16 + g * 12
                start, end, _ = struct.unpack(">III", data[go: go + 12])
                for cp in range(start, end + 1):
                    cps.add(cp)
        elif fmt == 4:
            seg_x2 = struct.unpack(">H", data[sub + 6: sub + 8])[0]
            sc = seg_x2 // 2
            end_o = sub + 14
            start_o = end_o + seg_x2 + 2
            for s in range(sc):
                ec = struct.unpack(">H", data[end_o + s * 2: end_o + s * 2 + 2])[0]
                sc2 = struct.unpack(">H", data[start_o + s * 2: start_o + s * 2 + 2])[0]
                for cp in range(sc2, ec + 1):
                    cps.add(cp)
    return cps


def collect_rendered_strings(value, out: list[str], current_key: str | None = None) -> None:
    """Walk a JSON tree, emitting every string value that's likely rendered.
    Skip values whose key is in DATA_ONLY_FIELDS.
    """
    if isinstance(value, dict):
        for k, v in value.items():
            if k in DATA_ONLY_FIELDS:
                continue
            collect_rendered_strings(v, out, current_key=k)
    elif isinstance(value, list):
        for v in value:
            collect_rendered_strings(v, out, current_key=current_key)
    elif isinstance(value, str):
        out.append(value)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--strict", action="store_true",
                    help="also fail on rare chars (counts <= 2)")
    args = ap.parse_args()

    fonts = list(FONTS_DIR.glob("*.ttf")) + list(FONTS_DIR.glob("*.otf"))
    if not fonts:
        print(f"FATAL: no font files found under {FONTS_DIR}", file=sys.stderr)
        return 2

    covered: set[int] = set()
    for font in fonts:
        try:
            covered |= read_cmap(font)
        except Exception as e:
            print(f"WARN: could not parse {font.name}: {e}", file=sys.stderr)

    print(f"Combined cmap from {len(fonts)} fonts: {len(covered):,} code points")

    found: dict[int, int] = {}
    for path in sorted(JSON_DIR.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARN: skip {path.name}: {e}", file=sys.stderr)
            continue
        rendered: list[str] = []
        collect_rendered_strings(data, rendered)
        for s in rendered:
            for ch in s:
                cp = ord(ch)
                if cp > 0x7F:
                    found[cp] = found.get(cp, 0) + 1

    # ARB files: every value in the top-level dict that isn't an `@`-metadata
    # key is a literal that will pass through Text(). A previous prod
    # incident shipped `✓` (U+2713) inside ARB values; Cairo+Amiri+Noto
    # didn't cover it, CanvasKit looped FontFallbackManager forever waiting
    # for a Noto variant that doesn't exist. The audit started missing this
    # because it only scanned JSON pools, not the ARB strings.
    for arb in sorted(ARB_DIR.glob("app_*.arb")):
        try:
            data = json.loads(arb.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARN: skip {arb.name}: {e}", file=sys.stderr)
            continue
        for k, v in data.items():
            if k.startswith("@") or not isinstance(v, str):
                continue
            for ch in v:
                cp = ord(ch)
                if cp > 0x7F:
                    found[cp] = found.get(cp, 0) + 1

    problem = sorted(
        ((cp, n) for cp, n in found.items()
         if cp not in covered
         and cp not in REGIONAL_INDICATOR_RANGE
         and cp not in ZERO_WIDTH_FORMAT_CHARS),
        key=lambda x: -x[1],
    )
    print(f"Rendered non-ASCII chars in JSON: {len(found):,}")
    print(f"Uncovered (excluding regional indicators): {len(problem)}")
    if not problem:
        print("OK — every rendered character is covered.")
        return 0

    print()
    threshold = 1 if args.strict else 3
    fatal: list[tuple[int, int]] = []
    for cp, n in problem:
        try:
            name = unicodedata.name(chr(cp))
        except ValueError:
            name = "?"
        marker = "FATAL" if n >= threshold else "warn "
        print(f"  [{marker}] U+{cp:05X}  count={n:5}  {name}")
        if n >= threshold:
            fatal.append((cp, n))

    print()
    if fatal:
        print(
            f"FAIL: {len(fatal)} character(s) with count >= {threshold} are not "
            f"covered by any bundled font. Either add a font that covers them or "
            f"add a substitution to scripts/replace_unrendered_unicode.py."
        )
        return 1
    print("Soft pass — only rare uncovered chars (count < threshold).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
