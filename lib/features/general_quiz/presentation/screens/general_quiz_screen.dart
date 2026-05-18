import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/widgets/difficulty_row.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/general_quiz/providers/general_quiz_provider.dart';

class GeneralQuizIntroScreen extends ConsumerWidget {
  const GeneralQuizIntroScreen({super.key});

  static const _categoryEmojis = {
    'جغرافيا': '🌍',
    'Geography': '🌍',
    'تربية إسلامية': '🕌',
    'Islamic Studies': '🕌',
    'لغة عربية': '📖',
    'Arabic': '📖',
    'رياضيات': '🔢',
    'Math': '🔢',
    'معلومات عامة': '💡',
    'General Knowledge': '💡',
  };

  static const _categoryColors = {
    'جغرافيا': Color(0xFF7BA8E0),
    'Geography': Color(0xFF7BA8E0),
    'تربية إسلامية': Color(0xFF67B99A),
    'Islamic Studies': Color(0xFF67B99A),
    'لغة عربية': Color(0xFFFFAE7B),
    'Arabic': Color(0xFFFFAE7B),
    'رياضيات': Color(0xFF2C63B3),
    'Math': Color(0xFF2C63B3),
    'معلومات عامة': Color(0xFFFFD166),
    'General Knowledge': Color(0xFFFFD166),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(generalQuizQuestionsProvider);

    final pageTitle = context.l10n.generalQuizTitle;
    final heroTitle = context.l10n.generalQuizHeroStartFull;
    final orChoose = context.l10n.generalQuizOrChooseCategory;
    final loadError = context.l10n.generalQuizLoadError;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          wide: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IntroHeader(title: pageTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroCard(
                        questionsAsync: questionsAsync,
                        heroTitle: heroTitle,
                      ),
                      const SizedBox(height: 18),
                      Consumer(
                        builder: (context, ref, _) {
                          return DifficultyRow(
                            value: ref.watch(generalQuizDifficultyProvider),
                            onChanged: (d) => ref
                                .read(generalQuizDifficultyProvider.notifier)
                                .set(d),
                            accentColor: const Color(0xFFFFD166),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        orChoose,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _CategoryGrid(
                        questionsAsync: questionsAsync,
                        categoryEmojis: _categoryEmojis,
                        categoryColors: _categoryColors,
                        loadError: loadError,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroHeader extends StatelessWidget {
  const _IntroHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: context.l10n.commonBack,
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: AppColors.secondary,
            ),
            onPressed: () => context.go(AppRoutes.home),
          ),
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.questionsAsync, required this.heroTitle});

  final AsyncValue<List<QuizQuestion>> questionsAsync;
  final String heroTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref
                .read(generalQuizCategoryFilterProvider.notifier)
                .setFilter(null);
            context.push(AppRoutes.generalQuiz);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heroTitle,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.surface,
                          height: 1.2,
                          fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      questionsAsync.when(
                        data: (q) => Text(
                          context.l10n.generalQuizCount(q.length),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.surface.withAlpha(200),
                            fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        error: (e, _) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(80),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🌍', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({
    required this.questionsAsync,
    required this.categoryEmojis,
    required this.categoryColors,
    required this.loadError,
  });

  final AsyncValue<List<QuizQuestion>> questionsAsync;
  final Map<String, String> categoryEmojis;
  final Map<String, Color> categoryColors;
  final String loadError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return questionsAsync.when(
      data: (questions) {
        final categoryCounts = <String, int>{};
        for (final q in questions) {
          categoryCounts[q.category] = (categoryCounts[q.category] ?? 0) + 1;
        }
        final categories = categoryCounts.keys.toList()
          ..sort((a, b) => categoryCounts[b]!.compareTo(categoryCounts[a]!));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 130,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final count = categoryCounts[cat]!;
            final color = categoryColors[cat] ?? AppColors.primary;
            final emoji = categoryEmojis[cat] ?? '💡';

            return _CategoryItemCard(
              category: cat,
              count: count,
              emoji: emoji,
              color: color,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text(loadError)),
    );
  }
}

class _CategoryItemCard extends ConsumerWidget {
  const _CategoryItemCard({
    required this.category,
    required this.count,
    required this.emoji,
    required this.color,
  });

  final String category;
  final int count;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref
                .read(generalQuizCategoryFilterProvider.notifier)
                .setFilter(category);
            context.push(AppRoutes.generalQuiz);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const Spacer(),
                Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  context.l10n.generalQuizCount(count),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.bold,
                    fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
