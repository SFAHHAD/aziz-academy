"""
Make every async method that touches _prefs!. defensive against pre-build race.

Why: After fix_late_prefs.py converted `late SharedPreferences _prefs;` to
`SharedPreferences? _prefs;` with `_prefs ??=` inside build(), setters that
use `_prefs!.foo()` still throw NullCheckError if they run before build().
Same crash, different error name.

Fix: for every async method body that contains `_prefs!`, prepend
`_prefs ??= await SharedPreferences.getInstance();` right after the opening
brace. After this line runs, `_prefs` is guaranteed non-null, so all the
existing `_prefs!.foo()` reads stay valid.

This is idempotent: the prepended line is itself `_prefs ??= ...`, so the
script skips methods that already start with that line.

The script is brace-aware: it finds method headers like `) async {`, then
walks the brace stack to find the matching `}` so it can scope the
"contains `_prefs!`" check to the method body and not bleed into the next
method.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

# Regex catches `) async {` and `) async* {` at the start of a method body.
ASYNC_HEADER = re.compile(r"\)\s*async\s*\*?\s*\{")
INIT_LINE = "_prefs ??= await SharedPreferences.getInstance();"


def find_method_bodies(text: str):
    """Yield (open_brace_idx, close_brace_idx, body_indent) for each async method.

    We locate `) async {` by regex, then walk the brace stack from the `{`
    to find the matching `}`. The body slice is `text[open+1:close]`.
    Indent is inferred from the line containing the opening brace.
    """
    for match in ASYNC_HEADER.finditer(text):
        open_idx = text.index("{", match.start())
        # Walk brace stack to find matching close.
        depth = 0
        i = open_idx
        # Skip strings/comments? For our codebase this is safe enough — Dart
        # source rarely has unbalanced braces inside strings, and we only
        # touch a known subset of files we just generated.
        while i < len(text):
            c = text[i]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    close_idx = i
                    break
            i += 1
        else:
            # Unbalanced — skip
            continue
        # Determine indent from the column of `{` (one level deeper for body).
        line_start = text.rfind("\n", 0, open_idx) + 1
        col = open_idx - line_start
        # Method body indent is the column of the brace + 2 spaces (Dart style).
        body_indent = " " * (col + 2)
        yield open_idx, close_idx, body_indent


def fix_file(path: Path) -> tuple[bool, str]:
    text = path.read_text(encoding="utf-8")
    if "_prefs!" not in text:
        return False, "no-_prefs!"
    # We rebuild text by walking method bodies in reverse so insertions don't
    # shift earlier offsets.
    methods = list(find_method_bodies(text))
    methods.reverse()
    new_text = text
    inserts = 0
    for open_idx, close_idx, indent in methods:
        body = new_text[open_idx + 1 : close_idx]
        if "_prefs!" not in body:
            continue
        # Skip if body already starts with our init line (idempotent).
        # Strip leading whitespace/newlines and check.
        body_stripped = body.lstrip("\n").lstrip(" ")
        if body_stripped.startswith("_prefs ??= await SharedPreferences"):
            continue
        # Insert the init line at the top of the body.
        injection = f"\n{indent}{INIT_LINE}"
        new_text = (
            new_text[: open_idx + 1]
            + injection
            + new_text[open_idx + 1 :]
        )
        inserts += 1

    if new_text == text:
        return False, "no-change"
    path.write_text(new_text, encoding="utf-8")
    return True, f"inserted {inserts}"


def main() -> int:
    files = sorted(LIB.rglob("*.dart"))
    targets = [
        f for f in files
        if "_prefs!" in f.read_text(encoding="utf-8")
    ]
    print(f"Found {len(targets)} files with `_prefs!`.")
    fixed = 0
    for f in targets:
        ok, status = fix_file(f)
        rel = f.relative_to(ROOT)
        print(f"  {'fixed' if ok else 'skip ':5}  {status:20}  {rel}")
        if ok:
            fixed += 1
    print(f"\nFixed {fixed}/{len(targets)} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
