import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/mental_math/mental_math_engine.dart';

/// Personal best (correct count in 60s) per difficulty band. The screen
/// updates this at round end so the kid can see "you beat your record!"
/// next time. Pure local persistence.
class MentalMathBests {
  const MentalMathBests({required this.byBand});

  /// Map of band name → personal best score.
  final Map<MentalMathBand, int> byBand;

  int bestFor(MentalMathBand b) => byBand[b] ?? 0;

  static const empty = MentalMathBests(byBand: {});

  Map<String, dynamic> toJson() =>
      {for (final e in byBand.entries) e.key.name: e.value};

  static MentalMathBests fromJson(Map<String, dynamic> j) {
    final out = <MentalMathBand, int>{};
    for (final band in MentalMathBand.values) {
      final v = j[band.name];
      if (v is num) out[band] = v.toInt();
    }
    return MentalMathBests(byBand: out);
  }

  MentalMathBests withMax(MentalMathBand b, int score) {
    if (score <= bestFor(b)) return this;
    return MentalMathBests(byBand: {...byBand, b: score});
  }
}

final mentalMathBestsProvider =
    AsyncNotifierProvider<MentalMathBestsNotifier, MentalMathBests>(
  MentalMathBestsNotifier.new,
  name: 'mentalMathBestsProvider',
);

const _kKey = 'mental_math_bests_v1';

class MentalMathBestsNotifier extends AsyncNotifier<MentalMathBests> {
  SharedPreferences? _prefs;

  @override
  Future<MentalMathBests> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null || raw.isEmpty) return MentalMathBests.empty;
    try {
      return MentalMathBests.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return MentalMathBests.empty;
    }
  }

  Future<bool> recordScore(MentalMathBand band, int score) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? MentalMathBests.empty;
    final next = cur.withMax(band, score);
    final isPB = score > cur.bestFor(band);
    state = AsyncData(next);
    await _prefs!.setString(_kKey, jsonEncode(next.toJson()));
    return isPB;
  }
}
