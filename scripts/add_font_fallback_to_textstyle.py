"""
Inject `fontFamilyFallback: const ['Amiri', 'NotoColorEmoji']` into every
TextStyle(...) constructor that declares an explicit `fontFamily:` but no
`fontFamilyFallback:`.

Why: a TextStyle with explicit fontFamily bypasses Theme propagation. If the
rendered string contains any char not in that family (Cairo misses ﷺ ʿ ḥ
arrows, JetBrainsMono misses Arabic entirely), CanvasKit logs "Could not
find a set of Noto fonts" once per frame inside requestAnimationFrame and
locks rendering. AppTheme already declares the global fallback chain; these
inline styles need the same chain copied in or they short-circuit it.

Skip:
  - admin/diag/dev (English-only by design, no Arabic content)
  - app_text_styles.dart (canonical styles already declare fallback)
  - any TextStyle that already has fontFamilyFallback
  - .copyWith(...) — those inherit fallback

Idempotent: re-running won't double-inject.
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

# Match TextStyle(...) — accept up to ~1500 chars of args and DOTALL so we
# match across newlines.
TEXTSTYLE_RE = re.compile(r'(?<!\.copyWith)\bTextStyle\s*\(([^)]{0,1500}?)\)', re.DOTALL)


def should_skip(path: Path) -> bool:
    s = str(path).replace("\\", "/").lower()
    if s.endswith("/app_text_styles.dart"):
        return True
    return any(x in s for x in ("/admin/", "/diag", "/dev/"))


def needs_fallback(args: str) -> bool:
    if "fontFamilyFallback" in args:
        return False
    # Has explicit fontFamily? (Skip if not — Theme propagates fallback.)
    if "fontFamily" not in args:
        return False
    return True


def derive_indent(text: str, ts_start: int) -> str:
    """Return the indent of the first line of the TextStyle args, used so the
    injected fontFamilyFallback aligns with the existing fontFamily.
    """
    # Find the line containing fontFamily within the args
    open_paren = text.index("(", ts_start)
    line_start = text.rfind("\n", 0, open_paren) + 1
    # Use 2 extra spaces past the start of "TextStyle"
    base_col = open_paren - line_start + 1  # column right after "("
    # Look at the next non-whitespace char to estimate the args indent
    i = open_paren + 1
    while i < len(text) and text[i] in " \t":
        i += 1
    if i < len(text) and text[i] == "\n":
        # Multi-line: find the indent of the first arg
        i += 1
        while i < len(text) and text[i] in " \t":
            i += 1
        line_start2 = text.rfind("\n", 0, i) + 1
        return text[line_start2:i]
    # Single-line — use 2 extra spaces of indent
    return " " * (base_col)


def fix_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    inserts: list[tuple[int, int, str]] = []  # (start, end, replacement)
    for m in TEXTSTYLE_RE.finditer(text):
        args = m.group(1)
        if not needs_fallback(args):
            continue
        # Inject right before the closing paren. Preserve indent + trailing comma style.
        indent = derive_indent(text, m.start())
        # Determine if existing args end with a trailing comma — if so, our
        # insertion needs a comma BEFORE it; if not, we don't add one.
        stripped_args = args.rstrip()
        ends_with_comma = stripped_args.endswith(",")
        # Build the injection. We always add a trailing comma for forward-compat.
        if ends_with_comma:
            injection = f"{indent}fontFamilyFallback: const ['Amiri', 'NotoColorEmoji'],\n"
        else:
            injection = f",\n{indent}fontFamilyFallback: const ['Amiri', 'NotoColorEmoji'],\n"
        # Find position right before the closing paren (matching m.group(1)'s end).
        close = m.start() + 1 + len(m.group(1))  # position of ')'
        # If the args end with whitespace before ')', insert injection just before that whitespace.
        # Walk back to find first non-whitespace before ')'.
        i = close - 1
        while i > m.start() and text[i] in " \t\n":
            i -= 1
        insert_at = i + 1  # right after last non-whitespace
        inserts.append((insert_at, insert_at, injection))

    if not inserts:
        return 0
    # Apply insertions in reverse so earlier offsets aren't shifted.
    inserts.sort(key=lambda x: -x[0])
    new_text = text
    for start, end, repl in inserts:
        new_text = new_text[:start] + ("\n" if not new_text[:start].endswith("\n") else "") + repl + new_text[end:]
    path.write_text(new_text, encoding="utf-8")
    return len(inserts)


def main() -> int:
    total = 0
    files_changed = 0
    for path in sorted(LIB.rglob("*.dart")):
        if should_skip(path):
            continue
        try:
            n = fix_file(path)
        except Exception as e:
            print(f"  WARN  {path}: {e}", file=sys.stderr)
            continue
        if n:
            files_changed += 1
            total += n
            print(f"  fixed  {n:3} TextStyle(s)  {path.relative_to(ROOT)}")
    print(f"\nInjected fontFamilyFallback into {total} TextStyles across {files_changed} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
