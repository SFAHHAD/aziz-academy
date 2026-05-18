import 'package:flutter/material.dart';

import 'package:aziz_academy/core/logic/did_you_know.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// "Did you know?" — daily-rotating fact card on the home screen.
/// Pure stateless — the rotation is handled by [factForToday()] which
/// derives the fact from the current date. Extracted from
/// home_screen.dart in v1.1.95.
class DidYouKnowCard extends StatelessWidget {
  const DidYouKnowCard({super.key, required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final fact = factForToday();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceContainerLow,
              AppColors.secondary.withAlpha(20),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withAlpha(40)),
        ),
        child: Row(
          children: [
            Text(fact.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'هل تعلم؟' : 'Did you know?',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic ? fact.ar : fact.en,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
