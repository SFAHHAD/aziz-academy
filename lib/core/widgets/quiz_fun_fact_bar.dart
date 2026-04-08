import 'package:flutter/material.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Fun fact + optional wrong-answer hint (shared by quiz modules).
class QuizFunFactBar extends StatelessWidget {
  const QuizFunFactBar({
    super.key,
    required this.funFact,
    this.wasWrong = false,
    this.correctAnswer,
  });

  final String funFact;
  final bool wasWrong;
  final String? correctAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wasWrong && correctAnswer != null && correctAnswer!.isNotEmpty) ...[
              Text(
                '${l10n.funFactCorrectPrefix} $correctAnswer',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wasWrong ? '📚' : '💡',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    funFact,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
