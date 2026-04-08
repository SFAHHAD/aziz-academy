import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/logic/daily_mission.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/recap_arm_provider.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/local_backup_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(audioServiceProvider).startBgm();
      try {
        await ref.read(appSettingsProvider.future);
        final s = ref.read(appSettingsProvider).value;
        if (s != null) {
          ref.read(audioServiceProvider).updateMuteStatus(!s.soundEnabled);
        }
      } catch (_) {}
      final beforeStreak =
          ref.read(achievementProvider).value?.streakCount ?? 0;
      await ref.read(achievementProvider.notifier).recordDailyVisit();
      if (!mounted) return;
      final afterStreak =
          ref.read(achievementProvider).value?.streakCount ?? 0;
      if (afterStreak > beforeStreak &&
          (afterStreak == 3 || afterStreak == 7)) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.streakSnack(afterStreak)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final achievementAsync = ref.watch(achievementProvider);
    final achievement = achievementAsync.value;
    final unlockedCount = achievement?.unlockedBadges.length ?? 0;
    final totalCorrect = achievement?.totalCorrect ?? 0;
    final progress = achievement?.progress ?? 0.0;
    final capitalsStars = achievement?.capitalsStars ?? 0;
    final logosStars = achievement?.logosStars ?? 0;
    final mathStars = achievement?.mathStars ?? 0;
    final sciencesStars = achievement?.sciencesStars ?? 0;
    final streakDays = achievement?.streakCount ?? 0;

    final localeAsync = ref.watch(localeProvider);
    final isArabic = localeAsync.value?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Starfield background ──────────────────────────────────────────
          const Positioned.fill(child: _StarfieldBackground()),

          // ── Main content ─────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildTopBar(context, ref, unlockedCount, isArabic),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHeroSection(context, _floatCtrl),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 8),

                            // ── Progress strip ──────────────────────────────
                            _GlowProgressStrip(
                              l10n: l10n,
                              totalCorrect: totalCorrect,
                              progress: progress,
                              streakDays: streakDays,
                            ),
                            const SizedBox(height: 16),
                            _SubjectStarsStrip(
                              l10n: l10n,
                              capitalsStars: capitalsStars,
                              logosStars: logosStars,
                              mathStars: mathStars,
                              sciencesStars: sciencesStars,
                            ),
                            const SizedBox(height: 20),

                            // ── Section label ───────────────────────────────
                            Text(
                              l10n.homeSectionLearn,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: AppColors.textMedium,
                                letterSpacing: 1,
                              ),
                            ),
                          ]),
                        ),
                      ),
                      
                      // ── Responsive Module Grid ──────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            mainAxisExtent: 110, // Fixed height keeps cards perfectly proportioned
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                          ),
                          delegate: SliverChildListDelegate([
                            _GlassModuleCard(
                              title: l10n.quiz_capitals,
                              subtitle: l10n.moduleCapitalsSubtitle,
                              emoji: '🏛️',
                              accentColor: AppColors.capitalsColor,
                              route: AppRoutes.capitals,
                              stars: capitalsStars,
                              showStars: true,
                              delay: 0,
                            ),
                            _GlassModuleCard(
                              title: l10n.quiz_flags,
                              subtitle: l10n.moduleFlagsSubtitle,
                              emoji: '🚩',
                              accentColor: AppColors.error,
                              route: AppRoutes.flags,
                              stars: 0,
                              showStars: false,
                              delay: 40,
                            ),
                            _GlassModuleCard(
                              title: l10n.quiz_maps,
                              subtitle: l10n.moduleMapsSubtitle,
                              emoji: '🗺️',
                              accentColor: AppColors.mapsColor,
                              route: AppRoutes.maps,
                              stars: 0,
                              showStars: false,
                              delay: 80,
                            ),
                            _GlassModuleCard(
                              title: l10n.quiz_logos,
                              subtitle: l10n.moduleLogosSubtitle,
                              emoji: '🏷️',
                              accentColor: AppColors.logosColor,
                              route: AppRoutes.logos,
                              stars: logosStars,
                              showStars: true,
                              delay: 120,
                            ),
                            _GlassModuleCard(
                              title: l10n.quiz_sciences,
                              subtitle: l10n.moduleSciencesSubtitle,
                              emoji: '🔬',
                              accentColor: const Color(0xFFC47AC0), // Softer purple
                              route: AppRoutes.sciences,
                              stars: sciencesStars,
                              showStars: true,
                              delay: 160,
                            ),
                            _GlassModuleCard(
                              title: l10n.quiz_math,
                              subtitle: l10n.moduleMathSubtitle,
                              emoji: '🔢',
                              accentColor: const Color(0xFF2C63B3), // Deep blue
                              route: AppRoutes.math,
                              stars: mathStars,
                              showStars: true,
                              delay: 200,
                            ),
                          ]),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Consumer(
                              builder: (context, ref, _) {
                                final async = ref.watch(recapQueueProvider);
                                final n = async.value?.length ?? 0;
                                if (n == 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RecapCard(
                                    l10n: l10n,
                                    count: n,
                                    onStart: () =>
                                        _startRecapSession(context, ref),
                                  ),
                                );
                              },
                            ),
                            _DailyMissionCard(
                              l10n: l10n,
                              mission: dailyMissionFor(DateTime.now()),
                            ),
                            const SizedBox(height: 12),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    int unlockedCount,
    bool isArabic,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo pip
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
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Text('🎓', style: TextStyle(fontSize: 20))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.l10n.homeBrandName,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),
          const Spacer(),

          // Language toggle
          _GlassPill(
            onTap: () => ref.read(localeProvider.notifier).toggle(),
            child: Text(
              isArabic ? context.l10n.langSwitchEn : context.l10n.langSwitchAr,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.secondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),

          Consumer(
            builder: (context, ref, _) {
              final soundOn =
                  ref.watch(appSettingsProvider).value?.soundEnabled ?? true;
              return _GlassPill(
                onTap: () async {
                  await ref.read(appSettingsProvider.notifier).toggleSound();
                  final on =
                      ref.read(appSettingsProvider).value?.soundEnabled ?? true;
                  ref.read(audioServiceProvider).updateMuteStatus(!on);
                },
                child: Text(
                  soundOn ? '🔊' : '🔇',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          _GlassPill(
            onTap: () => _showKidSettingsSheet(context, ref),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppColors.secondary.withAlpha(220),
            ),
          ),
          const SizedBox(width: 8),

          _GlassPill(
            onTap: () => context.push(AppRoutes.privacy),
            child: Icon(
              Icons.privacy_tip_outlined,
              size: 18,
              color: AppColors.secondary.withAlpha(220),
            ),
          ),
          const SizedBox(width: 8),

          _GlassPill(
            onTap: () => context.push(AppRoutes.about),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.secondary.withAlpha(220),
            ),
          ),
          const SizedBox(width: 8),

          // Trophy button with badge pip
          Stack(
            clipBehavior: Clip.none,
            children: [
              _GlassPill(
                onTap: () => context.go(AppRoutes.trophy),
                child: const Text('🏆', style: TextStyle(fontSize: 20)),
              ),
              if (unlockedCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$unlockedCount',
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, AnimationController floatCtrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: AnimatedBuilder(
        animation: floatCtrl,
        builder: (context, child) {
          final float =
              math.sin(floatCtrl.value * math.pi) * 6.0;
          return Transform.translate(
            offset: Offset(0, float),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.homeHeroWelcome,
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 30,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.homeHeroSubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Starfield Background
// =============================================================================

class _StarfieldBackground extends StatelessWidget {
  const _StarfieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();

    // Draw ~60 stars
    for (var i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 1.5 + 0.3;
      final opacity = rng.nextDouble() * 0.5 + 0.1;
      paint.color = AppColors.primary.withAlpha((opacity * 255).toInt());
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw a subtle gold glow in top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.secondary.withAlpha(25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.1),
        radius: size.width * 0.4,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.1),
      size.width * 0.4,
      glowPaint,
    );

    // Blue glow bottom-left
    final blueGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.capitalsColor.withAlpha(20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.75),
        radius: size.width * 0.35,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      size.width * 0.35,
      blueGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// Subject Stars Strip
// =============================================================================

class _SubjectStarsStrip extends StatelessWidget {
  const _SubjectStarsStrip({
    required this.l10n,
    required this.capitalsStars,
    required this.logosStars,
    required this.mathStars,
    required this.sciencesStars,
  });

  final AppLocalizations l10n;
  final int capitalsStars;
  final int logosStars;
  final int mathStars;
  final int sciencesStars;

  @override
  Widget build(BuildContext context) {
    final subjects = [
      ('🏛️', l10n.subjectStripCapitals, capitalsStars, AppColors.capitalsColor),
      ('🚩', l10n.subjectStripFlags, 0, AppColors.error),
      ('🏷️', l10n.subjectStripLogos, logosStars, AppColors.logosColor),
      ('🔬', l10n.subjectStripSciences, sciencesStars, const Color(0xFFC47AC0)),
      ('🔢', l10n.subjectStripMath, mathStars, const Color(0xFF2C63B3)),
    ];

    return Row(
      children: subjects.map((s) {
        final emoji = s.$1;
        final stars = s.$3;
        final color = s.$4;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: stars > 0 ? color.withAlpha(100) : AppColors.glassBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 10,
                    color: i < stars ? AppColors.secondary : AppColors.divider,
                  )),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// Glow Progress Strip
// =============================================================================

class _GlowProgressStrip extends StatelessWidget {
  const _GlowProgressStrip({
    required this.l10n,
    required this.totalCorrect,
    required this.progress,
    required this.streakDays,
  });

  final AppLocalizations l10n;
  final int totalCorrect;
  final double progress;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                l10n.homeCorrectTotalLabel,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const Spacer(),
              if (streakDays > 0) ...[
                Text(
                  '🔥 ${l10n.homeStreakLabel(streakDays)}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '$totalCorrect / ${AchievementState.maxCorrectForProgress}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Glow-Track progress bar
          Stack(
            children: [
              // Track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Active fill
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => FractionallySizedBox(
                  widthFactor: val.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: AppColors.progressGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(120),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeProgressPercent((progress * 100).toInt()),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Glass Module Card
// =============================================================================

class _GlassModuleCard extends StatefulWidget {
  const _GlassModuleCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accentColor,
    required this.route,
    required this.stars,
    required this.showStars,
    required this.delay,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final Color accentColor;
  final String route;
  final int stars;
  final bool showStars;
  final int delay;

  @override
  State<_GlassModuleCard> createState() => _GlassModuleCardState();
}

class _GlassModuleCardState extends State<_GlassModuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _hoverCtrl,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: GestureDetector(
          onTapDown: (_) => _hoverCtrl.forward(),
          onTapUp: (_) {
            _hoverCtrl.reverse();
            context.go(widget.route);
          },
          onTapCancel: () => _hoverCtrl.reverse(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.accentColor.withAlpha(50),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon with glow halo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withAlpha(25),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withAlpha(60),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.textMedium,
                          ),
                          maxLines: 2,
                        ),
                        if (widget.showStars) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(3, (i) {
                              return Icon(
                                i < widget.stars
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: i < widget.stars
                                    ? AppColors.secondary
                                    : AppColors.surfaceContainerHighest,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.accentColor,
                      size: 14,
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

// =============================================================================
// Recap queue card
// =============================================================================

class _RecapCard extends StatelessWidget {
  const _RecapCard({
    required this.l10n,
    required this.count,
    required this.onStart,
  });

  final AppLocalizations l10n;
  final int count;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Text('🔄', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeRecapTitle,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeRecapBody(count),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onStart,
            child: Text(
              l10n.homeRecapStart,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Daily Mission Card
// =============================================================================

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard({
    required this.l10n,
    required this.mission,
  });

  final AppLocalizations l10n;
  final DailyMissionData mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.7, -0.7),
          end: Alignment(-0.7, 0.7),
          colors: [Color(0xFFE9C349), Color(0xFFAF8D11)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dailyMissionTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  Text(
                    dailyMissionSubtitle(l10n, DateTime.now(), mission),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A1628).withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go(mission.route),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withAlpha(30),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  dailyMissionCta(l10n, mission),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A1628),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Glass Pill helper (for top bar actions)
// =============================================================================

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: child,
      ),
    );
  }
}

Future<void> _startRecapSession(BuildContext context, WidgetRef ref) async {
  await ref.read(recapQueueProvider.future);
  final notifier = ref.read(recapQueueProvider.notifier);
  final entries = notifier.entriesForFirstModule();
  if (entries.isEmpty || !context.mounted) return;
  ref.read(recapArmProvider.notifier).arm(RecapArm(entries: entries));
  await notifier.removeEntries(entries);
  if (!context.mounted) return;
  switch (entries.first.module) {
    case RecapModule.capitals:
      context.go(AppRoutes.capitalsQuiz);
      return;
    case RecapModule.flags:
      context.go(AppRoutes.flagsQuiz);
      return;
    case RecapModule.sciences:
      context.go(AppRoutes.sciencesQuiz);
      return;
    case RecapModule.math:
      context.go(AppRoutes.mathQuiz);
      return;
    case RecapModule.maps:
      context.go('${AppRoutes.maps}?recap=1');
      return;
  }
}

void _showKidSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
          child: Consumer(
            builder: (context, ref, _) {
              final s =
                  ref.watch(appSettingsProvider).value ?? const AppSettings();
              final l10n = context.l10n;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.settingsParentTitle,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    title: Text(l10n.settingsSoundTitle),
                    subtitle: Text(l10n.settingsSoundSubtitle),
                    value: s.soundEnabled,
                    onChanged: (v) async {
                      await ref
                          .read(appSettingsProvider.notifier)
                          .setSoundEnabled(v);
                      ref.read(audioServiceProvider).updateMuteStatus(!v);
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsReducedMotionTitle),
                    subtitle: Text(l10n.settingsReducedMotionSubtitle),
                    value: s.reducedMotion,
                    onChanged: (v) => ref
                        .read(appSettingsProvider.notifier)
                        .setReducedMotion(v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsCoPlayTitle),
                    subtitle: Text(l10n.settingsCoPlaySubtitle),
                    value: s.coPlayMode,
                    onChanged: (v) =>
                        ref.read(appSettingsProvider.notifier).setCoPlayMode(v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsPracticeTitle),
                    subtitle: Text(l10n.settingsPracticeSubtitle),
                    value: s.practiceMode,
                    onChanged: (v) => ref
                        .read(appSettingsProvider.notifier)
                        .setPracticeMode(v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.save_alt_rounded),
                    title: Text(l10n.settingsExportTitle),
                    subtitle: Text(l10n.settingsExportSubtitle),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await shareLocalProgressJson(context, ref);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload_file_rounded),
                    title: Text(l10n.settingsImportTitle),
                    subtitle: Text(l10n.settingsImportSubtitle),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await importLocalProgressFromFile(context, ref);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
