"""Audit the Islamic real-audio recordings and regenerate the registry.

What this does:
  1. Walks `assets/audio/{hadith,azkar,names,dua,tajweed}/` and lists every
     `.mp3` file present.
  2. Cross-checks against the expected manifest derived from the content
     JSONs (and the in-file athkar constants).
  3. Rewrites `lib/core/services/islamic_audio_registry.dart` to expose
     the present clips at runtime.
  4. Prints a coverage report.

Run from the repo root:
    python scripts/audit_islamic_audio.py

Exit code: 0 always (partial coverage is fine — the app falls back
gracefully). Pass `--strict` to make incomplete coverage fail the build.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parent.parent
AUDIO_DIR = REPO_ROOT / "assets" / "audio"
DATA_DIR = REPO_ROOT / "assets" / "data"
REGISTRY_PATH = (
    REPO_ROOT / "lib" / "core" / "services" / "islamic_audio_registry.dart"
)
ATHKAR_PATH = REPO_ROOT / "lib" / "features" / "athkar" / "athkar_screen.dart"

CATEGORIES = ("hadith", "azkar", "names", "dua", "tajweed")


def expected_hadith() -> list[str]:
    data = json.loads(
        (DATA_DIR / "hadith_memorization.json").read_text(encoding="utf-8")
    )
    return [r["id"] for r in data]


def expected_dua() -> list[str]:
    data = json.loads(
        (DATA_DIR / "dua_memorization.json").read_text(encoding="utf-8")
    )
    return [r["id"] for r in data]


def expected_tajweed() -> list[str]:
    data = json.loads(
        (DATA_DIR / "tajweed_basics.json").read_text(encoding="utf-8")
    )
    return [r["id"] for r in data]


def expected_names() -> list[str]:
    data = json.loads(
        (DATA_DIR / "asma_ul_husna_memorization.json").read_text(
            encoding="utf-8"
        )
    )
    return [f"name_{r['n']:03d}" for r in data]


def expected_azkar() -> list[str]:
    """Athkar entries live in source code, not JSON. Count the
    `_Dhikr(` instances under the `_morning` / `_evening` const lists in
    `athkar_screen.dart` and derive `morning_NN` / `evening_NN` ids."""
    src = ATHKAR_PATH.read_text(encoding="utf-8")

    def _section_count(name: str) -> int:
        # Match `const _morning = <_Dhikr>[ ... ];`
        pattern = re.compile(
            rf"const\s+_{name}\s*=\s*<_Dhikr>\[(.*?)\];",
            re.DOTALL,
        )
        m = pattern.search(src)
        if not m:
            raise RuntimeError(
                f"Could not find _{name} list in athkar_screen.dart"
            )
        body = m.group(1)
        return body.count("_Dhikr(")

    n_morning = _section_count("morning")
    n_evening = _section_count("evening")
    ids = [f"morning_{i:02d}" for i in range(1, n_morning + 1)]
    ids += [f"evening_{i:02d}" for i in range(1, n_evening + 1)]
    return ids


EXPECTED_BY_CATEGORY = {
    "hadith": expected_hadith,
    "azkar": expected_azkar,
    "names": expected_names,
    "dua": expected_dua,
    "tajweed": expected_tajweed,
}


def present_in(category: str) -> set[str]:
    cat_dir = AUDIO_DIR / category
    if not cat_dir.is_dir():
        return set()
    return {p.stem for p in cat_dir.glob("*.mp3")}


def regenerate_registry(present_paths: Iterable[str]) -> None:
    body = "\n".join(f"  '{p}'," for p in sorted(present_paths))
    if body:
        body = "\n" + body + "\n"
    content = f"""// GENERATED FILE — do not edit by hand.
//
// Regenerate with:   python scripts/audit_islamic_audio.py
//
// This file is the runtime source of truth for which Islamic-content MP3
// clips are bundled in the build. The audit script scans
// `assets/audio/<category>/` and rewrites this set.
//
// Until the first real recordings ship the set is empty and every
// `RealAudioButton` falls back to TTS (which is itself off by default, so
// the button hides — see v1.1.96 real-audio-only policy).

/// Set of audio asset paths (without the leading `assets/`) that the build
/// is known to ship. Lookups must be case-sensitive and exact.
const Set<String> kIslamicAudioRegistry = <String>{{{body}}};

/// Returns the asset path for a given (category, id) tuple, or null if the
/// clip is not in the registry.
///
/// Example: `islamicAudioAsset('hadith', 'hdt_001')`
///   → `'audio/hadith/hdt_001.mp3'` once shipped, else `null`.
String? islamicAudioAsset(String category, String id) {{
  final path = 'audio/$category/$id.mp3';
  return kIslamicAudioRegistry.contains(path) ? path : null;
}}
"""
    REGISTRY_PATH.write_text(content, encoding="utf-8", newline="\n")


def main() -> int:
    strict = "--strict" in sys.argv

    all_present_paths: list[str] = []
    total_expected = 0
    total_present = 0
    missing_overall: list[tuple[str, str]] = []
    unknown_overall: list[tuple[str, str]] = []

    print("=== Aziz Academy -- Islamic audio audit ===\n")

    for cat in CATEGORIES:
        expected = set(EXPECTED_BY_CATEGORY[cat]())
        present = present_in(cat)
        missing = sorted(expected - present)
        unknown = sorted(present - expected)
        registered = sorted(expected & present)

        total_expected += len(expected)
        total_present += len(registered)

        for r in registered:
            all_present_paths.append(f"audio/{cat}/{r}.mp3")

        pct = (len(registered) / len(expected) * 100) if expected else 0
        print(f"{cat:>8}: {len(registered):>3} / {len(expected):>3}  ({pct:5.1f}%)")
        if unknown:
            for u in unknown:
                unknown_overall.append((cat, u))
        if missing:
            for m in missing:
                missing_overall.append((cat, m))

    pct_total = (total_present / total_expected * 100) if total_expected else 0
    print(
        f"\nTotal: {total_present} / {total_expected} clips bundled "
        f"({pct_total:.1f}%)\n"
    )

    if unknown_overall:
        print("[!] Unknown files present (will be ignored by the registry):")
        for cat, name in unknown_overall:
            print(f"  - assets/audio/{cat}/{name}.mp3")
        print()

    if missing_overall and (strict or total_present == 0):
        print("Missing clips (next batch to record):")
        for cat, name in missing_overall[:30]:
            print(f"  - assets/audio/{cat}/{name}.mp3")
        if len(missing_overall) > 30:
            print(f"  ... and {len(missing_overall) - 30} more")
        print()

    regenerate_registry(all_present_paths)
    print(
        f"[OK] Regenerated {REGISTRY_PATH.relative_to(REPO_ROOT)} "
        f"({len(all_present_paths)} entries)"
    )

    if strict and missing_overall:
        print("\n--strict: missing clips → exit 1")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
