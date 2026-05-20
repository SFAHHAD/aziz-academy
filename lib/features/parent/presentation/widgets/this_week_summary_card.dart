import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/daily_quiz_streak_provider.dart';
import 'package:aziz_academy/core/providers/islamic_favorites_provider.dart';
import 'package:aziz_academy/core/providers/mental_math_bests_provider.dart';
import 'package:aziz_academy/core/providers/multiplication_progress_provider.dart';
import 'package:aziz_academy/core/providers/quran_progress_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/features/mental_math/mental_math_engine.dart';

/// Parent-only "at a glance" snapshot of how the kid is doing across
/// the math + Islamic practice surfaces. Pulls from existing providers,
/// no new persistence. Designed for a parent scanning quickly — six
/// stat tiles, one strongest-table callout, one shaky-table callout.
class ThisWeekSummaryCard extends ConsumerWidget {
  const ThisWeekSummaryCard({super.key, required this.arabic});

  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mult = ref.watch(multiplicationProgressProvider).value ??
        MultiplicationStats.empty;
    final streak = ref.watch(dailyQuizStreakProvider).value ??
        DailyQuizStreak.empty;
    final favs = ref.watch(islamicFavoritesProvider).value ??
        const <IslamicFavKind, Set<String>>{};
    final memorized =
        ref.watch(quranProgressProvider).value ?? const <String>{};
    final bests =
        ref.watch(mentalMathBestsProvider).value ?? MentalMathBests.empty;

    final hadithFavs = favs[IslamicFavKind.hadith]?.length ?? 0;
    final asmaFavs = favs[IslamicFavKind.asma]?.length ?? 0;
    final prophetFavs = favs[IslamicFavKind.prophet]?.length ?? 0;
    final islamicTotal = hadithFavs + asmaFavs + prophetFavs;

    // Identify strongest + shakiest table (if data exists).
    int? strongestTable;
    int? shakiestTable;
    // Only rank tables that have at least one attempt — dividing by a zero
    // `total` would yield NaN and sort inconsistently (picking the wrong
    // strongest/shakiest table to show the parent).
    final ranked = mult.tables.entries
        .where((e) => e.value.total > 0)
        .toList()
      ..sort((a, b) => (a.value.correct / a.value.total)
          .compareTo(b.value.correct / b.value.total));
    if (ranked.isNotEmpty) {
      shakiestTable = ranked.first.key;
      strongestTable = ranked.last.key;
    }
    final shaky = mult.shakyTables();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withAlpha(36),
            AppColors.accent.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                arabic ? 'لمحة سريعة' : 'At a glance',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              _StatTile(
                emoji: '🔥',
                labelEn: 'Daily streak',
                labelAr: 'تتابع يومي',
                valueText:
                    localizeDigits(streak.currentStreak, arabic: arabic),
                arabic: arabic,
              ),
              _StatTile(
                emoji: '🏆',
                labelEn: 'Best streak',
                labelAr: 'أفضل تتابع',
                valueText:
                    localizeDigits(streak.longestStreak, arabic: arabic),
                arabic: arabic,
              ),
              _StatTile(
                emoji: '📖',
                labelEn: 'Surahs',
                labelAr: 'سور محفوظة',
                valueText: localizeDigits(memorized.length, arabic: arabic),
                arabic: arabic,
              ),
              _StatTile(
                emoji: '☪️',
                labelEn: 'Islamic ❤️',
                labelAr: 'مفضلة',
                valueText: localizeDigits(islamicTotal, arabic: arabic),
                arabic: arabic,
              ),
              _StatTile(
                emoji: '⚡',
                labelEn: 'Math best',
                labelAr: 'أفضل حساب',
                valueText: localizeDigits(
                  bests.bestFor(MentalMathBand.medium),
                  arabic: arabic,
                ),
                arabic: arabic,
              ),
              _StatTile(
                emoji: '✖️',
                labelEn: 'Tables',
                labelAr: 'الجداول',
                valueText: localizeDigits(mult.tables.length, arabic: arabic),
                arabic: arabic,
              ),
            ],
          ),
          if (strongestTable != null) ...[
            const SizedBox(height: 12),
            _CalloutRow(
              emoji: '💪',
              labelEn:
                  'Strongest: ×$strongestTable (${(mult.accuracyFor(strongestTable)! * 100).round()}%)',
              labelAr:
                  'الأقوى: جدول ${localizeDigits(strongestTable, arabic: true)} (${localizeDigits((mult.accuracyFor(strongestTable)! * 100).round(), arabic: true)}٪)',
              color: AppColors.success,
              arabic: arabic,
            ),
          ],
          if (shaky.isNotEmpty && shakiestTable != null) ...[
            const SizedBox(height: 8),
            _CalloutRow(
              emoji: '🎯',
              labelEn:
                  'Needs practice: ×$shakiestTable (${(mult.accuracyFor(shakiestTable)! * 100).round()}%)',
              labelAr:
                  'يحتاج تدريبًا: جدول ${localizeDigits(shakiestTable, arabic: true)} (${localizeDigits((mult.accuracyFor(shakiestTable)! * 100).round(), arabic: true)}٪)',
              color: AppColors.warning,
              arabic: arabic,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
    required this.valueText,
    required this.arabic,
  });
  final String emoji;
  final String labelEn;
  final String labelAr;
  final String valueText;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            valueText,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            arabic ? labelAr : labelEn,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark.withAlpha(170),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutRow extends StatelessWidget {
  const _CalloutRow({
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
    required this.color,
    required this.arabic,
  });
  final String emoji;
  final String labelEn;
  final String labelAr;
  final Color color;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              arabic ? labelAr : labelEn,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
