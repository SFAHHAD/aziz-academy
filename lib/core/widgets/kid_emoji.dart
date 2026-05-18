import 'package:flutter/material.dart';

/// Renders an AI-generated PNG emoji from `assets/images/emojis/<name>.png`,
/// falling back to the matching Unicode character if the asset is missing.
///
/// **Why a custom widget instead of `Image.asset` directly:**
/// - The migration is incremental — assets get generated and dropped in over
///   time, but the UI must keep working before each one lands. The fallback
///   to the Unicode char makes the widget safe to ship at every step.
/// - Semantic labels for accessibility happen in one place.
/// - One day we may swap the asset format (e.g. SVG, animated WebP) — only
///   one widget needs to change.
///
/// **Where to use:** prominent UI emojis (home tiles, badges, reward
/// feedback). NOT inline question content (educational text where mixing
/// images into a sentence would mis-align).
///
/// **Asset spec** (see EMOJI_PROMPT_TEMPLATE.md):
///   - 256×256 PNG, transparent background
///   - Navy `#0F2C5C` + gold `#D4AF37` palette (matches Stitch theme)
///   - Flat illustrated, kid-friendly (not babyish), age 6-12
class KidEmoji extends StatelessWidget {
  const KidEmoji({
    super.key,
    required this.name,
    required this.fallbackChar,
    this.size = 32,
    this.semanticLabel,
  });

  /// Asset stem — the file is loaded as `assets/images/emojis/$name.png`.
  final String name;

  /// Unicode emoji char rendered when the asset is missing. Lets us migrate
  /// one PNG at a time without breaking the UI.
  final String fallbackChar;

  final double size;
  final String? semanticLabel;

  /// Convenience for the most-used emojis. Keeps call sites short and stops
  /// each caller from having to remember the matching Unicode fallback.
  ///
  /// Example: `KidEmoji.named('coin', size: 48)`
  static Widget named(
    String alias, {
    double size = 32,
    String? semanticLabel,
    Key? key,
  }) {
    final fallback = _aliases[alias];
    assert(
      fallback != null,
      'Unknown KidEmoji alias: "$alias". Add it to KidEmoji._aliases or use '
      'the full constructor with explicit fallbackChar.',
    );
    return KidEmoji(
      key: key,
      name: alias,
      fallbackChar: fallback ?? '?',
      size: size,
      semanticLabel: semanticLabel ?? alias,
    );
  }

