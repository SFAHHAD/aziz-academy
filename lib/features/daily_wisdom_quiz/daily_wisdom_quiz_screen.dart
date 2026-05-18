import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/daily_quiz_streak_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/utils/hijri_date.dart';
import 'package:aziz_academy/features/daily_wisdom_quiz/daily_question_engine.dart';

/// "Daily Wisdom Quiz" — one question per day, cycling through Hadith,
/// 99 Names, and Prophets. The question is the same for every kid on
/// the same day (deterministic from date) so families can talk about
/// it together. Tracks current streak, longest streak, and lifetime
/// correct count in shared_preferences. Once you've answered today,
/// the result view is sticky until midnight.
class DailyWisdomQuizScreen extends ConsumerStatefulWidget {
  const DailyWisdomQuizScreen({super.key});

  @override
  ConsumerState<DailyWisdomQuizScreen> createState() =>
      _DailyWisdomQuizScreenState();
}

class _DailyWisdomQuizScreenState
    extends ConsumerState<DailyWisdomQuizScreen> {
  DailyQuestion? _question;
  bool _loading = true;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/data/hadith_memorization.json'),
        rootBundle.loadString('assets/data/asma_ul_husna_memorization.json'),
        rootBundle.loadString('assets/data/prophet_stories.json'),
      ]);
      final hadithRaw = (jsonDecode(results[0]) as List).cast<Map<String, dynamic>>();
      final asmaRaw = (jsonDecode(results[1]) as List).cast<Map<String, dynamic>>();
      final prophetRaw = (jsonDecode(results[2]) as List).cast<Map<String, dynamic>>();

      final hadith = hadithRaw
          .map((j) => DailyPoolItem(
                id: j['id'] as String? ?? '',
                promptEn: j['ar'] as String? ?? '',
                promptAr: j['ar'] as String? ?? '',
                answerEn: j['translation'] as String? ?? '',
                answerAr: j['translation_ar'] as String? ?? '',
              ))
          .toList();
      final asma = asmaRaw
          .map((j) => DailyPoolItem(
                id: (j['n']?.toString()) ?? '',
                promptEn: j['name_ar'] as String? ?? '',
                promptAr: j['name_ar'] as String? ?? '',
                answerEn: j['en'] as String? ?? '',
                answerAr: j['en_ar'] as String? ?? '',
              ))
          .toList();
      final prophet = prophetRaw
          .map((j) => DailyPoolItem(
                id: j['id'] as String? ?? '',
                promptEn: '"${j['lesson'] as String? ?? ''}"',
                promptAr: '"${j['lesson_ar'] as String? ?? ''}"',
                answerEn: j['name'] as String? ?? '',
                answerAr: j['name_ar'] as String? ?? '',
              ))
          .toList();

      final q = buildDailyQuestion(
        date: DateTime.now(),
        hadith: hadith,
        asma: asma,
        prophet: prophet,
      );

      if (!mounted) return;
      setState(() {
        _question = q;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAnswer(int i) async {
    if (_picked != null) return;
    final q = _question!;
    final correct = q.options[i].id == q.correct.id;
    setState(() => _picked = i);
    await ref
        .read(dailyQuizStreakProvider.notifier)
        .recordAnswer(correct: correct);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final streakAsync = ref.watch(dailyQuizStreakProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'سؤال اليوم' : 'Daily Wisdom'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _question == null
              ? ContentEmptyState(
                  icon: Icons.today_outlined,
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : _body(isAr, streakAsync.value ?? DailyQuizStreak.empty),
    );
  }

  Widget _body(bool isAr, DailyQuizStreak streak) {
    final q = _question!;
    final correct = _picked != null && q.options[_picked!].id == q.correct.id;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _streakHeader(isAr, streak),
        const SizedBox(height: 14),
        _kindBadge(isAr, q.kind),
        const SizedBox(height: 10),
        _promptCard(isAr, q),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          _OptionTile(
            text: isAr ? q.options[i].answerAr : q.options[i].answerEn,
            state: _picked == null
                ? _OptionState.idle
                : (q.options[i].id == q.correct.id
                    ? _OptionState.correct
                    : (i == _picked
                        ? _OptionState.wrongPicked
                        : _OptionState.idle)),
            onTap: () => _pickAnswer(i),
          ),
        if (_picked != null) ...[
          const SizedBox(height: 12),
          _resultBanner(isAr, correct, streak),
        ],
      ],
    );
  }

  Widget _streakHeader(bool isAr, DailyQuizStreak streak) {
    final hijri = HijriDate.fromGregorian(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(46),
            AppColors.secondary.withAlpha(28),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                hijri.formatted(arabic: isAr),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark.withAlpha(200),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  emoji: '🔥',
                  labelEn: 'Streak',
                  labelAr: 'تتابع',
                  valueText:
                      localizeDigits(streak.currentStreak, arabic: isAr),
                  isAr: isAr,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  emoji: '🏆',
                  labelEn: 'Best',
                  labelAr: 'الأفضل',
                  valueText:
                      localizeDigits(streak.longestStreak, arabic: isAr),
                  isAr: isAr,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  emoji: '⭐',
                  labelEn: 'Correct',
                  labelAr: 'صحيح',
                  valueText:
                      '${localizeDigits(streak.totalCorrect, arabic: isAr)} / ${localizeDigits(streak.totalAttempts, arabic: isAr)}',
                  isAr: isAr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kindBadge(bool isAr, DailyQuestionKind kind) {
    final (label, emoji) = switch (kind) {
      DailyQuestionKind.hadith => (isAr ? 'حديث' : 'Hadith', '📜'),
      DailyQuestionKind.asma => (isAr ? 'اسم من أسماء الله' : 'Name of Allah', '☪️'),
      DailyQuestionKind.prophet => (isAr ? 'نبي' : 'Prophet', '📿'),
    };
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.outline.withAlpha(80)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promptCard(bool isAr, DailyQuestion q) {
    final prompt = isAr ? q.correct.promptAr : q.correct.promptEn;
    final hint = switch (q.kind) {
      DailyQuestionKind.hadith =>
        isAr ? 'ما معنى هذا الحديث؟' : 'What does this hadith mean?',
      DailyQuestionKind.asma =>
        isAr ? 'ماذا يعني هذا الاسم؟' : 'What does this name mean?',
      DailyQuestionKind.prophet =>
        isAr ? 'لأي نبي تنتمي هذه العبرة؟' : 'Which prophet does this lesson belong to?',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            hint,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark.withAlpha(170),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prompt,
            textAlign: TextAlign.center,
            textDirection: q.kind == DailyQuestionKind.prophet
                ? null
                : TextDirection.rtl,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textDark,
              fontSize: q.kind == DailyQuestionKind.asma ? 28 : 17,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBanner(bool isAr, bool correct, DailyQuizStreak streak) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (correct ? AppColors.success : AppColors.error).withAlpha(36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (correct ? AppColors.success : AppColors.error).withAlpha(120),
        ),
      ),
      child: Row(
        children: [
          Text(correct ? '🎉' : '💪', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct
                      ? (isAr ? 'إجابة صحيحة!' : 'Correct!')
                      : (isAr ? 'لا بأس — تعلَّمنا اليوم!' : 'No worries — we learned today!'),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                ),
                if (correct) ...[
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? '${localizeDigits(streak.currentStreak, arabic: true)} يوم متتالٍ'
                        : '${streak.currentStreak} day streak',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark.withAlpha(180),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
    required this.valueText,
    required this.isAr,
  });
  final String emoji;
  final String labelEn;
  final String labelAr;
  final String valueText;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          valueText,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          isAr ? labelAr : labelEn,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textDark.withAlpha(170),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrongPicked }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    switch (state) {
      case _OptionState.idle:
        bg = AppColors.surfaceContainerLow;
        border = AppColors.outline.withAlpha(80);
      case _OptionState.correct:
        bg = AppColors.success.withAlpha(46);
        border = AppColors.success;
      case _OptionState.wrongPicked:
        bg = AppColors.error.withAlpha(40);
        border = AppColors.error;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: state == _OptionState.idle ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (state == _OptionState.correct)
                const Icon(Icons.check_circle_rounded, color: AppColors.success)
              else if (state == _OptionState.wrongPicked)
                const Icon(Icons.cancel_rounded, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}
