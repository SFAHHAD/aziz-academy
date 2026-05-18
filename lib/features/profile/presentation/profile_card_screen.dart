import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/l10n/gendered_ar.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_activity_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/providers/xp_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// The "official" kid profile — a passport-style identity card plus this
/// profile's own activity tracking (streak, days active, sessions, a
/// 14-day calendar) and a personalised, gender-aware support message.
///
/// Activity here is scoped to the active family slot, unlike coins / XP /
/// trophies which are shared device-wide. That is what makes the family
/// feature meaningful — each sibling sees how *they* are doing.
class ProfileCardScreen extends ConsumerWidget {
  const ProfileCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final profile = ref.watch(profileProvider).value;
    final family = ref.watch(familyProfilesProvider).value;
    final activity =
        ref.watch(profileActivityProvider).value ?? const ProfileActivity();
    final xp = ref.watch(xpProvider).value ?? const XpState();

    final g = GenderedAr.of(profile);
    final name = (profile?.displayName ?? '').trim();
    final avatar = family?.active.avatarEmoji ?? '🦉';

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
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isArabic ? 'ملفي' : 'My Profile',
                        style: AppTextStyles.headingMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: isArabic ? 'تعديل' : 'Edit',
                      onPressed: () => context.push(AppRoutes.editProfile),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _IdCard(
                  avatar: avatar,
                  name: name,
                  gendered: g,
                  ageBand: profile?.ageBand ?? '8-10',
                  memberSince: activity.memberSince,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 16),
                _LevelCard(xp: xp, isArabic: isArabic),
                const SizedBox(height: 20),
                Text(
                  isArabic ? 'نشاطك' : 'Your activity',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'هذه الأرقام خاصة بك على هذا الجهاز.'
                      : 'These numbers are just for you, on this device.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _StatGrid(activity: activity, isArabic: isArabic),
                const SizedBox(height: 16),
                _ActivityCalendar(
                  recentDays: activity.recentDays,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 16),
                _SupportTip(
                  activity: activity,
                  gendered: g,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.familyProfiles),
                  icon: const Text(
                    '👨‍👩‍👧‍👦',
                    style: TextStyle(fontSize: 18),
                  ),
                  label: Text(
                    isArabic
                        ? 'وضع العائلة (إخوة وأخوات)'
                        : 'Family profiles (siblings)',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(isArabic ? 'تعديل الملف' : 'Edit profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// The ID card
// =============================================================================

class _IdCard extends StatelessWidget {
  const _IdCard({
    required this.avatar,
    required this.name,
    required this.gendered,
    required this.ageBand,
    required this.memberSince,
    required this.isArabic,
  });

  final String avatar;
  final String name;
  final GenderedAr gendered;
  final String ageBand;
  final String memberSince;
  final bool isArabic;

  String get _title {
    if (isArabic) {
      // "بطل" / "بطلة" — gendered champion title.
      return gendered.champion;
    }
    return 'Champion';
  }

  String get _genderLabel =>
      isArabic ? gendered.genderLabel : genderLabelEn(gendered.gender);

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? (isArabic ? 'صديقنا' : 'Friend') : name;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(46),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Text(avatar, style: const TextStyle(fontSize: 42)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      displayName,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _IdField(
                  icon: gendered.genderEmoji,
                  label: isArabic ? 'النوع' : 'Gender',
                  value: _genderLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IdField(
                  icon: '🎂',
                  label: isArabic ? 'العمر' : 'Age',
                  value: ageBand,
                ),
              ),
            ],
          ),
          if (memberSince.isNotEmpty) ...[
            const SizedBox(height: 10),
            _IdField(
              icon: '📅',
              label: isArabic ? 'عضو منذ' : 'Member since',
              value: memberSince,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _IdField extends StatelessWidget {
  const _IdField({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withAlpha(200),
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Level card
// =============================================================================

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.xp, required this.isArabic});

  final XpState xp;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withAlpha(46),
              border: Border.all(color: AppColors.accent.withAlpha(120)),
            ),
            child: Text(
              localizeDigits(xp.level, arabic: isArabic),
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'المستوى ${localizeDigits(xp.level, arabic: true)}'
                      : 'Level ${xp.level}',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: xp.progressInLevel,
                    minHeight: 8,
                    backgroundColor: AppColors.outline.withAlpha(60),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  xp.isMaxLevel
                      ? (isArabic ? 'أعلى مستوى! 🌟' : 'Max level! 🌟')
                      : (isArabic
                            ? '${localizeDigits(xp.xpInCurrentLevel, arabic: true)} / ${localizeDigits(xp.xpNeededForNextLevel, arabic: true)} نقطة'
                            : '${xp.xpInCurrentLevel} / ${xp.xpNeededForNextLevel} XP'),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stat grid
// =============================================================================

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.activity, required this.isArabic});

  final ProfileActivity activity;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        emoji: '🔥',
        value: localizeDigits(activity.streak, arabic: isArabic),
        label: isArabic ? 'أيام متتالية' : 'Day streak',
      ),
      _StatTile(
        emoji: '🏆',
        value: localizeDigits(activity.bestStreak, arabic: isArabic),
        label: isArabic ? 'أفضل سلسلة' : 'Best streak',
      ),
      _StatTile(
        emoji: '📅',
        value: localizeDigits(activity.daysActive, arabic: isArabic),
        label: isArabic ? 'أيام نشطة' : 'Days active',
      ),
      _StatTile(
        emoji: '✨',
        value: localizeDigits(activity.totalSessions, arabic: isArabic),
        label: isArabic ? 'مرات الدخول' : 'Visits',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 14-day activity calendar
// =============================================================================

class _ActivityCalendar extends StatelessWidget {
  const _ActivityCalendar({required this.recentDays, required this.isArabic});

  final List<String> recentDays;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = recentDays.toSet();
    final days = <bool>[];
    for (var i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      days.add(active.contains(activityDayKey(d)));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'آخر ١٤ يوماً' : 'Last 14 days',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final on in days)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: on
                        ? AppColors.accent
                        : AppColors.outline.withAlpha(50),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: on
                          ? AppColors.accent
                          : AppColors.outline.withAlpha(70),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'كل مربّع أخضر يعني يوماً تعلّمت فيه 🌱'
                : 'Each green square is a day you learned 🌱',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Personalised support tip
// =============================================================================

class _SupportTip extends StatelessWidget {
  const _SupportTip({
    required this.activity,
    required this.gendered,
    required this.isArabic,
  });

  final ProfileActivity activity;
  final GenderedAr gendered;
  final bool isArabic;

  /// Picks a message tuned to this profile's activity and gender.
  String _tip() {
    final g = gendered;
    if (isArabic) {
      if (!activity.hasData) {
        return 'مرحباً! ابدأ أول نشاط اليوم، و${g.youCanDoIt}';
      }
      if (activity.streak == 0) {
        return 'اشتقنا لك! ادخل اليوم وابدأ سلسلة جديدة — ${g.youCanDoIt}';
      }
      if (activity.streak >= 7) {
        return '${g.wellDone}! سلسلة ${localizeDigits(activity.streak, arabic: true)} أيام — أنت ${g.champion} حقيقي. ${g.keepGoing}!';
      }
      if (activity.streak >= 3) {
        return 'رائع! ${localizeDigits(activity.streak, arabic: true)} أيام متتالية. ${g.keepGoing} لتصل إلى ٧ أيام 🔥';
      }
      return 'بداية ${g.wonderful}! تعلّم قليلاً كل يوم وستصبح ${g.smart} جداً.';
    }
    // English path — not gendered.
    if (!activity.hasData) {
      return 'Welcome! Start your first activity today — you can do it!';
    }
    if (activity.streak == 0) {
      return 'We missed you! Come back today and start a fresh streak.';
    }
    if (activity.streak >= 7) {
      return 'Amazing! A ${activity.streak}-day streak — you are a true champion. Keep going!';
    }
    if (activity.streak >= 3) {
      return 'Great work! ${activity.streak} days in a row. Keep going to reach 7 🔥';
    }
    return 'Wonderful start! Learn a little every day and you will get really smart.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(40),
            AppColors.secondary.withAlpha(28),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'رسالة لك' : 'A message for you',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tip(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
