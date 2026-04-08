import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';

/// Full-screen overlay when the player completes the quiz with lives remaining.
class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    super.key,
    required this.session,
    required this.onPlayAgain,
    required this.onBack,
    this.title = 'أحسنت يا بطل!',
    this.subtitle = 'أتممت الاختبار بتفوق! 🎉',
    this.reducedMotion = false,
    this.enableShare = true,
    this.shareModuleLabel = 'أكاديمية عزيز',
  });

  final QuizSessionState session;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final bool reducedMotion;
  final bool enableShare;
  final String shareModuleLabel;

  static int starsFor(int livesRemaining) => livesRemaining.clamp(0, 3);

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with TickerProviderStateMixin {
  ConfettiController? _confetti;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    if (!widget.reducedMotion) {
      _confetti = ConfettiController(duration: const Duration(seconds: 5))
        ..play();
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.reducedMotion ? 1 : 550),
    )..forward();

    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: widget.reducedMotion ? 1.0 : 0.82, end: 1.0)
        .animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _confetti?.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  int get _stars => VictoryOverlay.starsFor(widget.session.livesRemaining);
  int get _wrong =>
      (widget.session.totalQuestions - widget.session.score).clamp(0, 999);

  Future<void> _onShare() async {
    final text =
        '${widget.shareModuleLabel}\n${widget.session.score}/${widget.session.totalQuestions} إجابات صحيحة • $_wrong خطأ\nنجوم: $_stars/3 ⭐';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {},
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
        if (_confetti != null)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti!,
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
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
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
                          widget.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _ScorePill(session: widget.session),
                        const SizedBox(height: 12),
                        Text(
                          'صحيح: ${widget.session.score}  •  خطأ: $_wrong',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _StarRow(stars: _stars),
                        const SizedBox(height: 8),
                        Text(
                          _starLabel(_stars),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (widget.enableShare) ...[
                          _ActionButton(
                            label: 'مشاركة الإنجاز',
                            icon: Icons.ios_share_rounded,
                            backgroundColor: AppColors.secondary,
                            onPressed: _onShare,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _ActionButton(
                          label: 'العب مجدداً',
                          icon: Icons.refresh_rounded,
                          backgroundColor: AppColors.primary,
                          onPressed: widget.onPlayAgain,
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          label: 'العودة للقائمة',
                          icon: Icons.home_rounded,
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
      child: Semantics(
        label: label,
        button: true,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            minimumSize: const Size(double.infinity, 56),
            textStyle:
                AppTextStyles.labelLarge.copyWith(color: foregroundColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: side,
            ),
            elevation: backgroundColor == Colors.transparent ? 0 : 2,
          ),
        ),
      ),
    );
  }
}
