import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/quiz_bests_provider.dart';
import 'package:aziz_academy/core/providers/quiz_misses_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart' as digits;

/// Parent-facing summary of the kid's progress on the three adaptive
/// early-elementary screens (Number Bonds × 2 targets, Place Value
/// × 2 modes, Skip Counting × 3 steps). Reads two on-device providers:
///   - `quizBestsProvider` for best round score per surface.
///   - `quizMissesProvider` for "tricky" item count per surface.
///
/// All data is on-device — nothing is uploaded, no PII. The card just
/// surfaces what the app already knows so parents can see where the
/// kid is mastering vs struggling, and tap straight into the right
/// screen for more practice.
class MasteryInsightsCard extends ConsumerWidget {
  const MasteryInsightsCard({super.key, required this.arabic});

  final bool arabic;

  static const _rows = <_SurfaceRow>[
    _SurfaceRow(
      bestKey: 'number_bonds:ten',
      missPrefix: 'number_bonds:ten',
      route: AppRoutes.numberBonds,
      labelEn: 'Bonds to 10',
      labelAr: 'روابط الـ ١٠',
      emoji: '🔟',
    ),
    _SurfaceRow(
      bestKey: 'number_bonds:twenty',
      missPrefix: 'number_bonds:twenty',
      route: AppRoutes.numberBonds,
      labelEn: 'Bonds to 20',
      labelAr: 'روابط الـ ٢٠',
      emoji: '🎯',
    ),
    _SurfaceRow(
      bestKey: 'place_value:blocks',
      missPrefix: 'place_value:blocks',
      route: AppRoutes.placeValue,
      labelEn: 'Place Value · Blocks → Number',
      labelAr: 'المنازل · مكعبات إلى عدد',
      emoji: '🟦',
    ),
    _SurfaceRow(
      bestKey: 'place_value:digit',
      missPrefix: 'place_value:digit',
      route: AppRoutes.placeValue,
      labelEn: 'Place Value · Number → Digit',
      labelAr: 'المنازل · عدد إلى منزلة',
      emoji: '🔢',
    ),
    _SurfaceRow(
      bestKey: 'skip_counting:twos',
      missPrefix: 'skip_counting:twos',
      route: AppRoutes.skipCounting,
      labelEn: 'Skip Counting · by 2s',
      labelAr: 'العد بالقفز · بـ ٢',
      emoji: '⏭️',
    ),
    _SurfaceRow(
      bestKey: 'skip_counting:fives',
      missPrefix: 'skip_counting:fives',
      route: AppRoutes.skipCounting,
      labelEn: 'Skip Counting · by 5s',
      labelAr: 'العد بالقفز · بـ ٥',
      emoji: '⏭️',
    ),
    _SurfaceRow(
      bestKey: 'skip_counting:tens',
      missPrefix: 'skip_counting:tens',
      route: AppRoutes.skipCounting,
      labelEn: 'Skip Counting · by 10s',
      labelAr: 'العد بالقفز · بـ ١٠',
      emoji: '⏭️',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bests = ref.watch(quizBestsProvider).value;
    final misses = ref.watch(quizMissesProvider).value;
    final touched = _rows.where((r) {
      return (bests?.hasRecord(r.bestKey) ?? false) ||
          (misses?.byKey.keys.any((k) => k.startsWith('${r.missPrefix}:')) ??
              false);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  arabic
                      ? 'إتقان الصفوف الأولى'
                      : 'Early-Elementary Mastery',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            arabic
                ? 'كل البيانات على الجهاز — لا تُرسل لأي خادم.'
                : 'All data on this device — never uploaded.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 14),
          if (touched.isEmpty)
            _EmptyState(arabic: arabic)
          else
            for (final row in touched)
              _Row(
                row: row,
                arabic: arabic,
                best: bests?.bestFor(row.bestKey) ?? 0,
                trickyCount: _countTricky(misses, row.missPrefix),
                onTap: () => context.push(row.route),
              ),
        ],
      ),
    );
  }

  int _countTricky(QuizMisses? misses, String prefix) {
    if (misses == null) return 0;
    var total = 0;
    for (final e in misses.byKey.entries) {
      if (e.key.startsWith('$prefix:')) total += e.value;
    }
    return total;
  }
}

class _SurfaceRow {
  const _SurfaceRow({
    required this.bestKey,
    required this.missPrefix,
    required this.route,
    required this.labelEn,
    required this.labelAr,
    required this.emoji,
  });

  final String bestKey;
  final String missPrefix;
  final String route;
  final String labelEn;
  final String labelAr;
  final String emoji;
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.arabic,
    required this.best,
    required this.trickyCount,
    required this.onTap,
  });

  final _SurfaceRow row;
  final bool arabic;
  final int best;
  final int trickyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (best / 10) * 100;
    final tier = best >= 8
        ? _MasteryTier.mastered
        : best >= 5
            ? _MasteryTier.learning
            : _MasteryTier.starting;
    final tierColor = switch (tier) {
      _MasteryTier.mastered => AppColors.success,
      _MasteryTier.learning => AppColors.warning,
      _MasteryTier.starting => AppColors.textLight,
    };
    final tierLabel = arabic
        ? switch (tier) {
            _MasteryTier.mastered => 'أتقن',
            _MasteryTier.learning => 'يتعلم',
            _MasteryTier.starting => 'يبدأ',
          }
        : switch (tier) {
            _MasteryTier.mastered => 'Mastered',
            _MasteryTier.learning => 'Learning',
            _MasteryTier.starting => 'Starting',
          };
    String fmt(int n) => digits.localizeDigits(n, arabic: arabic);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(row.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        arabic ? row.labelAr : row.labelEn,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: tierColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        tierLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (best / 10).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(tierColor),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      arabic
                          ? 'أفضل: ${fmt(best)} / ${fmt(10)} · ${fmt(pct.round())}٪'
                          : 'Best: ${fmt(best)} / ${fmt(10)} · ${fmt(pct.round())}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const Spacer(),
                    if (trickyCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.secondary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          arabic
                              ? '💪 ${fmt(trickyCount)} للتدريب'
                              : '💪 ${fmt(trickyCount)} to practice',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MasteryTier { starting, learning, mastered }

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        arabic
            ? 'لم يبدأ طفلك الصفوف الأولى بعد. عندما يلعب روابط الأعداد '
                'أو المنازل العشرية أو العد بالقفز، ستظهر بياناته هنا.'
            : 'Your child has not started the early-elementary screens '
                'yet. Once they play Number Bonds, Place Value, or Skip '
                'Counting, their progress will appear here.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLight,
          height: 1.5,
        ),
      ),
    );
  }
}
