import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// /for-schools — bilingual landing page targeting MOE-aligned schools
/// in Kuwait + the wider Gulf region. Sells the privacy posture
/// (zero-PII, on-device, MOE-curriculum-aligned) and routes interest
/// to a mailto contact. No analytics scripts, no lead-capture form.
class ForSchoolsScreen extends ConsumerWidget {
  const ForSchoolsScreen({super.key});

  static const _contactEmail = 's.fahhad@gmail.com';

  Future<void> _copyEmail(BuildContext context, bool ar) async {
    await Clipboard.setData(const ClipboardData(text: _contactEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ar
              ? 'نُسخ البريد: $_contactEmail'
              : 'Email copied: $_contactEmail',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(localeProvider).value?.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(
          ar ? 'للمدارس' : 'For Schools',
          style:
              AppTextStyles.headingSmall.copyWith(color: AppColors.textDark),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(ar: ar),
                const SizedBox(height: 24),
                _ValueGrid(ar: ar),
                const SizedBox(height: 32),
                _Section(
                  title: ar ? 'ما الذي يحصل عليه طلابكم' : 'What your students get',
                  bullets: ar
                      ? const [
                          '١٣٠+ نشاطًا تعليميًا ثنائي اللغة (عربي/إنجليزي)',
                          'محاذاة منهج وزارة التربية: رياضيات، علوم، لغة عربية، '
                              'تربية إسلامية، جغرافيا',
                          'وضع «مدرستي» — أسئلة من المنهج المدرسي مع مساعد واجبات',
                          'الصفوف الأولى: حروف، أشكال، روابط أعداد، منازل عشرية، '
                              'عد بالقفز',
                          'القرآن: ١٥ سورة بتلاوة حقيقية للقراء (مشاري العفاسي '
                              'و٥ آخرين)',
                          'بنك أسئلة ١٥٬٠٠٠+ سؤال مع مستويات ذكية',
                        ]
                      : const [
                          '130+ bilingual learning activities (AR/EN)',
                          'MOE-curriculum alignment: math, sciences, Arabic, '
                              'Islamic studies, geography',
                          '"Madrasati" mode — school-curriculum questions with '
                              'homework helper',
                          'Early-elementary suite: alphabets, shapes, number '
                              'bonds, place value, skip counting',
                          'Quran: 15 surahs with real reciter audio (Mishary '
                              'Alafasy + 5 alternates)',
                          '15,000+ question bank with smart difficulty levels',
                        ],
                ),
                const SizedBox(height: 28),
                _Section(
                  title: ar ? 'ما الذي يحصل عليه المعلمون' : 'What teachers get',
                  bullets: ar
                      ? const [
                          'حسابات عائلية متعددة على جهاز واحد — مناسب للفصل المشترك',
                          'لوحة ولي الأمر مع ملخصات أسبوعية وتقارير تقدُّم قابلة للطباعة',
                          'منطقة قراءة ثنائية اللغة (٣٩ قطعة فهم) + إملاء + مفردات',
                          'بدون إعلانات، بدون تتبُّع، بدون حسابات للأطفال',
                        ]
                      : const [
                          'Family Profiles — multiple kids on one device, ideal '
                              'for shared classroom tablets',
                          'Parent dashboard with weekly digest + printable '
                              'progress reports',
                          'Bilingual Reading Zone (39 comprehension passages) + '
                              'Spelling + Vocabulary',
                          'No ads, no tracking, no kid accounts',
                        ],
                ),
                const SizedBox(height: 28),
                _PrivacyCallout(ar: ar),
                const SizedBox(height: 32),
                _CtaCard(
                  ar: ar,
                  contactEmail: _contactEmail,
                  onCopy: () => _copyEmail(context, ar),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    ar
                        ? 'مقرّ التطوير: الكويت · Q8 Vision Studio'
                        : 'Developed in Kuwait · Q8 Vision Studio',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                    ),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.ar});
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏫', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ar
                      ? 'أكاديمية عزيز في صفّك'
                      : 'Aziz Academy in your classroom',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ar
                ? 'تطبيق تعليمي مجاني للأطفال (٦–١٢) ثنائي اللغة، مصمَّم '
                    'بالكويت ومحاذٍ لمنهج وزارة التربية. بدون إعلانات، '
                    'بدون تتبُّع، بدون أي بيانات شخصية تغادر الجهاز.'
                : 'A free bilingual educational app for kids 6–12, built '
                    'in Kuwait and aligned with the MOE primary-stage '
                    'curriculum. Zero ads, zero tracking, zero personal '
                    'data leaving the device.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueGrid extends StatelessWidget {
  const _ValueGrid({required this.ar});
  final bool ar;

  @override
  Widget build(BuildContext context) {
    final items = ar
        ? const [
            ('🎯', 'محاذاة منهج', 'وزارة التربية الكويتية'),
            ('🛡️', 'بدون بيانات', 'كل التقدُّم على الجهاز'),
            ('🌐', 'ثنائي اللغة', 'عربي / إنجليزي كامل'),
            ('🆓', 'مجاني للطلاب', 'لا اشتراك للطفل'),
          ]
        : const [
            ('🎯', 'Curriculum-aligned', 'Kuwait MOE primary stage'),
            ('🛡️', 'Zero PII', 'All progress on-device'),
            ('🌐', 'Truly bilingual', 'Full AR/EN with RTL'),
            ('🆓', 'Free for students', 'No kid subscription'),
          ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          _ValueCard(emoji: item.$1, title: item.$2, subtitle: item.$3),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PrivacyCallout extends StatelessWidget {
  const _PrivacyCallout({required this.ar});
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar ? 'متوافق مع متطلبات حماية الطفل' : 'Child-safe by design',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ar
                      ? 'لا نطلب اسم الطفل، ولا بريداً، ولا هاتفاً. لا توجد '
                          'إعلانات. لا توجد مكتبات تتبُّع. كل بيانات التقدُّم '
                          'محفوظة على جهاز الطالب فقط. متوافق مع COPPA '
                          'وقوانين حماية القاصرين.'
                      : 'We do not ask for the child\'s name, email, or '
                          'phone. There are no ads, no third-party '
                          'tracking SDKs. All progress data lives on the '
                          'student\'s device only. Aligned with COPPA / '
                          'GDPR-K / GCC minor data-protection norms.',
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

class _CtaCard extends StatelessWidget {
  const _CtaCard({
    required this.ar,
    required this.contactEmail,
    required this.onCopy,
  });
  final bool ar;
  final String contactEmail;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            ar
                ? 'اهتممت بأكاديمية عزيز لمدرستك؟'
                : 'Interested in Aziz Academy for your school?',
            style: AppTextStyles.headingMedium.copyWith(
              color: const Color(0xFF0A1628),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            ar
                ? 'تواصل معنا للحديث عن التراخيص والتدريب والمحاذاة مع المنهج.'
                : 'Reach out to talk licensing, onboarding, and curriculum alignment.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF0A1628),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SelectableText(
            contactEmail,
            style: AppTextStyles.headingSmall.copyWith(
              color: const Color(0xFF0A1628),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCopy,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0A1628),
              foregroundColor: AppColors.secondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              textStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: const Icon(Icons.content_copy_rounded),
            label:
                Text(ar ? 'نسخ البريد' : 'Copy email'),
          ),
        ],
      ),
    );
  }
}
