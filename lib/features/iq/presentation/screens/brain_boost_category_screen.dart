import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Per-category drill screen — shows the child's per-category skill EMA, lets
/// them pick a difficulty band, then dives into the standard IQ quiz flow with
/// the category and difficulty pre-set.
class BrainBoostCategoryScreen extends ConsumerWidget {
  const BrainBoostCategoryScreen({super.key, required this.category});
  final String category;

  static const _emoji = {
    'Patterns': '🧩',
    'الأنماط': '🧩',
    'Mental Math': '➗',
    'حساب ذهني': '➗',
    'Analogies': '🔄',
    'تشابه': '🔄',
    'Logic': '🧠',
    'منطق': '🧠',
    'Spatial': '🧊',
    'مكاني': '🧊',
    'Memory': '🎴',
    'ذاكرة': '🎴',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final learner = ref.watch(learnerStateProvider).value;
    final skill = learner?.skillForCategory('iq', category) ?? 0.5;
    final hasData = (learner?.skillByModuleCategory['iq'] ?? const {})
        .containsKey(category);
    final label = isArabic ? (_arLabel[category] ?? category) : category;
    final emoji = _emoji[category] ?? '🧠';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.go(AppRoutes.iq),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.headingMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SkillCard(skill: skill, hasData: hasData, arabic: isArabic),
                const SizedBox(height: 20),
                Text(
                  isArabic ? 'اختر مستوى التحدي' : 'Choose challenge level',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 12),
                _DifficultyPicker(
                  selected: ref.watch(iqDifficultyProvider),
                  onChanged: (d) =>
                      ref.read(iqDifficultyProvider.notifier).set(d),
                  arabic: isArabic,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _start(context, ref),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      isArabic ? 'ابدأ' : 'Start',
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isArabic
                        ? 'كل النتائج تبقى على هذا الجهاز فقط — وليست اختبار ذكاء حقيقياً.'
                        : 'All scores stay on this device — this is not a real IQ test.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context, WidgetRef ref) {
    ref.read(iqCategoryFilterProvider.notifier).setFilter(category);
    ref.invalidate(iqQuizProvider);
    context.push(AppRoutes.iqQuiz);
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.hasData,
    required this.arabic,
  });
  final double skill;
  final bool hasData;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final pct = (skill * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arabic ? 'مستواك في هذا المجال' : 'Your skill in this area',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: skill.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: AppColors.surfaceContainer,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(hasData ? '$pct%' : '—', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? (arabic
                      ? 'نمت هذه القيمة من جلساتك السابقة في هذا المجال.'
                      : 'This grows from your past sessions in this category.')
                : (arabic
                      ? 'العب جولة لتظهر قيمتك هنا.'
                      : 'Play a round to see your skill grow here.'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({
    required this.selected,
    required this.onChanged,
    required this.arabic,
  });
  final QuizDifficulty selected;
  final ValueChanged<QuizDifficulty> onChanged;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final items = <(QuizDifficulty, String, String)>[
      (QuizDifficulty.easy, 'Easy', 'سهل'),
      (QuizDifficulty.medium, 'Medium', 'متوسط'),
      (QuizDifficulty.hard, 'Hard', 'صعب'),
    ];
    return Wrap(
      spacing: 8,
      children: items.map((it) {
        final sel = selected == it.$1;
        return GestureDetector(
          onTap: () => onChanged(it.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? AppColors.secondary : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              arabic ? it.$3 : it.$2,
              style: AppTextStyles.labelLarge.copyWith(
                color: sel ? AppColors.background : AppColors.textDark,
                fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
