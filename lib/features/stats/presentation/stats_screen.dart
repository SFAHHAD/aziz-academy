import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/xp_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Aggregate stats screen — answers Research.txt's "User Statistics" item.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerStateProvider).value;
    final coins = ref.watch(coinProvider).value ?? 0;
    final xp = ref.watch(xpProvider).value;
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';

    final sessions = learner?.recentSessions ?? const [];
    final attended = sessions.fold<int>(0, (a, b) => a + b.total);
    final correct = sessions.fold<int>(0, (a, b) => a + b.score);
    final incorrect = attended - correct;
    final accuracy = attended == 0 ? 0 : ((correct / attended) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.commonBack,
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'إحصائياتي' : 'My Stats',
                    style: AppTextStyles.headingMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (attended == 0) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('🚀', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'لم تبدأ أي نشاط بعد!\nأكمل اختبارًا واحدًا لتظهر إحصاءاتك هنا.'
                            : 'No activity yet!\nFinish one quiz and your stats will start filling in here.',
                        style: AppTextStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.home),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(isArabic ? 'ابدأ الآن' : 'Start now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _Tile(
                emoji: '🎯',
                label: isArabic ? 'الإجابات الصحيحة' : 'Correct',
                value: localizeDigitsCtx(correct, context),
              ),
              _Tile(
                emoji: '❌',
                label: isArabic ? 'الإجابات الخاطئة' : 'Incorrect',
                value: localizeDigitsCtx(incorrect, context),
              ),
              _Tile(
                emoji: '📋',
                label: isArabic ? 'مجموع الأسئلة' : 'Questions answered',
                value: localizeDigitsCtx(attended, context),
              ),
              _Tile(
                emoji: '📈',
                label: isArabic ? 'الدقة' : 'Accuracy',
                value: '${localizeDigitsCtx(accuracy, context)}%',
              ),
              _Tile(
                emoji: '🪙',
                label: isArabic ? 'العملات' : 'Coins',
                value: localizeDigitsCtx(coins, context),
              ),
              _Tile(
                emoji: '⭐',
                label: isArabic ? 'النقاط (XP)' : 'XP',
                value: localizeDigitsCtx(xp?.totalXp ?? 0, context),
              ),
              _Tile(
                emoji: '🏅',
                label: isArabic ? 'المستوى' : 'Level',
                value: localizeDigitsCtx(xp?.level ?? 1, context),
              ),
              _Tile(
                emoji: '🎮',
                label: isArabic ? 'عدد الجلسات' : 'Sessions played',
                value: localizeDigitsCtx(learner?.totalSessions ?? 0, context),
              ),
              const SizedBox(height: 12),
              if (learner != null)
                _BrainBoostStrip(learner: learner, arabic: isArabic),
              const SizedBox(height: 16),
              _AlmostThereStrip(arabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrainBoostStrip extends StatelessWidget {
  const _BrainBoostStrip({required this.learner, required this.arabic});
  final LearnerState learner;
  final bool arabic;

  static const _cats = [
    'Patterns',
    'Mental Math',
    'Analogies',
    'Logic',
    'Spatial',
    'Memory',
  ];
  static const _emoji = {
    'Patterns': '🧩',
    'Mental Math': '➗',
    'Analogies': '🔄',
    'Logic': '🧠',
    'Spatial': '🧊',
    'Memory': '🎴',
  };
  static const _arLabel = {
    'Patterns': 'الأنماط',
    'Mental Math': 'حساب ذهني',
    'Analogies': 'تشابه',
    'Logic': 'منطق',
    'Spatial': 'مكاني',
    'Memory': 'ذاكرة',
  };

  @override
  Widget build(BuildContext context) {
    final cats = learner.skillByModuleCategory['iq'] ?? const {};
    final hasAny = _cats.any(cats.containsKey);
    if (!hasAny) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                arabic ? 'مهارات تنمية الذكاء' : 'Brain Boost skills',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final cat in _cats)
            if (cats.containsKey(cat))
              _SkillBar(
                emoji: _emoji[cat] ?? '🧠',
                label: arabic ? (_arLabel[cat] ?? cat) : cat,
                value: cats[cat]!,
              ),
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({
    required this.emoji,
    required this.label,
    required this.value,
  });
  final String emoji;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.surfaceContainer,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '$pct%',
              textAlign: TextAlign.end,
              style: AppTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.emoji, required this.label, required this.value});

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          Text(value, style: AppTextStyles.headingSmall),
        ],
      ),
    );
  }
}

/// Surfaces the 1-3 badges the kid is closest to unlocking, so progress feels
/// alive between actual unlocks. Self-hides if every relevant target is
/// already met (lock or numerically unreachable).
class _AlmostThereStrip extends ConsumerWidget {
  const _AlmostThereStrip({required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementProvider).value;
    if (state == null) return const SizedBox.shrink();
    final hints = nextBadgeHints(state, limit: 3);
    if (hints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                arabic ? 'أوشكت على الفوز' : 'Almost there',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final h in hints)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localizeDigitsCtx(h.remaining, context),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      arabic ? h.labelAr : h.labelEn,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
