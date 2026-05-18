import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/widgets/lifeline_bar.dart';
import 'package:aziz_academy/core/widgets/quiz_fun_fact_bar.dart';
import 'package:aziz_academy/core/widgets/quiz_narrow_content.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/victory_overlay.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/game_over_overlay.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/utils/digits.dart';

class IqQuizScreen extends ConsumerStatefulWidget {
  const IqQuizScreen({super.key});

  @override
  ConsumerState<IqQuizScreen> createState() => _IqQuizScreenState();
}

class _IqQuizScreenState extends ConsumerState<IqQuizScreen>
    with TickerProviderStateMixin {
  String? _selectedOption;
  bool get _isRevealed => _selectedOption != null;
  bool _coPlayChoicesVisible = false;

  // Lifeline state — reset every question.
  bool _usedFiftyFifty = false;
  bool _usedSkip = false;
  bool _usedHint = false;
  List<String> _hiddenOptions = const [];
  String? _hintText;

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
    final session = ref.read(iqQuizProvider).value;
    if (session != null && session.currentQuestion != null) {
      final isCorrect = option == session.currentQuestion!.correctAnswer;
      if (isCorrect) {
        HapticFeedback.lightImpact();
        ref.read(audioServiceProvider).playCorrectSound();
        // Comeback celebration: if this question was a spaced-repetition
        // repeat AND the kid got it right this time, show a quick "you got
        // it!" snack on top of the standard correct-feedback.
        final repeatIds = ref.read(iqSessionRepeatIdsProvider);
        final qid = session.currentQuestion?.id;
        if (qid != null && repeatIds.contains(qid)) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
              duration: const Duration(milliseconds: 2200),
              content: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.iqComebackSnack,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        HapticFeedback.mediumImpact();
        ref.read(audioServiceProvider).playWrongSound();
      }
      unawaited(
        ref
            .read(ttsServiceProvider)
            .speakAnswerFeedback(
              session.currentQuestion!.correctAnswer,
              correct: isCorrect,
            ),
      );
    }
    ref.read(iqQuizProvider.notifier).submitAnswer(option);
    setState(() => _selectedOption = option);
    _revealCtrl.forward();
  }

  void _onNext() {
    _revealCtrl.reset();
    final co = ref.read(appSettingsProvider).value?.coPlayMode ?? false;
    setState(() {
      _selectedOption = null;
      if (co) _coPlayChoicesVisible = false;
      _usedFiftyFifty = false;
      _usedSkip = false;
      _usedHint = false;
      _hiddenOptions = const [];
      _hintText = null;
    });
    ref.read(iqQuizProvider.notifier).nextQuestion();
  }

  void _onRestart() {
    _revealCtrl.reset();
    final co = ref.read(appSettingsProvider).value?.coPlayMode ?? false;
    setState(() {
      _selectedOption = null;
      _coPlayChoicesVisible = !co;
      _usedFiftyFifty = false;
      _usedSkip = false;
      _usedHint = false;
      _hiddenOptions = const [];
      _hintText = null;
    });
    ref.read(iqQuizProvider.notifier).restart();
  }

  void _onFiftyFifty(List<String> hidden) {
    setState(() {
      _hiddenOptions = hidden;
      _usedFiftyFifty = true;
    });
  }

  void _onSkip() {
    setState(() => _usedSkip = true);
    _onNext();
  }

  void _onHint(String text) {
    setState(() {
      _hintText = text;
      _usedHint = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(iqQuizProvider);
    final victoryTitle = context.l10n.iqVictoryTitle;
    final shareLabel = context.l10n.iqShareLabel;

    ref.listen<AsyncValue<QuizSessionState>>(iqQuizProvider, (prev, next) {
      if (next.value?.isComplete == true && prev?.value?.isComplete != true) {
        HapticFeedback.heavyImpact();
        ref.read(audioServiceProvider).playVictorySound();
      } else if (next.value?.isGameOver == true &&
          prev?.value?.isGameOver != true) {
        ref.read(audioServiceProvider).playWrongSound();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: sessionAsync.when(
            loading: () => const _LoadingView(),
            error: (e, st) => _ErrorView(onRetry: _onRestart),
            data: (session) {
              final coPlay = ref
                  .watch(appSettingsProvider)
                  .maybeWhen(data: (s) => s.coPlayMode, orElse: () => false);
              final showChoices = !coPlay || _coPlayChoicesVisible;
              final reducedMotion =
                  ref.watch(appSettingsProvider).value?.reducedMotion ?? false;

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
                      coPlayMode: coPlay,
                      showAnswerChoices: showChoices,
                      onRevealChoices: () =>
                          setState(() => _coPlayChoicesVisible = true),
                      usedFiftyFifty: _usedFiftyFifty,
                      usedSkip: _usedSkip,
                      usedHint: _usedHint,
                      hiddenOptions: _hiddenOptions,
                      hintText: _hintText,
                      onFiftyFifty: _onFiftyFifty,
                      onSkip: _onSkip,
                      onHint: _onHint,
                    )
                  : const ColoredBox(
                      color: AppColors.background,
                      child: SizedBox.expand(),
                    );

              if (!session.isComplete && !session.isGameOver) {
                return quizBody;
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  quizBody,
                  if (session.isComplete)
                    VictoryOverlay(
                      key: const ValueKey('iq-victory'),
                      session: session,
                      title: victoryTitle,
                      shareModuleLabel: shareLabel,
                      reducedMotion: reducedMotion,
                      coinsEarned:
                          session.score * 5 + session.livesRemaining * 10,
                      onPlayAgain: _onRestart,
                      onBack: () => context.go(AppRoutes.home),
                    ),
                  if (session.isGameOver)
                    GameOverOverlay(
                      key: const ValueKey('iq-gameover'),
                      session: session,
                      learningTip: session.currentQuestion?.funFact,
                      onTryAgain: _onRestart,
                      onBack: () => context.go(AppRoutes.home),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

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
    required this.coPlayMode,
    required this.showAnswerChoices,
    required this.onRevealChoices,
    required this.usedFiftyFifty,
    required this.usedSkip,
    required this.usedHint,
    required this.hiddenOptions,
    required this.hintText,
    required this.onFiftyFifty,
    required this.onSkip,
    required this.onHint,
  });

  final QuizSessionState session;
  final String? selectedOption;
  final bool isRevealed;
  final Animation<double> revealFade;
  final Animation<Offset> revealSlide;
  final void Function(String) onAnswerTapped;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool coPlayMode;
  final bool showAnswerChoices;
  final VoidCallback onRevealChoices;
  final bool usedFiftyFifty;
  final bool usedSkip;
  final bool usedHint;
  final List<String> hiddenOptions;
  final String? hintText;
  final void Function(List<String>) onFiftyFifty;
  final VoidCallback onSkip;
  final void Function(String) onHint;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion!;
    final size = MediaQuery.sizeOf(context);
    final shortViewport = size.height < 760;

    return QuizNarrowContent(
      child: Column(
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: LifelineBar(
                        options: question.options,
                        correctAnswer: question.correctAnswer,
                        locked: isRevealed,
                        usedFiftyFifty: usedFiftyFifty,
                        usedSkip: usedSkip,
                        usedHint: usedHint,
                        onFiftyFifty: onFiftyFifty,
                        onSkip: onSkip,
                        onHint: onHint,
                      ),
                    ),
                    _QuestionDisplay(
                      question: question,
                      compact: shortViewport,
                      hintText: hintText,
                    ),
                    const SizedBox(height: 12),
                    if (coPlayMode && !showAnswerChoices) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: onRevealChoices,
                          icon: const Icon(Icons.visibility_rounded),
                          label: Text(context.l10n.iqRevealChoices),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (showAnswerChoices)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _AnswerGrid(
                          question: question,
                          selectedOption: selectedOption,
                          isRevealed: isRevealed,
                          onTap: onAnswerTapped,
                          hiddenOptions: hiddenOptions,
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
                            QuizFunFactBar(
                              funFact: question.funFact,
                              wasWrong:
                                  selectedOption != question.correctAnswer,
                              correctAnswer: question.correctAnswer,
                            ),
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
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({required this.session, required this.onBack});

  final QuizSessionState session;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
                IconButton(
                  tooltip: context.l10n.commonBack,
                  icon: Icon(
                    isRtl
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                  ),
                  color: AppColors.textDark,
                  iconSize: 24,
                  onPressed: onBack,
                ),
                _ScoreBadge(
                  score: session.score,
                  label: context.l10n.iqScoreLabel,
                ),
                const Spacer(),
                _HeartBar(livesRemaining: session.livesRemaining),
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
    return Container(
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
            localizeDigitsCtx(score, context),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartBar extends StatelessWidget {
  const _HeartBar({required this.livesRemaining});
  final int livesRemaining;
  static const _maxLives = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_maxLives, (i) {
        final filled = i < livesRemaining;
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Icon(
            filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: filled ? AppColors.error : AppColors.disabled,
            size: 28,
          ),
        );
      }),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
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
    );
  }
}

class _QuestionDisplay extends ConsumerWidget {
  const _QuestionDisplay({
    required this.question,
    this.compact = false,
    this.hintText,
  });
  final QuizQuestion question;
  final bool compact;
  final String? hintText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 4 : 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧠', style: TextStyle(fontSize: compact ? 48 : 64)),
          SizedBox(height: compact ? 10 : 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: compact ? 20 : 22,
                    height: 1.4,
                  ),
                ),
              ),
              TtsSpeakerIcon(
                text: question.question,
                color: AppColors.primary,
                tooltip: context.l10n.ttsButtonTooltip,
              ),
            ],
          ),
          if (hintText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Text(
                '💡 $hintText',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerGrid extends StatelessWidget {
  const _AnswerGrid({
    required this.question,
    required this.selectedOption,
    required this.isRevealed,
    required this.onTap,
    this.hiddenOptions = const [],
  });

  final QuizQuestion question;
  final String? selectedOption;
  final bool isRevealed;
  final void Function(String) onTap;
  final List<String> hiddenOptions;

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
            final hidden = hiddenOptions.contains(option);
            return Opacity(
              opacity: hidden ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: hidden,
                child: _AnswerCard(
                  option: option,
                  correctAnswer: question.correctAnswer,
                  selectedOption: selectedOption,
                  isRevealed: isRevealed,
                  onTap: () => onTap(option),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AnswerCard extends StatelessWidget {
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

  Color get _bgColor {
    if (!isRevealed) return AppColors.surfaceContainerHigh;
    if (isCorrect) return AppColors.success.withAlpha(40);
    if (isSelected) return AppColors.error.withAlpha(40);
    return AppColors.surfaceContainerLow;
  }

  Color get _borderColor {
    if (!isRevealed) return AppColors.primary.withAlpha(100);
    if (isCorrect) return AppColors.success;
    if (isSelected) return AppColors.error;
    return AppColors.divider;
  }

  Color get _textColor {
    if (!isRevealed) return AppColors.textDark;
    if (isCorrect) return AppColors.success;
    if (isSelected) return AppColors.error;
    return AppColors.textMedium;
  }

  IconData? get _trailingIcon {
    if (!isRevealed || (!isCorrect && !isSelected)) return null;
    return isCorrect
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
          onTap: isRevealed ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
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
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: onNext,
        icon: const Text('🚀', style: TextStyle(fontSize: 20)),
        label: Text(context.l10n.iqNextQuestion),
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
    );
  }
}

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
          Text(context.l10n.iqLoading, style: AppTextStyles.bodyLarge),
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
              context.l10n.iqLoadFailed,
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retryAction),
            ),
          ],
        ),
      ),
    );
  }
}
