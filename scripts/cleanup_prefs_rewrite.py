"""
Cleanup pass after fix_late_prefs.py + fix_prefs_setters.py.

Three fixes:
  1) fix_prefs_setters.py over-indented every injected `_prefs ??= ...` line
     because it inferred indent from the column of `{`, which lives at the
     end of the method header. Normalize any over-indented occurrence to
     four spaces (standard top-level method body indent in this codebase).
  2) admin_traffic.dart already had its own `_ready()` lazy-init pattern;
     the setter injection is now redundant. Remove the injected lines from
     that file specifically.
  3) `_prefsInstance()` helper is unused in every file because we inlined
     `_prefs ??= ...` at every call site. Remove the helper definitions.

This is safe to run multiple times — each step is idempotent.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

# (1) over-indented `_prefs ??= await SharedPreferences.getInstance();`
OVER_INDENT = re.compile(
    r"^[ \t]{6,}(_prefs \?\?= await SharedPreferences\.getInstance\(\);)$",
    re.MULTILINE,
)

# (3) unused helper:
#     Future<SharedPreferences> _prefsInstance() async =>
#         _prefs ??= await SharedPreferences.getInstance();
HELPER_BLOCK = re.compile(
    r"\n[ \t]*Future<SharedPreferences>\s+_prefsInstance\(\)\s+async\s*=>\s*\n"
    r"[ \t]*_prefs \?\?= await SharedPreferences\.getInstance\(\);\s*\n",
)


def normalize_indent(text: str) -> tuple[str, int]:
    new = OVER_INDENT.sub(r"    \1", text)
    n = len(OVER_INDENT.findall(text))
    return new, n


def remove_helper(text: str) -> tuple[str, int]:
    new, n = HELPER_BLOCK.subn("\n", text)
    return new, n


def revert_admin_traffic(text: str) -> tuple[str, int]:
    """admin_traffic already calls `await _ready();` — drop the injected line."""
    pattern = re.compile(
        r"^[ \t]+_prefs \?\?= await SharedPreferences\.getInstance\(\);\s*\n"
        r"([ \t]*await _ready\(\);)",
        re.MULTILINE,
    )
    new, n = pattern.subn(r"\1", text)
    return new, n


def main() -> int:
    indent_total = 0
    helper_total = 0
    admin_total = 0
    files_touched = 0

    for path in sorted(LIB.rglob("*.dart")):
        original = path.read_text(encoding="utf-8")
        text = original
        i_n = h_n = a_n = 0

        if path.name == "admin_traffic.dart":
            text, a_n = revert_admin_traffic(text)
            admin_total += a_n

        text, i_n = normalize_indent(text)
        indent_total += i_n

        text, h_n = remove_helper(text)
        helper_total += h_n

        if text != original:
            path.write_text(text, encoding="utf-8")
            files_touched += 1
            print(
                f"  {path.relative_to(ROOT)}: "
                f"indent={i_n}  helper={h_n}  admin={a_n}"
            )

    print(
        f"\nTouched {files_touched} files. "
        f"Total: indent fixes={indent_total}, helpers removed={helper_total}, "
        f"admin_traffic injections reverted={admin_total}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
