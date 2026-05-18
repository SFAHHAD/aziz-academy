import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Badge definitions
// =============================================================================

enum BadgeId {
  capitalsExplorer,
  capitalsExpert,
  mapMaster,
  logoDetective,
  logoHunter,
  scienceGenius,
  mathChampion,
  triviaTitan,
  perfectScholar,
  academyStar,
  // ── New trophies ────────────────────────────────────────────────────────
  flagMaster,
  mathGenius,
  streakChampion,
  grandScholar,
  allRounder,
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.emoji,
    required this.color,
  });

  final BadgeId id;
  final String emoji;
  final Color color;
}

/// All badge definitions — order defines display order. Names/descriptions use [AppLocalizations].
const allBadges = [
  BadgeDefinition(
    id: BadgeId.capitalsExplorer,
    emoji: '🌍',
    color: Color(0xFF42A5F5),
  ),
  BadgeDefinition(
    id: BadgeId.capitalsExpert,
    emoji: '🏆',
    color: Color(0xFFFFB300),
  ),
  BadgeDefinition(
    id: BadgeId.mapMaster,
    emoji: '🗺️',
    color: Color(0xFF26A69A),
  ),
  BadgeDefinition(
    id: BadgeId.logoDetective,
    emoji: '🔍',
    color: Color(0xFFAB47BC),
  ),
  BadgeDefinition(
    id: BadgeId.logoHunter,
    emoji: '🎯',
    color: Color(0xFFEF5350),
  ),
  BadgeDefinition(
    id: BadgeId.triviaTitan,
    emoji: '⚡',
    color: Color(0xFFFF7043),
  ),
  BadgeDefinition(
    id: BadgeId.scienceGenius,
    emoji: '🔬',
    color: Color(0xFFC47AC0),
  ),
  BadgeDefinition(
    id: BadgeId.mathChampion,
    emoji: '🔢',
    color: Color(0xFF2C63B3),
  ),
  BadgeDefinition(
    id: BadgeId.perfectScholar,
    emoji: '🎓',
    color: Color(0xFF66BB6A),
  ),
  BadgeDefinition(
    id: BadgeId.academyStar,
    emoji: '🌟',
    color: Color(0xFFFFD600),
  ),
  // ── New trophies ──────────────────────────────────────────────────────────
  BadgeDefinition(
    id: BadgeId.flagMaster,
    emoji: '🚩',
    color: Color(0xFFEF5350),
  ),
  BadgeDefinition(
    id: BadgeId.mathGenius,
    emoji: '🧮',
    color: Color(0xFF2C63B3),
  ),
  BadgeDefinition(
    id: BadgeId.streakChampion,
    emoji: '🔥',
    color: Color(0xFFFF7043),
  ),
  BadgeDefinition(
    id: BadgeId.grandScholar,
    emoji: '📚',
    color: Color(0xFF66BB6A),
  ),
  BadgeDefinition(
    id: BadgeId.allRounder,
    emoji: '🌈',
    color: Color(0xFFAB47BC),
  ),
];

// =============================================================================
// State
// =============================================================================

class AchievementState {
  const AchievementState({
    this.capitalsStars = 0,
    this.logosStars = 0,
    this.mathStars = 0,
    this.sciencesStars = 0,
    this.flagsStars = 0,
    this.capitalsCompleted = 0,
    this.logosCompleted = 0,
    this.mathCompleted = 0,
    this.sciencesCompleted = 0,
    this.flagsCompleted = 0,
    this.mathPerfect = 0,
    this.totalCorrect = 0,
    this.streakCount = 0,
    this.lastVisitDate,
    this.continentsTapped = const {},
    this.unlockedBadges = const {},
  });

  final int capitalsStars;      // best star rating earned in Capitals (0-3)
  final int logosStars;         // best star rating earned in Logos (0-3)
  final int mathStars;
  final int sciencesStars;
  final int flagsStars;
  final int capitalsCompleted;  // total capitals quiz completions
  final int logosCompleted;     // total logos quiz completions
  final int mathCompleted;
  final int sciencesCompleted;
  final int flagsCompleted;
  final int mathPerfect;        // math sessions completed with 3 lives remaining
  final int totalCorrect;       // cumulative correct answers across all modules
  /// Consecutive calendar days the learner opened the app (updated on home).
  final int streakCount;
  /// Local date `yyyy-MM-dd` of the last streak update.
  final String? lastVisitDate;
  final Set<String> continentsTapped;   // continent IDs tapped in Map Explorer
  final Set<BadgeId> unlockedBadges;

  /// Progress bar target (lifetime correct answers) — kept modest for kids.
  static const int maxCorrectForProgress = 30;
  double get progress =>
      (totalCorrect / maxCorrectForProgress).clamp(0.0, 1.0);

