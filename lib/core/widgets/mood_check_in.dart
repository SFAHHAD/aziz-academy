import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/mood_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Compact 5-emoji mood check-in. If the kid hasn't picked yet today, shows
/// the question + row of options. Once picked, shows just the chosen emoji
/// with a small "tap to change" hint. No timer, no nagging — just one tap.
class MoodCheckIn extends ConsumerWidget {
  const MoodCheckIn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final state = ref.watch(moodProvider).value ?? const MoodState();
    final today = state.today;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: today == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'كيف شعورك اليوم؟' : 'How do you feel today?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final m in Mood.values)
                      _MoodChoice(
                        mood: m,
                        selected: false,
                        onTap: () =>
                            ref.read(moodProvider.notifier).setToday(m),
                      ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Text(today.mood.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAr
                        ? 'مزاجك اليوم: ${today.mood.label(true)}'
                        : "Today: ${today.mood.label(false)}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(moodProvider.notifier).setToday(Mood.okay),
                  child: Text(
                    isAr ? 'تغيير' : 'Change',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final m in Mood.values)
                      _MoodChoice(
                        mood: m,
                        selected: m == today.mood,
                        compact: true,
                        onTap: () =>
                            ref.read(moodProvider.notifier).setToday(m),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.mood,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: compact ? 30 : 44,
        height: compact ? 30 : 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withAlpha(80) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.outline.withAlpha(60),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(mood.emoji, style: TextStyle(fontSize: compact ? 16 : 22)),
      ),
    );
  }
}
