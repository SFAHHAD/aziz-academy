import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/cosmetics_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/streak_freeze_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/outfits_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Cosmetic-only coin shop. No real money. Kid spends earned coins on avatar
/// emojis and frame styles. Owned items can be equipped freely.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final coins = ref.watch(coinProvider).value ?? 0;
    final cos = ref.watch(cosmeticsProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          wide: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.commonBack,
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isArabic ? 'المتجر' : 'Shop',
                    style: AppTextStyles.headingMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          localizeDigitsCtx(coins, context),
                          style: AppTextStyles.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'الأفاتار' : 'Avatars',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _avatars.map((it) {
                  return _ShopTile(
                    emoji: it.emoji,
                    label: isArabic ? it.ar : it.en,
                    price: it.price,
                    owned: cos?.owned.contains(it.id) ?? false,
                    equipped: cos?.equippedAvatar == it.id,
                    onTap: () =>
                        _purchaseOrEquip(context, ref, it.id, it.price, true),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                isArabic ? 'بطاقات تأمين السلسلة' : 'Streak Freeze',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 8),
              _StreakFreezeRow(arabic: isArabic),
              const SizedBox(height: 24),
              Text(
                isArabic ? 'الأزياء' : 'Outfits',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 8),
              _OutfitsRow(arabic: isArabic),
              const SizedBox(height: 24),
              Text(
                isArabic ? 'إطارات الأفاتار' : 'Frames',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _frames.map((it) {
                  return _ShopTile(
                    emoji: it.emoji,
                    label: isArabic ? it.ar : it.en,
                    price: it.price,
                    owned: cos?.owned.contains(it.id) ?? false,
                    equipped: cos?.equippedFrame == it.id,
                    onTap: () =>
                        _purchaseOrEquip(context, ref, it.id, it.price, false),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseOrEquip(
    BuildContext context,
    WidgetRef ref,
    String id,
    int price,
    bool isAvatar,
  ) async {
    final cos = ref.read(cosmeticsProvider).value;
    if (cos == null) return;
    HapticFeedback.lightImpact();
    if (cos.owned.contains(id)) {
      // Equip
      if (isAvatar) {
        await ref.read(cosmeticsProvider.notifier).equipAvatar(id);
      } else {
        await ref.read(cosmeticsProvider.notifier).equipFrame(id);
      }
      return;
    }
    final ok = await ref.read(coinProvider.notifier).spend(price);
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(context.l10n.shopNotEnoughCoins)),
        );
      }
      return;
    }
    await ref.read(cosmeticsProvider.notifier).grant(id);
    if (isAvatar) {
      await ref.read(cosmeticsProvider.notifier).equipAvatar(id);
    } else {
      await ref.read(cosmeticsProvider.notifier).equipFrame(id);
    }
  }
}

class _Item {
  const _Item(this.id, this.emoji, this.en, this.ar, this.price);
  final String id;
  final String emoji;
  final String en;
  final String ar;
  final int price;
}

const _avatars = <_Item>[
  _Item('av_owl', '🦉', 'Owl', 'البومة', 0),
  _Item('av_fox', '🦊', 'Fox', 'الثعلب', 30),
  _Item('av_panda', '🐼', 'Panda', 'الباندا', 30),
  _Item('av_dragon', '🐲', 'Dragon', 'التنين', 80),
  _Item('av_robot', '🤖', 'Robot', 'الروبوت', 80),
  _Item('av_unicorn', '🦄', 'Unicorn', 'الوحيد', 120),
  _Item('av_astronaut', '👨‍🚀', 'Astronaut', 'رائد فضاء', 150),
  _Item('av_wizard', '🧙', 'Wizard', 'الساحر', 150),
];

const _frames = <_Item>[
  _Item('frame_basic', '⬜', 'Basic', 'العادي', 0),
  _Item('frame_gold', '🟡', 'Gold', 'الذهبي', 50),
  _Item('frame_blue', '🟦', 'Blue', 'الأزرق', 50),
  _Item('frame_purple', '🟪', 'Purple', 'البنفسجي', 80),
  _Item('frame_rainbow', '🌈', 'Rainbow', 'قوس قزح', 200),
];

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.emoji,
    required this.label,
    required this.price,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int price;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cta = equipped
        ? l10n.shopEquipped
        : (owned ? l10n.shopEquip : '🪙 ${price.toString()}');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: equipped
              ? AppColors.secondary.withAlpha(60)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: equipped
                ? AppColors.secondary
                : (owned ? AppColors.primary : AppColors.glassBorder),
            width: equipped ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              cta,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakFreezeRow extends ConsumerWidget {
  const _StreakFreezeRow({required this.arabic});
  final bool arabic;

  static const _price = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freezes = ref.watch(streakFreezeProvider).value;
    final coins = ref.watch(coinProvider).value ?? 0;
    final owned = freezes?.owned ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Text('❄️', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic ? 'بطاقة تأمين السلسلة' : 'Streak Freeze',
                  style: AppTextStyles.headingSmall,
                ),
                Text(
                  arabic
                      ? 'تنفق تلقائياً إذا فاتك يوم — تحفظ سلسلة تنشيط الذهن.'
                      : 'Auto-spends if you skip a day to keep your Brain Boost streak alive.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  arabic ? 'لديك: $owned' : 'Owned: $owned',
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: coins >= _price
                ? () async {
                    HapticFeedback.lightImpact();
                    final ok = await ref
                        .read(coinProvider.notifier)
                        .spend(_price);
                    if (!ok) return;
                    await ref.read(streakFreezeProvider.notifier).grant(1);
                  }
                : null,
            icon: const Text('🪙', style: TextStyle(fontSize: 14)),
            label: Text('$_price'),
          ),
        ],
      ),
    );
  }
}

