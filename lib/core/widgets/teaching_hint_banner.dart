import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Banner that appears below the question when a kid picks the wrong
/// option — short, friendly, and shows the mini-lesson the engine
/// generated. Hidden when [text] is null. Animates in/out so it
/// doesn't pop jarringly into view.
class TeachingHintBanner extends StatelessWidget {
  const TeachingHintBanner({
    super.key,
    required this.text,
    required this.arabic,
  });

  /// The bilingual hint already resolved for the active locale, or
  /// `null` when no wrong pick has happened yet.
  final String? text;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final hasText = text != null && text!.isNotEmpty;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedSize(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        child: !hasText
            ? const SizedBox(width: double.infinity, height: 0)
            : Container(
                key: ValueKey(text),
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            arabic ? 'تعلَّم:' : 'Learn:',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            text!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
