import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/weekly_tourney_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Weekly Tournament — every family slot gets one weekly best score that
/// rolls up onto a device-local leaderboard. Score = correct answers in a
/// 10-question mixed round. Resets each ISO week.
class WeeklyTourneyScreen extends ConsumerStatefulWidget {
  const WeeklyTourneyScreen({super.key});

  @override
  ConsumerState<WeeklyTourneyScreen> createState() =>
      _WeeklyTourneyScreenState();
}

enum _Phase { menu, play, summary }

class _WeeklyTourneyScreenState extends ConsumerState<WeeklyTourneyScreen> {
  static const _qsCount = 10;

  _Phase _phase = _Phase.menu;
  List<QuizQuestion> _qs = const [];
  int _idx = 0;
  int _score = 0;
  bool _answered = false;
  String? _picked;
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final caps = await ref
        .read(capitalsRepositoryProvider)
        .loadQuestions(arabic: isArabic);
    final sci = await ref
        .read(sciencesRepositoryProvider)
        .loadQuestions(arabic: isArabic);
    final mix = [...caps, ...sci]..shuffle();
    if (mounted) {
      setState(() {
        _qs = mix.take(_qsCount).toList();
        _idx = 0;
        _score = 0;
        _answered = false;
        _picked = null;
        _phase = _Phase.play;
        _loading = false;
      });
    }
  }

  void _onAnswer(String pick) {
    if (_answered) return;
    setState(() {
      _picked = pick;
      _answered = true;
      if (pick == _qs[_idx].correctAnswer) _score++;
    });
  }

  Future<void> _next() async {
    if (_idx + 1 >= _qs.length) {
      // Record score for active slot
      final family = ref.read(familyProfilesProvider).value;
      final slotId = family?.activeSlotId ?? 0;
      await ref
          .read(weeklyTourneyProvider.notifier)
          .recordScore(slotId: slotId, score: _score);
      // If active slot now leads the week, record top finish.
      final entries = ref.read(weeklyTourneyProvider.notifier).currentWeek();
      if (entries.isNotEmpty && entries.first.slotId == slotId) {
        await ref.read(achievementProvider.notifier).recordTourneyTopFinish();
      }
      if (mounted) setState(() => _phase = _Phase.summary);
    } else {
      setState(() {
        _idx++;
        _answered = false;
        _picked = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _body(isArabic),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool arabic) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_phase) {
      case _Phase.menu:
        return _menuBody(arabic);
      case _Phase.play:
        return _playBody(arabic);
      case _Phase.summary:
        return _summaryBody(arabic);
    }
  }

  Widget _menuBody(bool arabic) {
    final family = ref.watch(familyProfilesProvider).value;
    final tourney = ref.watch(weeklyTourneyProvider).value;
    final iso = currentIsoWeek();
    final entries = tourney?.entries.where((e) => e.iso == iso).toList()
      ?..sort((a, b) => b.score.compareTo(a.score));

    return SingleChildScrollView(
      key: const ValueKey('menu'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.l10n.commonBack,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  arabic ? 'بطولة الأسبوع' : 'Weekly Tournament',
                  style: AppTextStyles.headingMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            arabic
                ? 'كل لاعب في العائلة يحصل على نتيجة أسبوعية واحدة. ١٠ أسئلة للجولة. تُعاد كل أسبوع.'
                : 'Each family slot gets one weekly best score. 10 questions per round. Resets each week.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic ? 'لوحة الأسبوع — $iso' : 'This week — $iso',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                if (entries == null || entries.isEmpty)
                  Text(
                    arabic
                        ? 'لا توجد نتائج هذا الأسبوع بعد.'
                        : 'No scores yet this week.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  )
                else
                  for (int i = 0; i < entries.length; i++)
                    _LeaderRow(
                      rank: i + 1,
                      slot: family?.slots.firstWhere(
                        (s) => s.id == entries[i].slotId,
                        orElse: () => family.slots.first,
                      ),
                      score: entries[i].score,
                      total: _qsCount,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(arabic ? 'ابدأ جولة' : 'Start round'),
          ),
        ],
      ),
    );
  }

  Widget _playBody(bool arabic) {
    final q = _qs[_idx];
    return SingleChildScrollView(
      key: ValueKey('p-$_idx'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_idx + 1}/${_qs.length}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              Text(
                arabic ? 'النتيجة: $_score' : 'Score: $_score',
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_idx + 1) / _qs.length,
            backgroundColor: AppColors.surfaceContainerLow,
            color: AppColors.secondary,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(q.question, style: AppTextStyles.headingSmall),
          ),
          const SizedBox(height: 12),
          for (final opt in q.options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                onPressed: _answered ? null : () => _onAnswer(opt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _answered
                      ? (opt == q.correctAnswer
                            ? AppColors.success
                            : (opt == _picked
                                  ? AppColors.error
                                  : AppColors.surfaceContainerLow))
                      : AppColors.surfaceContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(opt, style: AppTextStyles.labelLarge),
                ),
              ),
            ),
          if (_answered) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _next,
              icon: Icon(
                _idx + 1 == _qs.length
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _idx + 1 == _qs.length
                    ? (arabic ? 'إنهاء' : 'Finish')
                    : (arabic ? 'التالي' : 'Next'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryBody(bool arabic) {
    return Center(
      key: const ValueKey('done'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 96)),
          const SizedBox(height: 12),
          Text(
            arabic
                ? 'حصلت على $_score من ${_qs.length}'
                : 'You scored $_score of ${_qs.length}',
            style: AppTextStyles.headingLarge,
          ),
          const SizedBox(height: 8),
          Text(
            arabic
                ? 'حُفظت أفضل نتيجة لك هذا الأسبوع.'
                : 'Your best score for this week is saved.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _phase = _Phase.menu),
                icon: const Icon(Icons.leaderboard_rounded),
                label: Text(arabic ? 'لوحة الأسبوع' : 'Leaderboard'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.home_rounded),
                label: Text(arabic ? 'الرئيسية' : 'Home'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.slot,
    required this.score,
    required this.total,
  });
  final int rank;
  final ProfileSlot? slot;
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(medal, style: const TextStyle(fontSize: 18)),
          ),
          Text(slot?.avatarEmoji ?? '👤', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (slot?.name.isNotEmpty ?? false) ? slot!.name : 'Unnamed',
              style: AppTextStyles.labelMedium,
            ),
          ),
          Text(
            '$score/$total',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
