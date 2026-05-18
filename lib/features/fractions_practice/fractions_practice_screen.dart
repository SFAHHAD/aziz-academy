import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/features/fractions_practice/fractions_engine.dart';

/// "Fractions Practice" — kid-friendly visual fractions drill. Two
/// modes: Identify (a pie chart shows a shaded portion, pick which
/// fraction it represents) and Compare (which is bigger, 1/3 or 1/4?).
/// 10 questions per round, stars at the end.
class FractionsPracticeScreen extends ConsumerStatefulWidget {
  const FractionsPracticeScreen({super.key});

  @override
  ConsumerState<FractionsPracticeScreen> createState() =>
      _FractionsPracticeScreenState();
}

class _FractionsPracticeScreenState
    extends ConsumerState<FractionsPracticeScreen> {
  static const _roundSize = 10;
  final _rng = math.Random();

  FractionMode? _mode; // null = picker
  List<dynamic> _questions = const []; // mix of Identify/Compare
  int _idx = 0;
  int _score = 0;
  Object? _picked; // FractionVal for identify, bool for compare
  bool _showingRound = false;

  void _startRound(FractionMode mode) {
    setState(() {
      _mode = mode;
      _questions = _buildRound(mode);
      _idx = 0;
      _score = 0;
      _picked = null;
      _showingRound = true;
    });
  }

  List<dynamic> _buildRound(FractionMode mode) {
    return List.generate(_roundSize, (_) {
      return mode == FractionMode.identify
          ? generateIdentifyQuestion(rng: _rng)
          : generateCompareQuestion(rng: _rng);
    });
  }

  void _pickIdentify(FractionVal v) {
    if (_picked != null) return;
    final q = _questions[_idx] as IdentifyQuestion;
    setState(() {
      _picked = v;
      if (v == q.correct) _score += 1;
    });
  }

  void _pickCompare(bool pickedLeft) {
    if (_picked != null) return;
    final q = _questions[_idx] as CompareQuestion;
    final correct = q.leftIsBigger == pickedLeft;
    setState(() {
      _picked = pickedLeft;
      if (correct) _score += 1;
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

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'الكسور' : 'Fractions Practice'),
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
          ? _modePickerView(isAr)
          : _idx >= _questions.length
              ? _resultView(isAr)
              : _mode == FractionMode.identify
                  ? _identifyView(isAr)
                  : _compareView(isAr),
    );
  }

  Widget _modePickerView(bool isAr) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          isAr ? 'اختر اللعبة' : 'Pick a mode',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAr
              ? '١٠ أسئلة لكل جولة.'
              : '10 questions per round.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark.withAlpha(170),
          ),
        ),
        const SizedBox(height: 16),
        _ModeTile(
          emoji: '🥧',
          labelEn: 'Identify',
          labelAr: 'تحديد',
          hintEn: 'See a shape, pick the fraction',
          hintAr: 'انظر للشكل واختر الكسر',
          accent: AppColors.secondary,
          onTap: () => _startRound(FractionMode.identify),
        ),
        const SizedBox(height: 10),
        _ModeTile(
          emoji: '⚖️',
          labelEn: 'Compare',
          labelAr: 'قارن',
          hintEn: 'Which fraction is bigger?',
          hintAr: 'أيُّ الكسرين أكبر؟',
          accent: AppColors.accent,
          onTap: () => _startRound(FractionMode.compare),
        ),
      ],
    );
  }

  Widget _identifyView(bool isAr) {
    final q = _questions[_idx] as IdentifyQuestion;
    return Column(
      children: [
        _progressHeader(isAr),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: Center(
            child: CustomPaint(
              size: const Size(160, 160),
              painter: _PiePainter(
                numerator: q.correct.numerator,
                denominator: q.correct.denominator,
                fillColor: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isAr ? 'أي كسر يطابق الشكل؟' : 'Which fraction matches?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark.withAlpha(180),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              for (final opt in q.options)
                _FractionAnswerTile(
                  text: _fractionText(opt, isAr),
                  state: _picked == null
                      ? _AnswerState.idle
                      : (opt == q.correct
                          ? _AnswerState.correct
                          : (opt == _picked
                              ? _AnswerState.wrongPicked
                              : _AnswerState.idle)),
                  onTap: () => _pickIdentify(opt),
                ),
            ],
          ),
        ),
        if (_picked != null) _nextButton(isAr),
      ],
    );
  }

  Widget _compareView(bool isAr) {
    final q = _questions[_idx] as CompareQuestion;
    return Column(
      children: [
        _progressHeader(isAr),
        const SizedBox(height: 18),
        Text(
          isAr ? 'أيهما أكبر؟' : 'Which is bigger?',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _CompareTile(
                    fraction: q.left,
                    isAr: isAr,
                    state: _picked == null
                        ? _AnswerState.idle
                        : (q.leftIsBigger
                            ? _AnswerState.correct
                            : (_picked == true
                                ? _AnswerState.wrongPicked
                                : _AnswerState.idle)),
                    onTap: () => _pickCompare(true),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isAr ? 'أم' : 'or',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark.withAlpha(160),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompareTile(
                    fraction: q.right,
                    isAr: isAr,
                    state: _picked == null
                        ? _AnswerState.idle
                        : (!q.leftIsBigger
                            ? _AnswerState.correct
                            : (_picked == false
                                ? _AnswerState.wrongPicked
                                : _AnswerState.idle)),
                    onTap: () => _pickCompare(false),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_picked != null) _nextButton(isAr),
      ],
    );
  }

  Widget _progressHeader(bool isAr) {
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
                  color: AppColors.success.withAlpha(40),
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
      ],
    );
  }

  Widget _nextButton(bool isAr) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: FilledButton.icon(
          onPressed: _next,
          icon: Icon(
            isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
          ),
          label: Text(
            _idx < _questions.length - 1
                ? (isAr ? 'التالي' : 'Next')
                : (isAr ? 'النتيجة' : 'See result'),
          ),
        ),
      ),
    );
  }

  Widget _resultView(bool isAr) {
    final stars = fractionStarsFor(_score, _roundSize);
    final praise = _score == _roundSize
        ? (isAr ? 'ممتاز! درجة كاملة!' : 'Perfect — every one right!')
        : _score >= _roundSize * 0.7
            ? (isAr ? 'أحسنت!' : 'Great work!')
            : (isAr ? 'حاول مرة أخرى.' : 'Try again — keep practicing.');
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
                  label: Text(isAr ? 'الأنماط' : 'Modes'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _startRound(_mode!),
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

  String _fractionText(FractionVal f, bool isAr) => isAr
      ? '${localizeDigits(f.numerator, arabic: true)} / ${localizeDigits(f.denominator, arabic: true)}'
      : '${f.numerator}/${f.denominator}';
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.numerator,
    required this.denominator,
    required this.fillColor,
  });
  final int numerator;
  final int denominator;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final filled = Paint()..color = fillColor;
    final empty = Paint()..color = fillColor.withAlpha(40);
    final border = Paint()
      ..color = AppColors.textDark.withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Empty background pie.
    canvas.drawArc(rect, 0, math.pi * 2, true, empty);

    // Filled slices — start at top (−π/2), sweep clockwise.
    final sliceAngle = (math.pi * 2) / denominator;
    final start = -math.pi / 2;
    for (var i = 0; i < numerator; i++) {
      canvas.drawArc(
        rect,
        start + i * sliceAngle,
        sliceAngle,
        true,
        filled,
      );
    }

    // Slice dividers.
    final center = rect.center;
    final radius = rect.width / 2;
    for (var i = 0; i < denominator; i++) {
      final a = start + i * sliceAngle;
      final dx = center.dx + radius * math.cos(a);
      final dy = center.dy + radius * math.sin(a);
      canvas.drawLine(center, Offset(dx, dy), border);
    }
    // Outer circle outline.
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.numerator != numerator ||
      old.denominator != denominator ||
      old.fillColor != fillColor;
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
    required this.hintEn,
    required this.hintAr,
    required this.accent,
    required this.onTap,
  });
  final String emoji;
  final String labelEn;
  final String labelAr;
  final String hintEn;
  final String hintAr;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withAlpha(120), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withAlpha(140)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? labelAr : labelEn,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textDark,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    isAr ? hintAr : hintEn,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark.withAlpha(180),
                      fontSize: 12,
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
}

enum _AnswerState { idle, correct, wrongPicked }

class _FractionAnswerTile extends StatelessWidget {
  const _FractionAnswerTile({
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
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.textDark,
            fontSize: 28,
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CompareTile extends StatelessWidget {
  const _CompareTile({
    required this.fraction,
    required this.isAr,
    required this.state,
    required this.onTap,
  });
  final FractionVal fraction;
  final bool isAr;
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _PiePainter(
                  numerator: fraction.numerator,
                  denominator: fraction.denominator,
                  fillColor: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAr
                  ? '${localizeDigits(fraction.numerator, arabic: true)} / ${localizeDigits(fraction.denominator, arabic: true)}'
                  : '${fraction.numerator}/${fraction.denominator}',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 28,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
