import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';

/// Per-child learning profile. Single source of truth for all in-app agents.
/// Lives entirely on-device (no telemetry uploaded).
@immutable
class LearnerState {
  const LearnerState({
    this.skillByModule = const <String, double>{},
    this.skillByModuleCategory = const <String, Map<String, double>>{},
    this.recentSessions = const <SessionStat>[],
    this.recentErrors = const <ErrorMark>[],
    this.frustrationLevel = 0.0,
    this.fastSessionRatio = 0.0,
    this.totalSessions = 0,
    this.interests = const <String>{},
    this.readingSupportAuto = false,
    this.shortSessionsAuto = false,
    this.lastSessionAt,
  });

  /// Skill per module on a 0..1 scale (rolling accuracy proxy).
  final Map<String, double> skillByModule;

  /// Skill per (module, category) on a 0..1 scale. Used by Brain Boost radar
  /// and any other module that wants to drill in by category.
  final Map<String, Map<String, double>> skillByModuleCategory;

  /// Last 30 session stats (newest first).
  final List<SessionStat> recentSessions;

  /// Last 50 error marks (newest first). Used by mistake-pattern + review.
  final List<ErrorMark> recentErrors;

  /// 0..1 — climbs on rapid retries / accuracy drop / rage-quits.
  /// Decays slowly. Triggers C2 Encouragement at >= 0.6.
  final double frustrationLevel;

  /// Ratio of recent sessions that ended in <60s. Triggers G2 Attention-Aware.
  final double fastSessionRatio;

  final int totalSessions;

  /// Optional onboarding interests ('animals', 'space', 'sports', ...).
  final Set<String> interests;

  /// Auto-enabled by G1 Reading-Support when text-question latency too high.
  final bool readingSupportAuto;

  /// Auto-enabled by G2 Attention-Aware when sessions are consistently short.
  final bool shortSessionsAuto;

  final DateTime? lastSessionAt;

  LearnerState copyWith({
    Map<String, double>? skillByModule,
    Map<String, Map<String, double>>? skillByModuleCategory,
    List<SessionStat>? recentSessions,
    List<ErrorMark>? recentErrors,
    double? frustrationLevel,
    double? fastSessionRatio,
    int? totalSessions,
    Set<String>? interests,
    bool? readingSupportAuto,
    bool? shortSessionsAuto,
    DateTime? lastSessionAt,
  }) {
    return LearnerState(
      skillByModule: skillByModule ?? this.skillByModule,
      skillByModuleCategory:
          skillByModuleCategory ?? this.skillByModuleCategory,
      recentSessions: recentSessions ?? this.recentSessions,
      recentErrors: recentErrors ?? this.recentErrors,
      frustrationLevel: frustrationLevel ?? this.frustrationLevel,
      fastSessionRatio: fastSessionRatio ?? this.fastSessionRatio,
      totalSessions: totalSessions ?? this.totalSessions,
      interests: interests ?? this.interests,
      readingSupportAuto: readingSupportAuto ?? this.readingSupportAuto,
      shortSessionsAuto: shortSessionsAuto ?? this.shortSessionsAuto,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
    );
  }

  /// Module skill on 0..1 (fallback 0.5 = unknown).
  double skillFor(String module) => skillByModule[module] ?? 0.5;

  /// Per-category skill within a module. Fallback 0.5 if no signal yet.
  double skillForCategory(String module, String category) {
    return skillByModuleCategory[module]?[category] ?? 0.5;
  }

  /// Categories the learner has attempted within a module.
  Iterable<String> categoriesFor(String module) =>
      skillByModuleCategory[module]?.keys ?? const Iterable.empty();

