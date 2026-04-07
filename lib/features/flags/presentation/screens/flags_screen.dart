import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/features/flags/providers/flags_quiz_provider.dart';
import 'package:aziz_academy/core/widgets/difficulty_row.dart';
import 'package:google_fonts/google_fonts.dart';
class FlagsScreen extends ConsumerWidget {
  const FlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _FlagsIntroScreen();
  }
}

class _FlagsIntroScreen extends ConsumerWidget {
  const _FlagsIntroScreen();

  static const _continentEmojis = {
    'Africa': '🌍',
    'Asia': '🌏',
    'Europe': '🌍',
    'Americas': '🌎',
    'Oceania': '🌏',
  };

  static const _continentColors = {
    'Africa': Color(0xFFFF9E7D),
    'Asia': Color(0xFF67B99A),
    'Europe': Color(0xFF78B0D1),
    'Americas': Color(0xFFF5C77E),
    'Oceania': Color(0xFFC47AC0),
  };

  static const _continentAr = {
    'Africa': 'أفريقيا',
    'Asia': 'آسيا',
    'Europe': 'أوروبا',
    'Americas': 'الأمريكيتين',
    'Oceania': 'أوقيانوسيا',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(flagsQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
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
                        _HeroCard(questionsAsync: questionsAsync),
                        const SizedBox(height: 18),
                        Consumer(builder: (context, ref, _) {
                          return DifficultyRow(
                            value: ref.watch(flagsDifficultyProvider),
                            onChanged: (d) => ref.read(flagsDifficultyProvider.notifier).set(d),
                            accentColor: AppColors.error,
                          );
                        }),
                        const SizedBox(height: 18),
                        Text(
                          'أو اختر قارة',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _ContinentGrid(
                          questionsAsync: questionsAsync,
                          continentEmojis: _continentEmojis,
                          continentColors: _continentColors,
                          continentAr: _continentAr,
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
            'تحدي الأعلام',
            style: AppTextStyles.headingMedium.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: 48), // Balance spacing
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.questionsAsync});
  final AsyncValue<List<QuizQuestion>> questionsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(flagsContinentFilterProvider.notifier).setFilter(null);
            context.push(AppRoutes.flagsQuiz);
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
                        'تحدي جميع أعلام العالم',
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
                          '${q.length} علم',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.surface.withAlpha(200),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
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
                    child: Text('🚩', style: TextStyle(fontSize: 32)),
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

class _ContinentGrid extends ConsumerWidget {
  const _ContinentGrid({
    required this.questionsAsync,
    required this.continentEmojis,
    required this.continentColors,
    required this.continentAr,
  });

  final AsyncValue<List<QuizQuestion>> questionsAsync;
  final Map<String, String> continentEmojis;
  final Map<String, Color> continentColors;
  final Map<String, String> continentAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return questionsAsync.when(
      data: (questions) {
        final continents = [
          'Asia',
          'Africa',
          'Europe',
          'Americas',
          'Oceania'
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 140,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: continents.length,
          itemBuilder: (context, index) {
            final cont = continents[index];
            final count = questions.where((q) => q.category == cont).length;
            if (count == 0) return const SizedBox.shrink();

            return _ContinentCard(
              continentCode: cont,
              title: continentAr[cont] ?? cont,
              count: count,
              emoji: continentEmojis[cont] ?? '🌍',
              color: continentColors[cont] ?? AppColors.primary,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Error loading regions')),
    );
  }
}

class _ContinentCard extends ConsumerWidget {
  const _ContinentCard({
    required this.continentCode,
    required this.title,
    required this.count,
    required this.emoji,
    required this.color,
  });

  final String continentCode;
  final String title;
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
            ref.read(flagsContinentFilterProvider.notifier).setFilter(continentCode);
            context.push(AppRoutes.flagsQuiz);
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$count علم',
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
    );
  }
}
