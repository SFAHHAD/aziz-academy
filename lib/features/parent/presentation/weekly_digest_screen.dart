import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Weekly digest — email-style summary for parents. Plain language, no PII
/// upload, no email actually sent. Generated entirely from on-device state.
class WeeklyDigestScreen extends ConsumerWidget {
  const WeeklyDigestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final learner = ref.watch(learnerStateProvider).value;
    final ach = ref.watch(achievementProvider).value;
    final coins = ref.watch(coinProvider).value ?? 0;
    final profile = ref.watch(profileProvider).value;
    final name = (profile?.displayName ?? '').trim().isEmpty
        ? (isArabic ? 'الطفل' : 'Your kid')
        : profile!.displayName;

    final unlockedCount = ach?.unlockedBadges.length ?? 0;
    final totalSessions = learner?.totalSessions ?? 0;
    final topSkill = _topSkill(learner);
    final weakestSkill = _weakestSkill(learner);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    const Text('📅', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'الملخص الأسبوعي' : 'Weekly Digest',
                        style: AppTextStyles.headingMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'نظرة سريعة على أسبوع $name'
                      : "A quick look at $name's week",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 16),
                _DigestCard(
                  emoji: '🎯',
                  title: isArabic ? 'جلسات التعلم' : 'Learning sessions',
                  body: isArabic
                      ? 'أتمّ $totalSessions جلسة على Aziz Academy.'
                      : '$name completed $totalSessions sessions on Aziz Academy.',
                ),
                const SizedBox(height: 12),
                _DigestCard(
                  emoji: '🏅',
                  title: isArabic ? 'الشارات' : 'Badges',
                  body: isArabic
                      ? 'فتح $unlockedCount شارة من ${allBadges.length}.'
                      : 'Unlocked $unlockedCount of ${allBadges.length} badges.',
                ),
                const SizedBox(height: 12),
                _DigestCard(
                  emoji: '🪙',
                  title: isArabic ? 'العملات' : 'Coins',
                  body: isArabic
                      ? 'يملك $coins عملة لاستخدامها في المتجر.'
                      : 'Has $coins coins to spend in the shop.',
                ),
                if (topSkill != null) ...[
                  const SizedBox(height: 12),
                  _DigestCard(
                    emoji: '⭐',
                    title: isArabic ? 'الأقوى' : 'Strongest area',
                    body: isArabic
                        ? '${_modAr(topSkill.$1)} — مستوى ${(topSkill.$2 * 100).round()}%.'
                        : '${topSkill.$1} — at ${(topSkill.$2 * 100).round()}% mastery.',
                  ),
                ],
                if (weakestSkill != null) ...[
                  const SizedBox(height: 12),
                  _DigestCard(
                    emoji: '🌱',
                    title: isArabic ? 'يحتاج تركيزاً' : 'Needs focus',
                    body: isArabic
                        ? '${_modAr(weakestSkill.$1)} — لنشجّعه على هذا القسم.'
                        : '${weakestSkill.$1} — encourage some practice here.',
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isArabic
                        ? 'هذا الملخص لا يُرسل لأي مكان — يُولَّد على هذا الجهاز فقط من نشاط طفلك.'
                        : 'This digest is generated entirely on this device. Nothing is sent anywhere.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.progressReport),
                  icon: const Icon(Icons.print_rounded),
                  label: Text(
                    isArabic ? 'تقرير قابل للطباعة' : 'Open printable report',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, double)? _topSkill(LearnerState? l) {
    if (l == null || l.skillByModule.isEmpty) return null;
    final sorted = l.skillByModule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return (sorted.first.key, sorted.first.value);
  }

  (String, double)? _weakestSkill(LearnerState? l) {
    if (l == null || l.skillByModule.isEmpty) return null;
    final sorted = l.skillByModule.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return (sorted.first.key, sorted.first.value);
  }

  String _modAr(String code) {
    const m = {
      'capitals': 'العواصم',
      'flags': 'الأعلام',
      'logos': 'الشعارات',
      'math': 'الرياضيات',
      'sciences': 'العلوم',
      'iq': 'تنشيط الذهن',
      'maps': 'الخرائط',
    };
    return m[code] ?? code;
  }
}

class _DigestCard extends StatelessWidget {
  const _DigestCard({
    required this.emoji,
    required this.title,
    required this.body,
  });
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
