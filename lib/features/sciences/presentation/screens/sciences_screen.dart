import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// Entry point for the Sciences module.
class SciencesScreen extends ConsumerWidget {
  const SciencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _SciencesIntroScreen();
  }
}

// =============================================================================
// Intro screen
// =============================================================================

class _SciencesIntroScreen extends ConsumerWidget {
  const _SciencesIntroScreen();

  static const _categoryEmojis = {
    'كيمياء': '🧪',
    'فيزياء': '⚛️',
    'أحياء': '🧬',
    'فلك': '🪐',
    'طب': '⚕️',
    'جيولوجيا': '🌋',
    'علوم البيئة': '🌿',
    'تشريح': '🦴',
    'اختراعات': '💡',
    'جغرافيا حيوي': '🦤',
  };

  static const _categoryColors = {
    'كيمياء': Color(0xFF67B99A),
    'فيزياء': Color(0xFF78B0D1),
    'أحياء': Color(0xFF9DC88D),
    'فلك': Color(0xFF4A65A4),
    'طب': Color(0xFFFF9E7D),
    'جيولوجيا': Color(0xFFC47AC0),
    'علوم البيئة': Color(0xFF86D9A0),
    'تشريح': Color(0xFFF5C77E),
    'اختراعات': Color(0xFFFFD166),
    'جغرافيا حيوي': Color(0xFFD4A373),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(sciencesQuestionsProvider);
    // TODO: implement specific sciences stars tracking
    final bestStars = 0; // Replace with achievement system implementation if present.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(
                      questionsAsync: questionsAsync,
                      bestStars: bestStars,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'أو اختر مجالاً علمياً',
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.secondary),
            onPressed: () => context.go(AppRoutes.home),
          ),
          Text(
            'الاكتشافات العلمية',
            style: AppTextStyles.headingMedium.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: 48), // Balance spacing
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.questionsAsync,
    required this.bestStars,
  });

  final AsyncValue<List<QuizQuestion>> questionsAsync;
  final int bestStars;

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
            ref.read(categoryFilterProvider.notifier).setFilter(null);
            context.push(AppRoutes.sciencesQuiz);
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
                        'ابدأ التحدي العلمي الكامل',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.surface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      questionsAsync.when(
                        data: (q) => Text(
                          '${q.length} سؤال شامل',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.surface.withAlpha(200),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                    child: Text('🔬', style: TextStyle(fontSize: 32)),
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
  });

  final AsyncValue<List<QuizQuestion>> questionsAsync;
  final Map<String, String> categoryEmojis;
  final Map<String, Color> categoryColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return questionsAsync.when(
      data: (questions) {
        final categoryCounts = <String, int>{};
        for (final q in questions) {
          final cat = q.category;
          categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
        }

        final categories = categoryCounts.keys.toList()
          ..sort((a, b) => categoryCounts[b]!.compareTo(categoryCounts[a]!));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, trace) => Center(child: Text('خطأ في تحميل البيانات $e')),
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
            ref.read(categoryFilterProvider.notifier).setFilter(category);
            context.push(AppRoutes.sciencesQuiz);
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
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count سؤال',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.bold,
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
