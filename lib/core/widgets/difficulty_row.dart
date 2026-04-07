import 'package:flutter/material.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Reusable difficulty selector row used on every quiz intro screen.
class DifficultyRow extends StatelessWidget {
  const DifficultyRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  final QuizDifficulty value;
  final ValueChanged<QuizDifficulty> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.capitalsColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مستوى الصعوبة',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
        ),
        const SizedBox(height: 8),
        Row(
          children: QuizDifficulty.values.map((d) {
            final selected = value == d;
            final isFirst = d == QuizDifficulty.values.first;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: isFirst ? 0 : 6),
                child: GestureDetector(
                  onTap: () => onChanged(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withAlpha(220)
                          : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? color
                            : AppColors.divider.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          d.labelAr,
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