class _OutfitsRow extends ConsumerWidget {
  const _OutfitsRow({required this.arabic});
  final bool arabic;

  Future<void> _buyAndEquip(WidgetRef ref, OutfitDef o) async {
    final coins = ref.read(coinProvider).value ?? 0;
    final owned = ref.read(ownedOutfitsProvider).value ?? const <String>{};
    if (!owned.contains(o.id)) {
      if (coins < o.cost) return;
      final spent = await ref.read(coinProvider.notifier).spend(o.cost);
      if (!spent) return;
      await ref.read(ownedOutfitsProvider.notifier).markOwned(o.id);
    }
    // Equip: write outfitId to active slot.
    final family = ref.read(familyProfilesProvider).value;
    if (family == null) return;
    final active = family.active;
    final updated = active.copyWith(outfitId: o.id);
    final slots = [
      for (final s in family.slots)
        if (s.id == active.id) updated else s,
    ];
    await ref
        .read(familyProfilesProvider.notifier)
        .replaceSlots(slots, activeSlotId: family.activeSlotId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinProvider).value ?? 0;
    final owned = ref.watch(ownedOutfitsProvider).value ?? const <String>{};
    final equippedId = ref.watch(familyProfilesProvider).value?.active.outfitId;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in kOutfits)
          _OutfitCard(
            outfit: o,
            arabic: arabic,
            owned: owned.contains(o.id),
            equipped: equippedId == o.id,
            affordable: coins >= o.cost,
            onTap: () => _buyAndEquip(ref, o),
          ),
      ],
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({
    required this.outfit,
    required this.arabic,
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.onTap,
  });
  final OutfitDef outfit;
  final bool arabic;
  final bool owned;
  final bool equipped;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = owned ? !equipped : affordable;
    return SizedBox(
      width: 110,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: equipped
                ? AppColors.success.withAlpha(40)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: equipped
                  ? AppColors.success
                  : (owned
                        ? AppColors.primary.withAlpha(140)
                        : AppColors.divider),
              width: equipped ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(outfit.glyph, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text(
                arabic ? outfit.labelAr : outfit.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (equipped)
                Text(
                  arabic ? 'مرتدى' : 'Equipped',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                )
              else if (owned)
                Text(
                  arabic ? 'املك — اضغط' : 'Owned — tap',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                )
              else
                Text(
                  '🪙 ${localizeDigits(outfit.cost, arabic: arabic)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: affordable ? AppColors.accent : AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
