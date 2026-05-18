import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/outfits_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Side-by-side parent view of every family profile slot. Shows each kid's
/// name, avatar, age band; the shared on-device stats (coins, streak,
/// sessions) are displayed once with a banner clarifying they aggregate
/// across slots — matching the family_profiles_provider design where slots
/// are display switchers, not separate stat namespaces.
class FamilyCompareScreen extends ConsumerWidget {
  const FamilyCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final family = ref.watch(familyProfilesProvider).value;
    final ach = ref.watch(achievementProvider).value;
    final learner = ref.watch(learnerStateProvider).value;
    final coins = ref.watch(coinProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'مقارنة الإخوة' : 'Compare siblings'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.parent);
            }
          },
        ),
      ),
      body: family == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withAlpha(110),
                      ),
                    ),
                    child: Text(
                      isAr
                          ? 'ملاحظة: الإنجازات والعملات والسلسلة مشتركة لكل العائلة على هذا الجهاز.'
                          : 'Note: achievements, coins, and the streak are shared across all slots on this device.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final slot in family.slots)
                        _SlotCard(
                          slot: slot,
                          isActive: slot.id == family.activeSlotId,
                          arabic: isAr,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isAr ? 'الإحصائيات المشتركة' : 'Shared stats',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatRow(
                    label: isAr ? 'عملات' : 'Coins',
                    value: localizeDigits(coins, arabic: isAr),
                    emoji: '🪙',
                  ),
                  _StatRow(
                    label: isAr ? 'السلسلة الحالية' : 'Current streak',
                    value: localizeDigits(ach?.streakCount ?? 0, arabic: isAr),
                    emoji: '🔥',
                  ),
                  _StatRow(
                    label: isAr ? 'إجمالي الجلسات' : 'Total sessions',
                    value: localizeDigits(
                      learner?.totalSessions ?? 0,
                      arabic: isAr,
                    ),
                    emoji: '🎯',
                  ),
                  _StatRow(
                    label: isAr ? 'إجابات صحيحة' : 'Correct answers',
                    value: localizeDigits(ach?.totalCorrect ?? 0, arabic: isAr),
                    emoji: '✅',
                  ),
                  _StatRow(
                    label: isAr ? 'شارات مفتوحة' : 'Badges unlocked',
                    value: localizeDigits(
                      ach?.unlockedBadges.length ?? 0,
                      arabic: isAr,
                    ),
                    emoji: '🏅',
                  ),
                ],
              ),
            ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.isActive,
    required this.arabic,
  });
  final ProfileSlot slot;
  final bool isActive;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withAlpha(28)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withAlpha(180)
              : AppColors.divider,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Text(slot.avatarEmoji, style: const TextStyle(fontSize: 44)),
                if (outfitById(slot.outfitId) != null)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Text(
                        outfitById(slot.outfitId)!.glyph,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            slot.name.isEmpty ? (arabic ? 'بدون اسم' : 'No name') : slot.name,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            slot.ageBand,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                arabic ? 'الحالي' : 'Active',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.emoji,
  });
  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
