import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/quiz/multiple_choice_engine.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Generic 10-question MCQ screen. Drives the Hadith and Prophet quizzes;
/// the 99 Names quiz predates this widget and keeps its own copy (it has
/// specific "skip same-translation distractor" logic and TTS in the
/// prompt card). The caller supplies:
///  - [assetPath]: JSON file with a list of items
///  - [fromJson]: maps each item map → [T]
///  - [buildPromptCard]: the question content shown at the top
///  - [optionText]: localized text for each option tile
///
/// Result/score view, progress, restart and back behavior are all
/// handled here — adding a new MCQ quiz is just plugging in content.
class MCQuizScreen<T extends QuizItem> extends ConsumerStatefulWidget {
  const MCQuizScreen({
    super.key,
    required this.assetPath,
    required this.titleEn,
    required this.titleAr,
    required this.promptEn,
    required this.promptAr,
    required this.fromJson,
    required this.buildPromptCard,
    required this.optionText,
    required this.accent,
    this.roundSize = 10,
  });

  final String assetPath;
  final String titleEn;
  final String titleAr;
  final String promptEn;
  final String promptAr;
  final T Function(Map<String, dynamic>) fromJson;
  final Widget Function(T item, bool isAr) buildPromptCard;
  final String Function(T option, bool isAr) optionText;
  final Color accent;
  final int roundSize;

  @override
  ConsumerState<MCQuizScreen<T>> createState() => _MCQuizScreenState<T>();
}

class _MCQuizScreenState<T extends QuizItem>
    extends ConsumerState<MCQuizScreen<T>> {
  final _rng = math.Random();

  List<T> _pool = const [];
  List<QuizRound<T>> _questions = const [];
  int _idx = 0;
  int _score = 0;
  int? _picked;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(widget.assetPath);
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _pool = list.map(widget.fromJson).toList();
        _questions = buildQuizRound<T>(
          _pool,
          roundSize: widget.roundSize,
          rng: _rng,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _pickAnswer(int i) {
    if (_picked != null) return;
    final q = _questions[_idx];
    final isCorrect = q.options[i].id == q.name.id;
    setState(() {
      _picked = i;
      if (isCorrect) _score += 1;
    });
  }

  void _next() {
    if (_idx < _questions.length - 1) {
      setState(() {
        _idx += 1;
        _picked = null;
      });
    } else {
      setState(() => _idx = _questions.length);
    }
  }

  void _restart() {
    setState(() {
      _idx = 0;
      _score = 0;
      _picked = null;
      _questions = buildQuizRound<T>(
        _pool,
        roundSize: widget.roundSize,
        rng: _rng,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? widget.titleAr : widget.titleEn),
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
          : _questions.isEmpty
              ? ContentEmptyState(
                  icon: Icons.quiz_outlined,
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : _idx >= _questions.length
                  ? _resultView(isAr)
                  : _questionView(isAr),
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
          color: widget.accent,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accent.withAlpha(48),
                AppColors.secondary.withAlpha(28),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.accent.withAlpha(140)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr ? widget.promptAr : widget.promptEn,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              widget.buildPromptCard(q.name, isAr),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              for (var i = 0; i < q.options.length; i++)
                _OptionTile(
                  text: widget.optionText(q.options[i], isAr),
                  state: _picked == null
                      ? _OptionState.idle
                      : (q.options[i].id == q.name.id
                          ? _OptionState.correct
                          : (i == _picked
                              ? _OptionState.wrongPicked
                              : _OptionState.idle)),
                  onTap: () => _pickAnswer(i),
                ),
            ],
          ),
        ),
        if (_picked != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton.icon(
                onPressed: _next,
                icon: Icon(
                  isAr
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _idx < _questions.length - 1
                      ? (isAr ? 'السؤال التالي' : 'Next question')
                      : (isAr ? 'النتيجة' : 'See result'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resultView(bool isAr) {
    final total = _questions.length;
    final stars = quizStarsFor(_score, total);
    final praise = _score == total
        ? (isAr ? 'ممتاز! درجة كاملة!' : 'Perfect — every one right!')
        : _score >= total * 0.7
            ? (isAr ? 'أحسنت! تقدُّم رائع.' : 'Great work — strong recall!')
            : (isAr
                ? 'حاول مرة أخرى لتحفظ أكثر.'
                : 'Try again — keep learning.');
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
                  ? '${localizeDigits(_score, arabic: true)} من ${localizeDigits(total, arabic: true)}'
                  : '$_score / $total',
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
                  onPressed: () => context.pop(),
                  icon: Icon(
                    isAr
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                  ),
                  label: Text(isAr ? 'رجوع' : 'Back'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _restart,
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
        onTap: onTap,
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
