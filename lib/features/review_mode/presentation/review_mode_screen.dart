import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/review_mode_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

// =============================================================================
// Review Mode Screen
// =============================================================================

class ReviewModeScreen extends ConsumerStatefulWidget {
  const ReviewModeScreen({super.key});

  @override
  ConsumerState<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _ReviewModeScreenState extends ConsumerState<ReviewModeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedAnswer;
  bool _answerRevealed = false;
  bool _completionSpoken = false;
  Timer? _commitTimer;

  late final AnimationController _feedbackCtrl;
  late final Animation<double> _feedbackScale;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _feedbackScale = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _commitTimer?.cancel();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  void _onOptionTap(String choice, ReviewItem item) {
    if (_answerRevealed) return;
    final correct = ref.read(reviewModeProvider.notifier).answer(choice);
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    // Fire-and-forget TTS: human feedback + correct answer in one utterance.
    unawaited(
      ref
          .read(ttsServiceProvider)
          .speakAnswerFeedback(
            item.question.correctAnswer,
            correct: correct,
            srsItem: correct && item.entry.missCount == 1,
          ),
    );
    setState(() {
      _selectedAnswer = choice;
      _answerRevealed = true;
    });
    _feedbackCtrl.forward(from: 0);

    // Persist SRS outcome after feedback window.
    _commitTimer?.cancel();
    _commitTimer = Timer(const Duration(milliseconds: 950), () async {
      if (!mounted) return;
      await ref
          .read(reviewModeProvider.notifier)
          .commitAnswer(item.entry, correct);
      if (!mounted) return;
      setState(() {
        _selectedAnswer = null;
        _answerRevealed = false;
      });
    });
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reviewModeProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (e, _) => _ErrorBody(message: l10n.quizLoadError),
        data: (s) {
          if (s.isEmpty) return _EmptyBody(l10n: l10n);
          if (s.isComplete) {
            if (!_completionSpoken) {
              _completionSpoken = true;
              HapticFeedback.heavyImpact();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref
                      .read(ttsServiceProvider)
                      .speakFeedback(TtsFeedbackType.reviewComplete);
                }
              });
            }
            return _ResultScreen(state: s, l10n: l10n);
          }
          final item = s.currentItem;
          if (item == null) return _EmptyBody(l10n: l10n);
          return _QuizBody(
            state: s,
            item: item,
            selectedAnswer: _selectedAnswer,
            answerRevealed: _answerRevealed,
            feedbackScale: _feedbackScale,
            onOptionTap: _onOptionTap,
            l10n: l10n,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Quiz body
// =============================================================================

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.state,
    required this.item,
    required this.selectedAnswer,
    required this.answerRevealed,
    required this.feedbackScale,
    required this.onOptionTap,
    required this.l10n,
  });

  final ReviewSessionState state;
  final ReviewItem item;
  final String? selectedAnswer;
  final bool answerRevealed;
  final Animation<double> feedbackScale;
  final void Function(String, ReviewItem) onOptionTap;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    final missCount = item.entry.missCount;

    return SafeArea(
      child: CenteredBody(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainerLow,
                      ),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reviewModeTitle,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          l10n.reviewModeQuestionOf(
                            state.currentIndex + 1 <= state.totalItems
                                ? state.currentIndex + 1
                                : state.totalItems,
                            state.totalItems,
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Priority indicator (how many times missed)
                  _PriorityBadge(missCount: missCount),
                ],
              ),
            ),

            // ── Progress bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.error,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Question + options ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _QuestionCard(question: q, missCount: missCount),
                    const SizedBox(height: 20),
                    ...q.options.map(
                      (opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionButton(
                          text: opt,
                          isSelected: opt == selectedAnswer,
                          isCorrect: answerRevealed && opt == q.correctAnswer,
                          isWrong:
                              answerRevealed &&
                              opt == selectedAnswer &&
                              opt != q.correctAnswer,
                          onTap: () => onOptionTap(opt, item),
                        ),
                      ),
                    ),
                    if (answerRevealed) ...[
                      const SizedBox(height: 8),
                      ScaleTransition(
                        scale: feedbackScale,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            q.funFact,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Question card — same renderer as DailyChallengeScreen
// =============================================================================

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.missCount});

  final QuizQuestion question;
  final int missCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: missCount >= 3
              ? [const Color(0xFF5C1A1A), const Color(0xFF3B0A0A)]
              : [const Color(0xFF3B1A1A), const Color(0xFF2A0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (question.flagUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: question.flagUrl!.startsWith('assets/')
                  ? Image.asset(
                      question.flagUrl!,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) =>
                          const Text('🏳', style: TextStyle(fontSize: 60)),
                    )
                  : Image.network(
                      question.flagUrl!,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) =>
                          const Text('🏳', style: TextStyle(fontSize: 60)),
                    ),
            ),
            const SizedBox(height: 14),
          ] else if (question.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: question.imageUrl!.startsWith('assets/')
                  ? Image.asset(
                      question.imageUrl!,
                      width: 120,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) =>
                          const Text('🏷️', style: TextStyle(fontSize: 60)),
                    )
                  : Image.network(
                      question.imageUrl!,
                      width: 120,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) =>
                          const Text('🏷️', style: TextStyle(fontSize: 60)),
                    ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            question.question,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Option button
// =============================================================================

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  Color _bgColor() {
    if (isCorrect) return const Color(0xFF66BB6A).withAlpha(50);
    if (isWrong) return AppColors.error.withAlpha(40);
    if (isSelected) return AppColors.primary.withAlpha(40);
    return AppColors.surfaceContainerLow;
  }

  Color _borderColor() {
    if (isCorrect) return const Color(0xFF66BB6A);
    if (isWrong) return AppColors.error;
    if (isSelected) return AppColors.primary;
    return AppColors.divider;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor(), width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isCorrect)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF66BB6A),
                size: 22,
              )
            else if (isWrong)
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Priority badge
// =============================================================================

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.missCount});

  final int missCount;

  @override
  Widget build(BuildContext context) {
    final flames = missCount >= 4
        ? '🔥🔥🔥'
        : missCount == 3
        ? '🔥🔥'
        : missCount == 2
        ? '🔥'
        : '📝';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: missCount >= 2
            ? AppColors.error.withAlpha(30)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: missCount >= 2
              ? AppColors.error.withAlpha(100)
              : AppColors.divider,
        ),
      ),
      child: Text(flames, style: const TextStyle(fontSize: 16)),
    );
  }
}

// =============================================================================
// Result screen
// =============================================================================

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.state, required this.l10n});

  final ReviewSessionState state;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final pct = state.totalItems == 0
        ? 0.0
        : state.correctCount / state.totalItems;
    final emoji = pct >= 0.8
        ? '🏆'
        : pct >= 0.5
        ? '⭐'
        : '💪';

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                l10n.reviewModeComplete,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B1A1A), Color(0xFF2A0D0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.reviewModeScore(
                        state.correctCount,
                        state.totalItems,
                      ),
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (state.masteredCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.reviewModeMastered(state.masteredCount),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF66BB6A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.error.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    l10n.reviewModeGoHome,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                    ),
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

// =============================================================================
// Empty + Error bodies
// =============================================================================

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n});
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              l10n.reviewModeEmpty,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.background,
              ),
              child: Text(l10n.reviewModeGoHome),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
      ),
    );
  }
}
