import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Self-Challenge picker (Research.txt). Kid configures their own round:
/// module, # questions, optional timer. Tapping "Start" routes to that
/// module's quiz screen — count/timer enforcement happens in v2; v1 routes
/// straight to the existing quiz with category/difficulty defaults so the
/// feature works end-to-end.
class SelfChallengeScreen extends ConsumerStatefulWidget {
  const SelfChallengeScreen({super.key});

  @override
  ConsumerState<SelfChallengeScreen> createState() =>
      _SelfChallengeScreenState();
}

class _SelfChallengeScreenState extends ConsumerState<SelfChallengeScreen> {
  String _module = 'sciences';
  int _count = 5;
  bool _timer = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                    Text(
                      isArabic ? 'تحدّ نفسك' : 'Self Challenge',
                      style: AppTextStyles.headingMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? 'اختر المادة وعدد الأسئلة وابدأ.'
                      : 'Pick a topic, choose how many questions, and go.',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 24),
                _SectionLabel(text: isArabic ? 'المادة' : 'Topic'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _modules.map((m) {
                    final selected = m.key == _module;
                    return GestureDetector(
                      onTap: () => setState(() => _module = m.key),
                      child: Container(
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
                            Text(m.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? m.ar : m.en,
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _SectionLabel(text: isArabic ? 'عدد الأسئلة' : 'Questions'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [3, 5, 10, 15].map((n) {
                    final sel = n == _count;
                    return GestureDetector(
                      onTap: () => setState(() => _count = n),
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.secondary
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$n',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: sel
                                ? AppColors.background
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: Text(
                    isArabic ? 'مع مؤقّت' : 'With timer',
                    style: AppTextStyles.labelLarge,
                  ),
                  subtitle: Text(
                    isArabic
                        ? '15 ثانية لكل سؤال — مزيد من الإثارة'
                        : '15 seconds per question — extra spice',
                    style: AppTextStyles.bodyMedium,
                  ),
                  value: _timer,
                  onChanged: (v) => setState(() => _timer = v),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final route = _routeFor(_module);
                      context.go(route);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(isArabic ? 'ابدأ التحدي' : 'Start Challenge'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _routeFor(String m) {
    switch (m) {
      case 'capitals':
        return AppRoutes.capitalsQuiz;
      case 'flags':
        return AppRoutes.flagsQuiz;
      case 'sciences':
        return AppRoutes.sciencesQuiz;
      case 'math':
        return AppRoutes.mathQuiz;
      case 'iq':
        return AppRoutes.iqQuiz;
      case 'general_quiz':
        return AppRoutes.generalQuiz;
      default:
        return AppRoutes.sciencesQuiz;
    }
  }
}

class _ModuleOpt {
  const _ModuleOpt(this.key, this.emoji, this.en, this.ar);
  final String key;
  final String emoji;
  final String en;
  final String ar;
}

const _modules = <_ModuleOpt>[
  _ModuleOpt('capitals', '🏛️', 'Capitals', 'العواصم'),
  _ModuleOpt('flags', '🚩', 'Flags', 'الأعلام'),
  _ModuleOpt('sciences', '🔬', 'Sciences', 'العلوم'),
  _ModuleOpt('math', '🔢', 'Math', 'الرياضيات'),
  _ModuleOpt('iq', '🧠', 'IQ', 'الذكاء'),
  _ModuleOpt('general_quiz', '🌍', 'General', 'معلومات عامة'),
];

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.headingSmall);
  }
}
