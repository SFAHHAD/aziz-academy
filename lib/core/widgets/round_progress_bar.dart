import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';

/// Slim 6px progress bar for quiz-style round headers. Animates the
/// fill width when [progress] changes so the bar feels alive on each
/// question. Respects [MediaQuery.disableAnimations] / accessibility
/// motion preferences by snapping when the platform asks for reduced
/// motion.
class RoundProgressBar extends StatelessWidget {
  const RoundProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.color,
  });

  /// 0.0 (empty) → 1.0 (full).
  final double progress;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: AppColors.surfaceContainerHigh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * clamped;
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.withValues(alpha: 0.85), c],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
