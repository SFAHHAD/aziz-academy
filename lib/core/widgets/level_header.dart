import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/xp_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';

// =============================================================================
// LevelHeader — Navy & Gold XP/level widget for the home screen
// =============================================================================

class LevelHeader extends ConsumerWidget {
  const LevelHeader({super.key, required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpProvider).value ?? const XpState();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3C6E), Color(0xFF0F2445)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9C349).withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9C349).withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Level badge ─────────────────────────────────────────────────────
          _LevelBadge(level: xp.level),
          const SizedBox(width: 14),

          // ── XP progress block ───────────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: "Level N" label  ↔  "xxx / yyy XP"
                Row(
                  children: [
                    Text(
                      context.l10n.levelLabel(
                        localizeDigitsCtx(xp.level, context),
                      ),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFFE9C349),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      xp.isMaxLevel
                          ? context.l10n.levelMaxXp(
                              localizeDigitsCtx(xp.totalXp, context),
                            )
                          : context.l10n.levelXpProgress(
                              localizeDigitsCtx(xp.xpInCurrentLevel, context),
                              localizeDigitsCtx(
                                xp.xpNeededForNextLevel,
                                context,
                              ),
                            ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Progress bar
                _XpBar(progress: xp.progressInLevel),

                const SizedBox(height: 5),

                // Sub-label: next level or max
                Text(
                  xp.isMaxLevel
                      ? context.l10n.levelMaxBanner
                      : context.l10n.levelNextInfo(
                          localizeDigitsCtx(xp.level + 1, context),
                          localizeDigitsCtx(xp.totalXp, context),
                        ),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Streak badge (shown only when streak > 0) ───────────────────────
          if (streakDays > 0) ...[
            const SizedBox(width: 14),
            _StreakBadge(days: streakDays),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Level badge (gold circle)
// =============================================================================

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9C349), Color(0xFFAF8D11)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9C349).withAlpha(100),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lv',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF0A1628),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          Text(
            localizeDigitsCtx(level, context),
            style: AppTextStyles.headingMedium.copyWith(
              color: const Color(0xFF0A1628),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Animated XP progress bar
// =============================================================================

class _XpBar extends StatelessWidget {
  const _XpBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Track
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Fill (animated)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, val, child) => FractionallySizedBox(
            widthFactor: val.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: AppColors.progressGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE9C349).withAlpha(130),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Streak badge
// =============================================================================

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9C349).withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9C349).withAlpha(70)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            localizeDigitsCtx(days, context),
            style: AppTextStyles.labelMedium.copyWith(
              color: const Color(0xFFE9C349),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
