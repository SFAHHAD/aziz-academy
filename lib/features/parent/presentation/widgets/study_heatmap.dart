import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';

/// 28-day study activity heatmap — GitHub-style 4-week grid showing daily
/// Brain Boost completions. Pulls from the existing `recentCompletions`
/// list (last 14 days are kept) and pads earlier days as "no activity".
/// Pure UI; no new persistence.
class StudyHeatmap extends ConsumerWidget {
  const StudyHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final state = ref.watch(brainBoostDailyProvider).value;
    final completions = (state?.recentCompletions ?? const <String>[]).toSet();

    final today = DateTime.now();
    final cells = <_Cell>[];
    for (var i = 27; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final ymd =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      cells.add(_Cell(date: d, ymd: ymd, done: completions.contains(ymd)));
    }
    final activeCount = cells.where((c) => c.done).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'خريطة النشاط (٢٨ يومًا)'
                      : 'Activity heatmap (28 days)',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                isAr
                    ? '${localizeDigits(activeCount, arabic: true)} يوم'
                    : '$activeCount days',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark.withAlpha(160),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (ctx, i) {
              final c = cells[i];
              final isToday = i == cells.length - 1;
              return Tooltip(
                message: c.ymd,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.done
                        ? AppColors.success.withAlpha(180)
                        : AppColors.outline.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: AppColors.accent, width: 1.6)
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.outline.withAlpha(40),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isAr ? 'لا نشاط' : 'no activity',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDark.withAlpha(160),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(180),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isAr ? 'يوم مكتمل' : 'day completed',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDark.withAlpha(160),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell {
  const _Cell({required this.date, required this.ymd, required this.done});
  final DateTime date;
  final String ymd;
  final bool done;
}