  // 292 aliases — every emoji that appears anywhere in lib/ Dart UI code,
  // each mapped to its Unicode-emoji fallback. Multiple keys can map to the
  // same emoji (e.g. 'coin' AND 'coin'; 'check' AND 'white_heavy_check_mark'),
  // so the widget loads `$name.png` regardless of which naming the AI used
  // when generating the asset file.
  // Generated from EMOJI_MIGRATION_MANIFEST.csv via scripts/build_emoji_alias_map.py.
  // To regenerate: rerun the catalog script, then paste the output here.
  static const Map<String, String> _aliases = {
    'abacus': '🧮', 'adult': '🧑', 'alembic': '⚗', 'american_football': '🏈',
    'amphora': '🏺', 'anticlockwise_downwards_and_upwards_open': '🔄',
    'art_palette': '🎨', 'artist_palette': '🎨', 'atom_symbol': '⚛',
    'automobile': '🚗', 'baby_chick': '🐤', 'balloon': '🎈', 'ballot_x': '✗',
    'banana': '🍌', 'bar_chart': '📊', 'baseball': '⚾', 'basket': '🧺',
    'basketball_and_hoop': '🏀', 'bear_face': '🐻', 'beaver': '🦫',
    'billiards': '🎱', 'bird': '🐦', 'birthday_cake': '🎂',
    'black_club_suit': '♣', 'black_diamond_suit': '♦', 'black_heart_suit': '♥',
    'black_question_mark_ornament': '❓', 'black_spade_suit': '♠',
    'black_sun_with_rays': '☀', 'bomb': '💣', 'bone': '🦴', 'book': '📖',
    'books': '📚', 'bowling': '🎳', 'boy': '👦', 'brain': '🧠', 'brick': '🧱',
    'bridge_at_night': '🌉', 'bubbles': '🫧', 'building_construction': '🏗',
    'bust_in_silhouette': '👤', 'butterfly': '🦋', 'cactus': '🌵',
    'calendar': '📅', 'card_index_dividers': '🗂', 'cat_face': '🐱',
    'chart': '📊', 'chart_with_upwards_trend': '📈', 'check': '✅',
    'check_mark': '✓', 'cherries': '🍒', 'cherry_blossom': '🌸',
    'chicken': '🐔', 'child': '🧒', 'clapping_hands_sign': '👏',
    'classical_building': '🏛', 'clipboard': '📋', 'clock': '🕘',
    'clock_face_nine_oclock': '🕘', 'clock_face_three_oclock': '🕒',
    'cloud': '☁', 'cloud_with_rain': '🌧', 'coin': '🪙', 'collision': '💥',
    'collision_symbol': '💥', 'comet': '☄', 'compass': '🧭',
    'confetti_ball': '🎊', 'confused_face': '😕', 'cow_face': '🐮',
    'crab': '🦀', 'crescent_moon': '🌙', 'cross': '❌', 'cross_mark': '❌',
    'crown': '👑', 'crying': '😢', 'crying_face': '😢', 'crystal_ball': '🔮',
    'cup_with_straw': '🥤', 'cyclone': '🌀', 'deciduous_tree': '🌳',
    'desert': '🏜', 'direct_hit': '🎯', 'dna_double_helix': '🧬',
    'dodo': '🦤', 'dog_face': '🐶', 'dolphin': '🐬', 'dragon': '🐉',
    'dragon_face': '🐲', 'droplet': '💧', 'eagle': '🦅', 'earth': '🌍',
    'earth_globe_americas': '🌎', 'earth_globe_asia_australia': '🌏',
    'earth_globe_europe_africa': '🌍', 'electric_light_bulb': '💡', 'eye': '👁',
    'face_with_look_of_triumph': '😤', 'family': '👪', 'fencer': '🤺',
    'film_frames': '🎞', 'fire': '🔥', 'first_place_medal': '🥇', 'flag': '🚩',
    'flexed_biceps': '💪', 'flower_playing_cards': '🎴', 'fox': '🦊',
    'fox_face': '🦊', 'frame_with_picture': '🖼', 'frog_face': '🐸',
    'game_die': '🎲', 'gear': '⚙', 'gem_stone': '💎', 'giraffe_face': '🦒',
    'girl': '👧', 'globe_americas': '🌎', 'globe_asia': '🌏',
    'globe_with_meridians': '🌐', 'gloves': '🧤', 'glowing_star': '🌟',
    'goal_net': '🥅', 'graduation': '🎓', 'graduation_cap': '🎓',
    'grapes': '🍇', 'hammer_and_wrench': '🛠', 'hamster_face': '🐹',
    'handshake': '🤝', 'heart': '❤️', 'heavy_black_heart': '❤',
    'heavy_division_sign': '➗', 'heavy_equals_sign': '🟰',
    'heavy_multiplication_x': '✖', 'heavy_plus_sign': '➕', 'herb': '🌿',
    'high_voltage_sign': '⚡', 'honeybee': '🐝', 'hot_beverage': '☕',
    'hot_pepper': '🌶', 'ice_cube': '🧊', 'incoming_envelope': '📨',
    'input_symbol_for_latin_letters': '🔤',
    'input_symbol_for_latin_small_letters': '🔡',
    'input_symbol_for_numbers': '🔢', 'input_symbol_for_symbols': '🔣',
    'japanese_castle': '🏯', 'japanese_ogre': '👹', 'jar': '🫙',
    'jigsaw_puzzle_piece': '🧩', 'kangaroo': '🦘', 'keycap_ten': '🔟',
    'kiwifruit': '🥝', 'knot': '🪢', 'koala': '🐨', 'label': '🏷',
    'lady_beetle': '🐞', 'large_blue_circle': '🔵', 'large_blue_diamond': '🔷',
    'large_blue_square': '🟦', 'large_green_circle': '🟢',
    'large_orange_diamond': '🔶', 'large_purple_circle': '🟣',
    'large_purple_square': '🟪', 'large_red_circle': '🔴',
    'large_red_square': '🟥', 'large_yellow_circle': '🟡',
    'left_pointing_magnifying_glass': '🔍', 'lemon': '🍋', 'lightbulb': '💡',
    'lightning': '⚡', 'lion_face': '🦁', 'lock': '🔒', 'mage': '🧙',
    'magic_wand': '🪄', 'magnifier': '🔍', 'man': '👨', 'medal': '🏅',
    'medium_black_circle': '⚫', 'medium_white_circle': '⚪', 'memo': '📝',
    'microscope': '🔬', 'milky_way': '🌌', 'mobile_phone': '📱',
    'monkey_face': '🐵', 'mosque': '🕌', 'mouse_face': '🐭',
    'musical_note': '🎵', 'nazar_amulet': '🧿', 'negative_squared_ab': '🆎',
    'negative_squared_latin_capital_letter_a': '🅰', 'nerd_face': '🤓',
    'neutral_face': '😐', 'numbers': '🔢', 'octopus': '🐙', 'onion': '🧅',
    'open_book': '📖', 'overheated_face': '🥵', 'owl': '🦉', 'package': '📦',
    'page_facing_up': '📄', 'palms_up_together': '🤲', 'panda_face': '🐼',
    'paperclip': '📎', 'party': '🎉', 'party_popper': '🎉', 'paw_prints': '🐾',
    'peach': '🍑', 'pencil': '✏️', 'penguin': '🐧', 'pensive_face': '😔',
    'personal_computer': '💻', 'phone': '📱', 'pie': '🥧', 'pig_face': '🐷',
    'pineapple': '🍍', 'playing_card_black_joker': '🃏', 'prayer_beads': '📿',
    'printer': '🖨', 'rabbit_face': '🐰', 'rainbow': '🌈', 'red_apple': '🍎',
    'regional_indicator_symbol_letter_b': '🇧',
    'regional_indicator_symbol_letter_g': '🇬',
    'regional_indicator_symbol_letter_k': '🇰',
    'regional_indicator_symbol_letter_w': '🇼', 'ribbon': '🎀',
    'ringed_planet': '🪐', 'robot_face': '🤖', 'rock': '🪨', 'rocket': '🚀',
    'ruler': '📏', 'scales': '⚖', 'school': '🏫', 'scroll': '📜',
    'second_place_medal': '🥈', 'seedling': '🌱', 'sheep': '🐑',
    'shield': '🛡', 'ship': '🚢', 'shopping_trolley': '🛒', 'skull': '💀',
    'slightly_smiling_face': '🙂',
    'smiling_face_with_open_mouth_and_smiling': '😄', 'snake': '🐍',
    'snowflake': '❄', 'snowman': '☃', 'soccer_ball': '⚽', 'sparkles': '✨',
    'speaker_with_cancellation_stroke': '🔇',
    'speaker_with_three_sound_waves': '🔊', 'spoon': '🥄',
    'sports_medal': '🏅', 'spouting_whale': '🐳', 'squared_ok': '🆗',
    'staff_of_aesculapius': '⚕', 'standing_person': '🧍', 'star': '⭐',
    'strawberry': '🍓', 'sun_with_face': '🌞', 'superhero': '🦸',
    't_rex': '🦖', 'table_tennis_paddle_and_ball': '🏓', 'tangerine': '🍊',
    'target': '🎯', 'tennis_racquet_and_ball': '🎾', 'test_tube': '🧪',
    'thinking_face': '🤔', 'third_place_medal': '🥉', 'thumbs_up': '👍',
    'thumbs_up_sign': '👍', 'tiger_face': '🐯', 'tokyo_tower': '🗼',
    'top_with_upwards_arrow_above': '🔝', 'triangular_flag_on_post': '🚩',
    'triangular_ruler': '📐', 'trophy': '🏆', 'tropical_fish': '🐠',
    'turtle': '🐢', 'unicorn_face': '🦄', 'video_game': '🎮',
    'volcano': '🌋', 'volleyball': '🏐', 'water_wave': '🌊',
    'watermelon': '🍉', 'waving_hand_sign': '👋', 'waving_white_flag': '🏳',
    'white_heavy_check_mark': '✅', 'wolf_face': '🐺', 'woman': '👩',
    'woman_with_bunny_ears': '👯', 'world_map': '🗺', 'wrapped_present': '🎁',
    'yellow_heart': '💛',
  };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/emojis/$name.png',
      width: size,
      height: size,
      semanticLabel: semanticLabel ?? name,
      errorBuilder: (context, error, stack) {
        // Asset hasn't been generated yet — render the Unicode emoji
        // sized to roughly match the image we'll eventually drop in.
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              fallbackChar,
              style: TextStyle(
                fontSize: size * 0.85,
                fontFamilyFallback: const ['Amiri', 'NotoColorEmoji'],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
