import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/features/islamic_search/islamic_search.dart';

/// Cross-content search over Hadith, 99 Names, Prophets, and Duas.
/// One text input, results grouped by section. Tapping a result deep
/// links into the source screen so the kid lands in context.
class IslamicSearchScreen extends ConsumerStatefulWidget {
  const IslamicSearchScreen({super.key});

  @override
  ConsumerState<IslamicSearchScreen> createState() =>
      _IslamicSearchScreenState();
}

class _IslamicSearchScreenState extends ConsumerState<IslamicSearchScreen> {
  final _ctrl = TextEditingController();
  List<SearchHit> _index = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadIndex();
    _ctrl.addListener(() {
      if (mounted) setState(() => _query = _ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadIndex() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/data/hadith_memorization.json'),
        rootBundle.loadString('assets/data/asma_ul_husna_memorization.json'),
        rootBundle.loadString('assets/data/prophet_stories.json'),
        rootBundle.loadString('assets/data/dua_memorization.json'),
      ]);
      final hadith = (jsonDecode(results[0]) as List).cast<Map<String, dynamic>>();
      final asma = (jsonDecode(results[1]) as List).cast<Map<String, dynamic>>();
      final prophets = (jsonDecode(results[2]) as List).cast<Map<String, dynamic>>();
      final duas = (jsonDecode(results[3]) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _index = [
          ...hadith.map(indexHadith),
          ...asma.map(indexAsmaName),
          ...prophets.map(indexProphet),
          ...duas.map(indexDua),
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onHitTap(SearchHit hit) {
    // Deep-link with ?focusId — the receiving screen scrolls the
    // matching card into view and flashes a brief border highlight.
    final route = switch (hit.section) {
      SearchSection.hadith => AppRoutes.hadithMemorization,
      SearchSection.asma => AppRoutes.asmaUlHusna,
      SearchSection.prophet => AppRoutes.prophetStories,
      SearchSection.dua => AppRoutes.duaMemorization,
    };
    context.push('$route?focusId=${Uri.encodeQueryComponent(hit.id)}');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final hits = runSearch(_index, _query);
    final grouped = groupBySection(hits);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'بحث إسلامي' : 'Islamic Search'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: isAr
                    ? 'ابحث عن حديث، اسم، نبي، دعاء…'
                    : 'Search hadith, names, prophets, duas…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: isAr ? 'مسح' : 'Clear',
                        onPressed: () => _ctrl.clear(),
                      ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outline.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outline.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.secondary, width: 1.6),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _index.isEmpty
                    ? ContentEmptyState(
                        icon: Icons.search_off_rounded,
                        onRetry: () {
                          setState(() => _loading = true);
                          _loadIndex();
                        },
                      )
                    : _query.trim().isEmpty
                        ? _idleView(isAr)
                        : hits.isEmpty
                            ? _noResults(isAr)
                            : _resultsView(grouped, isAr),
          ),
        ],
      ),
    );
  }

  Widget _idleView(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          isAr
              ? 'ابدأ الكتابة لتبحث في الأحاديث والأسماء الحسنى وقصص الأنبياء والأدعية.'
              : 'Start typing to search across hadiths, the 99 Names, prophets, and duas.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark.withAlpha(180),
          ),
        ),
      ),
    );
  }

  Widget _noResults(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد نتائج' : 'No results',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAr
                  ? 'جرّب كلمة أخرى أو تهجئة مختلفة.'
                  : 'Try another word or different spelling.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsView(Map<SearchSection, List<SearchHit>> grouped, bool isAr) {
    final order = [
      SearchSection.hadith,
      SearchSection.asma,
      SearchSection.prophet,
      SearchSection.dua,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final section in order)
          if (grouped[section] != null && grouped[section]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
              child: Row(
                children: [
                  Text(
                    _sectionEmoji(section),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sectionLabel(section, isAr),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${grouped[section]!.length})',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            for (final hit in grouped[section]!.take(50))
              _HitTile(
                hit: hit,
                isAr: isAr,
                onTap: () => _onHitTap(hit),
              ),
          ],
      ],
    );
  }

  String _sectionEmoji(SearchSection s) => switch (s) {
        SearchSection.hadith => '📜',
        SearchSection.asma => '☪️',
        SearchSection.prophet => '📿',
        SearchSection.dua => '🤲',
      };

  String _sectionLabel(SearchSection s, bool isAr) => switch (s) {
        SearchSection.hadith => isAr ? 'الأحاديث' : 'Hadith',
        SearchSection.asma => isAr ? 'الأسماء الحسنى' : '99 Names',
        SearchSection.prophet => isAr ? 'الأنبياء' : 'Prophets',
        SearchSection.dua => isAr ? 'الأدعية' : 'Duas',
      };
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.isAr, required this.onTap});
  final SearchHit hit;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = isAr ? hit.titleAr : hit.titleEn;
    final snippet = isAr ? hit.snippetAr : hit.snippetEn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isNotEmpty ? title : '—',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark.withAlpha(180),
                    fontSize: 12,
                    height: 1.4,
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
