"""
Replace Unicode characters in JSON content that no bundled font covers.

Why: CanvasKit's FontFallbackManager logs "Could not find a set of Noto fonts to
display all missing characters" and loops on requestAnimationFrame whenever it
hits a glyph not covered by any loaded font. Cairo (700cp) covers basic Arabic
+ Latin. Amiri (1700cp) adds full Arabic Presentation Forms + Latin Extended
(ḥ ʿ etc.). NotoColorEmoji COLRv1 covers emojis. Nothing in our chain covers
arrows, box-drawing, or Greek letters.

This script substitutes those into ASCII equivalents *only in JSON content*,
which is the runtime-rendered surface. Comments in `.dart` files (which use
U+2500 box-drawing for visual separators) are stripped at compile time and
don't reach the renderer, so they're left alone.

Substitutions:
  →   (U+2192 RIGHTWARDS ARROW)        -> "->"
  ←   (U+2190 LEFTWARDS ARROW)         -> "<-"
  ↑   (U+2191 UPWARDS ARROW)           -> "^"
  ↓   (U+2193 DOWNWARDS ARROW)         -> "v"
  θ   (U+03B8 GREEK SMALL THETA)       -> "theta"
  λ   (U+03BB GREEK SMALL LAMDA)       -> "lambda"
  μ   (U+03BC GREEK SMALL MU)          -> "mu"
  π   (U+03C0 GREEK SMALL PI)          -> "pi"
  Ω   (U+03A9 OHM SIGN candidate)      -> "ohm"
  ✓   (U+2713 CHECK MARK)              -> "OK"

Skipped (kept as-is, covered by Amiri):
  ﷺ ʿ ḥ ḍ ḏ ṣ ṭ ẓ — Arabic ligature + transliteration diacritics

Run: python scripts/replace_unrendered_unicode.py
"""
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_DIR = ROOT / "assets" / "data"

REPLACEMENTS = {
    # ── Single arrows ─────────────────────────────────────────────
    "→": "->",        # U+2192
    "←": "<-",        # U+2190
    "↑": "^",         # U+2191
    "↓": "v",         # U+2193
    # ── Double arrows ─────────────────────────────────────────────
    "⇒": "=>",        # U+21D2
    "⇐": "<=",        # U+21D0
    # ── White arrows (used for instruction callouts) ──────────────
    "⇨": "->",        # U+21E8 RIGHTWARDS WHITE ARROW
    "⇦": "<-",        # U+21E6
    "⇧": "^",         # U+21E7
    "⇩": "v",         # U+21E9
    # ── Greek letters spelled out for math/physics readers ────────
    "θ": "theta",
    "λ": "lambda",
    "μ": "mu",
    "π": "pi",
    "φ": "phi",
    "Ω": "ohm",
    # ── Symbols ───────────────────────────────────────────────────
    "✓": "OK",
    "★": "*",         # U+2605 BLACK STAR
    "ₙ": "n",         # U+2099 subscript n
    "ⁿ": "n",         # U+207F superscript n
    "₹": "INR",       # U+20B9 Indian Rupee Sign
    # ── Latin diacritics that no bundled font covers ──────────────
    # These appear in occasional Vietnamese / linguistic transliteration.
    # Substituting to the base letter is lossy but acceptable in our
    # children's-content context where the diacritic isn't pedagogically load-bearing.
    "ẻ": "e",         # U+1EBB
    "ơ": "o",         # U+1A1
    "Ǝ": "E",         # U+18E
    "ư": "u",         # U+1B0 (Vietnamese)
    "ể": "e",         # U+1EC3 (Vietnamese)
    # ── Math set notation: spell out for kids' content ────────────
    "∪": " union ",   # U+222A
    "∩": " intersection ", # U+2229
    # ── Music notation symbols ────────────────────────────────────
    "♯": "#",         # U+266F MUSIC SHARP SIGN
    "♭": "b",         # U+266D MUSIC FLAT SIGN
    # ── Variation Selector-16 ─────────────────────────────────────
    # This is an invisible modifier byte that requests "emoji style" for
    # the *previous* character. Stripping it is safe because the preceding
    # codepoint already renders correctly through our chain.
    "️": "",
}


def replace_in_text(text: str) -> tuple[str, int]:
    n = 0
    for src, dst in REPLACEMENTS.items():
        if src in text:
            count = text.count(src)
            text = text.replace(src, dst)
            n += count
    return text, n


def main() -> int:
    total_changes = 0
    files_changed = 0
    for path in sorted(JSON_DIR.glob("*.json")):
        original = path.read_text(encoding="utf-8")
        new, changes = replace_in_text(original)
        if changes:
            # Re-roundtrip JSON to make sure substitutions don't break parsing.
            try:
                json.loads(new)
            except json.JSONDecodeError as e:
                print(
                    f"  SKIP   {path.name}: substitutions broke JSON parse: {e}",
                    file=sys.stderr,
                )
                continue
            path.write_text(new, encoding="utf-8")
            files_changed += 1
            total_changes += changes
            print(f"  fixed  {changes:5} replacements  {path.name}")
    print(f"\nReplaced {total_changes} chars across {files_changed} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
