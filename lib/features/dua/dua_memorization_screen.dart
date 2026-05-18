import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/focus_highlight.dart';
import 'package:aziz_academy/core/widgets/real_audio_button.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Dua memorization library — 60 short authentic supplications grouped by
/// occasion. Each card shows Arabic with diacritics, transliteration, and
/// English meaning, plus 🔊 to hear it. Filter by category. Pure offline.
///
/// `?focusId=dua_xxx` (from Islamic Search) scrolls + highlights the
/// matching dua card.
class DuaMemorizationScreen extends ConsumerStatefulWidget {
  const DuaMemorizationScreen({super.key, this.focusId});

  final String? focusId;

  @override
  ConsumerState<DuaMemorizationScreen> createState() =>
      _DuaMemorizationScreenState();
}

class _DuaMemorizationScreenState extends ConsumerState<DuaMemorizationScreen> {
  List<_Dua> _all = const [];
  String? _filterCategory;
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
        'assets/data/dua_memorization.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Dua.fromJson).toList();
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
    setState(() {
      _filterCategory = null;
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
    for (final d in _all) {
      categories.add(d.category);
    }
    final visible = _filterCategory == null
        ? _all
        : _all.where((d) => d.category == _filterCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'حفظ الأدعية' : 'Dua Memorization'),
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
          : Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _CategoryChip(
                        label: isAr ? 'الكل' : 'All',
                        selected: _filterCategory == null,
                        onTap: () => setState(() => _filterCategory = null),
                      ),
                      for (final c in categories)
                        _CategoryChip(
                          label: c,
                          selected: _filterCategory == c,
                          onTap: () => setState(() => _filterCategory = c),
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
                      final d = visible[i];
                      final isFocused = d.id == widget.focusId;
                      return FocusHighlight(
                        key: isFocused ? _focusKey : null,
                        focused: d.id == _highlightedId,
                        child: _DuaCard(dua: d, isAr: isAr),
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

class _DuaCard extends ConsumerWidget {
  const _DuaCard({required this.dua, required this.isAr});
  final _Dua dua;
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
                  isAr ? dua.titleAr : dua.title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(36),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isAr ? dua.categoryAr : dua.category,
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
            isAr ? dua.occasionAr : dua.occasion,
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
              dua.ar,
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
            dua.transliteration,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark.withAlpha(180),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? dua.translationAr : dua.translation,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: RealAudioButton(
              category: 'dua',
              id: dua.id,
              arabicText: dua.ar,
              size: 20,
              filledTonal: true,
              tooltip: isAr ? 'استمع' : 'Listen',
            ),
          ),
        ],
      ),
    );
  }
}

class _Dua {
  const _Dua({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.ar,
    required this.transliteration,
    required this.translation,
    required this.translationAr,
    required this.occasion,
    required this.occasionAr,
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
  final String occasion;
  final String occasionAr;
  final String category;
  final String categoryAr;

  static _Dua fromJson(Map<String, dynamic> j) => _Dua(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    titleAr: j['title_ar'] as String? ?? '',
    ar: j['ar'] as String? ?? '',
    transliteration: j['transliteration'] as String? ?? '',
    translation: j['translation'] as String? ?? '',
    translationAr: j['translation_ar'] as String? ?? '',
    occasion: j['occasion'] as String? ?? '',
    occasionAr: j['occasion_ar'] as String? ?? '',
    category: j['category'] as String? ?? '',
    categoryAr: j['category_ar'] as String? ?? '',
  );
}
