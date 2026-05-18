import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// First-launch onboarding overlay — three swipeable cards introducing the
/// app's core loop: pick a subject, earn stars, daily mission. Closes itself
/// once the learner taps "Got it" on the final card and persists the
/// completion flag in [appSettingsProvider].
class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  final _ctrl = PageController();
  int _index = 0;
  final Set<String> _picked = {};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _finish() {
    if (_picked.isNotEmpty) {
      ref.read(learnerStateProvider.notifier).setInterests(_picked);
    }
    ref.read(appSettingsProvider.notifier).markOnboardingCompleted();
  }

  void _toggleInterest(String key) {
    setState(() {
      if (_picked.contains(key)) {
        _picked.remove(key);
      } else {
        _picked.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final pages = <Widget>[
      _OnboardingPage(
        emoji: '🎯',
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      _OnboardingPage(
        emoji: '⭐',
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
      ),
      _OnboardingPage(
        emoji: '🔥',
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
      _InterestPicker(
        arabic: isArabic,
        picked: _picked,
        onTap: _toggleInterest,
      ),
    ];

    return Material(
      color: AppColors.background.withAlpha(240),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _index = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => Container(
                  width: i == _index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.secondary
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_index >= pages.length - 1) {
                      _finish();
                    } else {
                      _ctrl.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _index >= pages.length - 1
                        ? l10n.onboardingGotIt
                        : l10n.onboardingNext,
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 96)),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InterestPicker extends StatelessWidget {
  const _InterestPicker({
    required this.arabic,
    required this.picked,
    required this.onTap,
  });

  final bool arabic;
  final Set<String> picked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <(String key, String emoji, String labelEn, String labelAr)>[
      ('animals', '🐾', 'Animals', 'الحيوانات'),
      ('space', '🚀', 'Space', 'الفضاء'),
      ('sports', '⚽', 'Sports', 'الرياضة'),
      ('art', '🎨', 'Art', 'الفنون'),
      ('history', '🏺', 'History', 'التاريخ'),
      ('nature', '🌳', 'Nature', 'الطبيعة'),
      ('robots', '🤖', 'Robots', 'الروبوتات'),
      ('food', '🍎', 'Food', 'الأطعمة'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌟', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            arabic ? 'ما الذي يعجبك أكثر؟' : 'What do you like most?',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            arabic ? 'اختر اثنين أو ثلاثة' : 'Pick two or three',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: items.map((it) {
              final selected = picked.contains(it.$1);
              return GestureDetector(
                onTap: () => onTap(it.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.secondary.withAlpha(70)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: selected
                          ? AppColors.secondary
                          : AppColors.glassBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(it.$2, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text(
                        arabic ? it.$4 : it.$3,
                        style: AppTextStyles.labelMedium,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
