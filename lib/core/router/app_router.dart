import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/features/home/splash_screen.dart';
import 'package:aziz_academy/features/home/home_screen.dart';
import 'package:aziz_academy/features/home/presentation/home_screen_v2.dart';
import 'package:aziz_academy/features/onboarding/presentation/welcome_screen_v2.dart';
import 'package:aziz_academy/features/achievements/presentation/screens/trophy_room_screen.dart';
import 'package:aziz_academy/features/achievements/presentation/screens/certificate_screen.dart';
import 'package:aziz_academy/features/maps/presentation/screens/maps_screen.dart'
    deferred as maps_screen;
import 'package:aziz_academy/features/capitals/presentation/screens/capitals_screen.dart';
import 'package:aziz_academy/features/capitals/presentation/screens/capitals_quiz_screen.dart'
    deferred as capitals_quiz;
import 'package:aziz_academy/features/logos/presentation/screens/logos_screen.dart'
    deferred as logos_screen_def;
import 'package:aziz_academy/features/sciences/presentation/screens/sciences_screen.dart';
import 'package:aziz_academy/features/sciences/presentation/screens/sciences_quiz_screen.dart'
    deferred as sciences_quiz;

import 'package:aziz_academy/features/flags/presentation/screens/flags_screen.dart';
import 'package:aziz_academy/features/flags/presentation/screens/flags_quiz_screen.dart'
    deferred as flags_quiz;

import 'package:aziz_academy/features/math/presentation/screens/math_screen.dart';
import 'package:aziz_academy/features/math/presentation/screens/math_quiz_screen.dart'
    deferred as math_quiz;
import 'package:aziz_academy/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:aziz_academy/features/review_mode/presentation/review_mode_screen.dart'
    deferred as review_mode_def;
import 'package:aziz_academy/features/legal/privacy_policy_screen.dart';
import 'package:aziz_academy/features/legal/about_screen.dart';
import 'package:aziz_academy/features/legal/for_schools_screen.dart';
import 'package:aziz_academy/features/legal/install_guide_screen.dart';
import 'package:aziz_academy/features/madrasati/presentation/madrasati_screen.dart'
    deferred as madrasati_def;
import 'package:aziz_academy/features/madrasati/presentation/school_quiz_screen.dart'
    deferred as school_quiz_def;
import 'package:aziz_academy/features/iq/presentation/screens/iq_screen.dart'
    deferred as iq_screen_def;
import 'package:aziz_academy/features/iq/presentation/screens/iq_quiz_screen.dart'
    deferred as iq_quiz;
import 'package:aziz_academy/features/iq/presentation/screens/brain_boost_category_screen.dart'
    deferred as bb_category;
import 'package:aziz_academy/features/iq/presentation/screens/brain_boost_daily_screen.dart'
    deferred as bb_daily;
import 'package:aziz_academy/features/iq/presentation/screens/brain_boost_champion_screen.dart'
    deferred as bb_champion;
import 'package:aziz_academy/features/general_quiz/presentation/screens/general_quiz_screen.dart';
import 'package:aziz_academy/features/general_quiz/presentation/screens/general_quiz_play_screen.dart'
    deferred as general_quiz_play_def;
import 'package:aziz_academy/features/blitz/presentation/blitz_screen.dart'
    deferred as blitz_def;
import 'package:aziz_academy/features/survival/presentation/survival_screen.dart'
    deferred as survival_def;
import 'package:aziz_academy/features/boss/presentation/boss_screen.dart'
    deferred as boss_def;
import 'package:aziz_academy/features/parent/presentation/parent_screen.dart'
    deferred as parent_main;
import 'package:aziz_academy/features/parent/presentation/weekly_digest_screen.dart'
    deferred as parent_digest;
import 'package:aziz_academy/features/parent/presentation/progress_report_screen.dart'
    deferred as parent_progress;
import 'package:aziz_academy/features/madrasati/presentation/homework_helper_screen.dart';
// Secondary screens — off the kid's primary path (boss rush, multiplayer,
// progress dashboards, shop, treasure). Pushed into separate JS chunks so
// they don't bloat the initial main.dart.js download.
import 'package:aziz_academy/features/boss/presentation/boss_rush_screen.dart'
    deferred as boss_rush;
import 'package:aziz_academy/features/multiplayer/presentation/pass_play_screen.dart'
    deferred as pass_play;
import 'package:aziz_academy/features/multiplayer/presentation/weekly_tourney_screen.dart'
    deferred as weekly_tourney;
import 'package:aziz_academy/features/stats/presentation/stats_screen.dart'
    deferred as stats_screen;
import 'package:aziz_academy/features/leaderboard/presentation/leaderboard_screen.dart'
    deferred as leaderboard_screen;
import 'package:aziz_academy/features/shop/presentation/shop_screen.dart'
    deferred as shop_screen;
import 'package:aziz_academy/features/treasure/treasure_room_screen.dart'
    deferred as treasure_screen;
import 'package:aziz_academy/features/dev/widget_gallery_screen.dart'
    deferred as dev_gallery;
import 'package:aziz_academy/features/quran/quran_screen.dart'
    deferred as quran_screen_def;
import 'package:aziz_academy/features/parent/presentation/worksheet_screen.dart'
    deferred as parent_worksheet;
import 'package:aziz_academy/features/parent/presentation/family_compare_screen.dart'
    deferred as parent_compare;
import 'package:aziz_academy/features/parent/presentation/curriculum_alignment_screen.dart'
    deferred as parent_curriculum;
import 'package:aziz_academy/features/times_tables/times_tables_screen.dart'
    deferred as times_tables_screen_def;
import 'package:aziz_academy/features/alphabet/arabic_alphabet_screen.dart'
    deferred as arabic_alphabet_screen_def;
import 'package:aziz_academy/features/alphabet/english_alphabet_screen.dart'
    deferred as english_alphabet_screen_def;
import 'package:aziz_academy/features/shapes_basics/shapes_basics_screen.dart'
    deferred as shapes_basics_screen_def;
import 'package:aziz_academy/features/number_bonds/number_bonds_screen.dart'
    deferred as number_bonds_screen_def;
import 'package:aziz_academy/features/place_value/place_value_screen.dart'
    deferred as place_value_screen_def;
import 'package:aziz_academy/features/skip_counting/skip_counting_screen.dart'
    deferred as skip_counting_screen_def;
import 'package:aziz_academy/features/prayer/prayer_times_screen.dart'
    deferred as prayer_times_screen_def;
import 'package:aziz_academy/features/athkar/athkar_screen.dart'
    deferred as athkar_screen_def;
import 'package:aziz_academy/features/speed_reading/speed_reading_screen.dart'
    deferred as speed_reading_screen_def;
import 'package:aziz_academy/features/vocab_flashcards/vocab_flashcards_screen.dart'
    deferred as vocab_flashcards_screen_def;
import 'package:aziz_academy/features/sadaqah/sadaqah_jar_screen.dart'
    deferred as sadaqah_jar_screen_def;
import 'package:aziz_academy/features/dua/dua_memorization_screen.dart'
    deferred as dua_memorization_screen_def;
import 'package:aziz_academy/features/hadith/hadith_memorization_screen.dart'
    deferred as hadith_memorization_screen_def;
import 'package:aziz_academy/features/asma_ul_husna/asma_ul_husna_screen.dart'
    deferred as asma_ul_husna_screen_def;
import 'package:aziz_academy/features/prophet_stories/prophet_stories_screen.dart'
    deferred as prophet_stories_screen_def;
