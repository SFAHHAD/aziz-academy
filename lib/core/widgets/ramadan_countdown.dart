import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/utils/hijri_date.dart';

/// Compact pill that shows days until Ramadan begins (Hijri month 9), or
/// "Day N of Ramadan" when the kid opens the app during Ramadan, or the
/// next Eid-al-Fitr / Eid-al-Adha indicator when those are within 30 days.
/// Pure calculation — no notifications, no permissions, no network.
class RamadanCountdown extends StatelessWidget {
  const RamadanCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final today = HijriDate.fromGregorian(DateTime.now());

    final (label, badge) = _resolveLabel(today, isAr);
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(48),
            AppColors.secondary.withAlpha(36),
          ],
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.accent.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (label, emoji) or (null, '') when no event is within window.
  (String?, String) _resolveLabel(HijriDate today, bool isAr) {
    if (today.month == 9) {
      // In Ramadan.
      final n = localizeDigits(today.day, arabic: isAr);
      return (isAr ? 'يوم $n من رمضان' : 'Ramadan day $n', '🌙');
    }
    final daysToRamadan = _daysUntilHijri(today, ramadanMonth: 9);
    if (daysToRamadan != null && daysToRamadan <= 60) {
      final n = localizeDigits(daysToRamadan, arabic: isAr);
      return (isAr ? '$n يومًا حتى رمضان' : '$n days to Ramadan', '🌙');
    }
    if (today.month == 10 && today.day <= 3) {
      return (isAr ? 'عيد الفطر' : 'Eid al-Fitr', '🎉');
    }
    if (today.month == 12 && today.day >= 9 && today.day <= 13) {
      return (isAr ? 'عيد الأضحى' : 'Eid al-Adha', '🐑');
    }
    return (null, '');
  }

  /// Approximate days until the upcoming Ramadan. Hijri months alternate
  /// 29/30 days; over a window of ≤60 days the rough average of 29.53 is
  /// accurate enough for a kid-facing countdown.
  static int? _daysUntilHijri(HijriDate today, {required int ramadanMonth}) {
    if (today.month >= ramadanMonth) return null;
    final monthsAway = ramadanMonth - today.month;
    final approxDays = (monthsAway * 29.53 - today.day + 1).round();
    return approxDays > 0 ? approxDays : null;
  }
}
