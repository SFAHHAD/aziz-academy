import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/multiplication_progress_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// "Multiplication Practice" — pick a times-table 2..12 and run a
/// 10-question round. Each question: "T × n = ?" with 4 answer choices.
/// Per-table accuracy persists between sessions so the kid can see
/// which tables they're shaky on. "All tables" mode picks a random
/// table per question for mixed practice.
class MultiplicationPracticeScreen extends ConsumerStatefulWidget {
  const MultiplicationPracticeScreen({super.key});

  @override
  ConsumerState<MultiplicationPracticeScreen> createState() =>
      _MultiplicationPracticeScreenState();
}

class _MultiplicationPracticeScreenState
    extends ConsumerState<MultiplicationPracticeScreen> {
  static const _roundSize = 10;
  final _rng = math.Random();

  // null = mixed (random table per question)
  int? _selectedTable;
  List<_Q> _questions = const [];
  int _idx = 0;
  int _score = 0;
  int? _picked;
  bool _showingRound = false;

  void _startRound(int? table) {
    setState(() {
      _selectedTable = table;
      _questions = _buildRound(table);
      _idx = 0;
      _score = 0;
      _picked = null;
      _showingRound = true;
    });
  }

  List<_Q> _buildRound(int? table) {
    return List.generate(_roundSize, (i) {
      final t = table ?? (2 + _rng.nextInt(11));
      final n = 1 + _rng.nextInt(12);
      final answer = t * n;
      // Build 3 plausible wrong answers near the correct value.
      final wrongs = <int>{};
      while (wrongs.length < 3) {
        // Wrong answers within ±20% of correct (or ±5 minimum), and ≠ correct
        final delta = math.max(5, (answer * 0.2).round());
        final cand = answer + _rng.nextInt(delta * 2 + 1) - delta;
        if (cand <= 0 || cand == answer) continue;
        wrongs.add(cand);
      }
      final options = [answer, ...wrongs]..shuffle(_rng);
      return _Q(table: t, multiplier: n, answer: answer, options: options);
    });
  }

  void _pickAnswer(int i) {
    if (_picked != null) return;
    final q = _questions[_idx];
    setState(() {
      _picked = i;
      if (q.options[i] == q.answer) _score += 1;
    });
  }

  Future<void> _nextOrFinish() async {
    if (_idx < _questions.length - 1) {
      setState(() {
        _idx += 1;
        _picked = null;
      });
      return;
    }
    // End of round. Persist accuracy for single-table mode so the
    // "shaky tables" banner can stay accurate. Mixed mode doesn't
    // persist — we'd need to track per-question correctness across
    // the round to attribute correctness to the right table, and the
    // payoff is small.
    if (_selectedTable != null) {
      await ref.read(multiplicationProgressProvider.notifier).recordRound(
            table: _selectedTable!,
            correct: _score,
            total: _roundSize,
          );
    }
    setState(() => _idx = _questions.length); // sentinel: result view
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'جدول الضرب' : 'Multiplication Practice'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (_showingRound) {
              setState(() => _showingRound = false);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: !_showingRound
          ? _selectTableView(isAr)
          : _idx >= _questions.length
              ? _resultView(isAr)
              : _questionView(isAr),
    );
  }

  Widget _selectTableView(bool isAr) {
    final stats = ref.watch(multiplicationProgressProvider).value ??
        MultiplicationStats.empty;
    final shaky = stats.shakyTables();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          isAr ? 'اختر جدولًا' : 'Pick a table',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAr
              ? '١٠ أسئلة لكل جولة — نتتبع نسبة إجاباتك الصحيحة.'
              : '10 questions per round — we track your accuracy.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark.withAlpha(170),
          ),
        ),
        const SizedBox(height: 14),
        if (shaky.isNotEmpty) ...[
          _shakyBanner(isAr, shaky, stats),
          const SizedBox(height: 14),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            for (var t = 2; t <= 12; t++)
              _TableTile(
                table: t,
                accuracy: stats.accuracyFor(t),
                total: stats.totalFor(t),
                isAr: isAr,
                onTap: () => _startRound(t),
              ),
            _MixedTile(
              isAr: isAr,
              onTap: () => _startRound(null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shakyBanner(bool isAr, List<int> shaky, MultiplicationStats stats) {
    final t = shaky.first;
    final acc = stats.accuracyFor(t) ?? 0;
    final pct = (acc * 100).round();
    return InkWell(
      onTap: () => _startRound(t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withAlpha(110)),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'ركّز هنا' : 'Focus here',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark.withAlpha(170),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    isAr
                        ? 'جدول ${localizeDigits(t, arabic: true)} — ${localizeDigits(pct, arabic: true)}٪'
                        : '×$t table — $pct%',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: AppColors.textDark.withAlpha(140),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionView(bool isAr) {
    final q = _questions[_idx];
    final progress = (_idx + 1) / _questions.length;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          color: AppColors.secondary,
          backgroundColor: AppColors.outline.withAlpha(60),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  isAr
                      ? 'سؤال ${localizeDigits(_idx + 1, arabic: true)} / ${localizeDigits(_questions.length, arabic: true)}'
                      : 'Q ${_idx + 1} / ${_questions.length}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark.withAlpha(180),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(40),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isAr
                      ? 'النقاط: ${localizeDigits(_score, arabic: true)}'
                      : 'Score: $_score',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withAlpha(48),
                AppColors.accent.withAlpha(28),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withAlpha(140)),
          ),
          child: Center(
            child: Text(
              isAr
                  ? '${localizeDigits(q.table, arabic: true)} × ${localizeDigits(q.multiplier, arabic: true)} = ؟'
                  : '${q.table} × ${q.multiplier} = ?',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              for (var i = 0; i < q.options.length; i++)
                _AnswerTile(
                  text: localizeDigits(q.options[i], arabic: isAr),
                  state: _picked == null
                      ? _AnswerState.idle
                      : (q.options[i] == q.answer
                          ? _AnswerState.correct
                          : (i == _picked
                              ? _AnswerState.wrongPicked
                              : _AnswerState.idle)),
                  onTap: () => _pickAnswer(i),
                ),
            ],
          ),
        ),
        if (_picked != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: FilledButton.icon(
                onPressed: _nextOrFinish,
                icon: Icon(
                  isAr
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _idx < _questions.length - 1
                      ? (isAr ? 'التالي' : 'Next')
                      : (isAr ? 'النتيجة' : 'See result'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resultView(bool isAr) {
    final stars = (_score / _roundSize * 3).round().clamp(0, 3);
    final praise = _score == _roundSize
        ? (isAr ? 'ممتاز! درجة كاملة!' : 'Perfect — every one right!')
        : _score >= _roundSize * 0.7
            ? (isAr ? 'أحسنت!' : 'Great work!')
            : (isAr ? 'حاول مرة أخرى.' : 'Try again — practice makes perfect.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              List.generate(3, (i) => i < stars ? '⭐' : '☆').join(),
              style: const TextStyle(fontSize: 44),
            ),
            const SizedBox(height: 18),
            Text(
              isAr
                  ? '${localizeDigits(_score, arabic: true)} من ${localizeDigits(_roundSize, arabic: true)}'
                  : '$_score / $_roundSize',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              praise,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _showingRound = false),
                  icon: Icon(
                    isAr
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                  ),
                  label: Text(isAr ? 'الجداول' : 'Tables'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _startRound(_selectedTable),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(isAr ? 'إعادة' : 'Play again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Q {
  const _Q({
    required this.table,
    required this.multiplier,
    required this.answer,
    required this.options,
  });
  final int table;
  final int multiplier;
  final int answer;
  final List<int> options;
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.table,
    required this.accuracy,
    required this.total,
    required this.isAr,
    required this.onTap,
  });
  final int table;
  final double? accuracy;
  final int total;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = accuracy == null
        ? AppColors.outline.withAlpha(80)
        : (accuracy! >= 0.9
            ? AppColors.success
            : accuracy! >= 0.7
                ? AppColors.secondary
                : AppColors.warning);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAr ? '× ${localizeDigits(table, arabic: true)}' : '× $table',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                fontFamily: 'JetBrainsMono',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              accuracy == null
                  ? (isAr ? 'جديد' : 'new')
                  : '${(accuracy! * 100).round()}%',
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MixedTile extends StatelessWidget {
  const _MixedTile({required this.isAr, required this.onTap});
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withAlpha(48),
              AppColors.secondary.withAlpha(28),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withAlpha(140)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎲', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Text(
              isAr ? 'متنوع' : 'Mixed',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AnswerState { idle, correct, wrongPicked }

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.text,
    required this.state,
    required this.onTap,
  });
  final String text;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    switch (state) {
      case _AnswerState.idle:
        bg = AppColors.surfaceContainerLow;
        border = AppColors.outline.withAlpha(80);
      case _AnswerState.correct:
        bg = AppColors.success.withAlpha(46);
        border = AppColors.success;
      case _AnswerState.wrongPicked:
        bg = AppColors.error.withAlpha(40);
        border = AppColors.error;
    }
    return InkWell(
      onTap: state == _AnswerState.idle ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.6),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
            fontSize: 24,
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
