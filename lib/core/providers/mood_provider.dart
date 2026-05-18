import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily mood check-in — kid taps one of five emoji on the home screen.
/// State holds today's pick + the last 14 daily picks for a parent-side
/// trend line. Pure on-device.
enum Mood { great, good, okay, sad, frustrated }

extension MoodEmoji on Mood {
  String get emoji {
    switch (this) {
      case Mood.great:
        return '😄';
      case Mood.good:
        return '🙂';
      case Mood.okay:
        return '😐';
      case Mood.sad:
        return '😔';
      case Mood.frustrated:
        return '😤';
    }
  }

  String label(bool isAr) {
    switch (this) {
      case Mood.great:
        return isAr ? 'رائع' : 'Great';
      case Mood.good:
        return isAr ? 'جيد' : 'Good';
      case Mood.okay:
        return isAr ? 'لا بأس' : 'Okay';
      case Mood.sad:
        return isAr ? 'حزين' : 'Sad';
      case Mood.frustrated:
        return isAr ? 'محبط' : 'Frustrated';
    }
  }

  static Mood? fromName(String name) {
    for (final m in Mood.values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

class MoodEntry {
  const MoodEntry({required this.ymd, required this.mood});
  final String ymd;
  final Mood mood;

  Map<String, dynamic> toJson() => {'d': ymd, 'm': mood.name};

  static MoodEntry? fromJson(Map<String, dynamic> j) {
    final ymd = j['d'] as String?;
    final m = MoodEmoji.fromName(j['m'] as String? ?? '');
    if (ymd == null || m == null) return null;
    return MoodEntry(ymd: ymd, mood: m);
  }
}

class MoodState {
  const MoodState({this.entries = const []});
  final List<MoodEntry> entries;

  MoodEntry? get today {
    final ymd = _todayYmd();
    for (final e in entries) {
      if (e.ymd == ymd) return e;
    }
    return null;
  }

  MoodState withSet(MoodEntry e) {
    final filtered = entries.where((x) => x.ymd != e.ymd).toList();
    final next = [e, ...filtered];
    next.sort((a, b) => b.ymd.compareTo(a.ymd));
    return MoodState(entries: next.take(60).toList());
  }
}

String _todayYmd() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}-${two(n.month)}-${two(n.day)}';
}

const _kKey = 'mood_v1';

final moodProvider = AsyncNotifierProvider<MoodNotifier, MoodState>(
  MoodNotifier.new,
);

class MoodNotifier extends AsyncNotifier<MoodState> {
  SharedPreferences? _prefs;

  @override
  Future<MoodState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) return const MoodState();
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final entries = <MoodEntry>[];
      for (final m in list) {
        final e = MoodEntry.fromJson(m);
        if (e != null) entries.add(e);
      }
      return MoodState(entries: entries);
    } catch (_) {
      return const MoodState();
    }
  }

  Future<void> setToday(Mood mood) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? const MoodState();
    final next = cur.withSet(MoodEntry(ymd: _todayYmd(), mood: mood));
    state = AsyncData(next);
    await _prefs!.setString(
      _kKey,
      jsonEncode(next.entries.map((e) => e.toJson()).toList()),
    );
  }
}
