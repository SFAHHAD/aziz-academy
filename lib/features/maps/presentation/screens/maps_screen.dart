import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';

import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/features/maps/providers/maps_quiz_provider.dart';
import 'package:aziz_academy/features/maps/presentation/widgets/real_interactive_map.dart';

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizStateAsync = ref.watch(mapsQuizProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: quizStateAsync.when(
        data: (state) {
          if (_showIntro) {
            return _buildIntro(context, state);
          }
          if (state.status == QuizStatus.complete) {
            return _buildResults(context, state);
          }
          return _buildQuiz(context, state);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, QuizSessionState state) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/images/map_bg.png', // Fallback or global bg
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Spacer(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.mapsColor.withValues(alpha:0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mapsColor.withValues(alpha:0.1),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.mapsColor.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🧭', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'مستكشف الخرائط',
                      style: AppTextStyles.headingLarge.copyWith(color: AppColors.mapsColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'أوجد الدول بناءً على مواقعها الجغرافية. هل أنت مستعد للتحدي؟',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showIntro = false);
                        _fadeController.forward();
                        ref.read(audioServiceProvider).startBgm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mapsColor,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.mapsColor.withValues(alpha:0.5),
                      ),
                      child: Text(
                        'ابدأ الاستكشاف',
                        style: AppTextStyles.headingSmall.copyWith(color: AppColors.surface),
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
          Text(
            '🧭 الجغرافيا',
            style: AppTextStyles.headingMedium.copyWith(color: AppColors.mapsColor),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildQuiz(BuildContext context, QuizSessionState state) {
    if (state.questions.isEmpty) return const SizedBox();
    final q = state.currentQuestion!;
    
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
            _buildQuizHeader(state),
            const SizedBox(height: 20),
            Expanded(
              child: RealInteractiveMap(
                targetLat: q.lat ?? 0.0,
                targetLng: q.lng ?? 0.0,
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      q.question,
                      style: AppTextStyles.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ...q.options.map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionButton(
                        text: opt,
                        color: AppColors.mapsColor,
                        onTap: () {
                          ref.read(mapsQuizProvider.notifier).submitAnswer(opt);
                          if (opt == q.correctAnswer) {
                            ref.read(audioServiceProvider).playCorrectSound();
                            _showFeedbackDialog(context, true, q.correctAnswer, q.funFact, () {
                              ref.read(mapsQuizProvider.notifier).nextQuestion();
                            });
                          } else {
                            ref.read(audioServiceProvider).playWrongSound();
                            _showFeedbackDialog(context, false, q.correctAnswer, '', () {
                              ref.read(mapsQuizProvider.notifier).nextQuestion();
                            });
                          }
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, bool isCorrect, String correctAnswer, String funFact, VoidCallback onNext) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isCorrect ? '✅ إجابة صحيحة!' : '❌ إجابة خاطئة',
            style: AppTextStyles.headingMedium.copyWith(
              color: isCorrect ? AppColors.success : AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الدولة هي: $correctAnswer',
                style: AppTextStyles.bodyLarge,
              ),
              if (isCorrect && funFact.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  funFact,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mapsColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('السؤال التالي', style: AppTextStyles.headingSmall),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizHeader(QuizSessionState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
             ref.read(audioServiceProvider).stopBgm();
             context.go(AppRoutes.home);
          },
          icon: const Icon(Icons.close, color: AppColors.primary),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.mapsColor.withValues(alpha:0.3)),
          ),
          child: Text(
            '${state.currentIndex + 1} / ${state.questions.length}',
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.mapsColor),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                index < state.livesRemaining ? Icons.favorite : Icons.favorite_border,
                color: AppColors.error,
                size: 24,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, QuizSessionState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (state.score > 0) {
         ref.read(audioServiceProvider).playVictorySound();
       } else {
         ref.read(audioServiceProvider).playWrongSound();
       }
    });
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.mapsColor.withValues(alpha:0.2),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text('انتهى التحدي!', style: AppTextStyles.headingLarge),
            const SizedBox(height: 12),
            Text(
              'نتيجتك: ${state.score}',
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.mapsColor),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(audioServiceProvider).stopBgm();
                      context.go(AppRoutes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Text('الرئيسية', style: AppTextStyles.headingSmall),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showIntro = true);
                      ref.read(mapsQuizProvider.notifier).reset();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mapsColor,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('إعادة المحاولة', style: AppTextStyles.headingSmall),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha:0.1),
        highlightColor: color.withValues(alpha:0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
        ),
      ),
    );
  }
}
