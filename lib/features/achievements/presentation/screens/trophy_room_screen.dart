import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';

// =============================================================================
// TROPHY ROOM SCREEN (Premium Restored Design + Insights)
// =============================================================================

class TrophyRoomScreen extends ConsumerStatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  ConsumerState<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends ConsumerState<TrophyRoomScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardAnimCtrl;

  @override
  void initState() {
    super.initState();
    _cardAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _cardAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementAsync = ref.watch(achievementProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient (Premium depth)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E3A5F), // Deep primary glow
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: achievementAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary)),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذّر تحميل الكؤوس. أعد المحاولة لاحقاً.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ),
              data: (state) {
                final unlocked = state.unlockedBadges;
                final n = unlocked.length;
                final total = allBadges.length;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(context, n, isRtl),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: _TrophyProgressStrip(
                          unlocked: n,
                          total: total,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'اضغط أي شارة لمعرفة شرط الحصول عليها',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textMedium.withAlpha(200),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final badge = allBadges[index];
                            final isUnlocked = unlocked.contains(badge.id);

                            return _AnimatedBadgeCard(
                              badge: badge,
                              isUnlocked: isUnlocked,
                              index: index,
                              animCtrl: _cardAnimCtrl,
                              onTap: () =>
                                  _showBadgeCondition(context, badge, isUnlocked),
                            );
                          },
                          childCount: allBadges.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 60)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, int unlockedCount, bool isRtl) {
    final h = MediaQuery.sizeOf(context).height;
    final expanded = h < 700 ? 220.0 : 260.0;
    return SliverAppBar(
      expandedHeight: expanded,
      backgroundColor: Colors.transparent,
      elevation: 0,
      stretch: true,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerLow.withAlpha(150),
          ),
          child: IconButton(
            icon: Icon(
              isRtl
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 24,
              right: 32,
              child: Text('✨', style: TextStyle(fontSize: 22, color: AppColors.secondary.withAlpha(120))),
            ),
            Positioned(
              bottom: 48,
              left: 28,
              child: Text('⭐', style: TextStyle(fontSize: 18, color: AppColors.secondary.withAlpha(100))),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: h < 700 ? 28 : 40),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(100),
                        blurRadius: 36,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 46)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'قاعة الكؤوس',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: h < 700 ? 26 : null,
                    shadows: [
                      Shadow(
                        color: AppColors.secondary.withAlpha(150),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(28),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: AppColors.secondary.withAlpha(90)),
                  ),
                  child: Text(
                    '$unlockedCount / ${allBadges.length} شارات',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeCondition(
      BuildContext context, BadgeDefinition badge, bool isUnlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color:
                    isUnlocked ? badge.color : AppColors.surfaceContainerHighest,
                width: 2),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? badge.color.withAlpha(50)
                    : Colors.black.withAlpha(60),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? badge.color.withAlpha(30)
                      : AppColors.surfaceContainerHighest,
                  border: Border.all(
                      color: isUnlocked ? badge.color : Colors.grey, width: 4),
                ),
                child: Center(
                  child: isUnlocked
                      ? Text(
                          badge.emoji,
                          style: const TextStyle(fontSize: 56),
                        )
                      : ColorFiltered(
                          colorFilter:
                              const ColorFilter.matrix(_kBadgeGrayscaleMatrix),
                          child: Opacity(
                            opacity: 0.55,
                            child: Text(
                              badge.emoji,
                              style: const TextStyle(fontSize: 56),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                badge.nameKey,
                style: AppTextStyles.headingLarge.copyWith(
                  color: isUnlocked
                      ? AppColors.textDark
                      : AppColors.textMedium.withAlpha(200),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isUnlocked ? badge.descKey : 'استمر في اللعب لفتح هذه الشارة',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background.withAlpha(150),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isUnlocked
                          ? badge.color.withAlpha(80)
                          : AppColors.divider),
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
                            color: isUnlocked ? badge.color : AppColors.primary,
                            size: 24),
                        const SizedBox(width: 8),
                        Text(
                          isUnlocked
                              ? 'إنجاز مكتمل!'
                              : 'شروط الحصول على الشارة:',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: isUnlocked
                                ? badge.color
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      badge.conditionAr,
                      style: AppTextStyles.bodyLarge.copyWith(
                          height: 1.5, color: AppColors.textDark),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    elevation: 10,
                    shadowColor: AppColors.secondary.withAlpha(100),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('حسناً',
                      style: AppTextStyles.headingMedium
                          .copyWith(color: AppColors.background)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Progress strip under hero
// -----------------------------------------------------------------------------

class _TrophyProgressStrip extends StatelessWidget {
  const _TrophyProgressStrip({
    required this.unlocked,
    required this.total,
  });

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = total <= 0 ? 1 : total;
    final p = (unlocked / t).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withAlpha(35),
            AppColors.surfaceContainerLow.withAlpha(180),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: AppColors.secondary.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقدّم المجموعة',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$unlocked / $total',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 10,
              backgroundColor: AppColors.divider.withAlpha(120),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Premium Animated Badge Card
// =============================================================================

/// Standard luminance weights → grayscale (locked badges look like earned, but faded).
const List<double> _kBadgeGrayscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

class _AnimatedBadgeCard extends StatelessWidget {
  const _AnimatedBadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.index,
    required this.animCtrl,
    required this.onTap,
  });

  final BadgeDefinition badge;
  final bool isUnlocked;
  final int index;
  final AnimationController animCtrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Staggered fade in + slide up
    final delay = (index * 0.1).clamp(0.0, 1.0);
    final slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: animCtrl,
            curve: Interval(delay, math.min(1.0, delay + 0.5),
                curve: Curves.easeOutCubic)));
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: animCtrl,
        curve: Interval(delay, math.min(1.0, delay + 0.5), curve: Curves.easeOut)));

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [
                        badge.color.withAlpha(40),
                        AppColors.surfaceContainerLow,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUnlocked ? null : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isUnlocked
                    ? badge.color.withAlpha(200)
                    : AppColors.divider.withAlpha(80),
                width: isUnlocked ? 2.5 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: badge.color.withAlpha(50),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked
                          ? RadialGradient(
                              colors: [
                                badge.color.withAlpha(100),
                                badge.color.withAlpha(10),
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
                        width: isUnlocked ? 4 : 3,
                      ),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: badge.color.withAlpha(80),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Text(
                              badge.emoji,
                              style: TextStyle(
                                fontSize: 42,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withAlpha(150),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            )
                          : ColorFiltered(
                              colorFilter:
                                  const ColorFilter.matrix(_kBadgeGrayscaleMatrix),
                              child: Opacity(
                                opacity: 0.5,
                                child: Text(
                                  badge.emoji,
                                  style: const TextStyle(fontSize: 42),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: isUnlocked
                        ? Text(
                            badge.nameKey,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          )
                        : ColorFiltered(
                            colorFilter:
                                const ColorFilter.matrix(_kBadgeGrayscaleMatrix),
                            child: Opacity(
                              opacity: 0.5,
                              child: Text(
                                badge.nameKey,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
