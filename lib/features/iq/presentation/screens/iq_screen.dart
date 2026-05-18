import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/widgets/difficulty_row.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';

const _kBrainBoostDisclaimerSeen = 'brain_boost_disclaimer_seen_v1';
const _kBrainBoostTourSeen = 'brain_boost_tour_seen_v1';

/// Entry point — Brain Boost intro screen (bilingual).
class IqScreen extends ConsumerStatefulWidget {
  const IqScreen({super.key});

  @override
  ConsumerState<IqScreen> createState() => _IqScreenState();
}

class _IqScreenState extends ConsumerState<IqScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDisclaimer());
  }

  Future<void> _maybeShowDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final disclaimerNeeded =
        !(prefs.getBool(_kBrainBoostDisclaimerSeen) ?? false);
    final tourNeeded = !(prefs.getBool(_kBrainBoostTourSeen) ?? false);
    if (disclaimerNeeded) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          title: Text(
            ctx.l10n.brainBoostDisclaimerTitle,
            style: AppTextStyles.headingSmall,
          ),
          content: Text(
            ctx.l10n.brainBoostDisclaimerBody,
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n.brainBoostDisclaimerOk),
            ),
          ],
        ),
      );
      await prefs.setBool(_kBrainBoostDisclaimerSeen, true);
    }
    if (tourNeeded && mounted) {
      await _showOnboardingTour();
      await prefs.setBool(_kBrainBoostTourSeen, true);
    }
  }

  Future<void> _showOnboardingTour() async {
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final steps = isArabic
        ? const [
            (
              '⭐',
              'تحدي اليوم',
              '٥ أسئلة مختارة لك يومياً. أكمل لتحصل على جوائز ومكافآت!',
            ),
            (
              '👑',
              'وضع البطل',
              '١٢ سؤالاً عبر كل المجالات بصعوبة متصاعدة. أتقن كل المهارات!',
            ),
            (
              '🎯',
              'تدرّب على نقاط ضعفك',
              'سنقترح عليك المجال الأقل تقدماً لتتحسّن أكثر.',
            ),
          ]
        : const [
            (
              '⭐',
              "Today's Challenge",
              '5 questions picked for you daily. Complete it for streak bonuses & cosmetic unlocks!',
            ),
            (
              '👑',
              'Champion Mode',
              '12 questions across all 4 categories with rising difficulty — master every skill.',
            ),
            (
              '🎯',
              'Train your weak areas',
              "We'll suggest your weakest category so you can grow faster.",
            ),
          ];
    var i = 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final s = steps[i];
            return Dialog(
              backgroundColor: AppColors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.$1, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(
                      s.$2,
                      style: AppTextStyles.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.$3,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(steps.length, (k) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: k == i
                                ? AppColors.secondary
                                : AppColors.glassBorder,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (i + 1 >= steps.length) {
                            Navigator.of(ctx).pop();
                          } else {
                            setSt(() => i++);
                          }
                        },
                        child: Text(
                          i + 1 >= steps.length
                              ? (isArabic ? 'هيا نبدأ' : "Let's go!")
                              : (isArabic ? 'التالي' : 'Next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _IqIntroScreen();
  }
}

class _IqIntroScreen extends ConsumerWidget {
  const _IqIntroScreen();

  static const _categoryEmojis = {
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
    // Legacy iq.json category names (kept for fallback safety):
    'Sequences': '🔢',
    'متتاليات': '🔢',
    'Pattern': '🧩',
    'أنماط': '🧩',
    'Odd One Out': '🎯',
    'الشاذ': '🎯',
  };

  static const _categoryColors = {
    'Patterns': Color(0xFF9DC88D),
    'الأنماط': Color(0xFF9DC88D),
    'Mental Math': Color(0xFF67B99A),
    'حساب ذهني': Color(0xFF67B99A),
    'Analogies': Color(0xFFFFAE7B),
    'تشابه': Color(0xFFFFAE7B),
    'Logic': Color(0xFFC47AC0),
    'منطق': Color(0xFFC47AC0),
    'Spatial': Color(0xFFFFD166),
    'مكاني': Color(0xFFFFD166),
    'Memory': Color(0xFF7BA8E0),
    'ذاكرة': Color(0xFF7BA8E0),
    // Legacy iq.json category names (kept for fallback safety):
    'Sequences': Color(0xFF7BA8E0),
    'متتاليات': Color(0xFF7BA8E0),
    'Pattern': Color(0xFF9DC88D),
    'أنماط': Color(0xFF9DC88D),
    'Odd One Out': Color(0xFFFF9E7D),
    'الشاذ': Color(0xFFFF9E7D),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(iqQuestionsProvider);

    final pageTitle = context.l10n.iqTitle;
    final heroTitle = context.l10n.iqHeroStartFull;
    final orChoose = context.l10n.iqOrChooseCategory;
    final loadError = context.l10n.iqLoadError;

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
                      const SizedBox(height: 12),
                      const _DailyChallengeChip(),
                      const SizedBox(height: 8),
                      const _SevenDayStrip(),
                      const SizedBox(height: 12),
                      const _ChampionModeChip(),
                      const SizedBox(height: 12),
                      const _WeakestAreaChip(),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          return DifficultyRow(
                            value: ref.watch(iqDifficultyProvider),
                            onChanged: (d) =>
                                ref.read(iqDifficultyProvider.notifier).set(d),
                            accentColor: const Color(0xFFC47AC0),
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
            ref.read(iqCategoryFilterProvider.notifier).setFilter(null);
            context.push(AppRoutes.iqQuiz);
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
                          context.l10n.iqComprehensiveCount(q.length),
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
                    child: Text('🧠', style: TextStyle(fontSize: 32)),
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
            context.push(
              '${AppRoutes.brainBoostCategory}/${Uri.encodeComponent(category)}',
            );
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
                  context.l10n.iqCategoryCount(count),
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

class _ChampionModeChip extends ConsumerWidget {
  const _ChampionModeChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    return GestureDetector(
      onTap: () => context.push(AppRoutes.brainBoostChampion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA500).withAlpha(80),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'وضع البطل' : 'Champion Mode',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? '١٢ سؤالاً عبر كل المجالات'
                        : '12 questions across all categories',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withAlpha(220),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _SevenDayStrip extends ConsumerWidget {
  const _SevenDayStrip();

  static String _ymd(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static const _enDows = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _arDows = ['ا', 'ا', 'ث', 'ر', 'خ', 'ج', 'س'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(brainBoostDailyProvider).value;
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final completed = (daily?.recentCompletions ?? const <String>[]).toSet();
    final now = DateTime.now();
    final cells = <Widget>[];
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final ymd = _ymd(d);
      final done = completed.contains(ymd);
      final isToday = i == 0;
      final dow = (d.weekday + 6) % 7; // 0=Mon
      final dowLabel = (isArabic ? _arDows : _enDows)[dow];
      cells.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Text(
                  dowLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.secondary
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !done
                        ? Border.all(
                            color: AppColors.secondary.withAlpha(150),
                            width: 1.5,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: cells),
    );
  }
}

class _DailyChallengeChip extends ConsumerWidget {
  const _DailyChallengeChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final daily = ref.watch(brainBoostDailyProvider).value;
    final streak = daily?.streak ?? 0;
    final doneToday = daily?.todayCompleted ?? false;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.brainBoostDaily),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withAlpha(60),
              AppColors.primary.withAlpha(40),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withAlpha(120)),
        ),
        child: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'تحدي اليوم' : "Today's Challenge",
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doneToday
                        ? (isArabic
                              ? 'انتهيت — عد غدًا!'
                              : 'Done — see you tomorrow!')
                        : (isArabic
                              ? '٥ أسئلة مختارة لك'
                              : '5 questions picked for you'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      localizeDigitsCtx(streak, context),
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              )
            else
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _WeakestAreaChip extends ConsumerWidget {
  const _WeakestAreaChip();

  static const _brainBoostCats = [
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final learner = ref.watch(learnerStateProvider).value;
    if (learner == null) return const SizedBox.shrink();
    final cats = learner.skillByModuleCategory['iq'] ?? const {};
    final attempted = _brainBoostCats
        .where((c) => cats.containsKey(c))
        .toList();
    if (attempted.isEmpty) return const SizedBox.shrink();
    attempted.sort((a, b) => cats[a]!.compareTo(cats[b]!));
    final weakest = attempted.first;
    final label = isArabic ? (_arLabel[weakest] ?? weakest) : weakest;
    final emoji = _emoji[weakest] ?? '🧠';
    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.brainBoostCategory}/${Uri.encodeComponent(weakest)}',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withAlpha(120)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'جرّب هذا التالي' : 'Try this next',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  Text(label, style: AppTextStyles.labelLarge),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
