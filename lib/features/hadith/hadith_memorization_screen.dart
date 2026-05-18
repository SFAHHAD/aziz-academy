import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/islamic_favorites_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/widgets/focus_highlight.dart';
import 'package:aziz_academy/core/widgets/real_audio_button.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Hadith memorization library — short authentic ahadith grouped by topic.
/// Each card shows Arabic with diacritics, transliteration, English meaning,
/// narrator, and a one-line lesson. Filter by category. Pure offline.
///
/// When opened via `?focusId=hdt_NNN` (from Islamic Search), the screen
/// scrolls the matching card into view after first paint and flashes a
/// brief border highlight on it.
class HadithMemorizationScreen extends ConsumerStatefulWidget {
  const HadithMemorizationScreen({super.key, this.focusId});

  final String? focusId;

  @override
  ConsumerState<HadithMemorizationScreen> createState() =>
      _HadithMemorizationScreenState();
}

class _HadithMemorizationScreenState
    extends ConsumerState<HadithMemorizationScreen> {
  List<_Hadith> _all = const [];
  String? _filterCategory;
  bool _favoritesOnly = false;
  bool _loading = true;
  final GlobalKey _focusKey = GlobalKey();
  String? _highlightedId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/hadith_memorization.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Hadith.fromJson).toList();
        _loading = false;
      });
      _maybeScrollToFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _maybeScrollToFocus() {
    final id = widget.focusId;
    if (id == null || id.isEmpty) return;
    // Clear filters so the focused item is in the visible list.
    setState(() {
      _filterCategory = null;
      _favoritesOnly = false;
      _highlightedId = id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _focusKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _highlightedId = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final categories = <String>{};
    for (final h in _all) {
      categories.add(isAr ? h.categoryAr : h.category);
    }
    final favs = ref.watch(islamicFavoritesProvider).value?[IslamicFavKind.hadith] ??
        const <String>{};
    var visible = _filterCategory == null
        ? _all
        : _all
              .where(
                (h) =>
                    (isAr ? h.categoryAr : h.category) == _filterCategory,
              )
              .toList();
    if (_favoritesOnly) {
      visible = visible.where((h) => favs.contains(h.id)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'حفظ الأحاديث' : 'Hadith Memorization'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
          ? ContentEmptyState(
              icon: Icons.menu_book_outlined,
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _CategoryChip(
                        label: isAr ? '❤︎ المفضلة' : '❤︎ Favorites',
                        selected: _favoritesOnly,
                        onTap: () =>
                            setState(() => _favoritesOnly = !_favoritesOnly),
                      ),
                      _CategoryChip(
                        label: isAr ? 'الكل' : 'All',
                        selected: _filterCategory == null && !_favoritesOnly,
                        onTap: () => setState(() {
                          _filterCategory = null;
                          _favoritesOnly = false;
                        }),
                      ),
                      for (final c in categories)
                        _CategoryChip(
                          label: c,
                          selected: _filterCategory == c,
                          onTap: () =>
                              setState(() => _filterCategory = c),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final h = visible[i];
                      final isFocused = h.id == widget.focusId;
                      return FocusHighlight(
                        key: isFocused ? _focusKey : null,
                        focused: h.id == _highlightedId,
                        child: _HadithCard(hadith: h, isAr: isAr),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _HadithCard extends ConsumerWidget {
  const _HadithCard({required this.hadith, required this.isAr});
  final _Hadith hadith;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isAr ? hadith.titleAr : hadith.title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(36),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isAr ? hadith.categoryAr : hadith.category,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? hadith.narratorAr : hadith.narrator,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark.withAlpha(160),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hadith.ar,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 18,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hadith.transliteration,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark.withAlpha(180),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? hadith.translationAr : hadith.translation,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark),
          ),
          if ((isAr ? hadith.lessonAr : hadith.lesson).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.secondary.withAlpha(80),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr ? hadith.lessonAr : hadith.lesson,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer(
                builder: (ctx, ref2, _) {
                  final isFav = ref2
                          .watch(islamicFavoritesProvider)
                          .value?[IslamicFavKind.hadith]
                          ?.contains(hadith.id) ??
                      false;
                  return IconButton(
                    onPressed: () => ref2
                        .read(islamicFavoritesProvider.notifier)
                        .toggle(IslamicFavKind.hadith, hadith.id),
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? AppColors.error
                          : AppColors.textDark.withAlpha(160),
                      size: 22,
                    ),
                    tooltip: isAr
                        ? (isFav ? 'إزالة من المفضلة' : 'أضف إلى المفضلة')
                        : (isFav ? 'Remove favorite' : 'Add to favorites'),
                  );
                },
              ),
              const SizedBox(width: 4),
              RealAudioButton(
                category: 'hadith',
                id: hadith.id,
                arabicText: hadith.ar,
                size: 20,
                filledTonal: true,
                tooltip: isAr ? 'استمع' : 'Listen',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hadith {
  const _Hadith({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.ar,
    required this.transliteration,
    required this.translation,
    required this.translationAr,
    required this.narrator,
    required this.narratorAr,
    required this.lesson,
    required this.lessonAr,
    required this.category,
    required this.categoryAr,
  });

  final String id;
  final String title;
  final String titleAr;
  final String ar;
  final String transliteration;
  final String translation;
  final String translationAr;
  final String narrator;
  final String narratorAr;
  final String lesson;
  final String lessonAr;
  final String category;
  final String categoryAr;

  static _Hadith fromJson(Map<String, dynamic> j) => _Hadith(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    titleAr: j['title_ar'] as String? ?? '',
    ar: j['ar'] as String? ?? '',
    transliteration: j['transliteration'] as String? ?? '',
    translation: j['translation'] as String? ?? '',
    translationAr: j['translation_ar'] as String? ?? '',
    narrator: j['narrator'] as String? ?? '',
    narratorAr: j['narrator_ar'] as String? ?? '',
    lesson: j['lesson'] as String? ?? '',
    lessonAr: j['lesson_ar'] as String? ?? '',
    category: j['category'] as String? ?? '',
    categoryAr: j['category_ar'] as String? ?? '',
  );
}
