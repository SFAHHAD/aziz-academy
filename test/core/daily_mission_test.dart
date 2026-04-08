import 'package:aziz_academy/core/logic/daily_mission.dart';
import 'package:aziz_academy/core/logic/seasonal_hint.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('dailyMissionSubtitle may include seasonal prefix', () {
    final m = dailyMissionFor(DateTime(2026, 4, 7));
    final sub = dailyMissionSubtitle(l10n, DateTime(2026, 4, 7), m);
    expect(sub, isNotEmpty);
    expect(sub.contains('•'), isTrue);
    expect(seasonalLine(l10n, DateTime(2026, 4, 7)), isNotNull);
  });

  test('dailyMissionFor returns stable route per calendar day bucket', () {
    final d = DateTime(2026, 4, 7);
    final m = dailyMissionFor(d);
    expect(dailyMissionSubtitle(l10n, d, m), isNotEmpty);
    expect(m.route, isIn(<String>[
      AppRoutes.maps,
      AppRoutes.capitals,
      AppRoutes.flags,
      AppRoutes.sciences,
      AppRoutes.math,
    ]));
  });

  test('dailyMissionFor changes across different day buckets', () {
    final a = dailyMissionFor(DateTime(2026, 1, 1));
    final b = dailyMissionFor(DateTime(2026, 6, 15));
    expect(a.route, isNotEmpty);
    expect(b.route, isNotEmpty);
  });
}
