import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';

/// Full-screen overlay shown when the player completes the quiz with lives remaining.
///
/// Shows:
/// - Confetti cannon 🎊
/// - "Master of Capitals!" heading
/// - Final score (correct / total)
/// - Star rating based on [QuizSessionState.livesRemaining]
/// - "Play Again" and "Back to Map" buttons
class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    super.key,
    required this.session,
    required this.onPlayAgain,
    required this.onBack,
  });

  final QuizSessionState session;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  /// Stars based on hearts remaining at end of quiz.
  static int starsFor(int livesRemaining) => livesRemaining.clamp(0, 3);

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Confetti — long enough to feel celebratory
    _confetti = ConfettiController(duration: const Duration(seconds: 6))
      ..play();

    // Entry animation: scale + fade in
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();

    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  int get _stars => VictoryOverlay.starsFor(widget.session.livesRemaining);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Stack(
      children: [
        // ── Frosted backdrop ─────────────────────────────────────────────
        GestureDetector(
          onTap: () {}, // absorb taps — don't let them reach quiz body
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1A2E).withAlpha(230),
                  const Color(0xFF16213E).withAlpha(245),
                ],
              ),
            ),
          ),
        ),

        // ── Confetti cannon at top-centre ─────────────────────────────────
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: pi / 2,
            numberOfParticles: 22,
            emissionFrequency: 0.04,
            gravity: 0.18,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
              AppColors.success,
              Colors.pinkAccent,
              Colors.lightBlueAccent,
            ],
            shouldLoop: false,
          ),
        ),

        // ── Content card ─────────────────────────────────────────────────
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 480 : 360),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 72)),
                        const SizedBox(height: 12),
                        Text(
                          'بطل العواصم!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أتممت الاختبار بتفوق! 🎉',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Score pill
                        _ScorePill(session: widget.session),
                        const SizedBox(height: 20),

                        // Star row
                        _StarRow(stars: _stars),
                        const SizedBox(height: 8),
                        Text(
                          _starLabel(_stars),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Play Again
                        _ActionButton(
                          label: 'العب مجدداً',
                          icon: Icons.refresh_rounded,
                          backgroundColor: AppColors.primary,
                          onPressed: widget.onPlayAgain,
                        ),
                        const SizedBox(height: 12),

                        // Back to Map
                        _ActionButton(
                          label: 'العودة للقائمة',
                          icon: Icons.map_rounded,
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(
                            color: AppColors.divider,
                            width: 2,
                          ),
                          onPressed: widget.onBack,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 3:
        return '⚡ إتقان تام! صفر أخطاء!';
      case 2:
        return '👍 ممتاز! شبه مثالي!';
      default:
        return '✅ أحسنت! واصل التدريب!';
    }
  }
}

// =============================================================================
// Sub-widgets shared between overlays
// =============================================================================

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.session});
  final QuizSessionState session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.capitalsColor.withAlpha(25),
            AppColors.capitalsColor.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.capitalsColor.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${session.score}',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.capitalsColor,
            ),
          ),
          Text(
            ' / ${session.totalQuestions}',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(width: 8),
          const Text('✅', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars من 3 نجوم',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final filled = i < stars;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (i * 150)),
            tween: Tween(begin: 0.0, end: filled ? 1.0 : 0.0),
            curve: Curves.elasticOut,
            builder: (context, value, _) => Transform.scale(
              scale: 0.6 + (value * 0.4),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: filled ? AppColors.accent : AppColors.disabled,
                size: 48,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.foregroundColor = Colors.white,
    this.side = BorderSide.none,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide side;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size(double.infinity, 56),
          textStyle: AppTextStyles.labelLarge.copyWith(color: foregroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: side,
          ),
          elevation: backgroundColor == Colors.transparent ? 0 : 2,
        ),
      ),
    );
  }
}
