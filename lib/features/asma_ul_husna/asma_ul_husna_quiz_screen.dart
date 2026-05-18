import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/features/asma_ul_husna/asma_quiz_engine.dart';

/// 10-question multiple-choice quiz over the 99 Names. Each question shows
/// a Name and 4 meaning options (1 correct + 3 plausible distractors drawn
/// from the same category when possible). Score + result screen at the
/// end. Pure recall — different cognitive task than the browse screen.
class AsmaUlHusnaQuizScreen extends ConsumerStatefulWidget {
  const AsmaUlHusnaQuizScreen({super.key});

  @override
  ConsumerState<AsmaUlHusnaQuizScreen> createState() =>
      _AsmaUlHusnaQuizScreenState();
}

class _AsmaUlHusnaQuizScreenState
    extends ConsumerState<AsmaUlHusnaQuizScreen> {
  static const int _kRoundSize = 10;
  final _rng = math.Random();

  List<AsmaName> _pool = const [];
  List<AsmaQuestion> _questions = const [];
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
      final raw = await rootBundle.loadString(
        'assets/data/asma_ul_husna_memorization.json',
      );
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _pool = list.map(AsmaName.fromJson).toList();
        _questions = buildAsmaQuestions(_pool, roundSize: _kRoundSize, rng: _rng);
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
    final isCorrect = q.options[i].n == q.name.n;
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
      setState(() => _idx = _questions.length); // sentinel: end of round
    }
  }

  void _restart() {
    setState(() {
      _idx = 0;
      _score = 0;
      _picked = null;
      _questions = buildAsmaQuestions(_pool, roundSize: _kRoundSize, rng: _rng);
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
        title: Text(isAr ? 'اختبار الأسماء الحسنى' : '99 Names Quiz'),
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
          color: AppColors.accent,
          backgroundColor: AppColors.outline.withAlpha(60),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Text(
                isAr
                    ? 'سؤال ${localizeDigits(_idx + 1, arabic: true)} / ${localizeDigits(_questions.length, arabic: true)}'
                    : 'Question ${_idx + 1} / ${_questions.length}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                ),
              ),
              const Spacer(),
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
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withAlpha(48),
                AppColors.secondary.withAlpha(28),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withAlpha(140)),
          ),
          child: Column(
            children: [
              Text(
                isAr ? 'ماذا يعني هذا الاسم؟' : 'What does this name mean?',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                q.name.nameAr,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textDark,
                  fontSize: 32,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                q.name.tr,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              TtsSpeakerIcon(
                text: q.name.nameAr,
                tooltip: isAr ? 'استمع' : 'Listen',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              for (var i = 0; i < q.options.length; i++)
                _OptionTile(
                  text: isAr ? q.options[i].enAr : q.options[i].en,
                  state: _picked == null
                      ? _OptionState.idle
                      : (q.options[i].n == q.name.n
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
    final stars = asmaStarsFor(_score, total);
    final praise = _score == total
        ? (isAr ? 'ممتاز! درجة كاملة!' : 'Perfect — every one right!')
        : _score >= total * 0.7
        ? (isAr ? 'أحسنت! تقدُّم رائع.' : 'Great work — strong recall!')
        : (isAr ? 'حاول مرة أخرى لتحفظ أكثر.' : 'Try again — keep learning.');
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
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                )
              else if (state == _OptionState.wrongPicked)
                const Icon(Icons.cancel_rounded, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

