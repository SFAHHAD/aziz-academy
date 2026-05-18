import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';

/// 7-day Brain Boost recap chart — small bar strip showing whether the
/// daily was completed for each of the last 7 days. Reads `recentCompletions`
/// from the existing `brainBoostDailyProvider`. Pure UI; no new persistence.
class BrainBoostWeeklyRecap extends ConsumerWidget {
  const BrainBoostWeeklyRecap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final state = ref.watch(brainBoostDailyProvider).value;
    final completions = (state?.recentCompletions ?? const <String>[]).toSet();

    final days = <(_DayCell, String)>[];
    final today = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final ymd =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final letter = _letterFor(d.weekday, isAr);
      days.add((
        _DayCell(
          letter: letter,
          done: completions.contains(ymd),
          isToday: i == 0,
        ),
        ymd,
      ));
    }

    final doneInWeek = days.where((t) => t.$1.done).length;
    final streak = state?.streak ?? 0;

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
              const Text('🧠', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'ملخّص الأسبوع' : 'This week',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(36),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.accent.withAlpha(120)),
                ),
                child: Text(
                  isAr
                      ? '🔥 ${localizeDigits(streak, arabic: true)}'
                      : '🔥 $streak',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final t in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: t.$1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'أكملت ${localizeDigits(doneInWeek, arabic: true)} من ٧ أيّام'
                : '$doneInWeek of 7 days completed',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _letterFor(int weekday, bool isAr) {
    if (isAr) {
      const ar = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
      return ar[(weekday - 1) % 7];
    }
    const en = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return en[(weekday - 1) % 7];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.letter,
    required this.done,
    required this.isToday,
  });
  final String letter;
  final bool done;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final fill = done
        ? AppColors.success.withAlpha(160)
        : AppColors.outline.withAlpha(40);
    return Column(
      children: [
        Text(
          letter,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textDark.withAlpha(180),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday
                  ? AppColors.accent.withAlpha(220)
                  : AppColors.outline.withAlpha(60),
              width: isToday ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              done ? '✓' : (isToday ? '·' : ''),
              style: TextStyle(
                color: done ? Colors.white : AppColors.textDark.withAlpha(120),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
