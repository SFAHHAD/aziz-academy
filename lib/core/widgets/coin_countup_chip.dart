import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';

/// End-of-quiz reward chip — counts up from 0 → [coinsEarned] over ~900ms,
/// with a coin emoji and "+" prefix. Renders nothing when [coinsEarned] is 0,
/// so callers can pass the value unconditionally.
class CoinCountUpChip extends StatelessWidget {
  const CoinCountUpChip({
    super.key,
    required this.coinsEarned,
    this.arabic = true,
    this.reducedMotion = false,
  });

  final int coinsEarned;
  final bool arabic;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (coinsEarned <= 0) return const SizedBox.shrink();
    final duration = Duration(milliseconds: reducedMotion ? 1 : 900);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: coinsEarned.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final shown = value.round();
        final formatted = localizeDigits(shown, arabic: arabic);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withAlpha(50),
                AppColors.accent.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withAlpha(120)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '+$formatted',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
