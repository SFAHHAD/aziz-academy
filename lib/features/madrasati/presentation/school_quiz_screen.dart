import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/madrasati/presentation/madrasati_screen.dart';

// =============================================================================
// School Quiz Screen — self-managed quiz state (no Riverpod provider needed)
// =============================================================================

class SchoolQuizScreen extends ConsumerStatefulWidget {
  const SchoolQuizScreen({super.key});

  @override
  ConsumerState<SchoolQuizScreen> createState() => _SchoolQuizScreenState();
}

class _SchoolQuizScreenState extends ConsumerState<SchoolQuizScreen>
    with SingleTickerProviderStateMixin {
  late final SchoolQuizArgs _args;
  late final List<QuizQuestion> _questions;
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealFade;

  int _currentIndex = 0;
  int _score = 0;
  String? _selected;
  bool _revealed = false;
  bool _done = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _args = GoRouterState.of(context).extra! as SchoolQuizArgs;
      final rng = math.Random();
      _questions = List<QuizQuestion>.from(_args.questions)..shuffle(rng);
      _revealCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      );
      _revealFade = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  QuizQuestion get _current => _questions[_currentIndex];

  void _onAnswer(String option) {
    if (_revealed) return;
    final isCorrect = option == _current.correctAnswer;
    if (isCorrect) {
      HapticFeedback.lightImpact();
      _score++;
    } else {
      HapticFeedback.mediumImpact();
    }
    unawaited(
      ref
          .read(ttsServiceProvider)
          .speakAnswerFeedback(_current.correctAnswer, correct: isCorrect),
    );
    setState(() {
      _selected = option;
      _revealed = true;
    });
    _revealCtrl.forward();
  }

  void _onNext() {
    if (_currentIndex + 1 >= _questions.length) {
      HapticFeedback.heavyImpact();
      setState(() => _done = true);
    } else {
      setState(() {
        _currentIndex++;
        _selected = null;
        _revealed = false;
      });
      _revealCtrl.reset();
    }
  }

  void _restart() {
    final rng = math.Random();
    setState(() {
      _questions.shuffle(rng);
      _currentIndex = 0;
      _score = 0;
      _selected = null;
      _revealed = false;
      _done = false;
    });
    _revealCtrl.reset();
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _done ? _buildResult() : _buildQuiz()),
    );
  }

  // ── Result screen ───────────────────────────────────────────────────────────

  Widget _buildResult() {
    final total = _questions.length;
    final pct = total == 0 ? 0 : (_score / total * 100).round();
    final String medal = pct >= 80
        ? '🏆'
        : pct >= 50
        ? '⭐'
        : '📖';
    final Color accent = _args.color;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(medal, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _args.chapterName,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.madrasatiResultScore(
                localizeDigitsCtx(_score, context),
                localizeDigitsCtx(total, context),
              ),
              style: AppTextStyles.headingMedium.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${localizeDigitsCtx(pct, context)}%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ).copyWith(color: accent.withAlpha(180)),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(context.l10n.madrasatiRestart),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.madrasati),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(context.l10n.madrasatiHome),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Quiz body ───────────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    final q = _current;
    final accent = _args.color;
    final progress = (_currentIndex + 1) / _questions.length;

    return CenteredBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.madrasati),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMedium,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_args.subjectEmoji}  ${_args.chapterName}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surfaceContainerLow,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${localizeDigitsCtx(_currentIndex + 1, context)}/${localizeDigitsCtx(_questions.length, context)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Score bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⭐ ${localizeDigitsCtx(_score, context)}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Question card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(22),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: accent.withAlpha(80)),
                    ),
                    child: Text(
                      q.question,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...q.options.map(
                    (opt) => _OptionButton(
                      option: opt,
                      correctAnswer: q.correctAnswer,
                      selected: _selected,
                      revealed: _revealed,
                      accent: accent,
                      onTap: () => _onAnswer(opt),
                    ),
                  ),

                  // Fun fact + next button
                  if (_revealed)
                    FadeTransition(
                      opacity: _revealFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withAlpha(60)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '💡',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    q.funFact,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textMedium,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _onNext,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _currentIndex + 1 >= _questions.length
                                  ? context.l10n.quizShowResult
                                  : context.l10n.quizNextQuestion,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
// Option button widget
// =============================================================================

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.correctAnswer,
    required this.selected,
    required this.revealed,
    required this.accent,
    required this.onTap,
  });

  final String option;
  final String correctAnswer;
  final String? selected;
  final bool revealed;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceContainerLow;
    Color border = AppColors.surfaceContainerLow;
    Color text = AppColors.textDark;
    Widget? trailing;

    if (revealed) {
      if (option == correctAnswer) {
        bg = AppColors.success.withAlpha(35);
        border = AppColors.success;
        text = AppColors.success;
        trailing = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 22,
        );
      } else if (option == selected) {
        bg = AppColors.error.withAlpha(25);
        border = AppColors.error;
        text = AppColors.error;
        trailing = const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 22,
        );
      }
    }

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: text,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }
}
