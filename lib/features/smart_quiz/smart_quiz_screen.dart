import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Smart Quiz — landing screen that suggests the kid practice their weakest
/// module first based on the rolling skill EMA in `learnerStateProvider`.
/// Shows a ranked list of all tracked modules with a one-tap drill button
/// that routes to that module's quiz. No new persistence; pure read of
/// existing learner state.
class SmartQuizScreen extends ConsumerWidget {
  const SmartQuizScreen({super.key});

  static const _moduleConfig = <String, _Module>{
    'capitals': _Module(
      emoji: '🌍',
      label: 'Capitals',
      labelAr: 'العواصم',
      route: AppRoutes.capitals,
    ),
    'flags': _Module(
      emoji: '🚩',
      label: 'Flags',
      labelAr: 'الأعلام',
      route: AppRoutes.flags,
    ),
    'math': _Module(
      emoji: '🔢',
      label: 'Math',
      labelAr: 'الرياضيات',
      route: AppRoutes.math,
    ),
    'sciences': _Module(
      emoji: '🔬',
      label: 'Sciences',
      labelAr: 'العلوم',
      route: AppRoutes.sciences,
    ),
    'logos': _Module(
      emoji: '🏷️',
      label: 'Logos',
      labelAr: 'الشعارات',
      route: AppRoutes.logos,
    ),
    'iq': _Module(
      emoji: '🧠',
      label: 'Brain Boost',
      labelAr: 'تنمية الذكاء',
      route: AppRoutes.iq,
    ),
    'general_quiz': _Module(
      emoji: '📚',
      label: 'General Knowledge',
      labelAr: 'معلومات عامة',
      route: AppRoutes.generalQuizIntro,
    ),
    'spelling': _Module(
      emoji: '✏️',
      label: 'Spelling',
      labelAr: 'الإملاء',
      route: AppRoutes.spelling,
    ),
    'learning_zone': _Module(
      emoji: '📖',
      label: 'Reading Zone',
      labelAr: 'منطقة القراءة',
      route: AppRoutes.learningZone,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final learner = ref.watch(learnerStateProvider).value;
    final skills = learner?.skillByModule ?? const <String, double>{};

    final ranked = _moduleConfig.entries.map((e) {
      final s = skills[e.key] ?? 0.5;
      return (id: e.key, mod: e.value, skill: s);
    }).toList()..sort((a, b) => a.skill.compareTo(b.skill));

    final weakest = ranked.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'تحدّي ذكي' : 'Smart Quiz'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withAlpha(60),
                    AppColors.accent.withAlpha(40),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withAlpha(140)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'الموضوع الأضعف' : 'Weakest topic',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        weakest.mod.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? weakest.mod.labelAr : weakest.mod.label,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr
                                  ? 'مستواك: ${localizeDigits((weakest.skill * 100).round(), arabic: true)}٪'
                                  : 'Your skill: ${(weakest.skill * 100).round()}%',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDark.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(weakest.mod.route),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        isAr ? 'ابدأ التدريب الذكي' : 'Start smart drill',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr
                  ? 'الترتيب من الأضعف للأقوى'
                  : 'Ranked from weakest to strongest',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            for (final r in ranked)
              _ModuleRow(mod: r.mod, skill: r.skill, isAr: isAr),
          ],
        ),
      ),
    );
  }
}

class _Module {
  const _Module({
    required this.emoji,
    required this.label,
    required this.labelAr,
    required this.route,
  });
  final String emoji;
  final String label;
  final String labelAr;
  final String route;
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.mod,
    required this.skill,
    required this.isAr,
  });
  final _Module mod;
  final double skill;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => context.push(mod.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withAlpha(60)),
          ),
          child: Row(
            children: [
              Text(mod.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? mod.labelAr : mod.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: skill.clamp(0, 1).toDouble(),
                        minHeight: 6,
                        color: skill < 0.4
                            ? AppColors.warning
                            : skill < 0.7
                            ? AppColors.accent
                            : AppColors.success,
                        backgroundColor: AppColors.outline.withAlpha(40),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAr
                    ? '${localizeDigits((skill * 100).round(), arabic: true)}٪'
                    : '${(skill * 100).round()}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDark.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
