import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/badge_l10n.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

// =============================================================================
// CelebrationOverlay
//
// Full-screen trophy-unlock celebration:
//   • Lottie confetti (assets/lottie/confetti.json) plays in the centre.
//   • The confetti package fires particles from the top corners.
//   • Newly unlocked badges are shown below the animation.
//   • Auto-dismisses after [autoDismissAfter]; also dismissible by tap.
// =============================================================================

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.newBadges,
    this.autoDismissAfter = const Duration(seconds: 4),
    this.onDismiss,
  });

  final Set<BadgeId> newBadges;
  final Duration autoDismissAfter;
  final VoidCallback? onDismiss;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final ConfettiController _leftCtrl;
  late final ConfettiController _rightCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _leftCtrl = ConfettiController(duration: const Duration(seconds: 3))
      ..play();
    _rightCtrl = ConfettiController(duration: const Duration(seconds: 3))
      ..play();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.autoDismissAfter, _dismiss);
  }

  @override
  void dispose() {
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _fadeCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withAlpha(160),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Left confetti cannon ────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                child: ConfettiWidget(
                  confettiController: _leftCtrl,
                  blastDirection: math.pi / 4,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.15,
                  colors: const [
                    Color(0xFFE9C349),
                    Color(0xFF42A5F5),
                    Color(0xFFEF5350),
                    Color(0xFF66BB6A),
                    Color(0xFFAB47BC),
                  ],
                ),
              ),

              // ── Right confetti cannon ───────────────────────────────────
              Positioned(
                top: 0,
                right: 0,
                child: ConfettiWidget(
                  confettiController: _rightCtrl,
                  blastDirection: math.pi * 3 / 4,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.15,
                  colors: const [
                    Color(0xFFE9C349),
                    Color(0xFF42A5F5),
                    Color(0xFFEF5350),
                    Color(0xFF66BB6A),
                    Color(0xFFAB47BC),
                  ],
                ),
              ),

              // ── Centre card ─────────────────────────────────────────────
              SlideTransition(
                position: _slide,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: const Color(0xFFE9C349).withAlpha(120),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE9C349).withAlpha(60),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lottie animation
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Lottie.asset(
                          'assets/lottie/confetti.json',
                          repeat: false,
                          errorBuilder: (ctx, err, st) => const Text(
                            '🎊',
                            style: TextStyle(fontSize: 80),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Headline
                      Text(
                        context.l10n.trophyNewBadgeTitle,
                        style: AppTextStyles.headingLarge.copyWith(
                          color: const Color(0xFFE9C349),
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Badge chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: widget.newBadges.map((id) {
                          final def = allBadges.firstWhere(
                              (b) => b.id == id,
                              orElse: () => allBadges.first);
                          return _BadgeChip(
                            badge: def,
                            name: context.l10n.badgeName(id),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),
                      Text(
                        context.l10n.trophyTapToDismiss,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Badge chip shown inside the celebration card
// =============================================================================

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.name});

  final BadgeDefinition badge;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: badge.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            name,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
