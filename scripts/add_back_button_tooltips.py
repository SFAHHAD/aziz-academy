"""
Add `tooltip:` to IconButton widgets whose icon is a back-arrow variant.

Why: 168 IconButtons across the app currently lack a tooltip. For
screen-reader users, IconButton's accessibility name comes from `tooltip`
— without it, kids using assistive tech hear "button, button, button"
with no indication of what each does.

Scope: just the back-arrow buttons for now (most common pattern, single
shared label `commonBack` works for all of them). Other IconButtons need
context-specific tooltips and should be done manually.

Match patterns:
  1. IconButton(
       icon: Icon(isAr ? Icons.arrow_forward... : Icons.arrow_back...),
       onPressed: ...,
     )
  2. IconButton(
       onPressed: ...,
       icon: const Icon(Icons.arrow_back_rounded),
     )
  3. Variants of (1)/(2) with `Directionality.of(context) == TextDirection.rtl`

Action: insert `tooltip: context.l10n.commonBack,` as the first arg.

Skip:
  - admin/diag/dev (English-only)
  - Files where tooltip already present in the matched IconButton
  - Files already importing context_ext.dart (will already have l10n in scope)
  - We add the import if missing
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
EXT_IMPORT = "import 'package:aziz_academy/core/l10n/context_ext.dart';"

# Regex: open-paren of IconButton, capture everything up to matching close-paren.
# We use a simpler approach: find IconButton( and walk parens manually so we
# don't get fooled by nested parens.
ICONBUTTON = re.compile(r'\bIconButton\s*\(')


def find_iconbutton_blocks(text: str):
    """Yield (open_idx, close_idx, body) for each balanced IconButton(...)."""
    for m in ICONBUTTON.finditer(text):
        open_idx = m.end() - 1  # position of '('
        depth = 0
        i = open_idx
        in_string = None  # track ' or " or null
        while i < len(text):
            c = text[i]
            # Naive string skipping (good enough for Dart in this repo)
            if in_string:
                if c == in_string and text[i - 1] != '\\':
                    in_string = None
            elif c in "'\"":
                in_string = c
            elif c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0:
                    body = text[open_idx + 1: i]
                    yield m.start(), open_idx, i, body
                    break
            i += 1


def is_back_button(body: str) -> bool:
    """Heuristic: matches if the body references arrow_back or arrow_forward
    icons (the directional-back pattern uses both)."""
    return ('arrow_back' in body) or ('arrow_forward' in body)


def has_tooltip(body: str) -> bool:
    return 'tooltip:' in body


def file_needs_skip(p: Path) -> bool:
    s = str(p).replace("\\", "/").lower()
    return any(x in s for x in ('/admin/', '/diag', '/dev/'))


def patch_file(path: Path) -> int:
    text = path.read_text(encoding='utf-8')
    blocks = list(find_iconbutton_blocks(text))
    if not blocks:
        return 0
    # Filter to back-button blocks without existing tooltip
    targets = [
        (start, open_idx, close_idx, body)
        for start, open_idx, close_idx, body in blocks
        if is_back_button(body) and not has_tooltip(body)
    ]
    if not targets:
        return 0

    # Apply patches in reverse offset order
    targets.reverse()
    new_text = text
    inserts = 0
    for start, open_idx, close_idx, body in targets:
        # Find indentation of the line containing the open paren
        line_start = new_text.rfind('\n', 0, open_idx) + 1
        # Indent of the IconButton itself; args go 2 spaces deeper
        ib_indent = len(new_text[line_start:start]) - len(new_text[line_start:start].lstrip())
        # Use 2 extra spaces for the tooltip arg
        args_indent = ' ' * (ib_indent + 2)
        # Insert tooltip immediately after the open paren, on a new line
        injection = f"\n{args_indent}tooltip: context.l10n.commonBack,"
        new_text = new_text[:open_idx + 1] + injection + new_text[open_idx + 1:]
        inserts += 1

    if new_text == text:
        return 0

    # Ensure context_ext.dart is imported
    if EXT_IMPORT not in new_text:
        lines = new_text.split('\n')
        last_import = -1
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import = i
        if last_import != -1:
            lines.insert(last_import + 1, EXT_IMPORT)
            new_text = '\n'.join(lines)

    path.write_text(new_text, encoding='utf-8')
    return inserts


def main() -> int:
    total = 0
    files_changed = 0
    for path in sorted(LIB.rglob('*.dart')):
        if file_needs_skip(path):
            continue
        n = patch_file(path)
        if n > 0:
            files_changed += 1
            total += n
            print(f"  {n:3} tooltip(s)  {path.relative_to(ROOT)}")
    print(f"\nAdded {total} back-button tooltips across {files_changed} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
