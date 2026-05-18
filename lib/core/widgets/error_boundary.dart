import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/widgets/error_boundary_reload_stub.dart'
    if (dart.library.html) 'package:aziz_academy/core/widgets/error_boundary_reload_web.dart';

/// Bilingual fallback UI for uncaught widget build errors.
///
/// In release mode Flutter normally shows a featureless gray box when a
/// widget's `build` throws. That looks like the app crashed even when the
/// rest of it is fine. We replace it with a friendly card that names the
/// problem in both languages and offers a reload button on web.
///
/// Wire this up in `main()` BEFORE `runApp()`:
/// ```
/// ErrorWidget.builder = friendlyErrorWidgetBuilder;
/// ```
Widget friendlyErrorWidgetBuilder(FlutterErrorDetails details) {
  // Best-effort locale detection — at this point we don't have a
  // ProviderScope to read from. PlatformDispatcher gives the OS locale,
  // which is right ~95% of the time.
  final locale = PlatformDispatcher.instance.locale;
  final isAr = locale.languageCode == 'ar';

  return _FriendlyErrorCard(isArabic: isAr, details: details);
}

class _FriendlyErrorCard extends StatelessWidget {
  const _FriendlyErrorCard({required this.isArabic, required this.details});

  final bool isArabic;
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: AppColors.background,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐞', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'حصلت مشكلة بسيطة' : 'Something went wrong',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'لا تقلق، تقدُّمك محفوظ. أعد تحميل الصفحة وحاول مرة أخرى.'
                    : "Don't worry, your progress is saved. Reload the page and try again.",
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  height: 1.5,
                  fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (kIsWeb)
                ElevatedButton.icon(
                  onPressed: reloadApp,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    isArabic ? 'إعادة التحميل' : 'Reload',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                // Debug-only: surface the actual exception so the developer
                // doesn't have to dig through the console. Released builds
                // keep this hidden — kids and parents shouldn't see stack
                // traces.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      color: AppColors.error,
                      fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
