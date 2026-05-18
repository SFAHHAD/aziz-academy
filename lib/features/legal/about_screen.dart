import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

const _kAppVersion = '1.1.113+118';

/// About — bilingual public-facing page suitable for visitors deciding
/// whether to trust the app, parents reading before letting their kids in,
/// or anyone landing here from the share sheet / store listing.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(localeProvider).value?.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(
          ar ? 'عن التطبيق' : 'About',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.textDark),
        ),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(80),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎓', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  ar ? 'أكاديمية عزيز' : 'Aziz Academy',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  ar ? 'إصدار $_kAppVersion' : 'Version $_kAppVersion',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'aziz-academy.com',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 32),
                _InfoCard(
                  icon: '🧒',
                  title: ar ? 'الفئة المستهدفة' : 'Who it\'s for',
                  body: ar
                      ? 'الأطفال من 6 إلى 12 عامًا — مدمج بمحتوى مدرسي وألعاب ذكاء وتسلية بلغتين.'
                      : 'Kids ages 6 to 12 — school subjects, brain games, and arcade fun in Arabic and English.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '📚',
                  title: ar ? 'المحتوى' : 'What\'s inside',
                  body: ar
                      ? '130+ نشاطًا في 8 فئات: تعلَّم • كلمات • رياضيات • ذكاء • تحدي • لاعبان • إسلامي • أدوات. أكثر من 15,000 سؤال بنسبة ثنائية اللغة 99.8٪.'
                      : '130+ activities across 8 categories: Learn • Words • Math • Brain • Action • Versus • Islamic • Tools. Over 15,000 questions at 99.8% bilingual coverage.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '🔒',
                  title: ar ? 'الخصوصية' : 'Privacy',
                  body: ar
                      ? 'لا حساب، لا بريد، لا تتبُّع. كل التقدُّم يُحفظ على الجهاز فقط. الاتصال الوحيد بالشبكة هو إحصاءات Vercel المجهولة بدون كوكيز.'
                      : 'No account, no email, no tracking. All progress lives on your device. The only network call is Vercel Analytics — anonymous, cookieless.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '☁️',
                  title: ar ? 'المزامنة' : 'Cloud sync',
                  body: ar
                      ? 'لا توجد مزامنة سحابية. كل عائلة تستخدم جهازًا واحدًا أو تستخدم ملفات شخصية متعددة على نفس الجهاز.'
                      : 'No cloud sync. One device per family, or use multiple profiles on the same device.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '🛠️',
                  title: ar ? 'التقنية' : 'Tech',
                  body: ar
                      ? 'مبني بـ Flutter للويب على Vercel. Riverpod للحالة، go_router للتنقل، Cairo + JetBrainsMono للخطوط.'
                      : 'Built with Flutter for web, hosted on Vercel. Riverpod for state, go_router for navigation, Cairo + JetBrainsMono for type.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '🇰🇼',
                  title: ar ? 'الاستوديو' : 'Studio',
                  body: ar
                      ? 'إنتاج Q8 Vision — استوديو منتجات في الكويت. q8vision.com'
                      : 'A Q8 Vision production — a Kuwaiti product studio. q8vision.com',
                ),
                const SizedBox(height: 28),
                Divider(color: AppColors.divider.withAlpha(80)),
                const SizedBox(height: 16),
                Text(
                  ar ? 'صُنع في الكويت ❤️' : 'Made in Kuwait ❤️',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
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
