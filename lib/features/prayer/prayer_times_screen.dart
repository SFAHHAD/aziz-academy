import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/utils/hijri_date.dart';
import 'package:aziz_academy/core/utils/prayer_times.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Educational-only prayer-times widget. Defaults to Mecca/Riyadh-area
/// coordinates with Umm al-Qura method. Calculation is approximate and the
/// screen displays a clear "always confirm with your local masjid" notice.
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  // Defaults: Kuwait City (closest major city for the primary audience).
  double _lat = 29.3759;
  double _lon = 47.9774;
  double _tz = 3.0;

  static const _cities = <String, (double, double, double)>{
    'Makkah': (21.4225, 39.8262, 3),
    'Madinah': (24.4667, 39.6111, 3),
    'Riyadh': (24.7136, 46.6753, 3),
    'Jeddah': (21.5433, 39.1728, 3),
    'Dammam': (26.4207, 50.0888, 3),
    'Cairo': (30.0444, 31.2357, 2),
    'Istanbul': (41.0082, 28.9784, 3),
    'Dubai': (25.2048, 55.2708, 4),
    'Doha': (25.276, 51.520, 3),
    'Kuwait': (29.3759, 47.9774, 3),
    'Manama': (26.2285, 50.5860, 3),
    'Karachi': (24.8607, 67.0011, 5),
    'London': (51.5074, -0.1278, 0),
    'New York': (40.7128, -74.0060, -5),
  };

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final today = DateTime.now();
    final times = PrayerTimes.compute(
      date: today,
      latitude: _lat,
      longitude: _lon,
      timezoneHours: _tz,
      method: PrayerMethod.ummAlQura,
    );
    final hijri = HijriDate.fromGregorian(today);
    final cityName = _cities.entries
        .firstWhere(
          (e) => e.value.$1 == _lat,
          orElse: () => const MapEntry('Custom', (0, 0, 0)),
        )
        .key;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? '🕌 مواقيت الصلاة' : '🕌 Prayer Times'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(36),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withAlpha(110)),
              ),
              child: Text(
                isAr
                    ? 'ملاحظة: هذه أوقات تقريبية للأغراض التعليمية. للتأكيد، اعتمد دائمًا على المسجد المحلي.'
                    : 'Note: approximate times for educational use. Always confirm with your local masjid.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _cities.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    selected: cityName == entry.key,
                    onSelected: (_) => setState(() {
                      _lat = entry.value.$1;
                      _lon = entry.value.$2;
                      _tz = entry.value.$3;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  Text(
                    hijri.formatted(arabic: isAr),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatGregorian(today, arabic: isAr),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium.withAlpha(160),
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cityName,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _PrayerRow(
              label: isAr ? 'الفجر' : 'Fajr',
              time: PrayerTimes.formatHours(times.fajr),
              arabic: isAr,
            ),
            _PrayerRow(
              label: isAr ? 'الشروق' : 'Sunrise',
              time: PrayerTimes.formatHours(times.sunrise),
              arabic: isAr,
            ),
            _PrayerRow(
              label: isAr ? 'الظهر' : 'Dhuhr',
              time: PrayerTimes.formatHours(times.dhuhr),
              arabic: isAr,
            ),
            _PrayerRow(
              label: isAr ? 'العصر' : 'Asr',
              time: PrayerTimes.formatHours(times.asr),
              arabic: isAr,
            ),
            _PrayerRow(
              label: isAr ? 'المغرب' : 'Maghrib',
              time: PrayerTimes.formatHours(times.maghrib),
              arabic: isAr,
            ),
            _PrayerRow(
              label: isAr ? 'العشاء' : 'Isha',
              time: PrayerTimes.formatHours(times.isha),
              arabic: isAr,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.label,
    required this.time,
    required this.arabic,
  });
  final String label;
  final String time;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            localizeDigits(time, arabic: arabic),
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
