import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/kid_emoji.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';

/// Compact app bar for SmartHomeScreen: logo + brand (≥480px), coins +
/// streak chip, trophy with badge pip, language toggle, sound toggle,
/// and an overflow icon. The overflow menu is owned by the home screen
/// (lots of inline navigation deps), so we take an [onOverflow] callback
/// rather than pulling that whole tree in here.
class SmartAppBar extends ConsumerWidget {
  const SmartAppBar({
    super.key,
    required this.isArabic,
    required this.onOverflow,
  });

  final bool isArabic;
  final VoidCallback onOverflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedCount =
        ref.watch(achievementProvider).value?.unlockedBadges.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_final.png',
                fit: BoxFit.contain,
                semanticLabel: context.l10n.homeBrandName,
                errorBuilder: (ctx, err, st) => Center(
                  child: KidEmoji.named('graduation', size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (MediaQuery.of(context).size.width >= 480)
            Text(
              context.l10n.homeBrandName,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          const Spacer(),
          const CoinsStreakChip(),
          const SizedBox(width: 8),
          PillIcon(
            onTap: () => context.go(AppRoutes.trophy),
            badge: unlockedCount,
            tooltip: isArabic ? 'غرفة الكؤوس' : 'Trophy room',
            child: KidEmoji.named('trophy', size: 18),
          ),
          const SizedBox(width: 8),
          PillIcon(
            onTap: () => ref.read(localeProvider.notifier).toggle(),
            tooltip: isArabic ? 'تبديل اللغة' : 'Switch language',
            child: Text(
              isArabic ? context.l10n.langSwitchEn : context.l10n.langSwitchAr,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, _) {
              final soundOn =
                  ref.watch(appSettingsProvider).value?.soundEnabled ?? true;
              return PillIcon(
                onTap: () async {
                  await ref.read(appSettingsProvider.notifier).toggleSound();
                  final on =
                      ref.read(appSettingsProvider).value?.soundEnabled ?? true;
                  ref.read(audioServiceProvider).updateMuteStatus(!on);
                },
                tooltip: isArabic
                    ? (soundOn ? 'إيقاف الصوت' : 'تشغيل الصوت')
                    : (soundOn ? 'Mute sound' : 'Unmute sound'),
                child: Text(
                  soundOn ? '🔊' : '🔇',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          PillIcon(
            onTap: onOverflow,
            tooltip: isArabic ? 'القائمة' : 'Menu',
            child: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: AppColors.secondary.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-chip readout for total coins + current brain-boost streak.
/// The streak half is hidden when streak == 0 so the chip doesn't carry
/// a dead divider on a fresh install.
class CoinsStreakChip extends ConsumerWidget {
  const CoinsStreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinProvider).value ?? 0;
    final streak = ref.watch(brainBoostDailyProvider).value?.streak ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              AppColors.secondary.withAlpha(28),
              AppColors.surfaceContainerLow,
            ),
            AppColors.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.secondary.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(24),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KidEmoji.named('coin', size: 14),
          const SizedBox(width: 4),
          Text(
            localizeDigitsCtx(coins, context),
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: AppColors.divider),
            const SizedBox(width: 8),
            KidEmoji.named('fire', size: 13),
            const SizedBox(width: 2),
            Text(
              localizeDigitsCtx(streak, context),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Round 40×40 chip that wraps an emoji or icon and an optional badge
/// pip. Used for trophy / language / sound / overflow in [SmartAppBar].
class PillIcon extends StatelessWidget {
  const PillIcon({
    super.key,
    required this.child,
    required this.onTap,
    this.badge = 0,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback onTap;
  final int badge;
  // When the icon is emoji or icon-only, pass a bilingual hint so screen
  // readers and tooltip-on-hover users know what the button does.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget tap = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Center(child: child),
        ),
      ),
    );
    if (tooltip != null) {
      tap = Tooltip(
        message: tooltip!,
        child: Semantics(label: tooltip, button: true, child: tap),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: 42, height: 42, child: tap),
        if (badge > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Center(
                child: Text(
                  localizeDigitsCtx(badge, context),
                  style: const TextStyle(
                    color: Color(0xFF0A1628),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
