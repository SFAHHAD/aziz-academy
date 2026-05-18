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
import 'package:aziz_academy/features/boss/providers/boss_provider.dart';

class BossScreen extends ConsumerStatefulWidget {
  const BossScreen({super.key});

  @override
  ConsumerState<BossScreen> createState() => _BossScreenState();
}

class _BossScreenState extends ConsumerState<BossScreen> {
  Timer? _advanceTimer;
  bool _starting = false;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    setState(() => _starting = true);
    await ref.read(bossProvider.notifier).start();
    if (mounted) setState(() => _starting = false);
  }

  void _onAnswer(String answer) {
    final correct = ref.read(bossProvider.notifier).submitAnswer(answer);
    final tts = ref.read(ttsServiceProvider);
    final audio = ref.read(audioServiceProvider);
    if (correct) {
      HapticFeedback.lightImpact();
      audio.playCorrectSound();
      unawaited(tts.speakAnswerFeedback('', correct: true));
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) ref.read(bossProvider.notifier).next();
      });
    } else {
      HapticFeedback.heavyImpact();
      audio.playWrongSound();
      // Boss kills you — no reward.
    }
  }

  void _claimVictory() {
    final score = ref.read(bossProvider).score;
    // Triple payout: 15 coins per correct answer (vs survival's 3x of 1 each).
    ref.read(coinProvider.notifier).award(score * 15);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bossProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (state.status) {
          BossStatus.ready => _ReadyView(
            onStart: _starting ? null : _start,
            onBack: () => context.go(AppRoutes.home),
            l10nTitle: l10n.bossTitle,
            l10nIntro: l10n.bossIntro,
            l10nStart: l10n.bossStart,
            starting: _starting,
          ),
          BossStatus.inProgress => _PlayingView(
            state: state,
            onAnswer: _onAnswer,
            onQuit: () {
              _advanceTimer?.cancel();
              ref.read(bossProvider.notifier).resetToReady();
              if (mounted) context.go(AppRoutes.home);
            },
          ),
          BossStatus.win => _WinView(
            state: state,
            onClaim: _claimVictory,
            onPlayAgain: () {
              ref.read(bossProvider.notifier).resetToReady();
              _start();
            },
            onBack: () {
              ref.read(bossProvider.notifier).resetToReady();
              context.go(AppRoutes.home);
            },
            l10nWin: l10n.bossWin,
            l10nReward: l10n.survivalReward,
            l10nPlayAgain: l10n.playAgain,
            l10nHome: l10n.homeButton,
          ),
          BossStatus.loss => _LossView(
            state: state,
            onPlayAgain: () {
              ref.read(bossProvider.notifier).resetToReady();
              _start();
            },
            onBack: () {
              ref.read(bossProvider.notifier).resetToReady();
              context.go(AppRoutes.home);
            },
            l10nLoss: l10n.bossLoss,
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
    required this.onStart,
    required this.onBack,
    required this.l10nTitle,
    required this.l10nIntro,
    required this.l10nStart,
    required this.starting,
  });

  final VoidCallback? onStart;
  final VoidCallback onBack;
  final String l10nTitle;
  final String l10nIntro;
  final String l10nStart;
  final bool starting;

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
          const Text('👹', style: TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            l10nTitle,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10nIntro,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.local_fire_department_rounded),
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
  });

  final BossState state;
  final ValueChanged<String> onAnswer;
  final VoidCallback onQuit;

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
                  child: Text(
                    '${localizeDigitsCtx(state.currentIndex + 1, context)}/'
                    '${localizeDigitsCtx(state.totalQuestions, context)}',
                    style: AppTextStyles.labelMedium,
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
                  border: Border.all(
                    color: AppColors.error.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      q.category,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.error,
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

class _WinView extends ConsumerStatefulWidget {
  const _WinView({
    required this.state,
    required this.onClaim,
    required this.onPlayAgain,
    required this.onBack,
    required this.l10nWin,
    required this.l10nReward,
    required this.l10nPlayAgain,
    required this.l10nHome,
  });

  final BossState state;
  final VoidCallback onClaim;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final String l10nWin;
  final String l10nReward;
  final String l10nPlayAgain;
  final String l10nHome;

  @override
  ConsumerState<_WinView> createState() => _WinViewState();
}

class _WinViewState extends ConsumerState<_WinView> {
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_claimed && mounted) {
        widget.onClaim();
        _claimed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final coinReward = widget.state.score * 15;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          const Text('🏆', style: TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            widget.l10nWin,
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
            child: Text(
              '🪙 ${localizeDigitsCtx(coinReward, context)} ${widget.l10nReward}',
              style: AppTextStyles.headingMedium,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onPlayAgain,
              icon: const Icon(Icons.replay_rounded),
              label: Text(widget.l10nPlayAgain),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: widget.onBack,
              child: Text(widget.l10nHome),
            ),
          ),
        ],
      ),
    );
  }
}

class _LossView extends StatelessWidget {
  const _LossView({
    required this.state,
    required this.onPlayAgain,
    required this.onBack,
    required this.l10nLoss,
    required this.l10nPlayAgain,
    required this.l10nHome,
  });

  final BossState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final String l10nLoss;
  final String l10nPlayAgain;
  final String l10nHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          const Text('💀', style: TextStyle(fontSize: 96)),
          const SizedBox(height: 16),
          Text(
            l10nLoss,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
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