  /// Top-2 weakest modules (by skill, only those with at least 1 session).
  List<String> weakestModules({int limit = 2}) {
    final entries = skillByModule.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  Map<String, dynamic> toJson() => {
    'skill': skillByModule,
    'skillCat': skillByModuleCategory.map((mod, cats) => MapEntry(mod, cats)),
    'sess': recentSessions.map((e) => e.toJson()).toList(),
    'err': recentErrors.map((e) => e.toJson()).toList(),
    'frust': frustrationLevel,
    'fastR': fastSessionRatio,
    'total': totalSessions,
    'int': interests.toList(),
    'rsa': readingSupportAuto,
    'ssa': shortSessionsAuto,
    'last': lastSessionAt?.toIso8601String(),
  };

  static LearnerState fromJson(Map<String, dynamic> m) {
    final rawCat = (m['skillCat'] as Map<String, dynamic>? ?? const {});
    final skillCat = <String, Map<String, double>>{
      for (final entry in rawCat.entries)
        entry.key: (entry.value as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
    };
    return LearnerState(
      skillByModule: (m['skill'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      skillByModuleCategory: skillCat,
      recentSessions: ((m['sess'] as List?) ?? const [])
          .map((e) => SessionStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentErrors: ((m['err'] as List?) ?? const [])
          .map((e) => ErrorMark.fromJson(e as Map<String, dynamic>))
          .toList(),
      frustrationLevel: (m['frust'] as num?)?.toDouble() ?? 0.0,
      fastSessionRatio: (m['fastR'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (m['total'] as num?)?.toInt() ?? 0,
      interests: ((m['int'] as List?) ?? const []).cast<String>().toSet(),
      readingSupportAuto: m['rsa'] as bool? ?? false,
      shortSessionsAuto: m['ssa'] as bool? ?? false,
      lastSessionAt: m['last'] is String
          ? DateTime.tryParse(m['last'] as String)
          : null,
    );
  }
}

@immutable
class SessionStat {
  const SessionStat({
    required this.module,
    required this.score,
    required this.total,
    required this.durationMs,
    required this.endedAt,
  });

  final String module;
  final int score;
  final int total;
  final int durationMs;
  final DateTime endedAt;

  double get accuracy => total == 0 ? 0 : score / total;

  Map<String, dynamic> toJson() => {
    'm': module,
    's': score,
    't': total,
    'd': durationMs,
    'e': endedAt.toIso8601String(),
  };

  static SessionStat fromJson(Map<String, dynamic> m) => SessionStat(
    module: m['m'] as String,
    score: (m['s'] as num).toInt(),
    total: (m['t'] as num).toInt(),
    durationMs: (m['d'] as num).toInt(),
    endedAt: DateTime.parse(m['e'] as String),
  );
}

@immutable
class ErrorMark {
  const ErrorMark({
    required this.module,
    required this.category,
    required this.questionId,
    required this.at,
  });

  final String module;
  final String category;
  final String questionId;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'm': module,
    'c': category,
    'q': questionId,
    'a': at.toIso8601String(),
  };

  static ErrorMark fromJson(Map<String, dynamic> m) => ErrorMark(
    module: m['m'] as String,
    category: m['c'] as String,
    questionId: m['q'] as String,
    at: DateTime.parse(m['a'] as String),
  );
}

const _kStateKey = 'learner_state_v1';
const _kMaxSessions = 30;
const _kMaxErrors = 50;

final learnerStateProvider =
    AsyncNotifierProvider<LearnerStateNotifier, LearnerState>(
      LearnerStateNotifier.new,
      name: 'learnerStateProvider',
    );

class LearnerStateNotifier extends AsyncNotifier<LearnerState> {
  SharedPreferences? _prefs;

  StreamSubscription<LearningEvent>? _busSub;

  // Tracks latest session being assembled.
  final List<({bool correct, int latencyMs, int? difficulty, String? cat})>
  _live = [];
  String? _liveModule;
  DateTime? _liveStart;

  @override
  Future<LearnerState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kStateKey);
    final initial = raw == null ? const LearnerState() : _safeDecode(raw);
    _busSub = ref.read(eventBusProvider).stream.listen(_onEvent);
    ref.onDispose(() => _busSub?.cancel());
    return initial;
  }

  LearnerState _safeDecode(String raw) {
    try {
      return LearnerState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const LearnerState();
    }
  }

  Future<void> _persist(LearnerState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(_kStateKey, jsonEncode(s.toJson()));
  }

  void _onEvent(LearningEvent e) {
    switch (e.type) {
      case LearningEventType.sessionStarted:
        _live.clear();
        _liveModule = e.module;
        _liveStart = e.timestamp;
        return;
      case LearningEventType.questionAnswered:
        _live.add((
          correct: e.correct ?? false,
          latencyMs: e.latencyMs ?? 0,
          difficulty: e.difficulty,
          cat: e.category,
        ));
        // Per-event mistake log
        if (e.correct == false && e.questionId != null && e.category != null) {
          _appendError(
            ErrorMark(
              module: e.module,
              category: e.category!,
              questionId: e.questionId!,
              at: e.timestamp,
            ),
          );
        }
        return;
      case LearningEventType.sessionEnded:
        _finalizeSession(e);
        return;
      case LearningEventType.rageQuit:
        _bumpFrustration(0.25);
        _finalizeSession(e);
        return;
      case LearningEventType.idleTimeout:
        _bumpFrustration(0.05);
        return;
      case LearningEventType.questionStarted:
      case LearningEventType.hintUsed:
      case LearningEventType.lifelineUsed:
        return;
    }
  }

  void _bumpFrustration(double delta) {
    final cur = state.value ?? const LearnerState();
    final next = (cur.frustrationLevel + delta).clamp(0.0, 1.0);
    _persist(cur.copyWith(frustrationLevel: next));
  }

  Future<void> _appendError(ErrorMark mark) async {
    final cur = state.value ?? const LearnerState();
    final next = <ErrorMark>[mark, ...cur.recentErrors];
    if (next.length > _kMaxErrors) next.removeRange(_kMaxErrors, next.length);
    await _persist(cur.copyWith(recentErrors: next));
  }

  Future<void> _finalizeSession(LearningEvent endEvent) async {
    if (_liveModule == null || _liveStart == null) return;
    final answered = _live.where((q) => q.latencyMs > 0).toList();
    final correct = answered.where((q) => q.correct).length;
    final total = answered.length;
    final dur = endEvent.timestamp.difference(_liveStart!).inMilliseconds.abs();

    final cur = state.value ?? const LearnerState();
    final stat = SessionStat(
      module: _liveModule!,
      score: correct,
      total: total,
      durationMs: dur,
      endedAt: endEvent.timestamp,
    );

    final newSessions = <SessionStat>[stat, ...cur.recentSessions];
    if (newSessions.length > _kMaxSessions) {
      newSessions.removeRange(_kMaxSessions, newSessions.length);
    }

    // Skill: EMA of accuracy per module (alpha = 0.35).
    final newSkill = Map<String, double>.from(cur.skillByModule);
    if (total > 0) {
      final acc = correct / total;
      final prev = newSkill[_liveModule!] ?? 0.5;
      newSkill[_liveModule!] = (prev * 0.65 + acc * 0.35).clamp(0.0, 1.0);
    }

    // Per-category EMA (alpha = 0.4 — slightly more reactive since each
    // category sees fewer answers per session).
    final newSkillCat = <String, Map<String, double>>{
      for (final entry in cur.skillByModuleCategory.entries)
        entry.key: Map<String, double>.from(entry.value),
    };
    final byCat = <String, ({int hit, int n})>{};
    for (final q in answered) {
      final c = q.cat;
      if (c == null || c.isEmpty) continue;
      final cur = byCat[c] ?? (hit: 0, n: 0);
      byCat[c] = (hit: cur.hit + (q.correct ? 1 : 0), n: cur.n + 1);
    }
    if (byCat.isNotEmpty) {
      final modCats = newSkillCat.putIfAbsent(
        _liveModule!,
        () => <String, double>{},
      );
      byCat.forEach((cat, agg) {
        final acc = agg.hit / agg.n;
        final prev = modCats[cat] ?? 0.5;
        modCats[cat] = (prev * 0.6 + acc * 0.4).clamp(0.0, 1.0);
      });
    }

    // Decay frustration, but bump if accuracy collapsed in this session.
    var frust = cur.frustrationLevel * 0.7;
    if (total >= 4 && correct / total < 0.4) {
      frust = (frust + 0.2).clamp(0.0, 1.0);
    }

    // Fast-session ratio over the last 10 sessions.
    final last10 = newSessions.take(10);
    final shorts = last10.where((s) => s.durationMs < 60000).length;
    final fastRatio = last10.isEmpty ? 0.0 : shorts / last10.length;

    // Auto-flags (G1, G2). Set sticky once tripped; user can override in settings.
    final readingAuto = cur.readingSupportAuto || _shouldAutoEnableRead(stat);
    final shortAuto = cur.shortSessionsAuto || fastRatio >= 0.7;

    await _persist(
      cur.copyWith(
        skillByModule: newSkill,
        skillByModuleCategory: newSkillCat,
        recentSessions: newSessions,
        frustrationLevel: frust,
        fastSessionRatio: fastRatio,
        totalSessions: cur.totalSessions + 1,
        readingSupportAuto: readingAuto,
        shortSessionsAuto: shortAuto,
        lastSessionAt: endEvent.timestamp,
      ),
    );

    _live.clear();
    _liveModule = null;
    _liveStart = null;
  }

  bool _shouldAutoEnableRead(SessionStat stat) {
    // Triggers when the session has at least 4 questions and average answer
    // latency on text-heavy modules exceeds 12 seconds.
    if (!const {'sciences', 'iq', 'general_quiz'}.contains(stat.module)) {
      return false;
    }
    if (_live.length < 4) return false;
    final avgLat =
        _live.map((q) => q.latencyMs).fold<int>(0, (a, b) => a + b) /
        _live.length;
    return avgLat > 12000;
  }

  // ── Public API for non-event mutations ────────────────────────────────────

  Future<void> setInterests(Set<String> interests) async {
    final cur = state.value ?? const LearnerState();
    await _persist(cur.copyWith(interests: interests));
  }

  Future<void> overrideReadingSupport(bool v) async {
    final cur = state.value ?? const LearnerState();
    await _persist(cur.copyWith(readingSupportAuto: v));
  }

  Future<void> overrideShortSessions(bool v) async {
    final cur = state.value ?? const LearnerState();
    await _persist(cur.copyWith(shortSessionsAuto: v));
  }

  /// Test/debug clear.
  Future<void> reset() async {
    await _persist(const LearnerState());
  }
}

// ── Helpers used by other agents ────────────────────────────────────────────

/// Returns 'easy' | 'mid' | 'hard' based on skill on the given module.
/// Used by adaptive_difficulty.dart.
String difficultyBandFor(double skill) {
  if (skill < 0.45) return 'easy';
  if (skill > 0.78) return 'hard';
  return 'mid';
}

/// Maps a band to the difficulty number(s) preferred when sampling.
List<int> preferredDifficulties(String band) {
  switch (band) {
    case 'easy':
      return const [1, 1, 1, 2];
    case 'hard':
      return const [3, 3, 2, 3];
    default:
      return const [2, 2, 1, 3];
  }
}

/// Random-but-weighted picker used by adaptive sampling.
T weightedPick<T>(List<T> items, double Function(T) weight, math.Random rng) {
  if (items.isEmpty) {
    throw StateError('weightedPick on empty list');
  }
  final total = items.fold<double>(0, (a, b) => a + math.max(0.0, weight(b)));
  if (total <= 0) return items[rng.nextInt(items.length)];
  var x = rng.nextDouble() * total;
  for (final it in items) {
    x -= math.max(0.0, weight(it));
    if (x <= 0) return it;
  }
  return items.last;
}
