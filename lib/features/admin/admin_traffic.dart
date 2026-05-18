import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Traffic tracking — on-device only.
//
// We capture three things in SharedPreferences so the admin can render a real
// monitoring view without a backend:
//
//   1. App opens — every cold start increments a counter and appends today's
//      ymd to a 90-day rolling set.
//   2. Active days — derived from #1; gives "active in last 7/30 days" KPIs.
//   3. Route hits — every push/replace via the NavigatorObserver below
//      increments a counter keyed by route path.
//
// IMPORTANT: This is a single-device picture. Cross-device visitor counts
// require Vercel Analytics or an analytics SDK; the audit/report section
// surfaces that recommendation explicitly.
// =============================================================================

const _kOpensKey = 'traffic_opens_total_v1';
const _kOpenDaysKey = 'traffic_open_days_v1'; // List<String> of ymd
const _kLastOpenKey = 'traffic_last_open_ms_v1';
const _kFirstOpenKey = 'traffic_first_open_ms_v1';
const _kRouteHitsKey = 'traffic_route_hits_v1'; // {route: count}
const _kRouteLastKey = 'traffic_route_last_v1'; // {route: ms}

const int _kKeepDays = 90;

class TrafficSnapshot {
  const TrafficSnapshot({
    required this.totalOpens,
    required this.activeDays,
    required this.openDaysLast30,
    required this.openDaysLast7,
    required this.firstOpenAt,
    required this.lastOpenAt,
    required this.openHistogramByDay,
    required this.routeHits,
    required this.routeLastSeen,
  });

  final int totalOpens;
  final List<String> activeDays;
  final int openDaysLast7;
  final int openDaysLast30;
  final DateTime? firstOpenAt;
  final DateTime? lastOpenAt;

  /// Last 14 days, oldest first, with 1 if any open occurred or 0 otherwise.
  /// Used for the spark-bar in the dashboard.
  final List<int> openHistogramByDay;
  final Map<String, int> routeHits;
  final Map<String, DateTime> routeLastSeen;

  int get totalRouteHits => routeHits.values.fold<int>(0, (a, b) => a + b);
}

class AdminTraffic {
  AdminTraffic._();

  static SharedPreferences? _prefs;

  static Future<void> _ready() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Call from `main()` once per cold start.
  static Future<void> recordAppOpen() async {
    await _ready();
    final p = _prefs!;
    final now = DateTime.now();
    final ymd = _ymd(now);

    p.setInt(_kOpensKey, (p.getInt(_kOpensKey) ?? 0) + 1);
    if ((p.getInt(_kFirstOpenKey) ?? 0) == 0) {
      await p.setInt(_kFirstOpenKey, now.millisecondsSinceEpoch);
    }
    await p.setInt(_kLastOpenKey, now.millisecondsSinceEpoch);

    final daysRaw = p.getStringList(_kOpenDaysKey) ?? <String>[];
    final cutoff = now.subtract(const Duration(days: _kKeepDays));
    final cutoffYmd = _ymd(cutoff);
    final keep = daysRaw.where((d) => d.compareTo(cutoffYmd) >= 0).toSet();
    keep.add(ymd);
    final out = keep.toList()..sort();
    await p.setStringList(_kOpenDaysKey, out);
  }

  /// Called by [TrafficObserver] on every navigation push / replace.
  static Future<void> recordRouteVisit(String route) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (route.isEmpty) return;
    await _ready();
    final p = _prefs!;

    final hitsRaw = p.getString(_kRouteHitsKey);
    final hits = <String, int>{};
    if (hitsRaw != null) {
      try {
        (jsonDecode(hitsRaw) as Map<String, dynamic>).forEach(
          (k, v) => hits[k] = (v as num).toInt(),
        );
      } catch (_) {}
    }
    hits[route] = (hits[route] ?? 0) + 1;
    await p.setString(_kRouteHitsKey, jsonEncode(hits));

    final lastRaw = p.getString(_kRouteLastKey);
    final last = <String, int>{};
    if (lastRaw != null) {
      try {
        (jsonDecode(lastRaw) as Map<String, dynamic>).forEach(
          (k, v) => last[k] = (v as num).toInt(),
        );
      } catch (_) {}
    }
    last[route] = DateTime.now().millisecondsSinceEpoch;
    await p.setString(_kRouteLastKey, jsonEncode(last));
  }

  static Future<TrafficSnapshot> snapshot() async {
    await _ready();
    final p = _prefs!;
    final now = DateTime.now();

    final total = p.getInt(_kOpensKey) ?? 0;
    final firstMs = p.getInt(_kFirstOpenKey);
    final lastMs = p.getInt(_kLastOpenKey);
    final days = p.getStringList(_kOpenDaysKey) ?? const <String>[];
    final daySet = days.toSet();

    int countSince(int n) {
      var c = 0;
      for (var i = 0; i < n; i++) {
        final d = now.subtract(Duration(days: i));
        if (daySet.contains(_ymd(d))) c++;
      }
      return c;
    }

    final histogram = <int>[];
    for (var i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      histogram.add(daySet.contains(_ymd(d)) ? 1 : 0);
    }

    Map<String, int> hits = {};
    final hitsRaw = p.getString(_kRouteHitsKey);
    if (hitsRaw != null) {
      try {
        (jsonDecode(hitsRaw) as Map<String, dynamic>).forEach(
          (k, v) => hits[k] = (v as num).toInt(),
        );
      } catch (_) {}
    }
    Map<String, DateTime> last = {};
    final lastRaw = p.getString(_kRouteLastKey);
    if (lastRaw != null) {
      try {
        (jsonDecode(lastRaw) as Map<String, dynamic>).forEach((k, v) {
          last[k] = DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
        });
      } catch (_) {}
    }

    return TrafficSnapshot(
      totalOpens: total,
      activeDays: days,
      openDaysLast7: countSince(7),
      openDaysLast30: countSince(30),
      firstOpenAt: firstMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(firstMs),
      lastOpenAt: lastMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMs),
      openHistogramByDay: histogram,
      routeHits: hits,
      routeLastSeen: last,
    );
  }

  /// Wipes all traffic counters. Used by the admin Tools section.
  static Future<void> reset() async {
    await _ready();
    final p = _prefs!;
    await p.remove(_kOpensKey);
    await p.remove(_kOpenDaysKey);
    await p.remove(_kLastOpenKey);
    await p.remove(_kFirstOpenKey);
    await p.remove(_kRouteHitsKey);
    await p.remove(_kRouteLastKey);
  }
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Plug into go_router via `observers: [TrafficObserver()]`.
class TrafficObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AdminTraffic.recordRouteVisit(name);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final name = newRoute?.settings.name;
    if (name != null && name.isNotEmpty) {
      AdminTraffic.recordRouteVisit(name);
    }
  }
}

final trafficSnapshotProvider = FutureProvider<TrafficSnapshot>(
  (ref) => AdminTraffic.snapshot(),
  name: 'trafficSnapshotProvider',
);
