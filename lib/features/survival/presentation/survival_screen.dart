import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/general_quiz/providers/general_quiz_provider.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/features/survival/providers/survival_provider.dart';

class SurvivalScreen extends ConsumerStatefulWidget {
  const SurvivalScreen({super.key});

  @override
  ConsumerState<SurvivalScreen> createState() => _SurvivalScreenState();
}

class _SurvivalScreenState extends ConsumerState<SurvivalScreen> {
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    ref.read(capitalsQuestionsProvider);
    ref.read(sciencesQuestionsProvider);
    ref.read(iqQuestionsProvider);
    ref.read(generalQuizQuestionsProvider);
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _startSurvival() {
    HapticFeedback.lightImpact();
    ref.read(survivalProvider.notifier).start();
  }

  void _onAnswer(String answer) {
    final correct = ref.read(survivalProvider.notifier).submitAnswer(answer);
    final tts = ref.read(ttsServiceProvider);
    final audio = ref.read(audioServiceProvider);
    if (correct) {
      HapticFeedback.lightImpact();
      audio.playCorrectSound();
      unawaited(tts.speakAnswerFeedback('', correct: true));
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) ref.read(survivalProvider.notifier).next();
      });
    } else {
      HapticFeedback.heavyImpact();
      audio.playWrongSound();
      // Game over — record + reward in 3x coin payout (one per score).
      final score = ref.read(survivalProvider).score;
      ref.read(survivalHighScoreProvider.notifier).recordScore(score);
      ref.read(coinProvider.notifier).award(score * 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(survivalProvider);
    final highScoreAsync = ref.watch(survivalHighScoreProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (state.status) {
          SurvivalStatus.ready => _ReadyView(
            highScore: highScoreAsync.value ?? 0,
            onStart: _startSurvival,
            onBack: () => context.go(AppRoutes.home),
            l10nTitle: l10n.survivalTitle,
            l10nBody: l10n.survivalIntro,
            l10nBest: l10n.survivalBest,
            l10nStart: l10n.survivalStart,
          ),
          SurvivalStatus.inProgress => _PlayingView(
            state: state,
            onAnswer: _onAnswer,
            onQuit: () {
              _advanceTimer?.cancel();
              ref.read(survivalProvider.notifier).resetToReady();
              if (mounted) context.go(AppRoutes.home);
            },
            l10nScore: l10n.score,
          ),
          SurvivalStatus.gameOver => _ResultView(
            state: state,
            highScore: highScoreAsync.value ?? 0,
            onPlayAgain: _startSurvival,
            onBack: () {
              ref.read(survivalProvider.notifier).resetToReady();
              context.go(AppRoutes.home);
            },
            l10nNewBest: l10n.survivalNewBest,
            l10nGameOver: l10n.survivalGameOver,
            l10nFinalScore: l10n.score,
            l10nReward: l10n.survivalReward,
            l10nPlayAgain: l10n.playAgain,
            l10nHome: l10n.homeButton,
          ),
        },
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.highScore,
    required this.onStart,
    required this.onBack,
    required this.l10nTitle,
    required this.l10nBody,
    required this.l10nBest,
    required this.l10nStart,
  });

  final int highScore;
  final VoidCallback onStart;
  final VoidCallback onBack;
  final String l10nTitle;
  final String l10nBody;
  final String l10nBest;
  final String l10nStart;

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
          const Text('🛡️', style: TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            l10nTitle,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10nBody,
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
                    '$l10nBest: ${localizeDigitsCtx(highScore, context)}',
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
              icon: const Icon(Icons.shield_rounded),
              label: Text(l10nStart),
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
    required this.onAnswer,
    required this.onQuit,
    required this.l10nScore,
  });

  final SurvivalState state;
  final ValueChanged<String> onAnswer;
  final VoidCallback onQuit;
  final String l10nScore;

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
                const Spacer(),
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 22,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$l10nScore: ', style: AppTextStyles.labelMedium),
                      Text(
                        localizeDigitsCtx(state.score, context),
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
                    ...q.options.map(
                      (opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerHigh,
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
                            child: Text(opt, style: AppTextStyles.bodyLarge),
                          ),
                        ),
                      ),
                    ),
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

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.state,
    required this.highScore,
    required this.onPlayAgain,
    required this.onBack,
    required this.l10nNewBest,
    required this.l10nGameOver,
    required this.l10nFinalScore,
    required this.l10nReward,
    required this.l10nPlayAgain,
    required this.l10nHome,
  });

  final SurvivalState state;
  final int highScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final String l10nNewBest;
  final String l10nGameOver;
  final String l10nFinalScore;
  final String l10nReward;
  final String l10nPlayAgain;
  final String l10nHome;

  @override
  Widget build(BuildContext context) {
    final isNewBest = state.score >= highScore && state.score > 0;
    final coinReward = state.score * 3;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(isNewBest ? '🏆' : '🛡️', style: const TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            isNewBest ? l10nNewBest : l10nGameOver,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
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
                Text(l10nFinalScore, style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(
                  localizeDigitsCtx(state.score, context),
                  style: AppTextStyles.displayLargeGold,
                ),
                const SizedBox(height: 12),
                Text(
                  '🪙 ${localizeDigitsCtx(coinReward, context)} $l10nReward',
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
              label: Text(l10nPlayAgain),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: onBack, child: Text(l10nHome)),
          ),
        ],
      ),
    );
  }
}
