import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Local leaderboard. Kid-safe: no global ranking, no other children. Shows
/// the child's own personal-bests broken into "This week" and "All time".
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _tab = 0; // 0 = week, 1 = all-time

  @override
  Widget build(BuildContext context) {
    final learner = ref.watch(learnerStateProvider).value;
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final sessions = learner?.recentSessions ?? const [];

    final now = DateTime.now();
    final scope = _tab == 0
        ? sessions.where((s) => now.difference(s.endedAt).inDays <= 7).toList()
        : sessions.toList();

    // Best score per module within scope.
    final byModule = <String, SessionStat>{};
    for (final s in scope) {
      final cur = byModule[s.module];
      if (cur == null || s.score > cur.score) byModule[s.module] = s;
    }
    final ranked = byModule.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          wide: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isArabic ? 'أفضل نتائجي' : 'My Best Scores',
                      style: AppTextStyles.headingMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabBtn(
                        label: isArabic ? 'هذا الأسبوع' : 'This Week',
                        active: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TabBtn(
                        label: isArabic ? 'كل الوقت' : 'All Time',
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ranked.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                isArabic
                                    ? (_tab == 0
                                          ? 'لم تلعب أي جولة هذا الأسبوع.\nابدأ تحديًا واحدًا لتظهر نتائجك هنا!'
                                          : 'العب بعض الجولات لتظهر نتائجك هنا!')
                                    : (_tab == 0
                                          ? "You haven't played this week.\nFinish one round to land on the board!"
                                          : 'Play a few rounds to see your best scores here!'),
                                style: AppTextStyles.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.go(AppRoutes.dailyChallenge),
                                icon: const Icon(Icons.bolt_rounded),
                                label: Text(
                                  isArabic ? 'تحدي اليوم' : "Today's challenge",
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: ranked.length,
                        itemBuilder: (_, i) {
                          final s = ranked[i];
                          final medal = i == 0
                              ? '🥇'
                              : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '⭐'));
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  medal,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.module,
                                        style: AppTextStyles.headingSmall,
                                      ),
                                      Text(
                                        '${localizeDigitsCtx(s.score, context)} / ${localizeDigitsCtx(s.total, context)}',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${(s.accuracy * 100).round()}%',
                                  style: AppTextStyles.headingMedium,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.secondary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: active ? AppColors.background : AppColors.textDark,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
