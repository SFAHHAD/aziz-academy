import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/victory_overlay.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/game_over_overlay.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';

import 'package:aziz_academy/l10n/app_localizations.dart';

// =============================================================================
// Screen entry-point
// =============================================================================

class SciencesQuizScreen extends ConsumerStatefulWidget {
  const SciencesQuizScreen({super.key});

  @override
  ConsumerState<SciencesQuizScreen> createState() =>
      _SciencesQuizScreenState();
}

class _SciencesQuizScreenState extends ConsumerState<SciencesQuizScreen>
    with TickerProviderStateMixin {
  /// The option the child just tapped (null = no answer yet this round).
  String? _selectedOption;
  bool get _isRevealed => _selectedOption != null;

  /// Controls the slide-up / fade-in of the fun-fact + Next button.
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealFade;
  late final Animation<Offset> _revealSlide;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _revealFade = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  void _onAnswerTapped(String option) {
    final session = ref.read(sciencesQuizProvider).value;
    if (session != null && session.currentQuestion != null) {
      if (option == session.currentQuestion!.correctAnswer) {
        ref.read(audioServiceProvider).playCorrectSound();
      } else {
        ref.read(audioServiceProvider).playWrongSound();
      }

      // Pronounce the correct answer aloud using dynamic TTS Engine
      ref.read(ttsServiceProvider).speakArabic(session.currentQuestion!.correctAnswer);
    }

    ref.read(sciencesQuizProvider.notifier).submitAnswer(option);
    setState(() => _selectedOption = option);
    _revealCtrl.forward();
  }

  void _onNext() {
    _revealCtrl.reset();
    setState(() => _selectedOption = null);
    ref.read(sciencesQuizProvider.notifier).nextQuestion();
  }

  void _onRestart() {
    _revealCtrl.reset();
    setState(() => _selectedOption = null);
    ref.read(sciencesQuizProvider.notifier).restart();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sciencesQuizProvider);

    ref.listen<AsyncValue<QuizSessionState>>(
      sciencesQuizProvider,
      (prev, next) {
        if (next.value?.isComplete == true &&
            prev?.value?.isComplete != true) {
          final session = next.value!;
          ref.read(achievementProvider.notifier).recordSciencesSession(
            score: session.score,
            livesRemaining: session.livesRemaining,
          );
          ref.read(audioServiceProvider).playVictorySound();
        } else if (next.value?.isGameOver == true &&
                   prev?.value?.isGameOver != true) {
          ref.read(audioServiceProvider).playWrongSound();
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const _LoadingView(),
          error: (e, st) => _ErrorView(onRetry: _onRestart),
          data: (session) {
            // Always render the quiz body; overlays appear on top as a Stack.
            final quizBody = session.currentQuestion != null
                ? _QuizBody(
                    session: session,
                    selectedOption: _selectedOption,
                    isRevealed: _isRevealed,
                    revealFade: _revealFade,
                    revealSlide: _revealSlide,
                    onAnswerTapped: _onAnswerTapped,
                    onNext: _onNext,
                    onBack: () => context.go(AppRoutes.home),
                  )
                : const ColoredBox(
                    color: AppColors.background,
                    child: SizedBox.expand(),
                  );

            if (!session.isComplete && !session.isGameOver) {
              return quizBody;
            }

            // Show quiz body underneath + overlay on top
            return Stack(
              fit: StackFit.expand,
              children: [
                quizBody,
                if (session.isComplete)
                  VictoryOverlay(
                    key: const ValueKey('victory'),
                    session: session,
                    onPlayAgain: _onRestart,
                    onBack: () => context.go(AppRoutes.home),
                  ),
                if (session.isGameOver)
                  GameOverOverlay(
                    key: const ValueKey('gameover'),
                    session: session,
                    onTryAgain: _onRestart,
                    onBack: () => context.go(AppRoutes.home),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Main quiz layout
// =============================================================================

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.session,
    required this.selectedOption,
    required this.isRevealed,
    required this.revealFade,
    required this.revealSlide,
    required this.onAnswerTapped,
    required this.onNext,
    required this.onBack,
  });

  final QuizSessionState session;
  final String? selectedOption;
  final bool isRevealed;
  final Animation<double> revealFade;
  final Animation<Offset> revealSlide;
  final void Function(String) onAnswerTapped;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion!;
    final size = MediaQuery.sizeOf(context);
    final shortViewport = size.height < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuizHeader(session: session, onBack: onBack),

        Expanded(
          child: SingleChildScrollView(
            clipBehavior: Clip.hardEdge,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuestionDisplay(
                    question: question,
                    compact: shortViewport,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _AnswerGrid(
                      question: question,
                      selectedOption: selectedOption,
                      isRevealed: isRevealed,
                      onTap: onAnswerTapped,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isRevealed
              ? SlideTransition(
                  position: revealSlide,
                  child: FadeTransition(
                    opacity: revealFade,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FunFactBanner(funFact: question.funFact),
                          const SizedBox(height: 10),
                          _NextButton(onNext: onNext),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// =============================================================================
// Header: score + hearts + progress bar
// =============================================================================

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({required this.session, required this.onBack});

  final QuizSessionState session;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // In RTL (Arabic) the Row auto-flips: score ends up on the right (start),
    // hearts on the left (end) â€” exactly what the user expects for Arabic.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      color: AppColors.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                // Back button â€” arrow direction follows text direction
                Semantics(
                  label: 'Go back to home',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      isRtl
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.arrow_back_ios_new_rounded,
                    ),
                    color: AppColors.textDark,
                    iconSize: 24,
                    onPressed: onBack,
                  ),
                ),
                // Score badge (START side: left in LTR, right in RTL)
                _ScoreBadge(score: session.score, label: l10n.score),
                const Spacer(),
                // Heart bar (END side: right in LTR, left in RTL)
                _HeartBar(
                  livesRemaining: session.livesRemaining,
                  label: l10n.hearts,
                ),
              ],
            ),
          ),
          _ProgressBar(progress: session.progress),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.label});
  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $score',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartBar extends StatelessWidget {
  const _HeartBar({required this.livesRemaining, required this.label});
  final int livesRemaining;
  final String label;
  static const _maxLives = 3;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $livesRemaining',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_maxLives, (i) {
          final filled = i < livesRemaining;
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(filled),
                color: filled ? AppColors.error : AppColors.disabled,
                size: 28,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quiz progress: ${(progress * 100).toInt()}%',
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        tween: Tween(begin: 0, end: progress),
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 6,
          backgroundColor: AppColors.divider,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

// =============================================================================
// Question display
// =============================================================================

class _QuestionDisplay extends StatelessWidget {
  const _QuestionDisplay({
    required this.question,
    this.compact = false,
  });
  final QuizQuestion question;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 4 : 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (question.flagUrl != null)
            _FlagImage(flagUrl: question.flagUrl!, compact: compact)
          else
            Text(
              question.question.split(' ').last,
              style: TextStyle(fontSize: compact ? 48 : 64),
            ),
          SizedBox(height: compact ? 10 : 16),
          Semantics(
            header: true,
            child: Text(
              question.question,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: compact ? 20 : 22,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Answer grid â€” responsive 2-column layout
// =============================================================================

class _AnswerGrid extends StatelessWidget {
  const _AnswerGrid({
    required this.question,
    required this.selectedOption,
    required this.isRevealed,
    required this.onTap,
  });

  final QuizQuestion question;
  final String? selectedOption;
  final bool isRevealed;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final options = question.options;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final ratio = w > 520 ? 3.4 : (w > 380 ? 2.9 : 2.55);
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: ratio,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: options.map((option) {
            return _AnswerCard(
              option: option,
              correctAnswer: question.correctAnswer,
              selectedOption: selectedOption,
              isRevealed: isRevealed,
              onTap: () => onTap(option),
            );
          }).toList(),
        );
      },
    );
  }
}

// =============================================================================
// Answer card â€” individual option with shake / bounce animations
// =============================================================================

class _AnswerCard extends StatefulWidget {
  const _AnswerCard({
    required this.option,
    required this.correctAnswer,
    required this.selectedOption,
    required this.isRevealed,
    required this.onTap,
  });

  final String option;
  final String correctAnswer;
  final String? selectedOption;
  final bool isRevealed;
  final VoidCallback onTap;

  bool get isSelected => option == selectedOption;
  bool get isCorrect => option == correctAnswer;

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Animation<double> _shake = const AlwaysStoppedAnimation(0.0);
  Animation<double> _scale = const AlwaysStoppedAnimation(1.0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(_AnswerCard old) {
    super.didUpdateWidget(old);
    // Fire animation the moment the answer is revealed for THIS card
    if (!old.isRevealed && widget.isRevealed && widget.isSelected) {
      _ctrl.reset();
      if (widget.isCorrect) {
        _scale = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.96), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 1),
        ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
        _shake = const AlwaysStoppedAnimation(0.0);
      } else {
        _shake = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
        ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
        _scale = const AlwaysStoppedAnimation(1.0);
      }
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ---- Visual state helpers -----------------------------------------------

  Color get _bgColor {
    if (!widget.isRevealed) return AppColors.surfaceContainerHigh;
    if (widget.isCorrect) return AppColors.success.withAlpha(40);
    if (widget.isSelected) return AppColors.error.withAlpha(40);
    return AppColors.surfaceContainerLow;
  }

  Color get _borderColor {
    if (!widget.isRevealed) return AppColors.primary.withAlpha(100);
    if (widget.isCorrect) return AppColors.success;
    if (widget.isSelected) return AppColors.error;
    return AppColors.divider;
  }

  Color get _textColor {
    if (!widget.isRevealed) return AppColors.textDark;
    if (widget.isCorrect) return AppColors.success;
    if (widget.isSelected) return AppColors.error;
    return AppColors.textMedium;
  }

  IconData? get _trailingIcon {
    if (!widget.isRevealed || (!widget.isCorrect && !widget.isSelected)) {
      return null;
    }
    return widget.isCorrect
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shake.value, 0),
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: widget.option,
        button: true,
        selected: widget.isSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: _borderColor.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isRevealed ? null : widget.onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: AppColors.primary.withAlpha(30),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.option,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_trailingIcon != null) ...[
                      const SizedBox(width: 6),
                      Icon(_trailingIcon, color: Colors.white, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Fun fact banner
// =============================================================================

class _FunFactBanner extends StatelessWidget {
  const _FunFactBanner({required this.funFact});
  final String funFact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withAlpha(120)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                funFact,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  height: 1.4,
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
// Next button
// =============================================================================

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        label: 'السؤال التالي',
        button: true,
        child: ElevatedButton.icon(
          onPressed: onNext,
          icon: const Text('🚀', style: TextStyle(fontSize: 20)),
          label: const Text('السؤال التالي'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            textStyle: AppTextStyles.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}



// =============================================================================
// Loading / Error views
// =============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text('جارٍ تحميل الاختبار…', style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'عذراً! تعذّر تحميل الاختبار.',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('حاول مجدداً'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Flag image widget â€” loads from flagcdn.com with shimmer + error fallback
// =============================================================================

class _FlagImage extends StatelessWidget {
  const _FlagImage({required this.flagUrl, this.compact = false});
  final String flagUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 88 : 120,
      constraints: BoxConstraints(maxWidth: compact ? 180 : 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          flagUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _ShimmerPlaceholder();
          },
          errorBuilder: (context, error, stack) {
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.flag_rounded, size: 60, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade100,
              Colors.grey.shade300,
            ],
            stops: [0, _animation.value, 1],
          ),
        ),
      ),
    );
  }
}

