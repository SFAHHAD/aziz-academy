import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';

/// Builds an opt-in, on-device-only CSV of the kid's play stats and shares
/// it via the system share sheet. Two sections:
///   1. Module skill EMA snapshot (one row per module).
///   2. Per-category Brain Boost skill EMA (one row per category).
///
/// No PII (no name, no IDs). Parent can save / email / print, never uploaded
/// by the app itself. Triggered from the parent dashboard.
String buildStatsCsv(LearnerState learner, AchievementState ach) {
  final buf = StringBuffer();
  buf.writeln('section,key,value');
  buf.writeln('summary,total_sessions,${learner.totalSessions}');
  buf.writeln('summary,unlocked_badges,${ach.unlockedBadges.length}');
  buf.writeln('summary,total_correct,${ach.totalCorrect}');
  buf.writeln('summary,streak_count,${ach.streakCount}');
  buf.writeln('summary,bb_streak_best,${ach.brainBoostStreakBest}');
  buf.writeln('summary,bb_daily_completed,${ach.brainBoostDailyCompleted}');
  buf.writeln('summary,boss_rush_perfect,${ach.bossRushPerfectCount}');
  buf.writeln('summary,pass_play_wins,${ach.passPlayWins}');
  buf.writeln('summary,tourney_top_finishes,${ach.tourneyTopFinishes}');

  for (final e in learner.skillByModule.entries) {
    buf.writeln('module_skill,${e.key},${e.value.toStringAsFixed(3)}');
  }
  for (final modEntry in learner.skillByModuleCategory.entries) {
    final mod = modEntry.key;
    for (final catEntry in modEntry.value.entries) {
      buf.writeln(
        'category_skill,$mod/${catEntry.key},${catEntry.value.toStringAsFixed(3)}',
      );
    }
  }
  return buf.toString();
}

Future<void> shareStatsCsv({
  required LearnerState learner,
  required AchievementState ach,
}) async {
  final csv = buildStatsCsv(learner, ach);
  final bytes = csv.codeUnits;
  final ts = DateTime.now().millisecondsSinceEpoch;
  if (kIsWeb) {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'text/csv',
            name: 'aziz_academy_stats_$ts.csv',
          ),
        ],
        text: 'Aziz Academy stats export',
      ),
    );
  } else {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/aziz_academy_stats_$ts.csv';
    final file = File(path);
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Aziz Academy stats export'),
    );
  }
}
