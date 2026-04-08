import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// About Aziz Academy — useful for store listings and transparency.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(
          'عن التطبيق',
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App logo
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
                  'أكاديمية عزيز',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'الإصدار 1.0.0',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 32),
                _InfoCard(
                  icon: '🧒',
                  title: 'الفئة المستهدفة',
                  body: 'تطبيق تعليمي تفاعلي مخصص للأطفال من سن 8 إلى 12 عاماً.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '📚',
                  title: 'المحتوى',
                  body:
                      'عواصم العالم • الأعلام • الخرائط التفاعلية • الشعارات • العلوم والاكتشافات • الرياضيات.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '🔒',
                  title: 'الخصوصية',
                  body:
                      'التطبيق لا يجمع بيانات شخصية. يُخزَّن التقدّم محلياً على جهازك فقط.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '☁️',
                  title: 'المزامنة',
                  body:
                      'لا توجد مزامنة سحابية حالياً — النقاط والشارات تبقى على هذا الجهاز فقط.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '🛠️',
                  title: 'التقنية',
                  body:
                      'مبني بـ Flutter + Riverpod + GoRouter. مفتوح المصدر على GitHub.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: '🐙',
                  title: 'المستودع',
                  body: 'github.com/SFAHHAD/aziz-academy',
                ),
                const SizedBox(height: 28),
                Divider(color: AppColors.divider.withAlpha(80)),
                const SizedBox(height: 16),
                Text(
                  'صُنع بـ ❤️ بمساعدة Cursor AI',
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
