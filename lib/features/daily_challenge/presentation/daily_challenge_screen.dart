import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/daily_challenge_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

// =============================================================================
// Daily Challenge Screen
// =============================================================================

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedAnswer;
  bool _answerRevealed = false;
  int _xpAwarded = 0;

  late final AnimationController _feedbackCtrl;
  late final Animation<double> _feedbackScale;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _feedbackScale = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  void _onOptionTap(String choice, DailyChallengeState s) {
    if (_answerRevealed) return;
    setState(() {
      _selectedAnswer = choice;
      _answerRevealed = true;
    });
    _feedbackCtrl.forward(from: 0);
    ref.read(dailyChallengeProvider.notifier).answer(choice);

    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() async {
    if (!mounted) return;
    final s = ref.read(dailyChallengeProvider).value;
    if (s == null) return;

    setState(() {
      _selectedAnswer = null;
      _answerRevealed = false;
    });

    if (s.isComplete && !s.isCompleted) {
      final xp =
          await ref.read(dailyChallengeProvider.notifier).complete();
      if (mounted) setState(() => _xpAwarded = xp);
    }
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailyChallengeProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
        ),
        data: (s) {
          if (s.isComplete) {
            return _ResultScreen(
              state: s,
              xpAwarded: _xpAwarded > 0 ? _xpAwarded : s.xpEarned,
              l10n: l10n,
            );
          }
          return _QuizBody(
            state: s,
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
// Quiz body — question + options
// =============================================================================

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.state,
    required this.selectedAnswer,
    required this.answerRevealed,
    required this.feedbackScale,
    required this.onOptionTap,
    required this.l10n,
  });

  final DailyChallengeState state;
  final String? selectedAnswer;
  final bool answerRevealed;
  final Animation<double> feedbackScale;
  final void Function(String, DailyChallengeState) onOptionTap;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final q = state.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        children: [
          // ── Header bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Back arrow
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
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + question counter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dailyChallengeTitle,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        l10n.dailyChallengeQuestionOf(
                          state.currentIndex + 1 <= state.totalQuestions
                              ? state.currentIndex + 1
                              : state.totalQuestions,
                          state.totalQuestions,
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lives
                _LivesRow(lives: state.livesRemaining),
              ],
            ),
          ),

          // ── Progress bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Question card ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _QuestionCard(question: q),
                  const SizedBox(height: 20),
                  // ── Options ─────────────────────────────────────────
                  ...q.options.map((opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionButton(
                          text: opt,
                          isSelected: opt == selectedAnswer,
                          isCorrect: answerRevealed && opt == q.correctAnswer,
                          isWrong: answerRevealed &&
                              opt == selectedAnswer &&
                              opt != q.correctAnswer,
                          onTap: () => onOptionTap(opt, state),
                        ),
                      )),
                  if (answerRevealed) ...[
                    const SizedBox(height: 8),
                    ScaleTransition(
                      scale: feedbackScale,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.divider,
                          ),
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
    );
  }
}

// =============================================================================
// Question card — handles text, flag image, and logo image variants
// =============================================================================

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3C6E), Color(0xFF0F2445)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.secondary.withAlpha(60),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2× XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(120)),
            ),
            child: Text(
              '2× XP',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Image (flag or logo)
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
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF66BB6A), size: 22)
            else if (isWrong)
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Lives row
// =============================================================================

class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: i < lives ? AppColors.error : AppColors.divider,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Result screen — shown when the challenge is complete
// =============================================================================

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({
    required this.state,
    required this.xpAwarded,
    required this.l10n,
  });

  final DailyChallengeState state;
  final int xpAwarded;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final percent = state.totalQuestions == 0
        ? 0.0
        : state.score / state.totalQuestions;
    final emoji = percent >= 0.8
        ? '🏆'
        : percent >= 0.5
            ? '⭐'
            : '💪';

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big emoji
              Text(emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),

              Text(
                l10n.dailyChallengeGreatJob,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3C6E), Color(0xFF0F2445)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(80),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.dailyChallengeScore(
                          state.score, state.totalQuestions),
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // XP earned
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondary.withAlpha(140),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.dailyChallengeXpEarned(xpAwarded),
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '2×',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reset countdown
                    Consumer(
                      builder: (ctx, ref, _) {
                        final dur = DailyChallengeState.timeUntilReset();
                        final h = dur.inHours;
                        final m = dur.inMinutes % 60;
                        final timeStr = '${h}h ${m}m';
                        return Text(
                          l10n.dailyChallengeResetsIn(timeStr),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        );
                      },
                    ),
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
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.background,
                    elevation: 8,
                    shadowColor: AppColors.secondary.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    l10n.dailyChallengeGoHome,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.background,
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
