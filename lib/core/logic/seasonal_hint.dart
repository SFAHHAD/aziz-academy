import 'package:aziz_academy/l10n/app_localizations.dart';

/// Gregorian-season hint for the daily mission subtitle (bilingual).
String? seasonalLine(AppLocalizations l10n, DateTime now) {
  final m = now.month;
  if (m == 12 || m == 1) {
    return l10n.seasonalWinter;
  }
  if (m >= 3 && m <= 5) {
    return l10n.seasonalSpring;
  }
  if (m >= 6 && m <= 8) {
    return l10n.seasonalSummer;
  }
  if (m >= 9 && m <= 11) {
    return l10n.seasonalAutumn;
  }
  return null;
}