import 'package:aziz_academy/features/salah/salah_steps_screen.dart'
    deferred as salah_steps_screen_def;
import 'package:aziz_academy/features/wudu/wudu_steps_screen.dart'
    deferred as wudu_steps_screen_def;
import 'package:aziz_academy/features/five_pillars/five_pillars_screen.dart'
    deferred as five_pillars_screen_def;
import 'package:aziz_academy/features/six_articles/six_articles_screen.dart'
    deferred as six_articles_screen_def;
import 'package:aziz_academy/features/islamic_journey/islamic_journey_screen.dart'
    deferred as islamic_journey_screen_def;
import 'package:aziz_academy/features/asma_ul_husna/asma_ul_husna_quiz_screen.dart'
    deferred as asma_ul_husna_quiz_screen_def;
import 'package:aziz_academy/features/hadith/hadith_quiz_screen.dart'
    deferred as hadith_quiz_screen_def;
import 'package:aziz_academy/features/prophet_stories/prophet_quiz_screen.dart'
    deferred as prophet_quiz_screen_def;
import 'package:aziz_academy/features/islamic_search/islamic_search_screen.dart'
    deferred as islamic_search_screen_def;
import 'package:aziz_academy/features/tajweed/tajweed_basics_screen.dart'
    deferred as tajweed_basics_screen_def;
import 'package:aziz_academy/features/daily_wisdom_quiz/daily_wisdom_quiz_screen.dart'
    deferred as daily_wisdom_quiz_screen_def;
import 'package:aziz_academy/features/multiplication_practice/multiplication_practice_screen.dart'
    deferred as multiplication_practice_screen_def;
import 'package:aziz_academy/features/mental_math/mental_math_sprint_screen.dart'
    deferred as mental_math_sprint_screen_def;
import 'package:aziz_academy/features/hijri/hijri_converter_screen.dart'
    deferred as hijri_converter_screen_def;
import 'package:aziz_academy/features/fractions_practice/fractions_practice_screen.dart'
    deferred as fractions_practice_screen_def;
import 'package:aziz_academy/features/tasbih/tasbih_screen.dart'
    deferred as tasbih_screen_def;
import 'package:aziz_academy/features/smart_quiz/smart_quiz_screen.dart'
    deferred as smart_quiz_screen_def;
import 'package:aziz_academy/features/word_search/word_search_screen.dart'
    deferred as word_search_screen_def;
import 'package:aziz_academy/features/tic_tac_toe/tic_tac_toe_screen.dart'
    deferred as tic_tac_toe_screen_def;
import 'package:aziz_academy/features/memory_match/memory_match_screen.dart'
    deferred as memory_match_screen_def;
import 'package:aziz_academy/features/sudoku/sudoku_screen.dart'
    deferred as sudoku_screen_def;
import 'package:aziz_academy/features/snake/snake_screen.dart'
    deferred as snake_screen_def;
import 'package:aziz_academy/features/connect_four/connect_four_screen.dart'
    deferred as connect_four_screen_def;
import 'package:aziz_academy/features/crossword/crossword_screen.dart'
    deferred as crossword_def;
import 'package:aziz_academy/features/two_thousand/two_thousand_screen.dart'
    deferred as two_thousand_screen_def;
import 'package:aziz_academy/features/lights_out/lights_out_screen.dart'
    deferred as lights_out_screen_def;
import 'package:aziz_academy/features/fifteen_puzzle/fifteen_puzzle_screen.dart'
    deferred as fifteen_puzzle_screen_def;
import 'package:aziz_academy/features/reaction_time/reaction_time_screen.dart'
    deferred as reaction_time_screen_def;
import 'package:aziz_academy/features/color_match/color_match_screen.dart'
    deferred as color_match_screen_def;
import 'package:aziz_academy/features/whack_a_mole/whack_a_mole_screen.dart'
    deferred as whack_a_mole_screen_def;
import 'package:aziz_academy/features/simon_says/simon_says_screen.dart'
    deferred as simon_says_screen_def;
import 'package:aziz_academy/features/hanoi/hanoi_screen.dart'
    deferred as hanoi_screen_def;
import 'package:aziz_academy/features/pong/pong_screen.dart'
    deferred as pong_screen_def;
import 'package:aziz_academy/features/mastermind/mastermind_screen.dart'
    deferred as mastermind_screen_def;
import 'package:aziz_academy/features/brick_breaker/brick_breaker_screen.dart'
    deferred as brick_breaker_screen_def;
import 'package:aziz_academy/features/maze_runner/maze_runner_screen.dart'
    deferred as maze_runner_screen_def;
import 'package:aziz_academy/features/math_sprint/math_sprint_screen.dart'
    deferred as math_sprint_screen_def;
import 'package:aziz_academy/features/reversi/reversi_screen.dart'
    deferred as reversi_screen_def;
import 'package:aziz_academy/features/pegs/pegs_screen.dart'
    deferred as pegs_screen_def;
import 'package:aziz_academy/features/tap_sequence/tap_sequence_screen.dart'
    deferred as tap_sequence_screen_def;
import 'package:aziz_academy/features/odd_one_out/odd_one_out_screen.dart'
    deferred as odd_one_out_screen_def;
import 'package:aziz_academy/features/word_scramble/word_scramble_screen.dart'
    deferred as word_scramble_screen_def;
import 'package:aziz_academy/features/battleship/battleship_screen.dart'
    deferred as battleship_screen_def;
import 'package:aziz_academy/features/dots_boxes/dots_boxes_screen.dart'
    deferred as dots_boxes_screen_def;
import 'package:aziz_academy/features/tetris_lite/tetris_lite_screen.dart'
    deferred as tetris_lite_screen_def;
import 'package:aziz_academy/features/bubble_pop/bubble_pop_screen.dart'
    deferred as bubble_pop_screen_def;
import 'package:aziz_academy/features/fruit_catcher/fruit_catcher_screen.dart'
    deferred as fruit_catcher_screen_def;
import 'package:aziz_academy/features/sokoban/sokoban_screen.dart'
    deferred as sokoban_screen_def;
import 'package:aziz_academy/features/stack_builder/stack_builder_screen.dart'
    deferred as stack_builder_screen_def;
import 'package:aziz_academy/features/pig_dice/pig_dice_screen.dart'
    deferred as pig_dice_screen_def;
import 'package:aziz_academy/features/penalty_shootout/penalty_shootout_screen.dart'
    deferred as penalty_shootout_screen_def;
import 'package:aziz_academy/features/tap_jump/tap_jump_screen.dart'
    deferred as tap_jump_screen_def;
import 'package:aziz_academy/features/beat_tap/beat_tap_screen.dart'
    deferred as beat_tap_screen_def;
import 'package:aziz_academy/features/hoop_shot/hoop_shot_screen.dart'
    deferred as hoop_shot_screen_def;
import 'package:aziz_academy/features/cup_shuffle/cup_shuffle_screen.dart'
    deferred as cup_shuffle_screen_def;
import 'package:aziz_academy/features/match_three/match_three_screen.dart'
    deferred as match_three_screen_def;
import 'package:aziz_academy/features/balloon_pop/balloon_pop_screen.dart'
    deferred as balloon_pop_screen_def;
import 'package:aziz_academy/features/lemonade_stand/lemonade_stand_screen.dart'
    deferred as lemonade_stand_screen_def;
import 'package:aziz_academy/features/stick_hero/stick_hero_screen.dart'
    deferred as stick_hero_screen_def;
