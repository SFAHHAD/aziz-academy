import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/favorites_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Favorites list — kid taps a heart on any question to add it; this screen
/// shows the list and lets them clear it. Replay-from-favorites uses the
/// existing review_mode flow under the hood (future hook).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider).value ?? const <String>{};
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text(
                      isArabic ? 'المفضلة' : 'My Favorites',
                      style: AppTextStyles.headingMedium,
                    ),
                    const Spacer(),
                    if (favs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(favoritesProvider.notifier).clearAll(),
                        icon: const Icon(Icons.clear_all_rounded),
                        label: Text(isArabic ? 'مسح' : 'Clear'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: favs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('💛', style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                isArabic
                                    ? 'لا توجد أسئلة مفضلة بعد.\nاضغط على القلب ❤️ على أي سؤال لتضيفه هنا.'
                                    : 'No favorites yet.\nTap the heart ❤️ on any question to save it here.',
                                style: AppTextStyles.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => context.go(AppRoutes.home),
                                icon: const Icon(Icons.explore_rounded),
                                label: Text(
                                  isArabic
                                      ? 'تصفّح الأنشطة'
                                      : 'Browse activities',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: favs.length,
                        itemBuilder: (_, i) {
                          final id = favs.elementAt(i);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    id,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggle(id),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
