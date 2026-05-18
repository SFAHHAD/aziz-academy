import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Six Articles of Faith (Arkan al-Iman) — the doctrinal foundation of
/// Islam, presented as a 6-card overview. Companion to Five Pillars (which
/// is the practice side). Each card shows the article, a kid-friendly
/// explanation, and a related Qur'anic verse with TTS.
class SixArticlesScreen extends ConsumerStatefulWidget {
  const SixArticlesScreen({super.key});

  @override
  ConsumerState<SixArticlesScreen> createState() => _SixArticlesScreenState();
}

class _SixArticlesScreenState extends ConsumerState<SixArticlesScreen> {
  List<_Article> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/six_articles_of_faith.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Article.fromJson).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'أركان الإيمان' : 'Six Articles of Faith'),
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withAlpha(46),
                        AppColors.accent.withAlpha(28),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.secondary.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    isAr
                        ? 'الإيمان مبني على ستة أركان — هي ما يعتقده المسلم في قلبه.'
                        : 'Iman (faith) rests on six articles — what a Muslim believes in their heart.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final a in _all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ArticleCard(a: a, isAr: isAr),
                  ),
              ],
            ),
    );
  }
}

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({required this.a, required this.isAr});
  final _Article a;
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(46),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.secondary.withAlpha(140)),
                ),
                alignment: Alignment.center,
                child: Text(
                  localizeDigits(a.n, arabic: isAr),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? a.nameAr : a.name,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(a.icon, style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? a.whatAr : a.what,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              height: 1.6,
            ),
          ),
          if (a.verseAr.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withAlpha(100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.verseAr,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.textDark,
                            fontSize: 16,
                            height: 1.7,
                          ),
                        ),
                        if (!isAr && a.verse.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            a.verse,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark.withAlpha(180),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TtsSpeakerIcon(
                    text: a.verseAr,
                    size: 20,
                    tooltip: isAr ? 'استمع' : 'Listen',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Article {
  const _Article({
    required this.id,
    required this.n,
    required this.name,
    required this.nameAr,
    required this.what,
    required this.whatAr,
    required this.verse,
    required this.verseAr,
    required this.icon,
  });
  final String id;
  final int n;
  final String name;
  final String nameAr;
  final String what;
  final String whatAr;
  final String verse;
  final String verseAr;
  final String icon;

  static _Article fromJson(Map<String, dynamic> j) => _Article(
    id: j['id'] as String? ?? '',
    n: (j['n'] as num?)?.toInt() ?? 0,
    name: j['name'] as String? ?? '',
    nameAr: j['name_ar'] as String? ?? '',
    what: j['what'] as String? ?? '',
    whatAr: j['what_ar'] as String? ?? '',
    verse: j['verse'] as String? ?? '',
    verseAr: j['verse_ar'] as String? ?? '',
    icon: j['icon'] as String? ?? '☪️',
  );
}
