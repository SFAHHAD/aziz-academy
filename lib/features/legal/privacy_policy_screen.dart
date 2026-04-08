import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// On-device privacy summary for parents and store listings (Arabic).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(
          'الخصوصية',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أكاديمية عزيز',
                  style: AppTextStyles.headingLarge
                      .copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'تطبيق تعليمي للأطفال. نلتزم بتقليل البيانات وجعل التعلم آمناً.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'ما الذي نجمعه؟',
                  body:
                      'لا نطلب بريداً إلكترونياً ولا حساباً للاستخدام الأساسي. تُخزَّن نقاط التقدم والإجابات الصحيحة والشارات على جهازك فقط (تخزين محلي).',
                ),
                _Section(
                  title: 'الإنترنت',
                  body:
                      'قد يُحمَّل محتوى مثل صور الأعلام أو الخرائط من الشبكة. لا نرسل معلومات تعريف الطفل الشخصية ضمن هذه التطبيقات الافتراضية.',
                ),
                _Section(
                  title: 'الصوت',
                  body:
                      'ميزة النطق (TTS) تستخدم محرك النظام أو المتصفح وقد تتطلب تفاعلاً من المستخدم في الويب.',
                ),
                _Section(
                  title: 'التغييرات',
                  body:
                      'قد نحدّث هذا الملخص مع تطور التطبيق. تاريخ آخر تحديث: أبريل 2026.',
                ),
              ],
            ),
          ),
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
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.textDark),
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
