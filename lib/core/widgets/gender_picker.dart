import 'package:flutter/material.dart';

import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Two-card Boy / Girl selector for the kid profile.
///
/// Why this exists: Arabic is a gendered language — once the app knows the
/// kid is a boy or a girl it can address them with the grammatically
/// correct second-person forms (see `gendered_ar.dart`). The picker is
/// visual (👦 / 👧) so a 6-year-old can use it without reading.
///
/// Selecting the already-selected card clears it back to "not set", so the
/// field is never forced — the app simply uses neutral Arabic when unset.
class GenderPicker extends StatelessWidget {
  const GenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.arabic,
    this.compact = false,
  });

  /// One of [Gender.boy], [Gender.girl], [Gender.unset].
  final String value;
  final ValueChanged<String> onChanged;
  final bool arabic;

  /// Smaller layout for bottom sheets.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderCard(
            emoji: '👦',
            label: arabic ? 'ولد' : 'Boy',
            selected: value == Gender.boy,
            compact: compact,
            onTap: () => onChanged(
              value == Gender.boy ? Gender.unset : Gender.boy,
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: _GenderCard(
            emoji: '👧',
            label: arabic ? 'بنت' : 'Girl',
            selected: value == Gender.girl,
            compact: compact,
            onTap: () => onChanged(
              value == Gender.girl ? Gender.unset : Gender.girl,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withAlpha(56)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.glassBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: compact ? 24 : 30),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
