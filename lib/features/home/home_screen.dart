import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/agents/learning_path.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/l10n/gendered_ar.dart';
import 'package:aziz_academy/core/logic/daily_mission.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/daily_challenge_provider.dart';
import 'package:aziz_academy/core/providers/daily_login_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_activity_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/providers/recap_arm_provider.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/local_backup_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/utils/hijri_date.dart';
import 'package:aziz_academy/core/widgets/level_header.dart';
import 'package:aziz_academy/core/widgets/onboarding_overlay.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

import 'package:aziz_academy/features/admin/admin_feedback.dart';
import 'package:aziz_academy/features/home/widgets/did_you_know_card.dart';
import 'package:aziz_academy/features/home/widgets/home_footer_stack.dart';
import 'package:aziz_academy/features/home/widgets/smart_app_bar.dart';
import 'package:aziz_academy/features/home/widgets/starfield_background.dart';
import 'activity_catalog.dart';
import 'package:aziz_academy/core/widgets/kid_emoji.dart';

// =============================================================================
// SmartHomeScreen — the redesigned hub.
//
// Layout (top → bottom):
//   1. Compact app bar — logo + brand + level chip + coins/streak + trophy +
//      language + sound + overflow.
//   2. Smart greeting — "Good morning, explorer" + Hijri date pill.
//   3. Smart picks rail — horizontal cards for Recap, Daily Mission, Daily
//      Challenge, Next-Up, Daily Verse. Empty cards self-hide.
//   4. Search bar — type to filter the whole catalog instantly.
//   5. Sticky category tabs — Featured · Learn · Words · Math · Brain ·
//      Action · Versus · Islamic · Tools.
//   6. Responsive grid — activity cards from `activity_catalog.dart`.
//   7. Footer — settings sheet, parent area, about/privacy.
// =============================================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;
  late final TextEditingController _searchCtrl;
  String _query = '';
  _Tab _tab = _Tab.featured;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _searchCtrl = TextEditingController();

    // Staged first-frame work — ordered to keep TTI snappy:
    //   t+0     record streak (cheap, drives the streak chip in app bar)
    //   t+0     show streak snack if a milestone was hit
    //   t+500   start background music (audio buffer warm-up is heavy)
    //   t+1000  show daily-bonus dialog (don't interrupt the kid's first
    //           glance at the home; let them see it before a modal lands)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final beforeStreak =
          ref.read(achievementProvider).value?.streakCount ?? 0;
      await ref.read(achievementProvider.notifier).recordDailyVisit();
      if (!mounted) return;
      final afterStreak = ref.read(achievementProvider).value?.streakCount ?? 0;
      // Record this launch against the active profile's own activity log —
      // per-profile, unlike the device-wide streak above.
      await ref.read(profileActivityProvider.notifier).recordActivity();
      if (!mounted) return;
      if (afterStreak > beforeStreak &&
          const {3, 7, 14, 30, 60, 100}.contains(afterStreak)) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('🔥 ${context.l10n.streakSnack(afterStreak)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    });

    // Audio warm-up — defer past first paint so it doesn't compete with
    // the layout / rasterizer threads. 500 ms is enough for the home to
    // settle and the kid to register what they're looking at.
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      ref.read(audioServiceProvider).startBgm();
      try {
        await ref.read(appSettingsProvider.future);
        final s = ref.read(appSettingsProvider).value;
        if (s != null) {
          ref.read(audioServiceProvider).updateMuteStatus(!s.soundEnabled);
        }
      } catch (_) {}
    });

    // Daily bonus dialog — wait long enough that the kid sees the home
    // first. Otherwise it feels like every launch starts with a popup.
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      await _maybeShowDailyBonus();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShowDailyBonus() async {
    if (!mounted) return;
    final daily = await ref.read(dailyLoginProvider.future);
    if (!daily.canClaimToday || !mounted) return;
    final isAr = ref.read(localeProvider).value?.languageCode == 'ar';
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? '🎁 مكافأة الدخول اليومي' : '🎁 Daily Bonus',
          textAlign: TextAlign.center,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🪙  +${daily.pendingReward}',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'سلسلتك: ${daily.streak + 1} يوم'
                  : 'Streak: ${daily.streak + 1} days',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(dailyLoginProvider.notifier).claimToday();
            },
            child: Text(isAr ? 'استلم' : 'Claim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final reviewCounts = ref.watch(moduleReviewCountProvider);
    final showOnboarding =
        ref.watch(appSettingsProvider).value?.onboardingCompleted == false;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _SurpriseMeFab(isArabic: isArabic),
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SmartAppBar(
                          isArabic: isArabic,
                          onOverflow: () =>
                              _showOverflowMenu(context, ref, isArabic),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _GreetingHeader(isArabic: isArabic),
                      ),
                      SliverToBoxAdapter(
                        child: _SmartPicksRail(isArabic: isArabic),
                      ),
                      SliverToBoxAdapter(
                        child: _RecentlyPlayedRail(isArabic: isArabic),
                      ),
                      SliverToBoxAdapter(
                        child: DidYouKnowCard(isArabic: isArabic),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: _SearchBar(
                            controller: _searchCtrl,
                            isArabic: isArabic,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTabsDelegate(
                          tab: _tab,
                          isArabic: isArabic,
                          onTab: (t) => setState(() => _tab = t),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        sliver: _ActivityGrid(
                          tab: _tab,
                          query: _query,
                          isArabic: isArabic,
                          reviewCounts: reviewCounts,
                          onJumpToCategory: (cat) {
                            _searchCtrl.clear();
                            setState(() {
                              _query = '';
                              _tab = _tabForCategory(cat);
                            });
                          },
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        sliver: SliverToBoxAdapter(
                          child: HomeFooterStack(isArabic: isArabic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showOnboarding) const Positioned.fill(child: OnboardingOverlay()),
        ],
      ),
    );
  }
}

// 1. Smart App Bar — extracted to `widgets/smart_app_bar.dart` in
//    v1.1.97 (SmartAppBar / CoinsStreakChip / PillIcon). The overflow
//    menu callback stays here because `_showOverflowMenu` threads
//    through too many local navigation helpers.

// =============================================================================
// 2. Greeting Header — friendly title + Hijri pill + level row.
// =============================================================================

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({required this.isArabic});
  final bool isArabic;

  String _greeting(BuildContext context, bool ar, String name, String gender) {
    final h = DateTime.now().hour;
    // Use the kid's stored display name when present; fall back to a friendly
    // pet name ("مكتشف" / "explorer") when the profile is anonymous. Keeps
    // the home screen feeling personal once onboarding is complete without
    // greeting the kid as "Friend"/"صديق" forever. The Arabic pet name is
    // gendered so a girl is greeted "مكتشفة", not "مكتشف".
    final addressee = name.trim().isEmpty
        ? (ar ? 'يا ${GenderedAr(gender).explorer}' : 'explorer')
        : name.trim();
    if (ar) {
      if (h < 12) return 'صباح الخير، $addressee 🌞';
      if (h < 17) return 'مرحبًا بعودتك يا $addressee 👋';
      return 'مساء الخير يا $addressee 🌙';
    }
    if (h < 12) return 'Good morning, $addressee 🌞';
    if (h < 17) return 'Welcome back, $addressee 👋';
    return 'Good evening, $addressee 🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakDays = ref.watch(achievementProvider).value?.streakCount ?? 0;
    final profile = ref.watch(profileProvider).value;
    final displayName = profile?.displayName ?? '';
    final gender = profile?.gender ?? Gender.unset;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(context, isArabic, displayName, gender),
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'النجوم في صفّك اليوم — ابدأ بنشاط ذكي'
                : 'The stars are aligned — start with a smart pick',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          LevelHeader(streakDays: streakDays),
          const SizedBox(height: 8),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: HijriDatePill(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. Smart Picks Rail — horizontal scroll of personalised entry points.
// =============================================================================

class _SmartPicksRail extends ConsumerWidget {
  const _SmartPicksRail({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapCount = ref.watch(recapQueueProvider).value?.length ?? 0;
    final struggling = ref.watch(strugglingCountProvider);
    final dailyDone =
        ref.watch(dailyChallengeProvider).value?.isCompleted ?? false;
    final mission = dailyMissionFor(DateTime.now());
    final learner = ref.watch(learnerStateProvider).value;
    final nextPick = (learner != null && learner.totalSessions >= 2)
        ? nextUp(learner, arabic: isArabic, limit: 1).firstOrNull
        : null;
    final brainBoost = ref.watch(brainBoostDailyProvider).value;
    final brainBoostDone = brainBoost?.todayCompleted ?? false;

    // Most-recent activity — only surfaces if the kid actually played
    // something in the last 24 hours, otherwise it feels stale.
    Activity? continueAct;
    if (learner != null && learner.recentSessions.isNotEmpty) {
      final last = learner.recentSessions.first;
      if (DateTime.now().difference(last.endedAt).inHours < 24) {
        continueAct = activityById(last.module);
      }
    }

    final picks = <Widget>[
      if (continueAct != null)
        _PickCard(
          title: isArabic ? 'تابع من حيث وصلت' : 'Continue',
          subtitle: continueAct.title(ar: isArabic),
          emoji: continueAct.emoji,
          accent: continueAct.accent,
          onTap: () => context.go(continueAct!.route),
          wide: true,
        ),
      _PickCard(
        title: isArabic ? 'تحدي اليوم' : 'Daily Challenge',
        subtitle: dailyDone
            ? (isArabic ? 'تم اليوم — رائع!' : 'Done today — nice!')
            : (isArabic ? '×٢ نقاط خبرة' : '2× XP today'),
        emoji: '⚡',
        accent: AppColors.secondary,
        onTap: () => context.go(AppRoutes.dailyChallenge),
        done: dailyDone,
        wide: continueAct == null,
      ),
      _PickCard(
        title: isArabic ? 'مهمة اليوم' : 'Today\'s Mission',
        subtitle: dailyMissionSubtitle(
          AppLocalizations.of(context)!,
          DateTime.now(),
          mission,
        ),
        emoji: '🌟',
        accent: AppColors.warning,
        onTap: () => context.go(mission.route),
      ),
      if (recapCount > 0)
        _PickCard(
          title: isArabic ? 'مراجعة سريعة' : 'Recap Round',
          subtitle: isArabic
              ? '$recapCount سؤالًا في الانتظار'
              : '$recapCount waiting for review',
          emoji: '🔄',
          accent: AppColors.primary,
          onTap: () => _startRecapSession(context, ref),
        ),
      if (struggling > 0)
        _PickCard(
          title: isArabic ? 'الأسئلة الصعبة' : 'Tricky Ones',
          subtitle: isArabic
              ? '$struggling سؤالًا تستحق التكرار'
              : '$struggling worth repeating',
          emoji: '🔥',
          accent: AppColors.error,
          onTap: () => context.go(AppRoutes.reviewMode),
        ),
      if (nextPick != null)
        _PickCard(
          title: isArabic ? 'التالي لك' : 'Next for you',
          subtitle: nextPick.title,
          emoji: nextPick.emoji,
          accent: AppColors.primary,
          onTap: () => context.go(nextPick.route),
        ),
      _PickCard(
        title: isArabic ? 'تمرين العقل' : 'Brain Boost',
        subtitle: brainBoostDone
            ? (isArabic ? 'تم اليوم 🔥' : 'Done today 🔥')
            : (isArabic ? '٥ أسئلة ذكاء يوميًا' : '5 daily IQ questions'),
        emoji: '🧠',
        accent: const Color(0xFFC47AC0),
        onTap: () => context.go(AppRoutes.brainBoostDaily),
        done: brainBoostDone,
      ),
      _PickCard(
        title: isArabic ? 'آية اليوم' : 'Verse of the Day',
        subtitle: isArabic ? 'افتح للقراءة' : 'Open to read',
        emoji: '📖',
        accent: AppColors.warning,
        onTap: () => context.go(AppRoutes.quran),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: picks.length,
          separatorBuilder: (ctx, i) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) => picks[i],
        ),
      ),
    );
  }
}

// =============================================================================
// "Surprise me" FAB — picks a random activity from the catalog (biased away
// from the last 8 modules played so it actually feels like a surprise) and
// jumps straight in. Lightweight discovery without leaving the home screen.
// =============================================================================

class _SurpriseMeFab extends ConsumerWidget {
  const _SurpriseMeFab({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      heroTag: 'surprise_me_fab',
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.background,
      icon: KidEmoji.named('game_die', size: 22),
      label: Text(
        isArabic ? 'فاجئني' : 'Surprise me',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
        ),
      ),
      onPressed: () {
        final learner = ref.read(learnerStateProvider).value;
        final recentIds = (learner?.recentSessions ?? const [])
            .take(8)
            .map((s) => s.module)
            .toSet();
        final pool = kActivities
            .where((a) => !recentIds.contains(a.id))
            .toList();
        final picks = pool.isEmpty ? kActivities : pool;
        final pick = picks[math.Random().nextInt(picks.length)];
        HapticFeedback.lightImpact();
        // Kid-friendly "going to..." flash so the choice feels personal,
        // not random.
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.clearSnackBars();
        messenger?.showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1200),
            backgroundColor: AppColors.surfaceContainerLow,
            content: Row(
              children: [
                Text(pick.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.surpriseGoingTo(
                      isArabic ? pick.titleAr : pick.titleEn,
                    ),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        context.push(pick.route);
      },
    );
  }
}

// =============================================================================
// "Did you know?" — a daily-rotating fun fact. Bilingual, kid-safe, 20-fact
// pool seeded by the calendar day. Shows a single line so it doesn't fight
// the activity grid for attention.
// =============================================================================

// _DidYouKnowCard extracted to lib/features/home/widgets/did_you_know_card.dart in v1.1.95.

// =============================================================================
// 3b. Recently Played — last 5 distinct activities the kid has actually used.
// Pulls from LearnerState.recentSessions; self-hides when empty.
// =============================================================================

class _RecentlyPlayedRail extends ConsumerWidget {
  const _RecentlyPlayedRail({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerStateProvider).value;
    if (learner == null || learner.recentSessions.isEmpty) {
      return const SizedBox.shrink();
    }
    final seen = <String>{};
    final recent = <Activity>[];
    for (final s in learner.recentSessions) {
      if (seen.contains(s.module)) continue;
      final a = activityById(s.module);
      if (a == null) continue;
      seen.add(s.module);
      recent.add(a);
      if (recent.length >= 5) break;
    }
    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                KidEmoji.named('clock', size: 16),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'لعبت مؤخرًا' : 'Recently played',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recent.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final a = recent[i];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.go(a.route);
                  },
                  child: Container(
                    width: 78,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: a.accent.withAlpha(60)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            a.title(ar: isArabic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCard extends StatefulWidget {
  const _PickCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accent,
    required this.onTap,
    this.wide = false,
    this.done = false,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final Color accent;
  final VoidCallback onTap;
  final bool wide;
  final bool done;

  @override
  State<_PickCard> createState() => _PickCardState();
}

class _PickCardState extends State<_PickCard> {
  // Tap-press depress only — these cards live inside a horizontal rail, so
  // no hover-lift (that would shift the rail's vertical baseline on every
  // mouse move). 0.96 matches the press scale used on the activity grid
  // tiles so all home tappables share the same tactile vocabulary.
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final done = widget.done;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: widget.wide ? 240 : 210,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withAlpha(done ? 30 : 60),
                AppColors.surfaceContainerLow,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withAlpha(done ? 50 : 130),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(done ? 10 : 50),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                  const Spacer(),
                  if (done)
                    Icon(Icons.check_circle_rounded, color: accent, size: 22),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 4. Search Bar — filters the catalog grid.
// =============================================================================

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isArabic,
    required this.onChanged,
  });
  final TextEditingController controller;
  final bool isArabic;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: AppColors.textMedium),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: isArabic
                    ? 'ابحث عن نشاط — مثلًا: عواصم، حساب، قرآن…'
                    : 'Search activities — capitals, math, quran…',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textMedium,
              ),
              tooltip: isArabic ? 'مسح البحث' : 'Clear search',
              onPressed: () {
                controller.clear();
                onChanged('');
                FocusScope.of(context).unfocus();
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. Sticky Tabs — Featured / Learn / Words / Math / ...
// =============================================================================

enum _Tab { featured, learn, games, islamic, tools }

/// Categories that fold into the single "Games" tab. Keeps the home shelf
/// uncluttered: kids see one section for everything playable, instead of
/// five near-identical pill rows (Words/Math/Brain/Action/Versus).
const Set<ActivityCategory> _gameCategories = {
  ActivityCategory.words,
  ActivityCategory.math,
  ActivityCategory.brain,
  ActivityCategory.action,
  ActivityCategory.versus,
};

ActivityCategory? _categoryForTab(_Tab tab) {
  switch (tab) {
    case _Tab.featured:
    case _Tab.games:
      return null;
    case _Tab.learn:
      return ActivityCategory.learn;
    case _Tab.islamic:
      return ActivityCategory.islamic;
    case _Tab.tools:
      return ActivityCategory.tools;
  }
}

String _tabLabel(_Tab tab, bool ar) {
  switch (tab) {
    case _Tab.featured:
      return ar ? 'مختارات' : 'Featured';
    case _Tab.learn:
      return ar ? 'تعلَّم' : 'Learn';
    case _Tab.games:
      return ar ? 'ألعاب' : 'Games';
    case _Tab.islamic:
      return ar ? 'إسلامي' : 'Islamic';
    case _Tab.tools:
      return ar ? 'الأدوات' : 'Tools';
  }
}

String _tabEmoji(_Tab tab) {
  switch (tab) {
    case _Tab.featured:
      return '⭐';
    case _Tab.learn:
      return '📚';
    case _Tab.games:
      return '🎮';
    case _Tab.islamic:
      return '🕌';
    case _Tab.tools:
      return '⚙️';
  }
}

/// Pre-computed activity count for each tab (Featured uses total).
int _tabCount(_Tab tab) {
  if (tab == _Tab.featured) return kActivities.length;
  if (tab == _Tab.games) {
    return kActivities
        .where((a) => _gameCategories.contains(a.category))
        .length;
  }
  final cat = _categoryForTab(tab);
  if (cat == null) return kActivities.length;
  var n = 0;
  for (final a in kActivities) {
    if (a.category == cat) n++;
  }
  return n;
}

_Tab _tabForCategory(ActivityCategory c) {
  switch (c) {
    case ActivityCategory.learn:
      return _Tab.learn;
    case ActivityCategory.islamic:
      return _Tab.islamic;
    case ActivityCategory.tools:
      return _Tab.tools;
    case ActivityCategory.words:
    case ActivityCategory.math:
    case ActivityCategory.brain:
    case ActivityCategory.action:
    case ActivityCategory.versus:
      return _Tab.games;
  }
}

/// Pick up to 4 categories whose label or contents loosely match the query.
/// Falls back to the four big buckets when nothing matches.
List<ActivityCategory> _suggestCategories(String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) {
    return const [
      ActivityCategory.learn,
      ActivityCategory.brain,
      ActivityCategory.action,
      ActivityCategory.islamic,
    ];
  }
  final scored = <ActivityCategory, int>{};
  for (final cat in ActivityCategory.values) {
    var score = 0;
    if (cat.labelEn().toLowerCase().contains(q)) score += 5;
    if (cat.labelAr().contains(q)) score += 5;
    for (final a in kActivities.where((x) => x.category == cat)) {
      if (a.titleEn.toLowerCase().contains(q) ||
          a.subtitleEn.toLowerCase().contains(q) ||
          a.titleAr.contains(q) ||
          a.subtitleAr.contains(q)) {
        score += 1;
      }
    }
    if (score > 0) scored[cat] = score;
  }
  if (scored.isEmpty) {
    return const [
      ActivityCategory.learn,
      ActivityCategory.brain,
      ActivityCategory.action,
      ActivityCategory.islamic,
    ];
  }
  final sorted = scored.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(4).map((e) => e.key).toList();
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({
    required this.category,
    required this.isArabic,
    required this.onTap,
  });

  final ActivityCategory category;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji(), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              isArabic ? category.labelAr() : category.labelEn(),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabsDelegate({
    required this.tab,
    required this.isArabic,
    required this.onTab,
  });

  final _Tab tab;
  final bool isArabic;
  final ValueChanged<_Tab> onTab;

  static const _h = 56.0;

  @override
  double get minExtent => _h;
  @override
  double get maxExtent => _h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background.withAlpha(240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _Tab.values.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final t = _Tab.values[i];
          final selected = t == tab;
          final count = _tabCount(t);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTab(t);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.goldGradient : null,
                color: selected ? null : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected ? Colors.transparent : AppColors.glassBorder,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tabEmoji(t), style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    _tabLabel(t, isArabic),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: selected
                          ? const Color(0xFF0A1628)
                          : AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0A1628).withAlpha(45)
                          : AppColors.surfaceContainerHigh.withAlpha(140),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      localizeDigitsCtx(count, context),
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? const Color(0xFF0A1628)
                            : AppColors.textMedium,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabsDelegate oldDelegate) =>
      oldDelegate.tab != tab || oldDelegate.isArabic != isArabic;
}

// =============================================================================
// 6. Activity Grid — filtered by tab + search query.
// =============================================================================

class _ActivityGrid extends ConsumerWidget {
  const _ActivityGrid({
    required this.tab,
    required this.query,
    required this.isArabic,
    required this.reviewCounts,
    required this.onJumpToCategory,
  });

  final _Tab tab;
  final String query;
  final bool isArabic;
  final Map<RecapModule, int> reviewCounts;
  final ValueChanged<ActivityCategory> onJumpToCategory;

  /// Personalised Featured curation:
  ///   1. Anything the kid played in the last 5 sessions (by module id)
  ///   2. Their two weakest modules (so practice surfaces naturally)
  ///   3. Anything flagged `featured: true` in the catalog
  ///   4. A handful of safe defaults (general, blitz, sudoku, quran...)
  ///
  /// Each entry is paired with a short reason chip so the personalisation
  /// is visible to the kid ("Recently played", "Worth practicing", ...).
  List<({Activity activity, _PickReason reason})> _featuredFor(
    LearnerState? learner,
  ) {
    final out = <({Activity activity, _PickReason reason})>[];
    final seen = <String>{};
    void add(Activity? a, _PickReason r) {
      if (a == null || !seen.add(a.id)) return;
      out.add((activity: a, reason: r));
    }

    if (learner != null) {
      for (final s in learner.recentSessions.take(5)) {
        add(activityById(s.module), _PickReason.recent);
      }
      for (final m in learner.weakestModules(limit: 2)) {
        add(activityById(m), _PickReason.practice);
      }
    }

    for (final a in kActivities.where((a) => a.featured)) {
      add(a, _PickReason.featured);
    }

    // Daily discovery rotation: surface 5 never-played activities so the long
    // tail of the 130+ catalog stays reachable. Seeded on day-of-year so the
    // picks are stable through the day but rotate every day.
    final played = <String>{};
    if (learner != null) {
      for (final s in learner.recentSessions) {
        played.add(s.module);
      }
    }
    final neverPlayed = kActivities
        .where((a) => !played.contains(a.id) && !seen.contains(a.id))
        .toList();
    if (neverPlayed.isNotEmpty) {
      final today = DateTime.now();
      final daySeed = today.year * 1000 + today.month * 32 + today.day;
      final rng = math.Random(daySeed);
      neverPlayed.shuffle(rng);
      for (final a in neverPlayed.take(5)) {
        add(a, _PickReason.discover);
      }
    }

    const safeDefaults = [
      'general_quiz',
      'blitz',
      'iq',
      'true_false',
      'random_quiz',
      'quran',
      'athkar',
      'madrasati',
      'sudoku',
      'memory_match',
      'spelling',
      'times_tables',
    ];
    for (final id in safeDefaults) {
      add(activityById(id), _PickReason.discover);
    }
    return out;
  }

  List<({Activity activity, _PickReason reason})> _resolveActivities(
    LearnerState? learner,
  ) {
    if (tab == _Tab.featured && query.isEmpty) {
      return _featuredFor(learner);
    }
    Iterable<Activity> base = kActivities;
    if (tab == _Tab.games) {
      base = base.where((a) => _gameCategories.contains(a.category));
      if (query.isNotEmpty) {
        base = base.where((a) => a.matches(query));
      }
    } else {
      base = filterActivities(category: _categoryForTab(tab), query: query);
    }
    return base.map((a) => (activity: a, reason: _PickReason.none)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerStateProvider).value;
    final list = _resolveActivities(learner);
    if (list.isEmpty) {
      // When the search returns nothing, suggest the closest category match
      // by partial name. Falls back to the four big buckets.
      final suggestions = _suggestCategories(query);
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              KidEmoji.named('magnifier', size: 40),
              const SizedBox(height: 12),
              Text(
                isArabic
                    ? 'لم نجد نشاطًا بهذا الاسم'
                    : 'No activity matches that.',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic ? 'جرّب فئة قريبة:' : 'Try a nearby category:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in suggestions)
                    _SuggestionPill(
                      category: c,
                      isArabic: isArabic,
                      onTap: () => onJumpToCategory(c),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 122,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      delegate: SliverChildBuilderDelegate((_, i) {
        final entry = list[i];
        final a = entry.activity;
        final review = a.recapModule == null
            ? 0
            : (reviewCounts[a.recapModule] ?? 0);
        return _ActivityCard(
          key: ValueKey('act-${a.id}'),
          activity: a,
          isArabic: isArabic,
          reviewCount: review,
          reason: entry.reason,
        );
      }, childCount: list.length),
    );
  }
}

/// Why an activity is appearing in the Featured strip. Drives a small chip on
/// the card so kids can see the personalisation is real.
enum _PickReason { none, recent, practice, featured, discover }

extension _PickReasonX on _PickReason {
  String? labelEn() {
    switch (this) {
      case _PickReason.recent:
        return 'Recently played';
      case _PickReason.practice:
        return 'Worth practicing';
      case _PickReason.featured:
        return 'Hand-picked';
      case _PickReason.discover:
        return 'Try this';
      case _PickReason.none:
        return null;
    }
  }

  String? labelAr() {
    switch (this) {
      case _PickReason.recent:
        return 'لعبت مؤخرًا';
      case _PickReason.practice:
        return 'يستحق التدريب';
      case _PickReason.featured:
        return 'مختار لك';
      case _PickReason.discover:
        return 'جرّب هذا';
      case _PickReason.none:
        return null;
    }
  }

  Color color() {
    switch (this) {
      case _PickReason.recent:
        return AppColors.secondary;
      case _PickReason.practice:
        return AppColors.error;
      case _PickReason.featured:
        return AppColors.warning;
      case _PickReason.discover:
        return AppColors.primary;
      case _PickReason.none:
        return AppColors.divider;
    }
  }
}

class _ActivityCard extends ConsumerStatefulWidget {
  const _ActivityCard({
    super.key,
    required this.activity,
    required this.isArabic,
    required this.reviewCount,
    this.reason = _PickReason.none,
  });

  final Activity activity;
  final bool isArabic;
  final int reviewCount;
  final _PickReason reason;

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard>
    with TickerProviderStateMixin {
  // Two animation channels so hover-lift and tap-depress don't fight:
  // hover slowly scales UP (1.0 → 1.025); press quickly scales DOWN
  // (1.0 → 0.97) for a tactile "button is being pushed" feel that's
  // closer to native iOS/Material Press states.
  late final AnimationController _hoverCtrl;
  late final AnimationController _pressCtrl;
  late final Animation<double> _hoverScale;
  late final Animation<double> _hoverLift;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _hoverScale = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
    _hoverLift = Tween<double>(
      begin: 0.0,
      end: -3.0,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        ref.watch(appSettingsProvider).value?.reducedMotion ?? false;
    final a = widget.activity;
    final ar = widget.isArabic;
    return MouseRegion(
      onEnter: (_) {
        if (!reducedMotion) _hoverCtrl.forward();
      },
      onExit: (_) {
        if (!reducedMotion) _hoverCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverCtrl, _pressCtrl]),
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _hoverLift.value),
          child: Transform.scale(
            scale: _hoverScale.value * _pressScale.value,
            child: child,
          ),
        ),
        child: GestureDetector(
          onTapDown: (_) {
            if (!reducedMotion) _pressCtrl.forward();
          },
          onTapUp: (_) {
            if (!reducedMotion) _pressCtrl.reverse();
            HapticFeedback.selectionClick();
            context.go(a.route);
          },
          onTapCancel: () {
            if (!reducedMotion) _pressCtrl.reverse();
          },
          child: Container(
            decoration: BoxDecoration(
              // Subtle accent-tinted vertical gradient so each tile reads as
              // its module's colour instead of a uniform slab. The top stop
              // carries the accent at low alpha; the bottom lands on the
              // standard surface so text contrast stays unchanged.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    a.accent.withAlpha(22),
                    AppColors.surfaceContainerLow,
                  ),
                  AppColors.surfaceContainerLow,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: a.accent.withAlpha(60)),
              boxShadow: [
                BoxShadow(
                  color: a.accent.withAlpha(36),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.accent.withAlpha(25),
                      boxShadow: [
                        BoxShadow(
                          color: a.accent.withAlpha(50),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        a.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                a.title(ar: ar),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (widget.reason != _PickReason.none) ...[
                              const SizedBox(width: 6),
                              _ReasonChip(reason: widget.reason, isArabic: ar),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          a.subtitle(ar: ar),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textMedium,
                            height: 1.3,
                          ),
                        ),
                        if (widget.reviewCount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withAlpha(100),
                              ),
                            ),
                            child: Text(
                              ar
                                  ? 'مراجعة: ${widget.reviewCount}'
                                  : 'Review: ${widget.reviewCount}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _hoverCtrl,
                    builder: (context, child) {
                      // Slide the chevron in the page-reading direction by
                      // up to 3 px while the card is hovered. Reads as a
                      // "ready to navigate" cue — RTL gets the mirrored sign
                      // so the chevron always slides toward where the route
                      // is conceptually going.
                      final dx =
                          (Directionality.of(context) == TextDirection.rtl
                              ? -1
                              : 1) *
                          3.0 *
                          _hoverCtrl.value;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: a.accent.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: a.accent,
                        size: 13,
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

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.reason, required this.isArabic});

  final _PickReason reason;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final label = isArabic ? reason.labelAr() : reason.labelEn();
    if (label == null) return const SizedBox.shrink();
    final color = reason.color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Footer (daily banners + mood + Madrasati shortcut) extracted to
// lib/features/home/widgets/home_footer_stack.dart in v1.1.94.

// =============================================================================
// Starfield Background — subtle decoration only.
// =============================================================================

// _StarfieldBackground + _StarfieldPainter extracted to
// lib/features/home/widgets/starfield_background.dart in v1.1.95.

// =============================================================================
// Recap session helper — kept verbatim from the previous home so the smart
// pick "Recap Round" still arms the right module.
// =============================================================================

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

// =============================================================================
// Overflow menu — settings, profile, account, parent, privacy, about, dev.
//
// Two identity hubs only: "My Profile" (the child — card, edit, siblings) and
// "Account" (the parent — sign-in, cloud backup, Plus). Family profiles and
// profile editing live inside the Profile hub, not as competing top-level
// menu entries.
// =============================================================================

void _showOverflowMenu(BuildContext context, WidgetRef ref, bool isArabic) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLow,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.78,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(isArabic ? 'الإعدادات' : 'Settings'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showKidSettingsSheet(context, ref);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.feedback_rounded,
                      color: AppColors.secondary,
                    ),
                    title: Text(
                      isArabic ? 'إرسال ملاحظة' : 'Send feedback',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      isArabic ? 'أخبرنا برأيك' : 'Tell us what you think',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showFeedbackSheet(context, ref, isArabic);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded),
                    title: Text(isArabic ? 'إحصائياتي' : 'My Stats'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.stats);
                    },
                  ),
                  // "My Profile" is reached from the home grid (Tools);
                  // "Parent account" lives here — one home each, no overlap.
                  ListTile(
                    leading: const Icon(Icons.account_circle_rounded),
                    title: Text(isArabic ? 'حساب الوالدين' : 'Parent account'),
                    subtitle: Text(
                      isArabic
                          ? 'تسجيل الدخول والنسخ الاحتياطي'
                          : 'Sign in & cloud backup',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.account);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.error,
                    ),
                    title: Text(isArabic ? 'المفضلة' : 'My Favorites'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.favorites);
                    },
                  ),
                  ListTile(
                    leading: const Text('🛒', style: TextStyle(fontSize: 22)),
                    title: Text(isArabic ? 'المتجر' : 'Shop'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.shop);
                    },
                  ),
                  ListTile(
                    leading: const Text('🎁', style: TextStyle(fontSize: 22)),
                    title: Text(isArabic ? 'غرفة الكنز' : 'Treasure Room'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.treasure);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shield_moon_rounded),
                    title: Text(isArabic ? 'ركن الوالدين' : 'Parent area'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.parent);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(isArabic ? 'الخصوصية' : 'Privacy'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.privacy);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(isArabic ? 'عن التطبيق' : 'About'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(AppRoutes.about);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _showKidSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLow,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
            child: Consumer(
              builder: (context, ref, _) {
                final s =
                    ref.watch(appSettingsProvider).value ?? const AppSettings();
                final l10n = context.l10n;
                return SingleChildScrollView(
                  child: Column(
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
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setCoPlayMode(v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.settingsPracticeTitle),
                        subtitle: Text(l10n.settingsPracticeSubtitle),
                        value: s.practiceMode,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setPracticeMode(v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.settingsDyslexiaFriendlyFont),
                        subtitle: Text(l10n.settingsDyslexiaFriendlyFontDesc),
                        value: s.dyslexiaFont,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setDyslexiaFont(v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.settingsLargerText),
                        subtitle: Text(l10n.settingsLargerTextDesc),
                        value: s.largerText,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setLargerText(v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.settingsShorterRounds),
                        subtitle: Text(l10n.settingsShorterRoundsDesc),
                        value: s.shortRounds,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setShortRounds(v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.settingsLightTheme),
                        subtitle: Text(l10n.settingsLightThemeDesc),
                        value: s.lightMode,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setLightMode(v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.settingsReadAloud),
                        subtitle: const Text(
                          'Auto-narrate every question (TTS)',
                        ),
                        value: s.audioQuiz,
                        onChanged: (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setAudioQuiz(v),
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
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

// =============================================================================
// Feedback sheet — kid/parent submits a note. Persisted via the admin
// feedback inbox provider. Adds zero network calls.
// =============================================================================

void _showFeedbackSheet(BuildContext context, WidgetRef ref, bool isArabic) {
  FeedbackKind selectedKind = FeedbackKind.idea;
  final messageCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLow,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: StatefulBuilder(
              builder: (ctx, setLocal) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.glassBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        isArabic ? 'إرسال ملاحظة' : 'Send feedback',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'تُحفظ الملاحظات على هذا الجهاز فقط — لا تذهب '
                                  'إلى أي خادم خارجي.'
                            : 'Saved on this device only — no external server.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in FeedbackKind.values)
                            GestureDetector(
                              onTap: () => setLocal(() => selectedKind = k),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedKind == k
                                      ? AppColors.secondary.withAlpha(40)
                                      : AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: selectedKind == k
                                        ? AppColors.secondary
                                        : AppColors.glassBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      k.emoji,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      k.label,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: selectedKind == k
                                            ? AppColors.secondary
                                            : AppColors.textDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: messageCtrl,
                        minLines: 4,
                        maxLines: 8,
                        textDirection: isArabic ? TextDirection.rtl : null,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceContainer,
                          hintText: isArabic
                              ? 'اكتب ملاحظتك هنا…'
                              : 'Write your feedback here…',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.glassBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.glassBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fromCtrl,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceContainer,
                                isDense: true,
                                hintText: isArabic
                                    ? 'الاسم (اختياري)'
                                    : 'Name (optional)',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMedium,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: contactCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceContainer,
                                isDense: true,
                                hintText: isArabic
                                    ? 'بريد للرد (اختياري)'
                                    : 'Email (optional)',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMedium,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: const Color(0xFF0A1628),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(isArabic ? 'إرسال' : 'Send'),
                            onPressed: () async {
                              final msg = messageCtrl.text.trim();
                              if (msg.isEmpty) return;
                              await ref
                                  .read(feedbackInboxProvider.notifier)
                                  .submit(
                                    kind: selectedKind,
                                    message: msg,
                                    from: fromCtrl.text,
                                    contact: contactCtrl.text,
                                    context: GoRouter.of(context)
                                        .routeInformationProvider
                                        .value
                                        .uri
                                        .toString(),
                                  );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.feedbackThanks),
                                    backgroundColor: AppColors.secondary,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
