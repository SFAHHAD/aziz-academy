import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/features/math/providers/math_quiz_provider.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/victory_overlay.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/game_over_overlay.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';

class MathQuizScreen extends ConsumerStatefulWidget {
  const MathQuizScreen({super.key});

  @override
  ConsumerState<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends ConsumerState<MathQuizScreen>
    with TickerProviderStateMixin {
  String? _selectedOption;
  bool get _isRevealed => _selectedOption != null;

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
    final session = ref.read(mathQuizProvider).value;
    if (session != null && session.currentQuestion != null) {
      if (option == session.currentQuestion!.correctAnswer) {
        ref.read(audioServiceProvider).playCorrectSound();
      } else {
        ref.read(audioServiceProvider).playWrongSound();
      }

      // Pronounce the correct answer aloud using dynamic TTS Engine
      ref.read(ttsServiceProvider).speakArabic(session.currentQuestion!.correctAnswer);
    }

    ref.read(mathQuizProvider.notifier).submitAnswer(option);
    setState(() => _selectedOption = option);
    _revealCtrl.forward();
  }

  void _onNext() {
    _revealCtrl.reset();
    setState(() => _selectedOption = null);
    ref.read(mathQuizProvider.notifier).nextQuestion();
  }

  void _onRestart() {
    _revealCtrl.reset();
    setState(() => _selectedOption = null);
    ref.read(mathQuizProvider.notifier).restart();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(mathQuizProvider);

    ref.listen<AsyncValue<QuizSessionState>>(
      mathQuizProvider,
      (prev, next) {
        if (next.value?.isComplete == true && prev?.value?.isComplete != true) {
          final session = next.value!;
          ref.read(achievementProvider.notifier).recordMathSession(
            score: session.score,
            livesRemaining: session.livesRemaining,
          );
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
            if (session.isComplete) {
              return VictoryOverlay(
                session: session,
                onPlayAgain: _onRestart,
                onBack: () => context.go(AppRoutes.home),
              );
            }
            if (session.isGameOver) {
              return GameOverOverlay(
                session: session,
                onTryAgain: _onRestart,
                onBack: () => context.go(AppRoutes.home),
              );
            }

            final question = session.currentQuestion;
            if (question == null) return const SizedBox.shrink();

            final shortViewport = MediaQuery.sizeOf(context).height < 760;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
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
                          child: Container(
                            width: double.infinity,
                            height: shortViewport ? 110 : 140,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.primary.withAlpha(50),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                question.question,
                                textDirection: TextDirection.ltr,
                                style: AppTextStyles.headingLarge.copyWith(
                                  fontSize: shortViewport ? 36 : 48,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildOpt(question.options[0], question),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildOpt(question.options[1], question),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildOpt(question.options[2], question),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildOpt(question.options[3], question),
                                  ),
                                ],
                              ),
                            ],
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
                          child: ElevatedButton(
                            onPressed: _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildOpt(String opt, QuizQuestion question) {
    return _OptionCard(
      text: opt,
      isRevealed: _isRevealed,
      isSelected: _selectedOption == opt,
      isCorrectOption: opt == question.correctAnswer,
      onTap: () {
        if (!_isRevealed) _onAnswerTapped(opt);
      },
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (!isRevealed)
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.headingMedium.copyWith(
                color: textColor,
                fontSize: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
