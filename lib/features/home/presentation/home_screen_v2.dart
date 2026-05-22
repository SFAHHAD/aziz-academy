import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/features/home/widgets/profile_strip.dart';
import 'package:aziz_academy/features/home/widgets/hero_category_card.dart';
import 'package:aziz_academy/features/home/widgets/todays_mission_card.dart';

// =============================================================================
// Home screen v2 — calm, kid-friendly, profile-first.
//
// Replaces the wall-of-tiles legacy home_screen.dart with 4 surfaces:
//   1. Profile strip (avatar + level + streak)
//   2. Today's mission (single rotating hero card)
//   3. 5 hero category cards (Learn, Play, Islamic, Brain, More)
//   4. "Did you know?" footer
//
// Activities live inside their categories — tapping a hero card opens a
// dedicated CategoryPage with the existing grid scoped to that category.
//
// Ship behind a feature flag so the legacy home stays available during
// rollout. See REDESIGN.md.
// =============================================================================

class HomeScreenV2 extends ConsumerWidget {
  const HomeScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).value?.languageCode == 'ar';
    final ach = ref.watch(achievementProvider).value;

    // Pull what we display in the profile strip from existing providers.
    // Map the legacy AchievementState fields into the v2 layout's level/XP/streak.
    // Level: every 50 correct = +1 level. XP in level: remainder.
    final totalCorrect = ach?.totalCorrect ?? 0;
    const xpPerLevel = 50;
    final level = (totalCorrect ~/ xpPerLevel) + 1;
    final xpInLevel = totalCorrect % xpPerLevel;
    const xpToNext = xpPerLevel;
    final streak = ach?.streakCount ?? 0;
    final displayName = isAr ? 'صديق' : 'Friend'; // TODO: wire to profileProvider

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileStrip(
                    displayName: displayName,
                    level: level,
                    xpInLevel: xpInLevel,
                    xpToNextLevel: xpToNext,
                    streak: streak,
                  ),
                  const SizedBox(height: 18),
                  TodaysMissionCard(
                    emoji: '🌟',
                    titleEn: 'Brain Boost',
                    titleAr: 'تنمية الذكاء',
                    subtitle: isAr
                        ? 'خمس أسئلة سريعة لتنمية الذكاء'
                        : 'Five quick brain-boost questions',
                    bonusLabel: '2× XP',
                    onStart: () => context.push(AppRoutes.brainBoostDaily),
                  ),
                  const SizedBox(height: 18),
                  // Section header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      isAr ? 'استكشف' : 'Explore',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 5 hero cards in a 3-2 layout
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.92,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      HeroCategoryCard(
                        emoji: '📚',
                        label: isAr ? 'تعلَّم' : 'Learn',
                        subtitle: isAr
                            ? 'علوم، رياضيات، عواصم'
                            : 'Sciences · Math · Capitals',
                        color: const Color(0xFF3B82F6),
                        onTap: () => _openCategory(context, 'learn'),
                      ),
                      HeroCategoryCard(
                        emoji: '🎮',
                        label: isAr ? 'العب' : 'Play',
                        subtitle: isAr
                            ? '٨٠+ لعبة ذهنية'
                            : '80+ brain games',
                        color: const Color(0xFFEC4899),
                        onTap: () => _openCategory(context, 'games'),
                      ),
                      HeroCategoryCard(
                        emoji: '🕌',
                        label: isAr ? 'إسلامي' : 'Islamic',
                        subtitle: isAr
                            ? 'قرآن، حديث، أذكار'
                            : 'Quran · Hadith · Athkar',
                        color: const Color(0xFF10B981),
                        onTap: () => _openCategory(context, 'islamic'),
                      ),
                      HeroCategoryCard(
                        emoji: '🧠',
                        label: isAr ? 'تحدي الذكاء' : 'Brain',
                        subtitle: isAr
                            ? 'منطق وأنماط'
                            : 'Logic & patterns',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => _openCategory(context, 'brain'),
                        isPro: true,
                      ),
                      HeroCategoryCard(
                        emoji: '⋯',
                        label: isAr ? 'المزيد' : 'More',
                        subtitle: isAr
                            ? 'كل الأنشطة'
                            : 'All activities',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _openCategory(context, 'all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Search shortcut
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openCategory(context, 'all'),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isAr ? 'ابحث عن نشاط…' : 'Search activities…',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.62),
                              ),
                            ),
                          ],
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

  void _openCategory(BuildContext context, String key) {
    // Deep-link into the full activity grid (legacy home), pre-filtered to
    // the tapped category. /browse renders HomeScreen with initialCategory.
    context.push('${AppRoutes.browse}?cat=$key');
  }
}