import 'package:aziz_academy/features/higher_lower/higher_lower_screen.dart'
    deferred as higher_lower_screen_def;
import 'package:aziz_academy/features/crossy_lane/crossy_lane_screen.dart'
    deferred as crossy_lane_screen_def;
import 'package:aziz_academy/features/counting_stars/counting_stars_screen.dart'
    deferred as counting_stars_screen_def;
import 'package:aziz_academy/features/number_memory/number_memory_screen.dart'
    deferred as number_memory_screen_def;
import 'package:aziz_academy/features/sum_hunt/sum_hunt_screen.dart'
    deferred as sum_hunt_screen_def;
import 'package:aziz_academy/features/schulte/schulte_screen.dart'
    deferred as schulte_screen_def;
import 'package:aziz_academy/features/stroop/stroop_screen.dart'
    deferred as stroop_screen_def;
import 'package:aziz_academy/features/find_twin/find_twin_screen.dart'
    deferred as find_twin_screen_def;
import 'package:aziz_academy/features/pattern_next/pattern_next_screen.dart'
    deferred as pattern_next_screen_def;
import 'package:aziz_academy/features/greater_than/greater_than_screen.dart'
    deferred as greater_than_screen_def;
import 'package:aziz_academy/features/asteroid_dodge/asteroid_dodge_screen.dart'
    deferred as asteroid_dodge_screen_def;
import 'package:aziz_academy/features/roman_numerals/roman_numerals_screen.dart'
    deferred as roman_numerals_screen_def;
import 'package:aziz_academy/features/fraction_match/fraction_match_screen.dart'
    deferred as fraction_match_screen_def;
import 'package:aziz_academy/features/even_odd/even_odd_screen.dart'
    deferred as even_odd_screen_def;
import 'package:aziz_academy/features/prime_tap/prime_tap_screen.dart'
    deferred as prime_tap_screen_def;
import 'package:aziz_academy/features/tap_letter/tap_letter_screen.dart'
    deferred as tap_letter_screen_def;
import 'package:aziz_academy/features/tap_greatest/tap_greatest_screen.dart'
    deferred as tap_greatest_screen_def;
import 'package:aziz_academy/features/shape_match/shape_match_screen.dart'
    deferred as shape_match_screen_def;
import 'package:aziz_academy/features/odd_color/odd_color_screen.dart'
    deferred as odd_color_screen_def;
import 'package:aziz_academy/features/anagram/anagram_screen.dart'
    deferred as anagram_screen_def;
import 'package:aziz_academy/features/speed_math/speed_math_screen.dart'
    deferred as speed_math_screen_def;
import 'package:aziz_academy/features/clock_read/clock_read_screen.dart'
    deferred as clock_read_screen_def;
import 'package:aziz_academy/features/hangman/hangman_screen.dart'
    deferred as hangman_screen_def;
import 'package:aziz_academy/features/bowling/bowling_screen.dart'
    deferred as bowling_screen_def;
import 'package:aziz_academy/features/color_mix/color_mix_screen.dart'
    deferred as color_mix_screen_def;
import 'package:aziz_academy/features/true_false/presentation/true_false_screen.dart'
    deferred as true_false_screen_def;
import 'package:aziz_academy/features/self_challenge/presentation/self_challenge_screen.dart'
    deferred as self_challenge_screen_def;
import 'package:aziz_academy/features/favorites/presentation/favorites_screen.dart';
import 'package:aziz_academy/features/onboarding/presentation/welcome_screen.dart';
import 'package:aziz_academy/features/account/presentation/account_screen.dart';
import 'package:aziz_academy/features/account/presentation/premium_screen.dart';
import 'package:aziz_academy/features/profile/presentation/edit_profile_screen.dart';
import 'package:aziz_academy/features/profile/presentation/family_profiles_screen.dart';
import 'package:aziz_academy/features/profile/presentation/profile_card_screen.dart';
import 'package:aziz_academy/features/random_quiz/presentation/random_quiz_screen.dart'
    deferred as random_quiz_screen_def;
import 'package:aziz_academy/features/spelling/presentation/spelling_screen.dart'
    deferred as spelling_screen_def;
import 'package:aziz_academy/features/type_answer/presentation/type_answer_screen.dart'
    deferred as type_answer_screen_def;
import 'package:aziz_academy/features/learning_zone/presentation/learning_zone_screen.dart'
    deferred as learning_zone_screen_def;
// Admin dashboard is the largest single file in the codebase (~5,800 lines)
// and is loaded by < 1% of sessions. Deferred-import keeps it out of the
// initial main.dart.js chunk; the browser fetches the admin chunk only when
// the operator navigates to /x9k2-admin-portal. Same for v2 console + the
// internal widget gallery.
import 'package:aziz_academy/features/admin/admin_dashboard_screen.dart'
    deferred as admin_v1;
import 'package:aziz_academy/features/admin/admin_v2_screen.dart'
    deferred as admin_v2;
import 'package:aziz_academy/features/admin/admin_traffic.dart';

