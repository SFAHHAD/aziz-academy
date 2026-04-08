import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/widgets/network_image_retry.dart';
import 'package:aziz_academy/core/widgets/quiz_fun_fact_bar.dart';
import 'package:aziz_academy/core/widgets/quiz_narrow_content.dart';
import 'package:aziz_academy/features/flags/providers/flags_quiz_provider.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/victory_overlay.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/game_over_overlay.dart';

class FlagsQuizScreen extends ConsumerStatefulWidget {
  const FlagsQuizScreen({super.key});

  @override
  ConsumerState<FlagsQuizScreen> createState() => _FlagsQuizScreenState();
}

class _FlagsQuizScreenState extends ConsumerState<FlagsQuizScreen>
    with TickerProviderStateMixin {
  String? _selectedOption;
  bool get _isRevealed => _selectedOption != null;
  bool _coPlayChoicesVisible = false;

  late final AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  void _onAnswerTapped(String option) {
    final session = ref.read(flagsQuizProvider).value;
    final q = session?.currentQuestion;
    if (session != null && session.currentQuestion != null) {
      if (option == session.currentQuestion!.correctAnswer) {
        ref.read(audioServiceProvider).playCorrectSound();
      } else {
        ref.read(audioServiceProvider).playWrongSound();
      }

      ref.read(ttsServiceProvider).speakArabic(session.currentQuestion!.correctAnswer);
    }

    ref.read(flagsQuizProvider.notifier).submitAnswer(option);
    if (q != null && option.trim() != q.correctAnswer.trim()) {
      unawaited(
        ref.read(recapQueueProvider.notifier).recordWrong(
              RecapModule.flags,
              q.id,
            ),
      );
    }
    setState(() => _selectedOption = option);
    _revealCtrl.forward();
  }

  void _onNext() {
    _revealCtrl.reset();
    final co = ref.read(appSettingsProvider).value?.coPlayMode ?? false;
    setState(() {
      _selectedOption = null;
      if (co) _coPlayChoicesVisible = false;
    });
    ref.read(flagsQuizProvider.notifier).nextQuestion();
  }

  void _onRestart() {
    _revealCtrl.reset();
    final co = ref.read(appSettingsProvider).value?.coPlayMode ?? false;
    setState(() {
      _selectedOption = null;
      _coPlayChoicesVisible = !co;
    });
    ref.read(flagsQuizProvider.notifier).restart();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(flagsQuizProvider);

    ref.listen<AsyncValue<QuizSessionState>>(
      flagsQuizProvider,
      (prev, next) {
        if (next.value?.isComplete == true && prev?.value?.isComplete != true) {
          ref.read(audioServiceProvider).playVictorySound();
        } else if (next.value?.isGameOver == true && prev?.value?.isGameOver != true) {
          ref.read(audioServiceProvider).playWrongSound();
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: sessionAsync.when(
          data: (session) {
            final reducedMotion =
                ref.watch(appSettingsProvider).value?.reducedMotion ?? false;

            if (session.isComplete) {
              return VictoryOverlay(
                session: session,
                title: 'بطل الأعلام!',
                shareModuleLabel: 'جولة الأعلام — أكاديمية عزيز',
                reducedMotion: reducedMotion,
                onPlayAgain: _onRestart,
                onBack: () => context.go(AppRoutes.home),
              );
            }
            if (session.isGameOver) {
              return GameOverOverlay(
                session: session,
                learningTip: session.currentQuestion?.funFact,
                onTryAgain: _onRestart,
                onBack: () => context.go(AppRoutes.home),
              );
            }

            final question = session.currentQuestion;
            if (question == null) return const SizedBox.shrink();

            final coPlay = ref.watch(appSettingsProvider).maybeWhen(
                  data: (s) => s.coPlayMode,
                  orElse: () => false,
                );
            final showChoices = !coPlay || _coPlayChoicesVisible;

            return QuizNarrowContent(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMedium),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                    ),
                  ),
                ),
                _Header(
                  score: session.score,
                  lives: session.livesRemaining,
                  currentIndex: session.currentIndex,
                  total: session.totalQuestions,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _HDFlagRenderer(flagUrl: question.flagUrl!),
                              ),
                            ),
                          ),
                        ),
                        if (coPlay && !showChoices) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  setState(() => _coPlayChoicesVisible = true),
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('اعرض خيارات الإجابة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.surface,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (showChoices)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: question.options.map((opt) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _OptionButton(
                                    text: opt,
                                    isRevealed: _isRevealed,
                                    isSelected: _selectedOption == opt,
                                    isCorrectOption:
                                        opt == question.correctAnswer,
                                    onTap: () {
                                      if (!_isRevealed) _onAnswerTapped(opt);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isRevealed
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Column(
                            children: [
                              QuizFunFactBar(
                                funFact: question.funFact,
                                wasWrong:
                                    _selectedOption != question.correctAnswer,
                                correctAnswer: question.correctAnswer,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'التالي',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.lives,
    required this.currentIndex,
    required this.total,
  });

  final int score;
  final int lives;
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Icon(
                i < lives ? Icons.favorite : Icons.favorite_border,
                color: AppColors.error,
                size: 24,
              ),
            ),
          ),
          Text(
            '${currentIndex + 1} / $total',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '⭐ $score',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.isRevealed,
    required this.isSelected,
    required this.isCorrectOption,
    required this.onTap,
  });

  final String text;
  final bool isRevealed;
  final bool isSelected;
  final bool isCorrectOption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textDark;
    Color borderColor = AppColors.textMedium.withAlpha(50);

    if (isRevealed) {
      if (isCorrectOption) {
        bgColor = AppColors.success;
        textColor = AppColors.surface;
        borderColor = AppColors.success;
      } else if (isSelected) {
        bgColor = AppColors.error;
        textColor = AppColors.surface;
        borderColor = AppColors.error;
      } else {
        bgColor = AppColors.surface.withAlpha(150);
        textColor = AppColors.textMedium;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (!isRevealed)
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HDFlagRenderer extends StatelessWidget {
  const _HDFlagRenderer({required this.flagUrl});
  final String flagUrl;

  @override
  Widget build(BuildContext context) {
    if (flagUrl.startsWith('assets/')) {
      return Image.asset(
        flagUrl,
        height: 200,
        fit: BoxFit.contain, // Allow intrinsic width scaling
        errorBuilder: (context, error, stack) => const SizedBox(
          width: 300, // Fixed width for error state
          height: 200,
          child: Center(
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        ),
      );
    }

    return NetworkImageRetry(
      url: flagUrl,
      height: 200,
      width: 300,
      fit: BoxFit.contain,
    );
  }
}
