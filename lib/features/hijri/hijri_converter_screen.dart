import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/utils/hijri_date.dart';

/// Pick any Gregorian date, see the Hijri equivalent. Useful for kids
/// learning to read both calendars side by side and for parents
/// looking up a birthday in Hijri.
class HijriConverterScreen extends ConsumerStatefulWidget {
  const HijriConverterScreen({super.key});

  @override
  ConsumerState<HijriConverterScreen> createState() =>
      _HijriConverterScreenState();
}

class _HijriConverterScreenState
    extends ConsumerState<HijriConverterScreen> {
  DateTime _picked = DateTime.now();

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _picked,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _picked = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final hijri = HijriDate.fromGregorian(_picked);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'محول التاريخ' : 'Hijri Converter'),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            isAr ? 'اختر تاريخًا ميلاديًا' : 'Pick a Gregorian date',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark.withAlpha(170),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatGregorian(_picked, isAr),
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    isAr
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: AppColors.textDark.withAlpha(140),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withAlpha(46),
                  AppColors.accent.withAlpha(28),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.secondary.withAlpha(140)),
            ),
            child: Column(
              children: [
                Text(
                  isAr ? 'التاريخ الهجري' : 'Hijri date',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hijri.formatted(arabic: isAr),
                  textAlign: TextAlign.center,
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.textDark,
                    fontSize: 28,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'الشهر: ${HijriDate.monthNamesAr[hijri.month - 1]}'
                      : 'Month: ${HijriDate.monthNamesEn[hijri.month - 1]}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'تستخدم الحسابات خوارزمية الكويتية القياسية. قد يختلف اليوم ١ يومًا عن تقويم أم القرى الرسمي.'
                        : 'Uses the standard Kuwaiti algorithm. May differ by ±1 day from the official Umm al-Qura calendar.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGregorian(DateTime d, bool isAr) {
    const monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const monthsAr = [
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
    final m = isAr ? monthsAr[d.month - 1] : monthsEn[d.month - 1];
    return isAr
        ? '${localizeDigits(d.day, arabic: true)} $m ${localizeDigits(d.year, arabic: true)}'
        : '${d.day} $m ${d.year}';
  }
}
