import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Weekly device-local tournament: single best score per ISO week per
/// family slot. Resets every 7 days (Mon→Sun). Pure offline; no PII.
class TourneyEntry {
  const TourneyEntry({
    required this.slotId,
    required this.score,
    required this.iso,
  });
  final int slotId;
  final int score;
  final String iso; // 'YYYY-WW' identifier

  Map<String, dynamic> toJson() => {'s': slotId, 'sc': score, 'i': iso};

  static TourneyEntry fromJson(Map<String, dynamic> m) => TourneyEntry(
    slotId: (m['s'] as num?)?.toInt() ?? 0,
    score: (m['sc'] as num?)?.toInt() ?? 0,
    iso: (m['i'] as String?) ?? '',
  );
}

class WeeklyTourneyState {
  const WeeklyTourneyState({this.entries = const []});
  final List<TourneyEntry> entries;

  WeeklyTourneyState copyWith({List<TourneyEntry>? entries}) =>
      WeeklyTourneyState(entries: entries ?? this.entries);
}

const _kKey = 'weekly_tourney_v1';

String currentIsoWeek([DateTime? now]) {
  final n = now ?? DateTime.now();
  // ISO 8601 week — keep simple: floor Mon, count weeks since Jan 1.
  final jan1 = DateTime(n.year, 1, 1);
  final daysSince = n.difference(jan1).inDays;
  final week = ((daysSince + jan1.weekday - 1) ~/ 7) + 1;
  return '${n.year}-${week.toString().padLeft(2, '0')}';
}

final weeklyTourneyProvider =
    AsyncNotifierProvider<WeeklyTourneyNotifier, WeeklyTourneyState>(
      WeeklyTourneyNotifier.new,
      name: 'weeklyTourneyProvider',
    );

class WeeklyTourneyNotifier extends AsyncNotifier<WeeklyTourneyState> {
  SharedPreferences? _prefs;

  @override
  Future<WeeklyTourneyState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) return const WeeklyTourneyState();
    try {
      final list = (jsonDecode(raw) as List?) ?? const [];
      final entries = list
          .whereType<Map<String, dynamic>>()
          .map(TourneyEntry.fromJson)
          .toList();
      return WeeklyTourneyState(entries: entries);
    } catch (_) {
      return const WeeklyTourneyState();
    }
  }

  Future<void> recordScore({required int slotId, required int score}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? const WeeklyTourneyState();
    final iso = currentIsoWeek();
    final existing = cur.entries
        .where((e) => e.slotId == slotId && e.iso == iso)
        .toList();
    if (existing.isNotEmpty && existing.first.score >= score) return;
    final filtered = cur.entries
        .where((e) => !(e.slotId == slotId && e.iso == iso))
        .toList();
    filtered.add(TourneyEntry(slotId: slotId, score: score, iso: iso));
    state = AsyncData(cur.copyWith(entries: filtered));
    await _prefs!.setString(
      _kKey,
      jsonEncode(filtered.map((e) => e.toJson()).toList()),
    );
  }

  List<TourneyEntry> currentWeek() {
    final cur = state.value ?? const WeeklyTourneyState();
    final iso = currentIsoWeek();
    final list = cur.entries.where((e) => e.iso == iso).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list;
  }
}
