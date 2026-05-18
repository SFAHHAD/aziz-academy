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
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Prophet stories (Sirah) — the 25 named prophets in canonical order with
/// a short kid-friendly story, one-line lesson, and 🔊 narration. Filter
/// by era (Beginning → Ancient → Patriarchs → Israelite Era → Last
/// Messenger). Pure offline.
///
/// `?focusId=pNN` (from Islamic Search) scrolls + highlights the matching
/// prophet card.
class ProphetStoriesScreen extends ConsumerStatefulWidget {
  const ProphetStoriesScreen({super.key, this.focusId});

  final String? focusId;

  @override
  ConsumerState<ProphetStoriesScreen> createState() =>
      _ProphetStoriesScreenState();
}

class _ProphetStoriesScreenState extends ConsumerState<ProphetStoriesScreen> {
  List<_Prophet> _all = const [];
  String? _filterEra;
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
        'assets/data/prophet_stories.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Prophet.fromJson).toList();
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
      _filterEra = null;
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
    // Preserve list order while collecting unique eras.
    final eras = <String>[];
    for (final p in _all) {
      final era = isAr ? p.eraAr : p.era;
      if (!eras.contains(era)) eras.add(era);
    }
    final favs = ref.watch(islamicFavoritesProvider).value?[IslamicFavKind.prophet] ??
        const <String>{};
    var visible = _filterEra == null
        ? _all
        : _all
              .where((p) => (isAr ? p.eraAr : p.era) == _filterEra)
              .toList();
    if (_favoritesOnly) {
      visible = visible.where((p) => favs.contains(p.id)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'قصص الأنبياء' : 'Prophet Stories'),
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
              icon: Icons.menu_book_rounded,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _EraChip(
                        label: isAr ? '❤︎ المفضلة' : '❤︎ Favorites',
                        selected: _favoritesOnly,
                        onTap: () =>
                            setState(() => _favoritesOnly = !_favoritesOnly),
                      ),
                      _EraChip(
                        label: isAr ? 'الكل' : 'All',
                        selected: _filterEra == null && !_favoritesOnly,
                        onTap: () => setState(() {
                          _filterEra = null;
                          _favoritesOnly = false;
                        }),
                      ),
                      for (final e in eras)
                        _EraChip(
                          label: e,
                          selected: _filterEra == e,
                          onTap: () => setState(() => _filterEra = e),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final p = visible[i];
                      // Position in the canonical 25-prophet list (1..25).
                      final n = _all.indexOf(p) + 1;
                      final isFocused = p.id == widget.focusId;
                      return FocusHighlight(
                        key: isFocused ? _focusKey : null,
                        focused: p.id == _highlightedId,
                        child: _ProphetCard(p: p, n: n, isAr: isAr),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EraChip extends StatelessWidget {
  const _EraChip({
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

class _ProphetCard extends ConsumerWidget {
  const _ProphetCard({
    required this.p,
    required this.n,
    required this.isAr,
  });
  final _Prophet p;
  final int n;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(46),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(140),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  localizeDigits(n, arabic: isAr),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? p.nameAr : p.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textDark,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isAr ? p.titleAr : p.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark.withAlpha(160),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (ctx, ref2, _) {
                  final isFav = ref2
                          .watch(islamicFavoritesProvider)
                          .value?[IslamicFavKind.prophet]
                          ?.contains(p.id) ??
                      false;
                  return IconButton(
                    onPressed: () => ref2
                        .read(islamicFavoritesProvider.notifier)
                        .toggle(IslamicFavKind.prophet, p.id),
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
              TtsSpeakerIcon(
                text: isAr ? p.storyAr : p.story,
                arabic: isAr,
                size: 18,
                filledTonal: true,
                tooltip: isAr ? 'استمع' : 'Listen',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr ? p.storyAr : p.story,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.accent.withAlpha(100)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr ? p.lessonAr : p.lesson,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 12,
                    ),
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

class _Prophet {
  const _Prophet({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.title,
    required this.titleAr,
    required this.era,
    required this.eraAr,
    required this.story,
    required this.storyAr,
    required this.lesson,
    required this.lessonAr,
  });
  final String id;
  final String name;
  final String nameAr;
  final String title;
  final String titleAr;
  final String era;
  final String eraAr;
  final String story;
  final String storyAr;
  final String lesson;
  final String lessonAr;

  static _Prophet fromJson(Map<String, dynamic> j) => _Prophet(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    nameAr: j['name_ar'] as String? ?? '',
    title: j['title'] as String? ?? '',
    titleAr: j['title_ar'] as String? ?? '',
    era: j['era'] as String? ?? '',
    eraAr: j['era_ar'] as String? ?? '',
    story: j['story'] as String? ?? '',
    storyAr: j['story_ar'] as String? ?? '',
    lesson: j['lesson'] as String? ?? '',
    lessonAr: j['lesson_ar'] as String? ?? '',
  );
}
