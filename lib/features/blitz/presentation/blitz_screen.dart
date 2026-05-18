import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/lifeline_bar.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/blitz/providers/blitz_provider.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/general_quiz/providers/general_quiz_provider.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';

class BlitzScreen extends ConsumerStatefulWidget {
  const BlitzScreen({super.key});

  @override
  ConsumerState<BlitzScreen> createState() => _BlitzScreenState();
}

class _BlitzScreenState extends ConsumerState<BlitzScreen> {
  Timer? _ticker;
  Timer? _advanceTimer;

  // Lifeline state — reset every question.
  bool _usedFiftyFifty = false;
  bool _usedSkip = false;
  bool _usedHint = false;
  List<String> _hiddenOptions = const [];
  String? _hintText;
  int _lastQuestionIndex = -1;

  void _resetLifelinesFor(int idx) {
    if (_lastQuestionIndex == idx) return;
    _lastQuestionIndex = idx;
    _usedFiftyFifty = false;
    _usedSkip = false;
    _usedHint = false;
    _hiddenOptions = const [];
    _hintText = null;
  }

  void _onFiftyFifty(List<String> hidden) {
    setState(() {
      _hiddenOptions = hidden;
      _usedFiftyFifty = true;
    });
  }

  void _onSkip() {
    // Blitz skip: advance to next question without scoring penalty.
    setState(() => _usedSkip = true);
    _advanceTimer?.cancel();
    ref.read(blitzProvider.notifier).next();
  }

  void _onHint(String text) {
    setState(() {
      _hintText = text;
      _usedHint = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Force the question pools to load once.
    ref.read(capitalsQuestionsProvider);
    ref.read(sciencesQuestionsProvider);
    ref.read(iqQuestionsProvider);
    ref.read(generalQuizQuestionsProvider);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _startBlitz() {
    ref.read(blitzProvider.notifier).start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(blitzProvider.notifier).tick();
      final s = ref.read(blitzProvider);
      if (s.isComplete) {
        _ticker?.cancel();
        ref.read(blitzHighScoreProvider.notifier).recordScore(s.score);
        HapticFeedback.heavyImpact();
        ref.read(audioServiceProvider).playVictorySound();
      }
    });
  }

  void _onAnswer(String answer) {
    final correct = ref.read(blitzProvider.notifier).submitAnswer(answer);
    final tts = ref.read(ttsServiceProvider);
    final audio = ref.read(audioServiceProvider);
    if (correct) {
      HapticFeedback.lightImpact();
      audio.playCorrectSound();
      unawaited(tts.speakAnswerFeedback('', correct: true));
    } else {
      HapticFeedback.mediumImpact();
      audio.playWrongSound();
    }
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) ref.read(blitzProvider.notifier).next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blitzProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final highScoreAsync = ref.watch(blitzHighScoreProvider);

    // Reset lifelines whenever the question index advances.
    if (state.status == BlitzStatus.inProgress) {
      _resetLifelinesFor(state.currentIndex);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (state.status) {
          BlitzStatus.ready => _ReadyView(
            isArabic: isArabic,
            highScore: highScoreAsync.value ?? 0,
            onStart: _startBlitz,
            onBack: () => context.go(AppRoutes.home),
          ),
          BlitzStatus.inProgress => _PlayingView(
            state: state,
            isArabic: isArabic,
            onAnswer: _onAnswer,
            onQuit: () {
              _ticker?.cancel();
              _advanceTimer?.cancel();
              ref.read(blitzProvider.notifier).resetToReady();
              if (mounted) context.go(AppRoutes.home);
            },
            usedFiftyFifty: _usedFiftyFifty,
            usedSkip: _usedSkip,
            usedHint: _usedHint,
            hiddenOptions: _hiddenOptions,
            hintText: _hintText,
            onFiftyFifty: _onFiftyFifty,
            onSkip: _onSkip,
            onHint: _onHint,
          ),
          BlitzStatus.complete => _ResultView(
            state: state,
            isArabic: isArabic,
            highScore: highScoreAsync.value ?? 0,
            onPlayAgain: () {
              _ticker?.cancel();
              _advanceTimer?.cancel();
              _startBlitz();
            },
            onBack: () {
              _ticker?.cancel();
              _advanceTimer?.cancel();
              ref.read(blitzProvider.notifier).resetToReady();
              context.go(AppRoutes.home);
            },
          ),
        },
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.isArabic,
    required this.highScore,
    required this.onStart,
    required this.onBack,
  });

  final bool isArabic;
  final int highScore;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              tooltip: context.l10n.commonBack,
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Spacer(),
          const Text('⚡', style: TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            context.l10n.blitzTitle,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.blitzDescription,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (highScore > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.blitzBest(highScore),
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.bolt_rounded),
              label: Text(context.l10n.blitzStartButton),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PlayingView extends StatelessWidget {
  const _PlayingView({
    required this.state,
    required this.isArabic,
    required this.onAnswer,
    required this.onQuit,
    required this.usedFiftyFifty,
    required this.usedSkip,
    required this.usedHint,
    required this.hiddenOptions,
    required this.hintText,
    required this.onFiftyFifty,
    required this.onSkip,
    required this.onHint,
  });

  final BlitzState state;
  final bool isArabic;
  final ValueChanged<String> onAnswer;
  final VoidCallback onQuit;
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
    final q = state.currentQuestion;
    if (q == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CenteredBody(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onQuit,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textDark,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: LinearProgressIndicator(
                      value: state.secondsLeft / 60,
                      minHeight: 12,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation(
                        state.secondsLeft <= 10
                            ? AppColors.error
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${localizeDigits(state.secondsLeft, arabic: isArabic)}s',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Pill(
                  label: context.l10n.blitzScoreLabel,
                  value: localizeDigits(state.score, arabic: isArabic),
                ),
                _Pill(
                  label: context.l10n.blitzStreakLabel,
                  value: localizeDigits(state.streak, arabic: isArabic),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LifelineBar(
              options: q.options,
              correctAnswer: q.correctAnswer,
              locked: state.lastAnswerCorrect != null,
              usedFiftyFifty: usedFiftyFifty,
              usedSkip: usedSkip,
              usedHint: usedHint,
              onFiftyFifty: onFiftyFifty,
              onSkip: onSkip,
              onHint: onHint,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      q.category,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(q.question, style: AppTextStyles.headingMedium),
                    if (hintText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💡 $hintText',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ...q.options.map((opt) {
                      final hidden = hiddenOptions.contains(opt);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Opacity(
                          opacity: hidden ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: hidden,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.surfaceContainerHigh,
                                  foregroundColor: AppColors.textDark,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  alignment: AlignmentDirectional.centerStart,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: state.lastAnswerCorrect == null
                                    ? () => onAnswer(opt)
                                    : null,
                                child: Text(
                                  opt,
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          const SizedBox(width: 8),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.state,
    required this.isArabic,
    required this.highScore,
    required this.onPlayAgain,
    required this.onBack,
  });

  final BlitzState state;
  final bool isArabic;
  final int highScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isNewBest = state.score >= highScore && state.score > 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(isNewBest ? '🏆' : '⚡', style: const TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            isNewBest ? context.l10n.blitzNewBest : context.l10n.blitzTimesUp,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  context.l10n.blitzScoreLabel,
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  localizeDigits(state.score, arabic: isArabic),
                  style: AppTextStyles.displayLargeGold,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.blitzBestStreak(state.bestStreak),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.replay_rounded),
              label: Text(context.l10n.blitzPlayAgain),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onBack,
              child: Text(context.l10n.blitzHome),
            ),
          ),
        ],
      ),
    );
  }
}
