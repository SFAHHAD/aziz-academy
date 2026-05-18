import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Visual state for a single tap-to-answer option tile.
enum QuizTileState {
  /// Default — not yet tapped, or wrong picks have been reset.
  neutral,

  /// The kid just tapped this tile and got it right. Green flash + scale.
  correct,

  /// The kid just tapped this tile and got it wrong. Red border, slight
  /// shake handled by the caller's setState; the tile itself just turns red.
  wrong,
}

/// Reusable answer-option tile for quiz-style screens. Centralises the
/// look + feedback animation so Number Bonds, Place Value, Skip Counting
/// (and any future tap-to-answer screen) share one visual grammar.
///
/// On correct picks the tile briefly flashes green and scales up by 6%
/// before the host advances to the next question — gives the kid the
/// "I got it right" beat. On wrong picks the tile turns red so the kid
/// sees which one they hit, while leaving the correct answer
/// untouched so they can self-correct.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
    this.semanticLabel,
  });

  final String text;
  final QuizTileState state;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isCorrect = state == QuizTileState.correct;
    final isWrong = state == QuizTileState.wrong;

    final bg = isCorrect
        ? AppColors.success.withValues(alpha: 0.18)
        : isWrong
            ? AppColors.error.withValues(alpha: 0.14)
            : AppColors.surface;
    final borderColor = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.error
            : AppColors.surfaceContainerHigh;
    final textColor = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.error
            : AppColors.textDark;
    final borderWidth = isCorrect ? 3.0 : 2.0;

    Widget tile = AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isCorrect
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state == QuizTileState.correct ? null : onTap,
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.headingLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      tile = AnimatedScale(
        scale: isCorrect ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: tile,
      );
    }

    final a11y = semanticLabel ?? text;
    return Semantics(
      button: true,
      enabled: state != QuizTileState.correct,
      label: a11y,
      child: ExcludeSemantics(child: tile),
    );
  }
}