  AchievementState copyWith({
    int? capitalsStars,
    int? logosStars,
    int? mathStars,
    int? sciencesStars,
    int? flagsStars,
    int? capitalsCompleted,
    int? logosCompleted,
    int? mathCompleted,
    int? sciencesCompleted,
    int? flagsCompleted,
    int? mathPerfect,
    int? totalCorrect,
    int? streakCount,
    String? lastVisitDate,
    Set<String>? continentsTapped,
    Set<BadgeId>? unlockedBadges,
  }) {
    return AchievementState(
      capitalsStars: capitalsStars ?? this.capitalsStars,
      logosStars: logosStars ?? this.logosStars,
      mathStars: mathStars ?? this.mathStars,
      sciencesStars: sciencesStars ?? this.sciencesStars,
      flagsStars: flagsStars ?? this.flagsStars,
      capitalsCompleted: capitalsCompleted ?? this.capitalsCompleted,
      logosCompleted: logosCompleted ?? this.logosCompleted,
      mathCompleted: mathCompleted ?? this.mathCompleted,
      sciencesCompleted: sciencesCompleted ?? this.sciencesCompleted,
      flagsCompleted: flagsCompleted ?? this.flagsCompleted,
      mathPerfect: mathPerfect ?? this.mathPerfect,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      streakCount: streakCount ?? this.streakCount,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      continentsTapped: continentsTapped ?? this.continentsTapped,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}

// =============================================================================
// Pure badge rules (testable)
// =============================================================================

/// Applies unlock rules from gameplay stats. Used by [AchievementNotifier] and tests.
AchievementState applyBadgeUnlocks(AchievementState s) {
  final unlocked = Set<BadgeId>.from(s.unlockedBadges);

  if (s.capitalsCompleted >= 1) unlocked.add(BadgeId.capitalsExplorer);
  if (s.capitalsStars >= 3) unlocked.add(BadgeId.capitalsExpert);
  if (s.continentsTapped.length >= 6) unlocked.add(BadgeId.mapMaster);
  if (s.logosCompleted >= 1) unlocked.add(BadgeId.logoDetective);
  if (s.logosStars >= 3) unlocked.add(BadgeId.logoHunter);
  if (s.totalCorrect >= 25) unlocked.add(BadgeId.triviaTitan);
  if (s.sciencesStars >= 3) unlocked.add(BadgeId.scienceGenius);
  if (s.mathStars >= 3) unlocked.add(BadgeId.mathChampion);

  // ── New trophy rules ──────────────────────────────────────────────────────
  if (s.flagsCompleted >= 10) unlocked.add(BadgeId.flagMaster);
  if (s.mathPerfect >= 5) unlocked.add(BadgeId.mathGenius);
  if (s.streakCount >= 7) unlocked.add(BadgeId.streakChampion);
  if (s.totalCorrect >= 50) unlocked.add(BadgeId.grandScholar);
  if (s.capitalsCompleted >= 1 &&
      s.flagsCompleted >= 1 &&
      s.logosCompleted >= 1 &&
      s.mathCompleted >= 1 &&
      s.sciencesCompleted >= 1) {
    unlocked.add(BadgeId.allRounder);
  }

  if (unlocked.contains(BadgeId.capitalsExpert) &&
      unlocked.contains(BadgeId.logoHunter) &&
      unlocked.contains(BadgeId.scienceGenius) &&
      unlocked.contains(BadgeId.mathChampion)) {
    unlocked.add(BadgeId.perfectScholar);
  }

  final prerequisite = BadgeId.values.where((b) => b != BadgeId.academyStar);
  if (prerequisite.every((b) => unlocked.contains(b))) {
    unlocked.add(BadgeId.academyStar);
  }

  return s.copyWith(unlockedBadges: unlocked);
}

// =============================================================================
// SharedPreferences keys
// =============================================================================

class _Keys {
  static const capitalsStars = 'ach_capitals_stars';
  static const logosStars = 'ach_logos_stars';
  static const mathStars = 'ach_math_stars';
  static const sciencesStars = 'ach_sciences_stars';
  static const flagsStars = 'ach_flags_stars';
  static const capitalsCompleted = 'ach_capitals_completed';
  static const logosCompleted = 'ach_logos_completed';
  static const mathCompleted = 'ach_math_completed';
  static const sciencesCompleted = 'ach_sciences_completed';
  static const flagsCompleted = 'ach_flags_completed';
  static const mathPerfect = 'ach_math_perfect';
  static const totalCorrect = 'ach_total_correct';
  static const streakCount = 'ach_streak_count';
  static const lastVisitDate = 'ach_last_visit_date';
  static const continentsTapped = 'ach_continents_tapped'; // JSON list<String>
  static const unlockedBadges = 'ach_unlocked_badges';     // JSON list<String>
}

// =============================================================================
// Provider
// =============================================================================

final achievementProvider =
    AsyncNotifierProvider<AchievementNotifier, AchievementState>(
  AchievementNotifier.new,
  name: 'achievementProvider',
);

class AchievementNotifier extends AsyncNotifier<AchievementState> {
  late SharedPreferences _prefs;

  @override
  Future<AchievementState> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _load();
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  AchievementState _load() {
    final continentsList =
        jsonDecode(_prefs.getString(_Keys.continentsTapped) ?? '[]') as List;
    final badgesList =
        jsonDecode(_prefs.getString(_Keys.unlockedBadges) ?? '[]') as List;

    final continents = continentsList.cast<String>().toSet();
    final badges = badgesList
        .cast<String>()
        .map((n) => BadgeId.values.firstWhere(
              (b) => b.name == n,
              orElse: () => BadgeId.capitalsExplorer,
            ))
        .toSet();

    return AchievementState(
      capitalsStars: _prefs.getInt(_Keys.capitalsStars) ?? 0,
      logosStars: _prefs.getInt(_Keys.logosStars) ?? 0,
      mathStars: _prefs.getInt(_Keys.mathStars) ?? 0,
      sciencesStars: _prefs.getInt(_Keys.sciencesStars) ?? 0,
      flagsStars: _prefs.getInt(_Keys.flagsStars) ?? 0,
      capitalsCompleted: _prefs.getInt(_Keys.capitalsCompleted) ?? 0,
      logosCompleted: _prefs.getInt(_Keys.logosCompleted) ?? 0,
      mathCompleted: _prefs.getInt(_Keys.mathCompleted) ?? 0,
      sciencesCompleted: _prefs.getInt(_Keys.sciencesCompleted) ?? 0,
      flagsCompleted: _prefs.getInt(_Keys.flagsCompleted) ?? 0,
      mathPerfect: _prefs.getInt(_Keys.mathPerfect) ?? 0,
      totalCorrect: _prefs.getInt(_Keys.totalCorrect) ?? 0,
      streakCount: _prefs.getInt(_Keys.streakCount) ?? 0,
      lastVisitDate: _prefs.getString(_Keys.lastVisitDate),
      continentsTapped: continents,
      unlockedBadges: badges,
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save(AchievementState s) async {
    await Future.wait([
      _prefs.setInt(_Keys.capitalsStars, s.capitalsStars),
      _prefs.setInt(_Keys.logosStars, s.logosStars),
      _prefs.setInt(_Keys.mathStars, s.mathStars),
      _prefs.setInt(_Keys.sciencesStars, s.sciencesStars),
      _prefs.setInt(_Keys.flagsStars, s.flagsStars),
      _prefs.setInt(_Keys.capitalsCompleted, s.capitalsCompleted),
      _prefs.setInt(_Keys.logosCompleted, s.logosCompleted),
      _prefs.setInt(_Keys.mathCompleted, s.mathCompleted),
      _prefs.setInt(_Keys.sciencesCompleted, s.sciencesCompleted),
      _prefs.setInt(_Keys.flagsCompleted, s.flagsCompleted),
      _prefs.setInt(_Keys.mathPerfect, s.mathPerfect),
      _prefs.setInt(_Keys.totalCorrect, s.totalCorrect),
      _prefs.setInt(_Keys.streakCount, s.streakCount),
      if (s.lastVisitDate != null)
        _prefs.setString(_Keys.lastVisitDate, s.lastVisitDate!)
      else
        _prefs.remove(_Keys.lastVisitDate),
      _prefs.setString(
        _Keys.continentsTapped,
        jsonEncode(s.continentsTapped.toList()),
      ),
      _prefs.setString(
        _Keys.unlockedBadges,
        jsonEncode(s.unlockedBadges.map((b) => b.name).toList()),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Call when Capitals quiz session completes.
  Future<void> recordCapitalsSession({
    required int score,
    required int livesRemaining,
  }) async {
    final current = state.value;
    if (current == null) return;

    final stars = livesRemaining.clamp(0, 3);
    var next = current.copyWith(
      capitalsStars:
          stars > current.capitalsStars ? stars : current.capitalsStars,
      capitalsCompleted: current.capitalsCompleted + 1,
      totalCorrect: current.totalCorrect + score,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  /// Call when Flags quiz session completes.
  Future<void> recordFlagsSession({
    required int score,
    required int livesRemaining,
  }) async {
    final current = state.value;
    if (current == null) return;

    final stars = livesRemaining.clamp(0, 3);
    var next = current.copyWith(
      flagsStars: stars > current.flagsStars ? stars : current.flagsStars,
      flagsCompleted: current.flagsCompleted + 1,
      totalCorrect: current.totalCorrect + score,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  /// Call when Logos quiz session completes.
  Future<void> recordLogosSession({
    required int score,
    required int livesRemaining,
  }) async {
    final current = state.value;
    if (current == null) return;

    final stars = livesRemaining.clamp(0, 3);
    var next = current.copyWith(
      logosStars: stars > current.logosStars ? stars : current.logosStars,
      logosCompleted: current.logosCompleted + 1,
      totalCorrect: current.totalCorrect + score,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  /// Call from MapsScreen when "Start Quiz" is pressed for a continent.
  Future<void> recordContinentTapped(String continentId) async {
    final current = state.value;
    if (current == null) return;

    if (current.continentsTapped.contains(continentId)) return;
    final updated = {...current.continentsTapped, continentId};
    var next = current.copyWith(continentsTapped: updated);
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> recordMathSession({
    required int score,
    required int livesRemaining,
  }) async {
    final current = state.value;
    if (current == null) return;

    final stars = livesRemaining.clamp(0, 3);
    final isPerfect = livesRemaining >= 3;
    var next = current.copyWith(
      mathStars: stars > current.mathStars ? stars : current.mathStars,
      mathCompleted: current.mathCompleted + 1,
      mathPerfect: current.mathPerfect + (isPerfect ? 1 : 0),
      totalCorrect: current.totalCorrect + score,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> recordSciencesSession({
    required int score,
    required int livesRemaining,
  }) async {
    final current = state.value;
    if (current == null) return;

    final stars = livesRemaining.clamp(0, 3);
    var next = current.copyWith(
      sciencesStars: stars > current.sciencesStars ? stars : current.sciencesStars,
      sciencesCompleted: current.sciencesCompleted + 1,
      totalCorrect: current.totalCorrect + score,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  /// Updates daily streak when the learner opens the home hub (once per calendar day).
  Future<void> recordDailyVisit() async {
    final current = state.value;
    if (current == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (current.lastVisitDate == todayStr) return;

    var nextStreak = 1;
    final lastStr = current.lastVisitDate;
    if (lastStr != null) {
      final parsed = DateTime.tryParse(lastStr);
      if (parsed != null) {
        final lastDay = DateTime(parsed.year, parsed.month, parsed.day);
        final diffDays = today.difference(lastDay).inDays;
        if (diffDays == 1) {
          nextStreak = current.streakCount + 1;
        }
      }
    }

    var next = current.copyWith(
      streakCount: nextStreak,
      lastVisitDate: todayStr,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  /// Called when the Daily Challenge session completes.
  /// Increments [totalCorrect] by [score] and re-evaluates badge unlocks.
  /// The streak is updated separately via [recordDailyVisit] (home open).
  Future<void> recordDailyChallenge({required int score}) async {
    final current = state.value;
    if (current == null) return;

    var next = current.copyWith(
      totalCorrect: current.totalCorrect + score,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }

  static int _clampInt(dynamic v, [int max = 1000000]) {
    final n = v is num ? v.toInt() : 0;
    if (n < 0) return 0;
    if (n > max) return max;
    return n;
  }

  /// Overwrites local progress from an imported backup map (same keys as export).
  Future<void> restoreFromBackup(Map<String, dynamic> j) async {
    _prefs = await SharedPreferences.getInstance();

    final continents = <String>{};
    final ct = j['continentsTapped'];
    if (ct is List) {
      for (final e in ct) {
        if (e is String) continents.add(e);
      }
    }

    final badges = <BadgeId>{};
    final ub = j['unlockedBadges'];
    if (ub is List) {
      for (final e in ub) {
        if (e is! String) continue;
        for (final b in BadgeId.values) {
          if (b.name == e) badges.add(b);
        }
      }
    }

    var next = AchievementState(
      capitalsStars: _clampInt(j['capitalsStars'], 3),
      logosStars: _clampInt(j['logosStars'], 3),
      mathStars: _clampInt(j['mathStars'], 3),
      sciencesStars: _clampInt(j['sciencesStars'], 3),
      capitalsCompleted: _clampInt(j['capitalsCompleted']),
      logosCompleted: _clampInt(j['logosCompleted']),
      mathCompleted: _clampInt(j['mathCompleted']),
      sciencesCompleted: _clampInt(j['sciencesCompleted']),
      totalCorrect: _clampInt(j['totalCorrect']),
      streakCount: _clampInt(j['streakCount'], 10000),
      lastVisitDate: j['lastVisitDate'] as String?,
      continentsTapped: continents,
      unlockedBadges: badges,
    );
    next = applyBadgeUnlocks(next);
    state = AsyncData(next);
    await _save(next);
  }
}