/// Build-time flag for the redesigned welcome + home screens.
///
/// Defaults to `false` so existing users see the legacy screens until you
/// are ready to flip the redesign live. Flip this to `true` in a single
/// commit (or behind a remote feature flag) when you've verified the
/// v2 surfaces locally:
///
///   const _kUseV2Screens = true;
///
/// Touched routes when the flag is on:
///   - AppRoutes.welcome -> WelcomeScreenV2
///   - AppRoutes.home    -> HomeScreenV2
///
/// Everything else is unchanged. The legacy widgets remain importable so
/// you can revert the flag instantly if anything regresses.
const bool _kUseV2Screens = true;

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const maps = '/maps';
  static const capitals = '/capitals';
  static const capitalsQuiz = '/capitals/quiz';
  static const flags = '/flags';
  static const flagsQuiz = '/flags/quiz';
  static const math = '/math';
  static const mathQuiz = '/math/quiz';
  static const logos = '/logos';
  static const sciences = '/sciences';
  static const sciencesQuiz = '/sciences/quiz';
  static const iq = '/iq';
  static const iqQuiz = '/iq/quiz';
  static const brainBoostCategory = '/iq/category';
  static const brainBoostDaily = '/iq/daily';
  static const brainBoostChampion = '/iq/champion';
  static const generalQuizIntro = '/general-quiz';
  static const generalQuiz = '/general-quiz/quiz';
  static const blitz = '/blitz';
  static const survival = '/survival';
  static const boss = '/boss';
  static const parent = '/parent';
  static const stats = '/stats';
  static const leaderboard = '/leaderboard';
  static const shop = '/shop';
  static const treasure = '/treasure';
  static const devGallery = '/dev/gallery';
  static const quran = '/quran';
  static const worksheet = '/parent/worksheet';
  static const familyCompare = '/parent/family-compare';
  static const curriculumAlignment = '/parent/curriculum';
  static const timesTables = '/times-tables';
  static const alphabet = '/alphabet';
  static const englishAlphabet = '/english-alphabet';
  static const shapesBasics = '/shapes-basics';
  static const numberBonds = '/number-bonds';
  static const placeValue = '/place-value';
  static const skipCounting = '/skip-counting';
  static const prayerTimes = '/prayer-times';
  static const athkar = '/athkar';
  static const speedReading = '/speed-reading';
  static const vocabFlashcards = '/vocab-flashcards';
  static const sadaqahJar = '/sadaqah-jar';
  static const duaMemorization = '/dua';
  static const hadithMemorization = '/hadith';
  static const asmaUlHusna = '/names-of-allah';
  static const prophetStories = '/prophet-stories';
  static const salahSteps = '/how-to-pray';
  static const wuduSteps = '/how-to-wudu';
  static const fivePillars = '/five-pillars';
  static const sixArticles = '/six-articles-of-faith';
  static const islamicJourney = '/my-islamic-journey';
  static const asmaUlHusnaQuiz = '/names-of-allah-quiz';
  static const hadithQuiz = '/hadith-quiz';
  static const prophetQuiz = '/prophet-quiz';
  static const islamicSearch = '/islamic-search';
  static const tajweedBasics = '/tajweed-basics';
  static const dailyWisdomQuiz = '/daily-wisdom-quiz';
  static const multiplicationPractice = '/multiplication-practice';
  static const mentalMathSprint = '/mental-math-sprint';
  static const hijriConverter = '/hijri-converter';
  static const fractionsPractice = '/fractions-practice';
  static const tasbih = '/tasbih';
  static const smartQuiz = '/smart-quiz';
  static const wordSearch = '/word-search';
  static const ticTacToe = '/tic-tac-toe';
  static const memoryMatch = '/memory-match';
  static const sudoku = '/sudoku';
  static const snake = '/snake';
  static const connectFour = '/connect-four';
  static const crossword = '/crossword';
  static const twoThousand = '/2048';
  static const lightsOut = '/lights-out';
  static const fifteenPuzzle = '/15-puzzle';
  static const reactionTime = '/reaction-time';
  static const colorMatch = '/color-match';
  static const whackAMole = '/whack-a-mole';
  static const simonSays = '/simon-says';
  static const hanoi = '/hanoi';
  static const pong = '/pong';
  static const mastermind = '/mastermind';
  static const brickBreaker = '/brick-breaker';
  static const mazeRunner = '/maze-runner';
  static const mathSprint = '/math-sprint';
  static const reversi = '/reversi';
  static const pegs = '/pegs';
  static const tapSequence = '/tap-sequence';
  static const oddOneOut = '/odd-one-out';
  static const wordScramble = '/word-scramble';
  static const battleship = '/battleship';
  static const dotsBoxes = '/dots-boxes';
  static const tetrisLite = '/tetris-lite';
  static const bubblePop = '/bubble-pop';
  static const fruitCatcher = '/fruit-catcher';
  static const sokoban = '/sokoban';
  static const stackBuilder = '/stack-builder';
  static const pigDice = '/pig-dice';
  static const penaltyShootout = '/penalty-shootout';
  static const tapJump = '/tap-jump';
  static const beatTap = '/beat-tap';
  static const hoopShot = '/hoop-shot';
  static const cupShuffle = '/cup-shuffle';
  static const matchThree = '/match-three';
  static const balloonPop = '/balloon-pop';
  static const lemonadeStand = '/lemonade-stand';
  static const stickHero = '/stick-hero';
  static const higherLower = '/higher-lower';
  static const crossyLane = '/crossy-lane';
  static const countingStars = '/counting-stars';
  static const numberMemory = '/number-memory';
  static const sumHunt = '/sum-hunt';
  static const schulte = '/schulte';
  static const stroop = '/stroop';
  static const findTwin = '/find-twin';
  static const patternNext = '/pattern-next';
  static const greaterThan = '/greater-than';
  static const asteroidDodge = '/asteroid-dodge';
  static const romanNumerals = '/roman-numerals';
  static const fractionMatch = '/fraction-match';
  static const evenOdd = '/even-odd';
  static const primeTap = '/prime-tap';
  static const tapLetter = '/tap-letter';
  static const tapGreatest = '/tap-greatest';
  static const shapeMatch = '/shape-match';
  static const oddColor = '/odd-color';
  static const anagram = '/anagram';
  static const speedMath = '/speed-math';
  static const clockRead = '/clock-read';
  static const hangman = '/hangman';
  static const bowling = '/bowling';
  static const colorMix = '/color-mix';
  static const trueFalse = '/true-false';
  static const selfChallenge = '/self-challenge';
  static const favorites = '/favorites';
  static const editProfile = '/edit-profile';
  static const profileCard = '/profile';
  static const browse = '/browse';
  static const account = '/account';
  static const premium = '/plus';
  static const familyProfiles = '/family';
  static const welcome = '/welcome';
  static const weeklyDigest = '/parent/digest';
  static const progressReport = '/parent/report';
  static const homeworkHelper = '/madrasati/homework';
  static const bossRush = '/boss-rush';
  static const passPlay = '/pass-play';
  static const weeklyTourney = '/weekly-tourney';
  static const randomQuiz = '/random-quiz';
  static const spelling = '/spelling';
  static const typeAnswer = '/type-answer';
  static const learningZone = '/learning-zone';
  static const trophy = '/trophy';
  static const certificate = '/trophy/certificate';
  static const dailyChallenge = '/daily-challenge';
  static const reviewMode = '/review-mode';
  static const madrasati = '/madrasati';
  static const schoolQuiz = '/school-quiz';
  static const privacy = '/privacy';
  static const about = '/about';
  static const forSchools = '/for-schools';
  static const installGuide = '/install-app';

  /// Hidden admin route — not surfaced anywhere in the UI. Type the URL
  /// directly to reach the passcode gate. Default code: 4242 (configurable
  /// in `admin_dashboard_screen.dart`).
  static const admin = '/x9k2-admin-portal';

  /// Admin v2 — minimal monochrome console at a fresh route to bypass any
  /// service-worker cache on the old admin URL. No passcode gate (it's a
  /// short-term verification surface; gate later if it stays).
  static const adminV2 = '/x9k2-console-v2';

  /// Diagnostic route — pure red bg + huge white text. If this URL doesn't
  /// show that, routing/cache is broken upstream of the admin screens.
  static const adminDiag = '/x9k2-diag-test';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  // Feeds the on-device traffic counters surfaced in the admin console
  // (Traffic section). One observer is enough — every push/replace bubbles up.
  observers: [TrafficObserver()],
  errorBuilder: (context, state) {
    final l10n = context.l10n;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final requested = state.uri.path;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧭', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text(
                  l10n.errorPageTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr ? 'لا يوجد شيء على هذا المسار:' : "Nothing's here at:",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requested,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(l10n.errorPageHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) =>
          _kUseV2Screens ? const HomeScreenV2() : const HomeScreen(),
    ),
    // Full activity grid (legacy home), optionally pre-filtered to a category.
    // The v2 home's hero cards deep-link here: /browse?cat=learn|games|islamic|tools|all
    GoRoute(
      path: AppRoutes.browse,
      builder: (context, state) =>
          HomeScreen(initialCategory: state.uri.queryParameters['cat']),
    ),
    GoRoute(
      path: AppRoutes.maps,
      builder: (context, state) {
        final skip = state.uri.queryParameters['recap'] == '1';
        return _DeferredLoader(
          load: maps_screen.loadLibrary,
          builder: () => maps_screen.MapsScreen(skipIntro: skip),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.capitals,
      builder: (context, state) => const CapitalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.capitalsQuiz,
      builder: (context, state) => _DeferredLoader(
        load: capitals_quiz.loadLibrary,
        builder: () => capitals_quiz.CapitalsQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.flags,
      builder: (context, state) => const FlagsScreen(),
    ),
    GoRoute(
      path: AppRoutes.flagsQuiz,
      builder: (context, state) => _DeferredLoader(
        load: flags_quiz.loadLibrary,
        builder: () => flags_quiz.FlagsQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.math,
      builder: (context, state) => const MathScreen(),
    ),
    GoRoute(
      path: AppRoutes.mathQuiz,
      builder: (context, state) => _DeferredLoader(
        load: math_quiz.loadLibrary,
        builder: () => math_quiz.MathQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.logos,
      builder: (context, state) => _DeferredLoader(
        load: logos_screen_def.loadLibrary,
        builder: () => logos_screen_def.LogosScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.trophy,
      builder: (context, state) => const TrophyRoomScreen(),
    ),
    GoRoute(
      path: AppRoutes.certificate,
      builder: (context, state) => const CertificateScreen(),
    ),
    GoRoute(
      path: AppRoutes.dailyChallenge,
      builder: (context, state) => const DailyChallengeScreen(),
    ),
    GoRoute(
      path: AppRoutes.reviewMode,
      builder: (context, state) => _DeferredLoader(
        load: review_mode_def.loadLibrary,
        builder: () => review_mode_def.ReviewModeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.madrasati,
      builder: (context, state) => _DeferredLoader(
        load: madrasati_def.loadLibrary,
        builder: () => madrasati_def.MadrasatiScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.schoolQuiz,
      builder: (context, state) => _DeferredLoader(
        load: school_quiz_def.loadLibrary,
        builder: () => school_quiz_def.SchoolQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.forSchools,
      builder: (context, state) => const ForSchoolsScreen(),
    ),
    GoRoute(
      path: AppRoutes.installGuide,
      builder: (context, state) => const InstallGuideScreen(),
    ),
    GoRoute(
      path: AppRoutes.sciences,
      builder: (context, state) => const SciencesScreen(),
    ),
    GoRoute(
      path: AppRoutes.sciencesQuiz,
      builder: (context, state) => _DeferredLoader(
        load: sciences_quiz.loadLibrary,
        builder: () => sciences_quiz.SciencesQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.iq,
      builder: (context, state) => _DeferredLoader(
        load: iq_screen_def.loadLibrary,
        builder: () => iq_screen_def.IqScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.iqQuiz,
      builder: (context, state) => _DeferredLoader(
        load: iq_quiz.loadLibrary,
        builder: () => iq_quiz.IqQuizScreen(),
      ),
    ),
    GoRoute(
      path: '${AppRoutes.brainBoostCategory}/:cat',
      builder: (context, state) => _DeferredLoader(
        load: bb_category.loadLibrary,
        builder: () => bb_category.BrainBoostCategoryScreen(
          category: state.pathParameters['cat'] ?? 'Patterns',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.brainBoostDaily,
      builder: (context, state) => _DeferredLoader(
        load: bb_daily.loadLibrary,
        builder: () => bb_daily.BrainBoostDailyScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.brainBoostChampion,
      builder: (context, state) => _DeferredLoader(
        load: bb_champion.loadLibrary,
        builder: () => bb_champion.BrainBoostChampionScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.generalQuizIntro,
      builder: (context, state) => const GeneralQuizIntroScreen(),
    ),
    GoRoute(
      path: AppRoutes.generalQuiz,
      builder: (context, state) => _DeferredLoader(
        load: general_quiz_play_def.loadLibrary,
        builder: () => general_quiz_play_def.GeneralQuizPlayScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.blitz,
      builder: (context, state) => _DeferredLoader(
        load: blitz_def.loadLibrary,
        builder: () => blitz_def.BlitzScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.survival,
      builder: (context, state) => _DeferredLoader(
        load: survival_def.loadLibrary,
        builder: () => survival_def.SurvivalScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.boss,
      builder: (context, state) => _DeferredLoader(
        load: boss_def.loadLibrary,
        builder: () => boss_def.BossScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.parent,
      builder: (context, state) => _DeferredLoader(
        load: parent_main.loadLibrary,
        builder: () => parent_main.ParentScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => _DeferredLoader(
        load: stats_screen.loadLibrary,
        builder: () => stats_screen.StatsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.leaderboard,
      builder: (context, state) => _DeferredLoader(
        load: leaderboard_screen.loadLibrary,
        builder: () => leaderboard_screen.LeaderboardScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.shop,
      builder: (context, state) => _DeferredLoader(
        load: shop_screen.loadLibrary,
        builder: () => shop_screen.ShopScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.treasure,
      builder: (context, state) => _DeferredLoader(
        load: treasure_screen.loadLibrary,
        builder: () => treasure_screen.TreasureRoomScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.devGallery,
      builder: (context, state) => _DeferredLoader(
        load: dev_gallery.loadLibrary,
        builder: () => dev_gallery.WidgetGalleryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.quran,
      builder: (context, state) => _DeferredLoader(
        load: quran_screen_def.loadLibrary,
        builder: () => quran_screen_def.QuranScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.worksheet,
      builder: (context, state) => _DeferredLoader(
        load: parent_worksheet.loadLibrary,
        builder: () => parent_worksheet.WorksheetScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.familyCompare,
      builder: (context, state) => _DeferredLoader(
        load: parent_compare.loadLibrary,
        builder: () => parent_compare.FamilyCompareScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.curriculumAlignment,
      builder: (context, state) => _DeferredLoader(
        load: parent_curriculum.loadLibrary,
        builder: () => parent_curriculum.CurriculumAlignmentScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.timesTables,
      builder: (context, state) => _DeferredLoader(
        load: times_tables_screen_def.loadLibrary,
        builder: () => times_tables_screen_def.TimesTablesScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.alphabet,
      builder: (context, state) => _DeferredLoader(
        load: arabic_alphabet_screen_def.loadLibrary,
        builder: () => arabic_alphabet_screen_def.ArabicAlphabetScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.englishAlphabet,
      builder: (context, state) => _DeferredLoader(
        load: english_alphabet_screen_def.loadLibrary,
        builder: () => english_alphabet_screen_def.EnglishAlphabetScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.shapesBasics,
      builder: (context, state) => _DeferredLoader(
        load: shapes_basics_screen_def.loadLibrary,
        builder: () => shapes_basics_screen_def.ShapesBasicsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.numberBonds,
      builder: (context, state) => _DeferredLoader(
        load: number_bonds_screen_def.loadLibrary,
        builder: () => number_bonds_screen_def.NumberBondsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.placeValue,
      builder: (context, state) => _DeferredLoader(
        load: place_value_screen_def.loadLibrary,
        builder: () => place_value_screen_def.PlaceValueScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.skipCounting,
      builder: (context, state) => _DeferredLoader(
        load: skip_counting_screen_def.loadLibrary,
        builder: () => skip_counting_screen_def.SkipCountingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.prayerTimes,
      builder: (context, state) => _DeferredLoader(
        load: prayer_times_screen_def.loadLibrary,
        builder: () => prayer_times_screen_def.PrayerTimesScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.athkar,
      builder: (context, state) => _DeferredLoader(
        load: athkar_screen_def.loadLibrary,
        builder: () => athkar_screen_def.AthkarScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.speedReading,
      builder: (context, state) => _DeferredLoader(
        load: speed_reading_screen_def.loadLibrary,
        builder: () => speed_reading_screen_def.SpeedReadingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.vocabFlashcards,
      builder: (context, state) => _DeferredLoader(
        load: vocab_flashcards_screen_def.loadLibrary,
        builder: () => vocab_flashcards_screen_def.VocabFlashcardsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.sadaqahJar,
      builder: (context, state) => _DeferredLoader(
        load: sadaqah_jar_screen_def.loadLibrary,
        builder: () => sadaqah_jar_screen_def.SadaqahJarScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.duaMemorization,
      builder: (context, state) => _DeferredLoader(
        load: dua_memorization_screen_def.loadLibrary,
        builder: () => dua_memorization_screen_def.DuaMemorizationScreen(
          focusId: state.uri.queryParameters['focusId'],
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.hadithMemorization,
      builder: (context, state) => _DeferredLoader(
        load: hadith_memorization_screen_def.loadLibrary,
        builder: () => hadith_memorization_screen_def.HadithMemorizationScreen(
          focusId: state.uri.queryParameters['focusId'],
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.asmaUlHusna,
      builder: (context, state) => _DeferredLoader(
        load: asma_ul_husna_screen_def.loadLibrary,
        builder: () => asma_ul_husna_screen_def.AsmaUlHusnaScreen(
          focusId: state.uri.queryParameters['focusId'],
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.prophetStories,
      builder: (context, state) => _DeferredLoader(
        load: prophet_stories_screen_def.loadLibrary,
        builder: () => prophet_stories_screen_def.ProphetStoriesScreen(
          focusId: state.uri.queryParameters['focusId'],
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.salahSteps,
      builder: (context, state) => _DeferredLoader(
        load: salah_steps_screen_def.loadLibrary,
        builder: () => salah_steps_screen_def.SalahStepsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.wuduSteps,
      builder: (context, state) => _DeferredLoader(
        load: wudu_steps_screen_def.loadLibrary,
        builder: () => wudu_steps_screen_def.WuduStepsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.fivePillars,
      builder: (context, state) => _DeferredLoader(
        load: five_pillars_screen_def.loadLibrary,
        builder: () => five_pillars_screen_def.FivePillarsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.sixArticles,
      builder: (context, state) => _DeferredLoader(
        load: six_articles_screen_def.loadLibrary,
        builder: () => six_articles_screen_def.SixArticlesScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.islamicJourney,
      builder: (context, state) => _DeferredLoader(
        load: islamic_journey_screen_def.loadLibrary,
        builder: () => islamic_journey_screen_def.IslamicJourneyScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.asmaUlHusnaQuiz,
      builder: (context, state) => _DeferredLoader(
        load: asma_ul_husna_quiz_screen_def.loadLibrary,
        builder: () =>
            asma_ul_husna_quiz_screen_def.AsmaUlHusnaQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.hadithQuiz,
      builder: (context, state) => _DeferredLoader(
        load: hadith_quiz_screen_def.loadLibrary,
        builder: () => hadith_quiz_screen_def.HadithQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.prophetQuiz,
      builder: (context, state) => _DeferredLoader(
        load: prophet_quiz_screen_def.loadLibrary,
        builder: () => prophet_quiz_screen_def.ProphetQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.islamicSearch,
      builder: (context, state) => _DeferredLoader(
        load: islamic_search_screen_def.loadLibrary,
        builder: () => islamic_search_screen_def.IslamicSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tajweedBasics,
      builder: (context, state) => _DeferredLoader(
        load: tajweed_basics_screen_def.loadLibrary,
        builder: () => tajweed_basics_screen_def.TajweedBasicsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.dailyWisdomQuiz,
      builder: (context, state) => _DeferredLoader(
        load: daily_wisdom_quiz_screen_def.loadLibrary,
        builder: () => daily_wisdom_quiz_screen_def.DailyWisdomQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.multiplicationPractice,
      builder: (context, state) => _DeferredLoader(
        load: multiplication_practice_screen_def.loadLibrary,
        builder: () =>
            multiplication_practice_screen_def.MultiplicationPracticeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.mentalMathSprint,
      builder: (context, state) => _DeferredLoader(
        load: mental_math_sprint_screen_def.loadLibrary,
        builder: () => mental_math_sprint_screen_def.MentalMathSprintScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.hijriConverter,
      builder: (context, state) => _DeferredLoader(
        load: hijri_converter_screen_def.loadLibrary,
        builder: () => hijri_converter_screen_def.HijriConverterScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.fractionsPractice,
      builder: (context, state) => _DeferredLoader(
        load: fractions_practice_screen_def.loadLibrary,
        builder: () =>
            fractions_practice_screen_def.FractionsPracticeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tasbih,
      builder: (context, state) => _DeferredLoader(
        load: tasbih_screen_def.loadLibrary,
        builder: () => tasbih_screen_def.TasbihScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.smartQuiz,
      builder: (context, state) => _DeferredLoader(
        load: smart_quiz_screen_def.loadLibrary,
        builder: () => smart_quiz_screen_def.SmartQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.wordSearch,
      builder: (context, state) => _DeferredLoader(
        load: word_search_screen_def.loadLibrary,
        builder: () => word_search_screen_def.WordSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.ticTacToe,
      builder: (context, state) => _DeferredLoader(
        load: tic_tac_toe_screen_def.loadLibrary,
        builder: () => tic_tac_toe_screen_def.TicTacToeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.memoryMatch,
      builder: (context, state) => _DeferredLoader(
        load: memory_match_screen_def.loadLibrary,
        builder: () => memory_match_screen_def.MemoryMatchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.sudoku,
      builder: (context, state) => _DeferredLoader(
        load: sudoku_screen_def.loadLibrary,
        builder: () => sudoku_screen_def.SudokuScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.snake,
      builder: (context, state) => _DeferredLoader(
        load: snake_screen_def.loadLibrary,
        builder: () => snake_screen_def.SnakeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.connectFour,
      builder: (context, state) => _DeferredLoader(
        load: connect_four_screen_def.loadLibrary,
        builder: () => connect_four_screen_def.ConnectFourScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.crossword,
      builder: (context, state) => _DeferredLoader(
        load: crossword_def.loadLibrary,
        builder: () => crossword_def.CrosswordScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.twoThousand,
      builder: (context, state) => _DeferredLoader(
        load: two_thousand_screen_def.loadLibrary,
        builder: () => two_thousand_screen_def.TwoThousandScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.lightsOut,
      builder: (context, state) => _DeferredLoader(
        load: lights_out_screen_def.loadLibrary,
        builder: () => lights_out_screen_def.LightsOutScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.fifteenPuzzle,
      builder: (context, state) => _DeferredLoader(
        load: fifteen_puzzle_screen_def.loadLibrary,
        builder: () => fifteen_puzzle_screen_def.FifteenPuzzleScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.reactionTime,
      builder: (context, state) => _DeferredLoader(
        load: reaction_time_screen_def.loadLibrary,
        builder: () => reaction_time_screen_def.ReactionTimeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.colorMatch,
      builder: (context, state) => _DeferredLoader(
        load: color_match_screen_def.loadLibrary,
        builder: () => color_match_screen_def.ColorMatchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.whackAMole,
      builder: (context, state) => _DeferredLoader(
        load: whack_a_mole_screen_def.loadLibrary,
        builder: () => whack_a_mole_screen_def.WhackAMoleScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.simonSays,
      builder: (context, state) => _DeferredLoader(
        load: simon_says_screen_def.loadLibrary,
        builder: () => simon_says_screen_def.SimonSaysScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.hanoi,
      builder: (context, state) => _DeferredLoader(
        load: hanoi_screen_def.loadLibrary,
        builder: () => hanoi_screen_def.HanoiScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.pong,
      builder: (context, state) => _DeferredLoader(
        load: pong_screen_def.loadLibrary,
        builder: () => pong_screen_def.PongScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.mastermind,
      builder: (context, state) => _DeferredLoader(
        load: mastermind_screen_def.loadLibrary,
        builder: () => mastermind_screen_def.MastermindScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.brickBreaker,
      builder: (context, state) => _DeferredLoader(
        load: brick_breaker_screen_def.loadLibrary,
        builder: () => brick_breaker_screen_def.BrickBreakerScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.mazeRunner,
      builder: (context, state) => _DeferredLoader(
        load: maze_runner_screen_def.loadLibrary,
        builder: () => maze_runner_screen_def.MazeRunnerScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.mathSprint,
      builder: (context, state) => _DeferredLoader(
        load: math_sprint_screen_def.loadLibrary,
        builder: () => math_sprint_screen_def.MathSprintScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.reversi,
      builder: (context, state) => _DeferredLoader(
        load: reversi_screen_def.loadLibrary,
        builder: () => reversi_screen_def.ReversiScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.pegs,
      builder: (context, state) => _DeferredLoader(
        load: pegs_screen_def.loadLibrary,
        builder: () => pegs_screen_def.PegsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tapSequence,
      builder: (context, state) => _DeferredLoader(
        load: tap_sequence_screen_def.loadLibrary,
        builder: () => tap_sequence_screen_def.TapSequenceScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.oddOneOut,
      builder: (context, state) => _DeferredLoader(
        load: odd_one_out_screen_def.loadLibrary,
        builder: () => odd_one_out_screen_def.OddOneOutScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.wordScramble,
      builder: (context, state) => _DeferredLoader(
        load: word_scramble_screen_def.loadLibrary,
        builder: () => word_scramble_screen_def.WordScrambleScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.battleship,
      builder: (context, state) => _DeferredLoader(
        load: battleship_screen_def.loadLibrary,
        builder: () => battleship_screen_def.BattleshipScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.dotsBoxes,
      builder: (context, state) => _DeferredLoader(
        load: dots_boxes_screen_def.loadLibrary,
        builder: () => dots_boxes_screen_def.DotsBoxesScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tetrisLite,
      builder: (context, state) => _DeferredLoader(
        load: tetris_lite_screen_def.loadLibrary,
        builder: () => tetris_lite_screen_def.TetrisLiteScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bubblePop,
      builder: (context, state) => _DeferredLoader(
        load: bubble_pop_screen_def.loadLibrary,
        builder: () => bubble_pop_screen_def.BubblePopScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.fruitCatcher,
      builder: (context, state) => _DeferredLoader(
        load: fruit_catcher_screen_def.loadLibrary,
        builder: () => fruit_catcher_screen_def.FruitCatcherScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.sokoban,
      builder: (context, state) => _DeferredLoader(
        load: sokoban_screen_def.loadLibrary,
        builder: () => sokoban_screen_def.SokobanScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.stackBuilder,
      builder: (context, state) => _DeferredLoader(
        load: stack_builder_screen_def.loadLibrary,
        builder: () => stack_builder_screen_def.StackBuilderScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.pigDice,
      builder: (context, state) => _DeferredLoader(
        load: pig_dice_screen_def.loadLibrary,
        builder: () => pig_dice_screen_def.PigDiceScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.penaltyShootout,
      builder: (context, state) => _DeferredLoader(
        load: penalty_shootout_screen_def.loadLibrary,
        builder: () => penalty_shootout_screen_def.PenaltyShootoutScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tapJump,
      builder: (context, state) => _DeferredLoader(
        load: tap_jump_screen_def.loadLibrary,
        builder: () => tap_jump_screen_def.TapJumpScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.beatTap,
      builder: (context, state) => _DeferredLoader(
        load: beat_tap_screen_def.loadLibrary,
        builder: () => beat_tap_screen_def.BeatTapScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.hoopShot,
      builder: (context, state) => _DeferredLoader(
        load: hoop_shot_screen_def.loadLibrary,
        builder: () => hoop_shot_screen_def.HoopShotScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.cupShuffle,
      builder: (context, state) => _DeferredLoader(
        load: cup_shuffle_screen_def.loadLibrary,
        builder: () => cup_shuffle_screen_def.CupShuffleScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.matchThree,
      builder: (context, state) => _DeferredLoader(
        load: match_three_screen_def.loadLibrary,
        builder: () => match_three_screen_def.MatchThreeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.balloonPop,
      builder: (context, state) => _DeferredLoader(
        load: balloon_pop_screen_def.loadLibrary,
        builder: () => balloon_pop_screen_def.BalloonPopScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.lemonadeStand,
      builder: (context, state) => _DeferredLoader(
        load: lemonade_stand_screen_def.loadLibrary,
        builder: () => lemonade_stand_screen_def.LemonadeStandScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.stickHero,
      builder: (context, state) => _DeferredLoader(
        load: stick_hero_screen_def.loadLibrary,
        builder: () => stick_hero_screen_def.StickHeroScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.higherLower,
      builder: (context, state) => _DeferredLoader(
        load: higher_lower_screen_def.loadLibrary,
        builder: () => higher_lower_screen_def.HigherLowerScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.crossyLane,
      builder: (context, state) => _DeferredLoader(
        load: crossy_lane_screen_def.loadLibrary,
        builder: () => crossy_lane_screen_def.CrossyLaneScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.countingStars,
      builder: (context, state) => _DeferredLoader(
        load: counting_stars_screen_def.loadLibrary,
        builder: () => counting_stars_screen_def.CountingStarsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.numberMemory,
      builder: (context, state) => _DeferredLoader(
        load: number_memory_screen_def.loadLibrary,
        builder: () => number_memory_screen_def.NumberMemoryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.sumHunt,
      builder: (context, state) => _DeferredLoader(
        load: sum_hunt_screen_def.loadLibrary,
        builder: () => sum_hunt_screen_def.SumHuntScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.schulte,
      builder: (context, state) => _DeferredLoader(
        load: schulte_screen_def.loadLibrary,
        builder: () => schulte_screen_def.SchulteScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.stroop,
      builder: (context, state) => _DeferredLoader(
        load: stroop_screen_def.loadLibrary,
        builder: () => stroop_screen_def.StroopScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.findTwin,
      builder: (context, state) => _DeferredLoader(
        load: find_twin_screen_def.loadLibrary,
        builder: () => find_twin_screen_def.FindTwinScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.patternNext,
      builder: (context, state) => _DeferredLoader(
        load: pattern_next_screen_def.loadLibrary,
        builder: () => pattern_next_screen_def.PatternNextScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.greaterThan,
      builder: (context, state) => _DeferredLoader(
        load: greater_than_screen_def.loadLibrary,
        builder: () => greater_than_screen_def.GreaterThanScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.asteroidDodge,
      builder: (context, state) => _DeferredLoader(
        load: asteroid_dodge_screen_def.loadLibrary,
        builder: () => asteroid_dodge_screen_def.AsteroidDodgeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.romanNumerals,
      builder: (context, state) => _DeferredLoader(
        load: roman_numerals_screen_def.loadLibrary,
        builder: () => roman_numerals_screen_def.RomanNumeralsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.fractionMatch,
      builder: (context, state) => _DeferredLoader(
        load: fraction_match_screen_def.loadLibrary,
        builder: () => fraction_match_screen_def.FractionMatchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.evenOdd,
      builder: (context, state) => _DeferredLoader(
        load: even_odd_screen_def.loadLibrary,
        builder: () => even_odd_screen_def.EvenOddScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.primeTap,
      builder: (context, state) => _DeferredLoader(
        load: prime_tap_screen_def.loadLibrary,
        builder: () => prime_tap_screen_def.PrimeTapScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tapLetter,
      builder: (context, state) => _DeferredLoader(
        load: tap_letter_screen_def.loadLibrary,
        builder: () => tap_letter_screen_def.TapLetterScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tapGreatest,
      builder: (context, state) => _DeferredLoader(
        load: tap_greatest_screen_def.loadLibrary,
        builder: () => tap_greatest_screen_def.TapGreatestScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.shapeMatch,
      builder: (context, state) => _DeferredLoader(
        load: shape_match_screen_def.loadLibrary,
        builder: () => shape_match_screen_def.ShapeMatchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.oddColor,
      builder: (context, state) => _DeferredLoader(
        load: odd_color_screen_def.loadLibrary,
        builder: () => odd_color_screen_def.OddColorScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.anagram,
      builder: (context, state) => _DeferredLoader(
        load: anagram_screen_def.loadLibrary,
        builder: () => anagram_screen_def.AnagramScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.speedMath,
      builder: (context, state) => _DeferredLoader(
        load: speed_math_screen_def.loadLibrary,
        builder: () => speed_math_screen_def.SpeedMathScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.clockRead,
      builder: (context, state) => _DeferredLoader(
        load: clock_read_screen_def.loadLibrary,
        builder: () => clock_read_screen_def.ClockReadScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.hangman,
      builder: (context, state) => _DeferredLoader(
        load: hangman_screen_def.loadLibrary,
        builder: () => hangman_screen_def.HangmanScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bowling,
      builder: (context, state) => _DeferredLoader(
        load: bowling_screen_def.loadLibrary,
        builder: () => bowling_screen_def.BowlingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.colorMix,
      builder: (context, state) => _DeferredLoader(
        load: color_mix_screen_def.loadLibrary,
        builder: () => color_mix_screen_def.ColorMixScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.trueFalse,
      builder: (context, state) => _DeferredLoader(
        load: true_false_screen_def.loadLibrary,
        builder: () => true_false_screen_def.TrueFalseScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.selfChallenge,
      builder: (context, state) => _DeferredLoader(
        load: self_challenge_screen_def.loadLibrary,
        builder: () => self_challenge_screen_def.SelfChallengeScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileCard,
      builder: (context, state) => const ProfileCardScreen(),
    ),
    GoRoute(
      path: AppRoutes.account,
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: AppRoutes.premium,
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: AppRoutes.familyProfiles,
      builder: (context, state) => const FamilyProfilesScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) =>
          _kUseV2Screens ? const WelcomeScreenV2() : const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.weeklyDigest,
      builder: (context, state) => _DeferredLoader(
        load: parent_digest.loadLibrary,
        builder: () => parent_digest.WeeklyDigestScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.progressReport,
      builder: (context, state) => _DeferredLoader(
        load: parent_progress.loadLibrary,
        builder: () => parent_progress.ProgressReportScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.homeworkHelper,
      builder: (context, state) => const HomeworkHelperScreen(),
    ),
    GoRoute(
      path: AppRoutes.bossRush,
      builder: (context, state) => _DeferredLoader(
        load: boss_rush.loadLibrary,
        builder: () => boss_rush.BossRushScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.passPlay,
      builder: (context, state) => _DeferredLoader(
        load: pass_play.loadLibrary,
        builder: () => pass_play.PassPlayScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.weeklyTourney,
      builder: (context, state) => _DeferredLoader(
        load: weekly_tourney.loadLibrary,
        builder: () => weekly_tourney.WeeklyTourneyScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.randomQuiz,
      builder: (context, state) => _DeferredLoader(
        load: random_quiz_screen_def.loadLibrary,
        builder: () => random_quiz_screen_def.RandomQuizScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.spelling,
      builder: (context, state) => _DeferredLoader(
        load: spelling_screen_def.loadLibrary,
        builder: () => spelling_screen_def.SpellingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.typeAnswer,
      builder: (context, state) => _DeferredLoader(
        load: type_answer_screen_def.loadLibrary,
        builder: () => type_answer_screen_def.TypeAnswerScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.learningZone,
      builder: (context, state) => _DeferredLoader(
        load: learning_zone_screen_def.loadLibrary,
        builder: () => learning_zone_screen_def.LearningZoneScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => _DeferredLoader(
        load: admin_v1.loadLibrary,
        builder: () => admin_v1.AdminDashboardScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminV2,
      builder: (context, state) => _DeferredLoader(
        load: admin_v2.loadLibrary,
        builder: () => admin_v2.AdminV2Screen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminDiag,
      builder: (context, state) => const _DiagnosticScreen(),
    ),
  ],
);

/// Pure-Flutter diagnostic page. Zero theme, zero providers, zero shared
/// widgets. If this loads, routing works. If you still see the kid app,
/// it's a service-worker/cache issue, not a code issue.
class _DiagnosticScreen extends StatelessWidget {
  const _DiagnosticScreen();

  @override
  Widget build(BuildContext context) {
    final commit = const String.fromEnvironment(
      'GIT_COMMIT',
      defaultValue: 'no-commit-define',
    );
    final time = const String.fromEnvironment('BUILD_TIME', defaultValue: '?');
    return Material(
      color: const Color(0xFFB30000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DIAGNOSTIC OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'route: ${AppRoutes.adminDiag}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'JetBrainsMono',
                  fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'build: $commit  |  $time',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                  fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'If you see this red page, routing works.\n'
                'Go check /x9k2-console-v2 — if that shows the kid app,\n'
                'tell me. If both show kid app, your browser is loading\n'
                'an old cached bundle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic loader for deferred-imported screens. Shows a brief progress
/// indicator while the .js chunk is fetched, then renders the real screen.
/// Fast on a warm cache, ~50-200ms on the first hit.
class _DeferredLoader extends StatefulWidget {
  const _DeferredLoader({required this.load, required this.builder});
  final Future<void> Function() load;
  final Widget Function() builder;

  @override
  State<_DeferredLoader> createState() => _DeferredLoaderState();
}

class _DeferredLoaderState extends State<_DeferredLoader> {
  late Future<void> _future = widget.load();

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    return FutureBuilder<void>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // Brand-colored splash for the brief moment between route entry
          // and chunk arrival — most chunks load in <300ms over 4G+.
          return Scaffold(
            backgroundColor: const Color(0xFF0F2445),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFC107),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isAr ? 'لحظة…' : 'One moment…',
                    style: const TextStyle(
                      color: Color(0xFFE0F4FF),
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (snap.hasError) {
          // Network blip / chunk fetch failed. Offer retry + go-home so the
          // user isn't stranded on a blank screen.
          return Scaffold(
            backgroundColor: const Color(0xFF0F2445),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌐', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        isAr
                            ? 'تعذَّر تحميل هذا القسم'
                            : "Couldn't load this section",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE0F4FF),
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'تأكَّد من الاتصال بالإنترنت ثم أعد المحاولة.'
                            : 'Check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFA5C9E5),
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              isAr ? 'إعادة المحاولة' : 'Retry',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: const Color(0xFF0F2445),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => ctx.go(AppRoutes.home),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFC107),
                              side: const BorderSide(color: Color(0xFFFFC107)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              isAr ? 'الرئيسية' : 'Home',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return widget.builder();
      },
    );
  }
}
