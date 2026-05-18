import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Bilingual privacy summary. Reads at the level of a parent who is asking
/// "is it safe for my kid?" rather than a lawyer reading a EULA.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(localeProvider).value?.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(
          ar ? 'الخصوصية' : 'Privacy',
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar ? 'أكاديمية عزيز' : 'Aziz Academy',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ar
                      ? 'نُلخِّص هنا ما يحدث لبيانات طفلك بلغة بسيطة. السطر القصير: لا حساب، لا تتبُّع، كل شيء على الجهاز.'
                      : 'A plain-language summary of what happens with your child\'s data. The short version: no account, no tracking, everything stays on the device.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _Pill(
                  text: ar ? 'لا بيانات شخصية' : 'NO PII',
                  tone: AppColors.success,
                ),
                const SizedBox(height: 6),
                _Section(
                  title: ar ? 'ما الذي نجمعه؟' : 'What we collect',
                  body: ar
                      ? 'لا شيء يغادر جهازك بصيغة شخصية. لا بريد، لا حساب، لا اسم، لا رقم هاتف. التقدُّم والنقاط والشارات تُحفَظ في تخزين المتصفح المحلي على جهازك فقط.'
                      : 'Nothing identifying leaves your device. No email, no account, no name, no phone. Progress, scores, and badges live in the browser\'s local storage on this device only.',
                ),
                _Section(
                  title: ar ? 'الاتصالات الشبكية' : 'Network connections',
                  body: ar
                      ? 'بعد التحميل الأول للتطبيق، لا توجد اتصالات شبكية تلقائية. لا تحليلات، لا كوكيز، لا بصمات جهاز. التطبيق يعمل بالكامل من ذاكرة المتصفح المحلية. الاستثناء الوحيد: عند فتح لعبة الخرائط (يحمّل خرائط OpenStreetMap عند الطلب) أو لعبة الأعلام (يحمّل صور الأعلام من flagcdn.com).'
                      : 'After the initial app download, there are no automatic network calls. No analytics, no cookies, no device fingerprinting. The app runs entirely from local browser storage. The only exceptions: when you open the Maps game (loads OpenStreetMap tiles on demand) or the Flags game (fetches flag images from flagcdn.com).',
                ),
                _Section(
                  title: ar ? 'الإعلانات' : 'Advertising',
                  body: ar
                      ? 'لا إعلانات على الإطلاق. لا إعلانات بانر، لا فيديو، لا تتبُّع إعلاني. التطبيق مجاني الاستخدام بالكامل.'
                      : 'Zero ads. No banners, no video ads, no ad-tracking. The app is fully free to use.',
                ),
                _Section(
                  title: ar ? 'الصوت والقراءة' : 'Audio & speech',
                  body: ar
                      ? 'بعض الميزات تستخدم محرك تحويل النص إلى كلام في المتصفح أو نظام التشغيل. لا يُرسَل النص لأي خادم — كل المعالجة محلية.'
                      : 'Some features use the browser\'s or device\'s built-in text-to-speech engine. The text is never sent to any server — all processing is local.',
                ),
                _Section(
                  title: ar
                      ? 'الامتثال (COPPA / GDPR-K / PDPL)'
                      : 'Compliance (COPPA / GDPR-K / PDPL)',
                  body: ar
                      ? 'مصمَّم للأطفال دون 13 عامًا، ولا يجمع أي بيانات تعريفية. لا تسجيل دخول، لا حساب، لا إعلانات سلوكية، لا مشاركة بيانات. هذا يتوافق مع COPPA الأمريكي و GDPR-K الأوروبي و نظام حماية البيانات الشخصية السعودي (PDPL) للقاصرين.'
                      : 'Designed for kids under 13, collects zero PII. No login, no account, no behavioral ads, no data sharing. Compliant with US COPPA, EU GDPR-K, and Saudi PDPL provisions for minors.',
                ),
                _Section(
                  title: ar ? 'حقوق الوالدين' : 'Parents\' rights',
                  body: ar
                      ? 'يمكنك مراجعة كل ما هو مُخزَّن من شاشة "ركن الوالدين"، أو حذفه بالكامل من الإعدادات → "تصفير البيانات". لا حاجة للتواصل معنا — كل البيانات على هذا الجهاز.'
                      : 'You can review everything stored via the Parent Area, or wipe it entirely from Settings → "Reset all data". No need to contact us — the data only exists on this device.',
                ),
                _Section(
                  title: ar
                      ? 'مشاركة الشهادات والإنجازات'
                      : 'Sharing certificates & achievements',
                  body: ar
                      ? 'إذا اختار طفلك مشاركة شهادة إنجاز، يستخدم التطبيق نافذة المشاركة الخاصة بنظام الجهاز. أنت من تختار الوجهة (واتساب، البريد، الطباعة، إلخ). التطبيق نفسه لا يُرسل شيئًا تلقائيًا.'
                      : 'When your child shares a certificate, the app uses the device\'s share sheet — you pick the destination (WhatsApp, mail, print, etc). The app itself never auto-sends anything.',
                ),
                _Section(
                  title: ar ? 'التحديثات' : 'Updates',
                  body: ar
                      ? 'قد نُحدِّث هذا الملخص مع تطوُّر التطبيق. آخر تحديث: مايو 2026.'
                      : 'We may update this summary as the app evolves. Last updated: May 2026.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_moon_outlined,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ar
                              ? 'إنتاج Q8 Vision — استوديو منتجات في الكويت. q8vision.com'
                              : 'A Q8 Vision production — a Kuwaiti product studio. q8vision.com',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.withAlpha(120)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: tone,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
