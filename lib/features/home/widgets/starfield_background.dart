import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';

/// Subtle decorative starfield + two soft glows behind the home hero.
/// Pure visual — no business logic. Extracted from home_screen.dart so
/// the big file can shrink further.
class StarfieldBackground extends StatelessWidget {
  const StarfieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarfieldPainter());
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 1.5 + 0.3;
      final opacity = rng.nextDouble() * 0.5 + 0.1;
      paint.color = AppColors.primary.withAlpha((opacity * 255).toInt());
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.secondary.withAlpha(25), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.1),
          radius: size.width * 0.4,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.1),
      size.width * 0.4,
      glowPaint,
    );

    final blueGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.capitalsColor.withAlpha(20), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.75),
          radius: size.width * 0.35,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      size.width * 0.35,
      blueGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
