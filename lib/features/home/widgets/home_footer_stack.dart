import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/mood_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/daily_hadith_banner.dart';
import 'package:aziz_academy/core/widgets/daily_verse_banner.dart';
import 'package:aziz_academy/core/widgets/daily_wisdom_banner.dart';
import 'package:aziz_academy/core/widgets/kid_emoji.dart';
import 'package:aziz_academy/core/widgets/mood_check_in.dart';

/// Footer of the home screen: optional mood check-in, the three daily
/// banners (verse + hadith + wisdom), and the Madrasati shortcut. Lives
/// in its own file so the 2,700-line home_screen.dart doesn't grow
/// every time we add a new daily-rotating prompt.
class HomeFooterStack extends ConsumerWidget {
  const HomeFooterStack({super.key, required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mood check-in only takes vertical space when today is unanswered.
    // Once the kid picks a mood, the prompt becomes noise — collapse it.
    final moodToday = ref.watch(moodProvider).value?.today;
    final showMood = moodToday == null;

    return Column(
      children: [
        if (showMood) ...[const MoodCheckIn(), const SizedBox(height: 12)],
        const DailyVerseBanner(),
        const SizedBox(height: 10),
        const DailyHadithBanner(),
        const SizedBox(height: 10),
        const DailyWisdomBanner(),
        const SizedBox(height: 12),
        _MadrasatiCard(isArabic: isArabic),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MadrasatiCard extends StatelessWidget {
  const _MadrasatiCard({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6A1B9A);
    return GestureDetector(
      onTap: () => context.go(AppRoutes.madrasati),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(70),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            KidEmoji.named('school', size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'مدرستي' : 'Madrasati',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? 'مناهج المدرسة — ابتدائي · متوسط · ثانوي'
                        : 'School curriculum — primary · middle · high',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
