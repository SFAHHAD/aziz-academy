#!/usr/bin/env python3
"""
One-off rewriter that converts direct screen imports in app_router.dart to
deferred imports, and wraps their `builder:` calls in `_DeferredLoader`.

Run once, review the diff, commit. Skips screens listed in KEEP_DIRECT —
those stay direct because they're on the kid's primary path.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROUTER = Path("lib/core/router/app_router.dart")

# Screens we keep direct in main.dart.js. These are either tiny, on the
# primary kid path, or otherwise eager-load critical.
KEEP_DIRECT = {
    "splash_screen",
    "home_screen",
    "trophy_room_screen",
    "certificate_screen",
    "capitals_screen",
    "flags_screen",
    "math_screen",
    "sciences_screen",
    "daily_challenge_screen",
    "general_quiz_screen",
    "privacy_policy_screen",
    "about_screen",
    "install_guide_screen",
    "homework_helper_screen",
    "welcome_screen",
    "favorites_screen",
    "edit_profile_screen",
    "family_profiles_screen",
}

# Screen file → (alias, ScreenClass). The screen file is the basename
# without .dart. We auto-derive ScreenClass from the file name in
# CamelCase, but a few exceptions need explicit mapping.
CLASS_OVERRIDES: dict[str, str] = {
    # quran_screen.dart actually exports `QuranScreen`. (default mapping is fine)
    # alphabet/arabic_alphabet_screen.dart → ArabicAlphabetScreen (default ok)
    # ones that don't follow snake-to-camel exactly:
    "two_thousand_screen": "TwoThousandScreen",
    "tic_tac_toe_screen": "TicTacToeScreen",
}


def to_class_name(file_stem: str) -> str:
    if file_stem in CLASS_OVERRIDES:
        return CLASS_OVERRIDES[file_stem]
    return "".join(part.capitalize() for part in file_stem.split("_"))


def main() -> int:
    src = ROUTER.read_text(encoding="utf-8")

    # Match direct imports of feature screens that aren't already deferred.
    # Format: import 'package:aziz_academy/features/<dir>/.../<file>_screen.dart';
    import_re = re.compile(
        r"^import\s+'package:aziz_academy/features/([^']+)/([a-z0-9_]+_screen)\.dart';$",
        re.MULTILINE,
    )

    converted: list[tuple[str, str, str]] = []  # (file_stem, alias, class)
    new_src = src

    for m in import_re.finditer(src):
        path_dir = m.group(1)
        file_stem = m.group(2)  # e.g. snake_screen
        if file_stem in KEEP_DIRECT:
            continue
        alias = f"{file_stem}_def"
        cls = to_class_name(file_stem)
        old_line = m.group(0)
        new_line = (
            f"import 'package:aziz_academy/features/{path_dir}/"
            f"{file_stem}.dart'\n    deferred as {alias};"
        )
        new_src = new_src.replace(old_line, new_line, 1)
        converted.append((file_stem, alias, cls))

    print(f"Converted {len(converted)} screen imports to deferred.")

    # Now wrap the matching builder calls. Pattern:
    #   builder: (context, state) => const SnakeScreen(),
    # → builder: (context, state) => _DeferredLoader(
    #       load: snake_screen_def.loadLibrary,
    #       builder: () => snake_screen_def.SnakeScreen(),
    #     ),
    for file_stem, alias, cls in converted:
        old = f"builder: (context, state) => const {cls}(),"
        new = (
            f"builder: (context, state) => _DeferredLoader(\n"
            f"        load: {alias}.loadLibrary,\n"
            f"        builder: () => {alias}.{cls}(),\n"
            f"      ),"
        )
        if old in new_src:
            new_src = new_src.replace(old, new, 1)
        else:
            print(f"  WARN: builder for {cls} not found via simple pattern", file=sys.stderr)

    if new_src == src:
        print("Nothing changed. Either everything is already deferred, or no matches found.")
        return 0

    ROUTER.write_text(new_src, encoding="utf-8")
    print(f"Wrote {ROUTER}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
