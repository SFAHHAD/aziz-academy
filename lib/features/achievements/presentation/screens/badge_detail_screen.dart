import 'package:flutter/material.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/badge_l10n.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

// =============================================================================
// Hero tag helper — must match the tag used in _AnimatedBadgeCard
// =============================================================================

String badgeHeroTag(BadgeId id) => 'badge_emoji_${id.name}';

// =============================================================================
// BadgeDetailScreen
// Full-page badge detail that participates in Hero animation from TrophyRoom.
// =============================================================================

class BadgeDetailScreen extends StatelessWidget {
  const BadgeDetailScreen({
    super.key,
    required this.badge,
    required this.isUnlocked,
  });

  final BadgeDefinition badge;
  final bool isUnlocked;

  static const List<double> _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Radial glow background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.4,
                  colors: [
                    isUnlocked
                        ? badge.color.withAlpha(60)
                        : AppColors.surfaceContainerLow,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CenteredBody(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── AppBar ─────────────────────────────────────────────────
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainerLow.withAlpha(180),
                        ),
                        child: IconButton(
                          tooltip: context.l10n.commonBack,
                          icon: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.arrow_back_ios_new_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    pinned: true,
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                      child: Column(
                        children: [
                          // ── Hero badge emoji ──────────────────────────────
                          Hero(
                            tag: badgeHeroTag(badge.id),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isUnlocked
                                    ? RadialGradient(
                                        colors: [
                                          badge.color.withAlpha(120),
                                          badge.color.withAlpha(20),
                                        ],
                                      )
                                    : RadialGradient(
                                        colors: [
                                          AppColors.surfaceContainerHighest,
                                          AppColors.surfaceContainerLow,
                                        ],
                                      ),
                                border: Border.all(
                                  color: isUnlocked
                                      ? badge.color
                                      : AppColors.divider.withAlpha(140),
                                  width: isUnlocked ? 5 : 3,
                                ),
                                boxShadow: isUnlocked
                                    ? [
                                        BoxShadow(
                                          color: badge.color.withAlpha(100),
                                          blurRadius: 40,
                                          spreadRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? Text(
                                        badge.emoji,
                                        style: const TextStyle(fontSize: 70),
                                      )
                                    : ColorFiltered(
                                        colorFilter: const ColorFilter.matrix(
                                          _grayscaleMatrix,
                                        ),
                                        child: Opacity(
                                          opacity: 0.5,
                                          child: Text(
                                            badge.emoji,
                                            style: const TextStyle(
                                              fontSize: 70,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Name ─────────────────────────────────────────
                          Text(
                            l10n.badgeName(badge.id),
                            style: AppTextStyles.headingLarge.copyWith(
                              color: isUnlocked
                                  ? AppColors.textDark
                                  : AppColors.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

                          // ── Subtitle / locked hint ────────────────────────
                          Text(
                            isUnlocked
                                ? l10n.badgeSubtitle(badge.id)
                                : l10n.trophyLockedHint,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // ── Condition card ────────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? badge.color.withAlpha(18)
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isUnlocked
                                    ? badge.color.withAlpha(80)
                                    : AppColors.divider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isUnlocked
                                          ? Icons.verified_rounded
                                          : Icons.info_outline_rounded,
                                      color: isUnlocked
                                          ? badge.color
                                          : AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isUnlocked
                                          ? l10n.trophyAchievementDone
                                          : l10n.trophyHowToEarnBadge,
                                      style: AppTextStyles.headingSmall
                                          .copyWith(
                                            color: isUnlocked
                                                ? badge.color
                                                : AppColors.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.badgeCondition(badge.id),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Dismiss button ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isUnlocked
                                    ? badge.color
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: isUnlocked
                                    ? badge.color.withAlpha(80)
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                l10n.trophyOk,
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
