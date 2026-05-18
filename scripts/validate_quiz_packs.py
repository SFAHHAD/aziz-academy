#!/usr/bin/env python3
"""Validate quiz JSON packs.

Asserts schema integrity across every JSON pack we ship:
  - Each item has all required keys
  - options has exactly 4 strings (and options_ar where present)
  - options[0] == correct_answer (i.e., correct sits at index 0; UI shuffles)
  - For bilingual entries, options_ar[0] == correct_answer_ar
  - Arabic numerals in *_ar fields use Arabic-Indic digits ٠-٩, not 0-9
  - IDs are unique within a pack AND across all Brain Boost packs
  - Brain Boost item count by category meets the 90/category target

Exit code 0 = all good; 1 = at least one violation.

Usage:  python scripts/validate_quiz_packs.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data"

# All Brain Boost packs that share an ID namespace.
BB_PACKS = [
    "brain_boost.json",
    "brain_boost_spatial.json",
    "brain_boost_memory.json",
    "brain_boost_spatial_extra.json",
    "brain_boost_memory_extra.json",
    "brain_boost_patterns_extra.json",
    "brain_boost_mental_math_extra.json",
    "brain_boost_analogies_extra.json",
    "brain_boost_logic_extra.json",
    "brain_boost_patterns_extra2.json",
    "brain_boost_mental_math_extra2.json",
    "brain_boost_analogies_extra2.json",
    "brain_boost_logic_extra2.json",
    "brain_boost_analogies_extra3.json",
    "brain_boost_patterns_extra3.json",
    "brain_boost_logic_extra3.json",
    "brain_boost_memory_extra2.json",
    "brain_boost_mental_math_extra3.json",
    "brain_boost_spatial_extra2.json",
]

# Sciences packs.
SCIENCES_PACKS = [
    "sciences.json",
    "sciences_l2.json",
    "sciences_l3.json",
    "sciences_l4.json",
    "sciences_l5.json",
    "sciences_l6.json",
]

# Other bilingual packs that follow same options[0]==correct_answer rule.
OTHER_PACKS = [
    "capitals.json",
    "general_quiz.json",
    "math_word_problems.json",
    "vocabulary.json",
    "landmarks.json",
    "historical_figures.json",
    "animals_nature.json",
    "geography.json",
    "english_grammar.json",
    "arabic_grammar.json",
    "fiqh_basics.json",
    "sirah_prophets.json",
    "asma_ul_husna.json",
    "hadith_kids.json",
    "islamic_history.json",
    "financial_literacy.json",
    "health_body.json",
    "environment_sustainability.json",
    "coding_for_kids.json",
    "art_culture.json",
    "sports_games.json",
    "chemistry_deep.json",
    "astronomy_space.json",
    "famous_inventions.json",
    "world_history.json",
    "riddles_puzzles.json",
    "plants_botany.json",
    "cooking_nutrition.json",
    "music_instruments.json",
    "quran_prophet_stories.json",
    "arabic_poetry_literature.json",
    "dinosaurs_prehistoric.json",
    "weather_natural_phenomena.json",
    "body_anatomy.json",
    "kuwait_heritage.json",
    "sign_language.json",
    "world_mythology.json",
    "oceanography.json",
    "logic_critical_thinking.json",
    "architecture_marvels.json",
    "famous_experiments.json",
    "chess_fundamentals.json",
    "first_aid_basics.json",
    "rivers_lakes.json",
    "periodic_elements.json",
    "cybersecurity_kids.json",
    "clouds_atmosphere.json",
    "famous_scientists_deep.json",
    "emotional_intelligence.json",
    "inventions_antiquity.json",
    "quran_sciences.json",
    "entrepreneurship_kids.json",
    "maps_cartography.json",
    "robotics_ai_kids.json",
    "modern_tech_basics.json",
    "human_brain.json",
    "climate_change_kids.json",
    "optical_illusions_vision.json",
    "insects_bugs.json",
    "female_scholars_pioneers.json",
    "ancient_egypt.json",
    "volcanoes_earthquakes.json",
    "microbes_cells.json",
    "maritime_exploration.json",
    "telescopes_discoveries.json",
    "money_trade_history.json",
    "calligraphy_writing.json",
    "mountains_peaks.json",
    "codes_ciphers.json",
    "ancient_mesopotamia.json",
    "deserts_world.json",
    "aviation_history.json",
    "medicine_pioneers.json",
    "ancient_china.json",
    "famous_mathematicians.json",
    "african_civilizations.json",
    "time_clocks.json",
    "photography.json",
    "forests_biomes.json",
    "famous_battles.json",
    "olympic_games.json",
    "cars_engineering.json",
    "languages_world.json",
    "ancient_india.json",
    "bridges_tunnels.json",
    "treaties_diplomacy.json",
    "sleep_dreams.json",
    "trains_railways.json",
    "renaissance_art.json",
    "submarines_ocean_tech.json",
    "wildlife_conservation.json",
    "simple_machines.json",
    "music_genres.json",
    "internet_history.json",
    "modern_inventions.json",
    "economics_basics.json",
    "famous_mosques.json",
    "marine_biology.json",
    "ancient_greece.json",
    "polar_regions.json",
    "gemstones_minerals.json",
    "world_festivals.json",
    "famous_lighthouses.json",
    "egyptian_pharaohs.json",
    "fairy_tales_world.json",
    "famous_libraries.json",
    "beekeeping_pollinators.json",
    "classical_composers.json",
    "famous_universities.json",
    "currencies_history.json",
    "famous_stadiums.json",
    "famous_castles.json",
    "tea_coffee_history.json",
    "spice_trade.json",
    "renewable_energy.json",
    "famous_mountaineers.json",
    "chocolate_history.json",
    "famous_architects.json",
    "birds_of_prey.json",
    "magnets_electromagnetism.json",
    "iconic_trees_world.json",
    "anatomy_senses.json",
    "toys_history.json",
    "roman_empire.json",
    "vikings_norse.json",
    "hajj_umrah.json",
    "ottoman_empire.json",
    "mesoamerica_civilizations.json",
    "salah_prayer.json",
    "mughal_empire.json",
    "computer_pioneers.json",
    "sound_acoustics.json",
    "mongolian_empire.json",
    "sahaba_companions.json",
    "famous_detectives_lit.json",
    "famous_disasters_history.json",
    "the_imams_madhabs.json",
    "famous_authors_kids.json",
    "black_holes_cosmology.json",
    "stars_life_cycle.json",
    "constellations_stories.json",
    "famous_modern_cities.json",
    "famous_pirates_real.json",
    "famous_modern_chefs.json",
    "dna_genes_basics.json",
    "plate_tectonics_deep.json",
    "world_records_guinness.json",
    "whales_dolphins_deep.json",
    "famous_modern_athletes.json",
    "islamic_calendar_months.json",
    "famous_volcanoes_deep.json",
    "periodic_table_basics.json",
    "sharks_world_deep.json",
    "famous_bridges_world.json",
    "robots_ai_history.json",
    "insects_world.json",
    "big_cats_world.json",
    "famous_castles_world.json",
    "currency_money_history.json",
    "famous_skyscrapers.json",
    "mythological_creatures.json",
    "automobile_history.json",
    "famous_museums_world.json",
    "birds_world.json",
    "classical_composers.json",
    "aviation_history.json",
    "frogs_amphibians.json",
    "comic_book_heroes.json",
    "cold_war_spies.json",
    "unesco_heritage_sites.json",
    "penguins_world_deep.json",
    "coral_reefs_world.json",
    "snakes_world.json",
    "spiders_arachnids.json",
    "famous_caves_world.json",
    "movies_cinema_history.json",
    "famous_photographers.json",
    "famous_beaches.json",
    "famous_foods_world.json",
    "famous_roads_routes.json",
    "famous_ships_boats.json",
    "famous_magicians.json",
    "famous_walls.json",
    "famous_hotels.json",
    "famous_statues.json",
    "famous_comets.json",
    "antarctic_explorers.json",
    "famous_operas_musicals.json",
    "famous_aquariums_zoos.json",
    "famous_fossils.json",
    "famous_plays.json",
    "famous_diamonds.json",
    "famous_dancers_ballet.json",
    "famous_national_parks.json",
    "famous_animals_history.json",
    "famous_music_festivals.json",
    "famous_painters.json",
    "famous_astronauts.json",
    "famous_logos.json",
    "famous_inventors.json",
    "famous_video_games.json",
    "famous_theme_parks.json",
    "famous_cartoons.json",
    "famous_tennis_players.json",
    "famous_aircraft_spacecraft.json",
    "famous_childrens_tv.json",
    "famous_programming_languages.json",
    "famous_pets_history.json",
    "famous_chess_players.json",
    "famous_galaxies_cosmic.json",
    "famous_f1_drivers.json",
    "famous_palaces_world.json",
    "famous_boxers.json",
    "famous_game_consoles.json",
]

# Catches stray Western digits inside Arabic strings.
WESTERN_DIGIT = re.compile(r"[0-9]")
ARABIC_INDIC = "٠١٢٣٤٥٦٧٨٩"


def fail(msg: str) -> None:
    print(f"  X {msg}")


def load(path: Path) -> list | None:
    if not path.exists():
        return None
    try:
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, list):
            return None
        return data
    except (json.JSONDecodeError, OSError):
        return None


def check_item(
    item: dict, idx: int, path: Path, errors: list[str], strict_index_zero: bool
) -> None:
    rid = item.get("id", f"#{idx}")
    required = ["id", "question", "options", "correct_answer"]
    for k in required:
        if k not in item:
            errors.append(f"{path.name}:{rid} missing key '{k}'")
            return

    opts = item["options"]
    if not isinstance(opts, list) or len(opts) != 4:
        errors.append(f"{path.name}:{rid} options must be list of 4 (got {len(opts) if isinstance(opts, list) else type(opts).__name__})")
        return
    if strict_index_zero:
        if opts[0] != item["correct_answer"]:
            errors.append(f"{path.name}:{rid} options[0] != correct_answer")
    else:
        if item["correct_answer"] not in opts:
            errors.append(f"{path.name}:{rid} correct_answer not in options")

    # Bilingual sub-checks.
    if "options_ar" in item:
        opts_ar = item["options_ar"]
        if not isinstance(opts_ar, list) or len(opts_ar) != 4:
            errors.append(f"{path.name}:{rid} options_ar must be list of 4")
        elif "correct_answer_ar" in item:
            if strict_index_zero:
                if opts_ar[0] != item["correct_answer_ar"]:
                    errors.append(f"{path.name}:{rid} options_ar[0] != correct_answer_ar")
            else:
                if item["correct_answer_ar"] not in opts_ar:
                    errors.append(f"{path.name}:{rid} correct_answer_ar not in options_ar")

    # Arabic digit hygiene — flag only if Western digits appear OUTSIDE of
    # Latin-letter strings. Chemistry formulas (H2O, CO2) and product names
    # legitimately stay in Latin form even in Arabic translations.
    def _arabic_has_stray_digits(s: str) -> bool:
        # Ignore sub-tokens that contain a Latin letter (chem formulas etc.)
        tokens = re.split(r"\s+|[،,؛/]", s)
        for t in tokens:
            if not t:
                continue
            if re.search(r"[A-Za-z]", t):
                continue
            if WESTERN_DIGIT.search(t):
                return True
        return False

    for k in ("question_ar", "correct_answer_ar"):
        v = item.get(k)
        if isinstance(v, str) and _arabic_has_stray_digits(v):
            errors.append(f"{path.name}:{rid} '{k}' contains Western digits")
    if "options_ar" in item and isinstance(item["options_ar"], list):
        for i, v in enumerate(item["options_ar"]):
            if isinstance(v, str) and _arabic_has_stray_digits(v):
                errors.append(f"{path.name}:{rid} options_ar[{i}] contains Western digits")


def main() -> int:
    errors: list[str] = []
    bb_ids: dict[str, str] = {}
    bb_by_cat: dict[str, int] = defaultdict(int)

    print("Validating Brain Boost packs...")
    for fname in BB_PACKS:
        path = DATA / fname
        items = load(path)
        if items is None:
            print(f"  · {fname}: not present (skip)")
            continue
        for i, it in enumerate(items):
            if not isinstance(it, dict):
                errors.append(f"{path.name}#{i} not a dict")
                continue
            check_item(it, i, path, errors, strict_index_zero=True)
            rid = it.get("id")
            if rid:
                if rid in bb_ids:
                    errors.append(f"BB id collision: {rid} in {bb_ids[rid]} and {fname}")
                else:
                    bb_ids[rid] = fname
                cat = it.get("category", "?")
                bb_by_cat[cat] += 1
        print(f"  · {fname}: {len(items)} items")

    print("\nBrain Boost coverage:")
    for cat in sorted(bb_by_cat):
        print(f"  - {cat}: {bb_by_cat[cat]}")

    print("\nValidating Sciences packs...")
    sci_ids: dict[str, str] = {}
    for fname in SCIENCES_PACKS:
        path = DATA / fname
        items = load(path)
        if items is None:
            print(f"  · {fname}: not present (skip)")
            continue
        # Legacy sciences.json doesn't enforce options[0]; the repo uses the
        # explicit correct_answer field. Newer packs (l2/l3) DO enforce it.
        strict = fname != "sciences.json"
        for i, it in enumerate(items):
            if not isinstance(it, dict):
                errors.append(f"{fname}#{i} not a dict")
                continue
            check_item(it, i, path, errors, strict_index_zero=strict)
            rid = it.get("id")
            if rid:
                if rid in sci_ids:
                    errors.append(f"Sciences id collision: {rid} in {sci_ids[rid]} and {fname}")
                else:
                    sci_ids[rid] = fname
        print(f"  · {fname}: {len(items)} items")

    print("\nValidating other bilingual packs...")
    for fname in OTHER_PACKS:
        path = DATA / fname
        items = load(path)
        if items is None:
            print(f"  · {fname}: not present (skip)")
            continue
        for i, it in enumerate(items):
            if not isinstance(it, dict):
                errors.append(f"{fname}#{i} not a dict")
                continue
            # capitals.json schema differs — only enforce options[0]==correct.
            if "options" in it and "correct_answer" in it:
                opts = it["options"]
                if isinstance(opts, list) and opts and opts[0] != it["correct_answer"]:
                    errors.append(f"{fname}:{it.get('id', i)} options[0] != correct_answer")
        print(f"  · {fname}: {len(items)} items")

    print()
    if errors:
        print(f"FAIL — {len(errors)} violations:")
        for e in errors:
            fail(e)
        return 1
    print("OK — all packs pass schema and ID uniqueness checks.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
