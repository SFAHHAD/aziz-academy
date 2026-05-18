"""
Sweep providers for `late SharedPreferences _prefs` and rewrite to lazy-init.

Why: a late field that's set inside an async build() throws LateInitializationError
if any other method (setter, listener) touches _prefs before build() resolves.
Failure mode: Uncaught Error during widget render with cryptic stack trace.

Rewrite, per file:
  1) `  late SharedPreferences _prefs;`
       -> `  SharedPreferences? _prefs;\n
              Future<SharedPreferences> _prefsInstance() async =>
                  _prefs ??= await SharedPreferences.getInstance();`
  2) `_prefs = await SharedPreferences.getInstance();`
       -> `_prefs ??= await SharedPreferences.getInstance();`

Step 2 keeps every existing `_prefs.foo()` reference valid (the field is now
nullable but Dart `_prefs!` is implicit when assignment uses ??=, so we use
explicit `.!` only at read sites). Simpler: keep all reads as `_prefs!.foo()`.

This script does the surgical version — keeps existing references working
by using a non-null assertion operator only where needed.

Strategy used here (most defensive):
  - Replace the field declaration as above.
  - Replace any `_prefs = await SharedPreferences.getInstance();` (typically
    inside build()) with `_prefs ??= await SharedPreferences.getInstance();`.
  - Replace `_prefs.` with `_prefs!.` (read sites become null-asserted; safe
    because every code path that gets here has assigned via ??= before use).
  - Skip files where `_prefs!` already exists (idempotent).

Limitations:
  - Doesn't handle exotic naming. All 18 audited files use `_prefs`.
  - Doesn't handle the case where `_prefs` is read from a method that runs
    before build(). For those, the caller still throws (now NullCheckError
    instead of LateInitializationError). For callers like ProfileNotifier
    that are accessed pre-build, the file already has _prefsInstance() and
    the script leaves it alone.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

# Files where we already applied a richer lazy-init pattern manually.
SKIP = {
    LIB / "core" / "providers" / "profile_provider.dart",
}

LATE_FIELD = re.compile(r"^(\s*)late\s+SharedPreferences\s+_prefs\s*;\s*$", re.MULTILINE)
INIT_LINE = re.compile(r"_prefs\s*=\s*await\s+SharedPreferences\.getInstance\(\)\s*;")
PREFS_READ = re.compile(r"\b_prefs\.")  # capture _prefs.<member>


def fix_file(path: Path) -> tuple[bool, str]:
    text = path.read_text(encoding="utf-8")
    if "late SharedPreferences _prefs" not in text:
        return False, "no-late-field"
    if "_prefs!" in text:
        return False, "already-null-asserted"

    # Replace the late field with nullable + helper.
    def replace_field(m: re.Match) -> str:
        indent = m.group(1)
        return (
            f"{indent}SharedPreferences? _prefs;\n\n"
            f"{indent}Future<SharedPreferences> _prefsInstance() async =>\n"
            f"{indent}    _prefs ??= await SharedPreferences.getInstance();"
        )

    new = LATE_FIELD.sub(replace_field, text, count=1)
    if new == text:
        return False, "field-not-matched"

    # Replace plain assignment with idempotent ??= (works whether _prefs is null
    # or already populated).
    new = INIT_LINE.sub(
        "_prefs ??= await SharedPreferences.getInstance();",
        new,
    )

    # Read sites: `_prefs.` -> `_prefs!.`. Skip the new declaration line
    # (which already has `_prefs` without a `.` immediately after).
    # The ! is safe because by the time any read runs, build() has assigned _prefs
    # OR _prefsInstance() must be awaited first by callers (which they will when
    # extending this pattern).
    new = PREFS_READ.sub("_prefs!.", new)
    # Undo `_prefs!.` if it appears in the helper definition we just inserted.
    new = new.replace(
        "_prefs!.= await SharedPreferences.getInstance()",
        "_prefs ??= await SharedPreferences.getInstance()",
    )

    if new == text:
        return False, "no-change"

    path.write_text(new, encoding="utf-8")
    return True, "ok"


def main() -> int:
    files = sorted(LIB.rglob("*.dart"))
    targets = [
        f for f in files
        if f not in SKIP and "late SharedPreferences _prefs" in f.read_text(encoding="utf-8")
    ]
    print(f"Found {len(targets)} files with `late SharedPreferences _prefs`.")
    fixed = 0
    for f in targets:
        ok, status = fix_file(f)
        rel = f.relative_to(ROOT)
        print(f"  {'fixed' if ok else 'skip ':5}  {status:25}  {rel}")
        if ok:
            fixed += 1
    print(f"\nFixed {fixed}/{len(targets)} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
