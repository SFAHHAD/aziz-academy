import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Shown when a content pack fails to load (corrupted JSON, missing asset)
/// or loads zero rows. Bilingual, with a retry button.
class ContentEmptyState extends StatelessWidget {
  const ContentEmptyState({
    super.key,
    required this.onRetry,
    this.icon = Icons.menu_book_outlined,
  });
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.textDark.withAlpha(120),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'تعذّر تحميل المحتوى'
                  : 'Could not load this content',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAr
                  ? 'تحقق من اتصال الجهاز ثم حاول مجدداً.'
                  : 'Check the device storage and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark.withAlpha(160),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isAr ? 'إعادة المحاولة' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
