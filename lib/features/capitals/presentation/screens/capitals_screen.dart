import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/capitals/presentation/screens/capitals_quiz_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Entry point for the Capitals module.
class CapitalsScreen extends ConsumerWidget {
  const CapitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continent = ref.watch(continentFilterProvider);

    if (continent != null) {
      return const CapitalsQuizScreen();
    }

    return const _CapitalsIntroScreen();
  }
}

// =============================================================================
// Intro screen
// =============================================================================

class _CapitalsIntroScreen extends ConsumerWidget {
  const _CapitalsIntroScreen();

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
    final questionsAsync = ref.watch(capitalsQuestionsProvider);
    final achievementAsync = ref.watch(achievementProvider);
    final bestStars = achievementAsync.value?.capitalsStars ?? 0;

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
                    _HeroCard(
                      questionsAsync: questionsAsync,
                      bestStars: bestStars,
                    ),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 32),
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

// =============================================================================
// Header
// =============================================================================

class _IntroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isRtl
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            onPressed: () => context.go(AppRoutes.home),
          ),
          // Gold glow icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.capitalsColor.withAlpha(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.capitalsColor.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏛️', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'اختبار العواصم',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Hero "Play All" card
// =============================================================================

class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.questionsAsync,
    required this.bestStars,
  });

  final AsyncValue<List<dynamic>> questionsAsync;
  final int bestStars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = questionsAsync.value?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.capitalsColor.withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.capitalsColor.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with glow
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.capitalsColor.withAlpha(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.capitalsColor.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌍', style: TextStyle(fontSize: 32)),
                ),
              ),
              const Spacer(),
              // Star display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'أفضل نتيجة',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(3, (i) {
                      return Icon(
                        i < bestStars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: i < bestStars
                            ? AppColors.secondary
                            : AppColors.surfaceContainerHighest,
                        size: 24,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'عواصم العالم',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختبر معلوماتك عن عواصم العالم عبر القارات.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
            Text(
                    '$total سؤال • 3 حياة • اربح حتى ⭐⭐⭐',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DifficultyRow(),
                  const SizedBox(height: 18),
                  // Gold gradient CTA button
                  GestureDetector(
                    onTap: total > 0
                        ? () {
                            ref.read(continentFilterProvider.notifier).clear();
                            context.go(AppRoutes.capitalsQuiz);
                          }
                        : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: total > 0
                    ? AppColors.goldGradient
                    : null,
                color: total > 0 ? null : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(50),
                boxShadow: total > 0
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(
                    'العب جميع الدول',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: total > 0
                          ? const Color(0xFF0A1628)
                          : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Difficulty Row
// =============================================================================

class _DifficultyRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(difficultyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مستوى الصعوبة',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
        ),
        const SizedBox(height: 8),
        Row(
          children: QuizDifficulty.values.map((d) {
            final selected = current == d;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: d == QuizDifficulty.values.first ? 0 : 6,
                ),
                child: GestureDetector(
                  onTap: () => ref.read(difficultyProvider.notifier).set(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.capitalsColor.withAlpha(220)
                          : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.capitalsColor
                            : AppColors.divider.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(d.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          d.labelAr,
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// Continent pick grid
// =============================================================================

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
    final allQuestions = questionsAsync.value ?? [];
    final continents = continentEmojis.keys.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 130,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: continents.length,
      itemBuilder: (context, i) {
        final id = continents[i];
        final emoji = continentEmojis[id] ?? '🌍';
        final color = continentColors[id] ?? AppColors.primary;
        final count = allQuestions.where((q) => q.category == id).length;

        return _ContinentChip(
          id: id,
          nameAr: continentAr[id] ?? id,
          emoji: emoji,
          color: color,
          questionCount: count,
          onTap: () {
            ref.read(continentFilterProvider.notifier).set(id);
            context.go(AppRoutes.capitalsQuiz);
          },
        );
      },
    );
  }
}

class _ContinentChip extends StatelessWidget {
  const _ContinentChip({
    required this.id,
    required this.nameAr,
    required this.emoji,
    required this.color,
    required this.questionCount,
    required this.onTap,
  });

  final String id;
  final String nameAr;
  final String emoji;
  final Color color;
  final int questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: questionCount > 0 ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withAlpha(80),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glow icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(60),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nameAr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$questionCount دول',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontSize: 11,
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
