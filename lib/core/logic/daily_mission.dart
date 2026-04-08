import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/logic/seasonal_hint.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

/// Rotating daily suggestion (no extra tracking — uses calendar day).
class DailyMissionData {
  const DailyMissionData({
    required this.variant,
    required this.route,
  });

  /// 0 = maps, 1 = capitals, 2 = flags, 3 = sciences, 4 = math
  final int variant;
  final String route;
}

DailyMissionData dailyMissionFor(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  final bucket = day.millisecondsSinceEpoch ~/ 86400000;
  final v = bucket % 5;
  final route = switch (v) {
    0 => AppRoutes.maps,
    1 => AppRoutes.capitals,
    2 => AppRoutes.flags,
    3 => AppRoutes.sciences,
    _ => AppRoutes.math,
  };
  return DailyMissionData(variant: v, route: route);
}

/// Subtitle for the mission card, with optional seasonal prefix.
String dailyMissionSubtitle(AppLocalizations l10n, DateTime now, DailyMissionData data) {
  final base = switch (data.variant) {
    0 => l10n.dailyMissionSubtitleMaps,
    1 => l10n.dailyMissionSubtitleCapitals,
    2 => l10n.dailyMissionSubtitleFlags,
    3 => l10n.dailyMissionSubtitleSciences,
    _ => l10n.dailyMissionSubtitleMath,
  };
  final seasonal = seasonalLine(l10n, now);
  if (seasonal == null) return base;
  return '$seasonal • $base';
}

/// CTA label for the gold button (maps uses a different label).
String dailyMissionCta(AppLocalizations l10n, DailyMissionData data) {
  return data.variant == 0
      ? l10n.dailyMissionCtaToMaps
      : l10n.dailyMissionCtaStart;
}
