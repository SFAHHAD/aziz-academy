import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';

/// Pure-Dart Hijri (Umm al-Qura tabular) date calculation. No network, no
/// platform code. Accurate to within 1 day for most modern dates — good
/// enough for a kid's home-screen display, NOT a prayer-time source.
///
/// Algorithm: standard Tabular Islamic calendar (Kuwaiti algorithm)
/// reproduced from public references. Returns 1-based month and day.
class HijriDate {
  const HijriDate({required this.year, required this.month, required this.day});
  final int year;
  final int month;
  final int day;

  static const monthNamesAr = [
    'مُحَرَّم',
    'صَفَر',
    'ربيع الأول',
    'ربيع الآخر',
    'جُمَادَى الأولى',
    'جُمَادَى الآخرة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة',
  ];

  static const monthNamesEn = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qadah',
    'Dhu al-Hijjah',
  ];

  static HijriDate fromGregorian(DateTime g) {
    // Gregorian date → Julian Day Number
    int y = g.year;
    int m = g.month;
    int d = g.day;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    final jdn =
        (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524;

    // JDN → Tabular Islamic date.
    final jd = jdn - 1948440 + 10632;
    final n = (jd - 1) ~/ 10631;
    final j2 = jd - 10631 * n + 354;
    final j =
        ((10985 - j2) ~/ 5316) * ((50 * j2) ~/ 17719) +
        (j2 ~/ 5670) * ((43 * j2) ~/ 15238);
    final j3 =
        j2 -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * j3 ~/ 709).clamp(1, 12);
    final day = j3 - 709 * month ~/ 24;
    final year = 30 * n + j - 30;
    return HijriDate(
      year: year,
      month: month.clamp(1, 12),
      day: day.clamp(1, 30),
    );
  }

  String formatted({required bool arabic}) {
    final m = arabic ? monthNamesAr[month - 1] : monthNamesEn[month - 1];
    final dd = localizeDigits(day, arabic: arabic);
    final yy = localizeDigits(year, arabic: arabic);
    return arabic ? '$dd $m $yy هـ' : '$dd $m $yy AH';
  }
}

/// Gulf-Arabic Gregorian month names (يناير…ديسمبر). Kuwaiti & wider Gulf
/// convention uses these transliterated forms rather than the Levantine set
/// (كانون الثاني…). Matches what parents see on local TV news and school
/// schedules.
const _gregorianMonthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const _gregorianMonthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a [DateTime] as a Gregorian date stamp. Trailing "م" (ميلادي,
/// "Common Era") on the Arabic side mirrors the trailing "هـ" (هجري) used
/// by [HijriDate.formatted], so both calendar stamps read consistently
/// when shown side by side.
String formatGregorian(DateTime g, {required bool arabic}) {
  final m = arabic
      ? _gregorianMonthsAr[g.month - 1]
      : _gregorianMonthsEn[g.month - 1];
  final dd = localizeDigits(g.day, arabic: arabic);
  final yy = localizeDigits(g.year, arabic: arabic);
  return arabic ? '$dd $m $yy م' : '$dd $m $yy';
}

/// Tiny widget — drop into any screen header/footer for a date stamp.
/// Shows Hijri (primary) and Gregorian (secondary, muted) in one pill so
/// kids and parents can read whichever calendar they think in.
class HijriDatePill extends StatelessWidget {
  const HijriDatePill({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final now = DateTime.now();
    final hijri = HijriDate.fromGregorian(now);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hijri (primary): bold + gold so the Islamic calendar reads as
          // the "lead" date stamp.
          Text(
            hijri.formatted(arabic: isAr),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.divider,
            ),
          ),
          const SizedBox(width: 8),
          // Gregorian (secondary): lighter weight, muted colour, smaller,
          // with a touch of letter-spacing for that quiet almanac feel.
          // Same Cairo family as the Hijri side — using a different family
          // (e.g. Amiri italic) triggers the FontFallbackManager because
          // we don't bundle an Amiri italic variant, locking renderer in
          // a "Could not find Noto fonts" requestAnimationFrame loop.
          Text(
            formatGregorian(now, arabic: isAr),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium.withAlpha(160),
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
