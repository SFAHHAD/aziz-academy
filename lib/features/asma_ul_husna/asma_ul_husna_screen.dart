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
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/widgets/focus_highlight.dart';
import 'package:aziz_academy/core/widgets/real_audio_button.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// 99 Names of Allah (Asma Ul Husna) — full canonical list with Arabic
/// vocalised script, transliteration, and a one-line meaning. Filter by
/// theme (Mercy, Power, Knowledge, etc.) and tap any card to hear it.
/// Pure offline, no network.
///
/// When opened with `?focusId=N` (Islamic Search deep-link), scrolls and
/// flashes the matching name card.
class AsmaUlHusnaScreen extends ConsumerStatefulWidget {
  const AsmaUlHusnaScreen({super.key, this.focusId});

  final String? focusId;

  @override
  ConsumerState<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends ConsumerState<AsmaUlHusnaScreen> {
  List<_Name> _all = const [];
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
        'assets/data/asma_ul_husna_memorization.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Name.fromJson).toList();
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
    for (final n in _all) {
      categories.add(isAr ? n.categoryAr : n.category);
    }
    final favs = ref.watch(islamicFavoritesProvider).value?[IslamicFavKind.asma] ??
        const <String>{};
    var visible = _filterCategory == null
        ? _all
        : _all
              .where(
                (n) =>
                    (isAr ? n.categoryAr : n.category) == _filterCategory,
              )
              .toList();
    if (_favoritesOnly) {
      visible =
          visible.where((n) => favs.contains(n.n.toString())).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(
          isAr ? 'أسماء الله الحسنى' : '99 Names of Allah',
        ),
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
              icon: Icons.auto_awesome_rounded,
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : Column(
              children: [
                Container(
                  margin:
                      const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withAlpha(46),
                        AppColors.secondary.withAlpha(32),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.accent.withAlpha(110)),
                  ),
                  child: Text(
                    isAr
                        ? 'لله تسعة وتسعون اسماً، مَن أحصاها دخل الجنة. اضغط 🔊 لسماع الاسم.'
                        : 'Allah has 99 beautiful names — whoever learns them enters Paradise. Tap 🔊 to hear each name.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
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
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final n = visible[i];
                      final idStr = n.n.toString();
                      final isFocused = idStr == widget.focusId;
                      return FocusHighlight(
                        key: isFocused ? _focusKey : null,
                        focused: idStr == _highlightedId,
                        child: _NameCard(name: n, isAr: isAr),
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

class _NameCard extends ConsumerWidget {
  const _NameCard({required this.name, required this.isAr});
  final _Name name;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(46),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.accent.withAlpha(120)),
            ),
            alignment: Alignment.center,
            child: Text(
              localizeDigits(name.n, arabic: isAr),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.nameAr,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 22,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.tr_,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark.withAlpha(180),
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? name.enAr : name.en,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (ctx, ref2, _) {
                  final id = name.n.toString();
                  final isFav = ref2
                          .watch(islamicFavoritesProvider)
                          .value?[IslamicFavKind.asma]
                          ?.contains(id) ??
                      false;
                  return IconButton(
                    onPressed: () => ref2
                        .read(islamicFavoritesProvider.notifier)
                        .toggle(IslamicFavKind.asma, id),
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? AppColors.error
                          : AppColors.textDark.withAlpha(160),
                      size: 18,
                    ),
                    tooltip: isAr
                        ? (isFav ? 'إزالة' : 'أضف للمفضلة')
                        : (isFav ? 'Remove' : 'Favorite'),
                  );
                },
              ),
              RealAudioButton(
                category: 'names',
                id: 'name_${name.n.toString().padLeft(3, '0')}',
                arabicText: name.nameAr,
                size: 18,
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

class _Name {
  const _Name({
    required this.n,
    required this.nameAr,
    required this.tr_,
    required this.en,
    required this.enAr,
    required this.category,
    required this.categoryAr,
  });
  final int n;
  final String nameAr;
  final String tr_;
  final String en;
  final String enAr;
  final String category;
  final String categoryAr;

  static _Name fromJson(Map<String, dynamic> j) => _Name(
    n: (j['n'] as num).toInt(),
    nameAr: j['name_ar'] as String? ?? '',
    tr_: j['name'] as String? ?? '',
    en: j['en'] as String? ?? '',
    enAr: j['en_ar'] as String? ?? '',
    category: j['category'] as String? ?? '',
    categoryAr: j['category_ar'] as String? ?? '',
  );
}
