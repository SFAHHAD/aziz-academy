import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart' as digits;

/// Reusable round-result panel for quiz-style screens. Renders a big
/// emoji, varied bilingual praise text, score + percent, optional
/// "new best" / "best to beat" subtext, and a row of two actions
/// (play again / change settings). Caller passes a `confettiSeed` to
/// trigger a brief particle burst on perfect rounds.
class RoundResultPanel extends StatelessWidget {
  const RoundResultPanel({
    super.key,
    required this.correct,
    required this.total,
    required this.arabic,
    required this.onAgain,
    required this.onChange,
    this.previousBest,
    this.isNewBest = false,
    this.changeLabelAr = 'تغيير الإعدادات',
    this.changeLabelEn = 'Change settings',
  });

  final int correct;
  final int total;
  final bool arabic;
  final VoidCallback onAgain;
  final VoidCallback onChange;
  final int? previousBest;
  final bool isNewBest;
  final String changeLabelAr;
  final String changeLabelEn;

  static const _praiseAr = [
    'أحسنت!',
    'ممتاز!',
    'رائع!',
    'عمل جميل!',
  ];
  static const _praiseEn = [
    'Great job!',
    'Excellent!',
    'Awesome!',
    'Nice work!',
  ];

  String _pickPraise(bool ar) {
    // Seed on score so the same kid sees a stable praise inside one
    // result view but variety across rounds.
    final pool = ar ? _praiseAr : _praiseEn;
    final i = (correct + total * 7) % pool.length;
    return pool[i];
  }

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (100 * correct / total).round();
    final perfect = correct == total && total > 0;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    String fmt(int n) => digits.localizeDigits(n, arabic: arabic);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (perfect && !reduceMotion)
          IgnorePointer(
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: _ConfettiBurst(seed: correct + total),
            ),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                perfect ? '🌟' : '👏',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                _pickPraise(arabic),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                arabic
                    ? 'نتيجتك ${fmt(correct)} / ${fmt(total)}'
                    : 'You scored ${fmt(correct)} / ${fmt(total)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${fmt(pct)}%',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isNewBest) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: AppColors.secondary, width: 1.5),
                  ),
                  child: Text(
                    arabic ? '🌟 أفضل نتيجة!' : '🌟 New best!',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ] else if (previousBest != null && previousBest! > correct) ...[
                const SizedBox(height: 8),
                Text(
                  arabic
                      ? 'أفضل نتيجة سابقة: ${fmt(previousBest!)} / ${fmt(total)}'
                      : 'Previous best: ${fmt(previousBest!)} / ${fmt(total)}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onAgain,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(arabic ? 'مرة أخرى' : 'Play again'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onChange,
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(arabic ? changeLabelAr : changeLabelEn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.seed});
  final int seed;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    final r = math.Random(widget.seed);
    _particles = List.generate(28, (i) {
      return _Particle(
        x: r.nextDouble(),
        dx: (r.nextDouble() - 0.5) * 0.6,
        dy: 0.6 + r.nextDouble() * 0.6,
        rot: r.nextDouble() * math.pi * 2,
        spin: (r.nextDouble() - 0.5) * 6,
        color: [
          AppColors.secondary,
          AppColors.primary,
          AppColors.success,
          AppColors.warning,
        ][r.nextInt(4)],
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return CustomPaint(
          painter: _ConfettiPainter(_particles, _c.value),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.dx,
    required this.dy,
    required this.rot,
    required this.spin,
    required this.color,
  });
  final double x;
  final double dx;
  final double dy;
  final double rot;
  final double spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final cx = (p.x + p.dx * t) * size.width;
      // Easy gravity curve: starts upward then falls.
      final cy = (-30 + p.dy * size.height * t + 0.6 * size.height * t * t)
          .toDouble();
      final rot = p.rot + p.spin * t;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      final paint = Paint()..color = p.color.withValues(alpha: 1 - t * 0.4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.particles != particles;
}
