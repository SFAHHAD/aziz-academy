import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// "Add to Home Screen" guide for parents. The PWA manifest is wired up
/// (standalone display, icons, shortcuts), so once the kid taps the share
/// icon and chooses "Add to Home Screen", the app launches without browser
/// chrome — feels like a real app. Browsers don't expose a one-tap install
/// API on iOS, and on Chrome it's gated on a service worker, so the cleanest
/// UX is just to show the steps clearly.
class InstallGuideScreen extends ConsumerWidget {
  const InstallGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.commonBack,
                    onPressed: () => context.go(AppRoutes.parent),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic ? 'تثبيت التطبيق' : 'Install on phone',
                      style: AppTextStyles.headingMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('📱', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'بعد التثبيت يفتح التطبيق دون شريط المتصفح ويبدو مثل أي تطبيق على هاتفك.'
                            : 'Once installed, the app opens without the browser bar and feels like any other app on the phone.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _PlatformCard(
                emoji: '🍎',
                titleEn: 'iPhone / iPad (Safari)',
                titleAr: 'آيفون / آيباد (سفاري)',
                stepsEn: const [
                  'Open Safari (not Chrome) and visit aziz-academy.com',
                  'Tap the Share icon at the bottom of the screen',
                  'Scroll down and tap "Add to Home Screen"',
                  'Tap "Add" — the app icon appears on the home screen',
                ],
                stepsAr: const [
                  'افتح متصفح Safari (وليس Chrome) وزر aziz-academy.com',
                  'اضغط أيقونة المشاركة في أسفل الشاشة',
                  'مرّر للأسفل واضغط "إضافة إلى الشاشة الرئيسية"',
                  'اضغط "إضافة" — ستظهر أيقونة التطبيق على الشاشة الرئيسية',
                ],
                isArabic: isArabic,
              ),
              const SizedBox(height: 14),
              _PlatformCard(
                emoji: '🤖',
                titleEn: 'Android (Chrome)',
                titleAr: 'أندرويد (كروم)',
                stepsEn: const [
                  'Open Chrome and visit aziz-academy.com',
                  'Tap the three-dot menu in the top right',
                  'Tap "Install app" or "Add to Home screen"',
                  'Confirm — the app icon appears on the home screen',
                ],
                stepsAr: const [
                  'افتح Chrome وزر aziz-academy.com',
                  'اضغط قائمة النقاط الثلاث أعلى اليمين',
                  'اضغط "تثبيت التطبيق" أو "إضافة إلى الشاشة الرئيسية"',
                  'أكِّد — ستظهر أيقونة التطبيق على الشاشة الرئيسية',
                ],
                isArabic: isArabic,
              ),
              const SizedBox(height: 14),
              _PlatformCard(
                emoji: '💻',
                titleEn: 'Desktop (Chrome / Edge)',
                titleAr: 'كمبيوتر (Chrome / Edge)',
                stepsEn: const [
                  'Visit aziz-academy.com',
                  'Look for a small install icon in the address bar',
                  'Click it and confirm — the app opens in its own window',
                ],
                stepsAr: const [
                  'زر aziz-academy.com',
                  'ابحث عن أيقونة تثبيت صغيرة في شريط العنوان',
                  'اضغطها وأكِّد — سيفتح التطبيق في نافذته الخاصة',
                ],
                isArabic: isArabic,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'بعد التثبيت تظل بياناتك على الجهاز تمامًا كما في المتصفح — لا تتغيَّر سياسة الخصوصية.'
                            : 'After install, your data stays on the device exactly as in the browser — no change to privacy.',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.emoji,
    required this.titleEn,
    required this.titleAr,
    required this.stepsEn,
    required this.stepsAr,
    required this.isArabic,
  });

  final String emoji;
  final String titleEn;
  final String titleAr;
  final List<String> stepsEn;
  final List<String> stepsAr;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final steps = isArabic ? stepsAr : stepsEn;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic ? titleAr : titleEn,
                  style: AppTextStyles.headingSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(40),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
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
