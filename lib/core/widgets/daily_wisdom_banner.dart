import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Rotates between two daily Islamic wisdom sources to keep the home page
/// fresh without piling on banners: even days surface a Prophet Story
/// snippet, odd days surface a Name of Allah. Pure offline, deterministic.
class DailyWisdomBanner extends ConsumerStatefulWidget {
  const DailyWisdomBanner({super.key});

  @override
  ConsumerState<DailyWisdomBanner> createState() => _DailyWisdomBannerState();
}

class _DailyWisdomBannerState extends ConsumerState<DailyWisdomBanner> {
  _Pick? _todays;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final dayOfYear = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(now.year)).inDays;
      // Even day → prophet, odd day → name. Within each, deterministic pick.
      if (dayOfYear.isEven) {
        await _loadProphet(dayOfYear);
      } else {
        await _loadName(dayOfYear);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  Future<void> _loadProphet(int dayOfYear) async {
    final raw = await rootBundle.loadString('assets/data/prophet_stories.json');
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    if (!mounted) return;
    if (list.isEmpty) {
      setState(() => _loaded = true);
      return;
    }
    final m = list[(dayOfYear ~/ 2) % list.length];
    setState(() {
      _todays = _Pick(
        kind: _Kind.prophet,
        titleEn: m['name'] as String? ?? '',
        titleAr: m['name_ar'] as String? ?? '',
        ar: m['story_ar'] as String? ?? '',
        translation: m['story'] as String? ?? '',
        route: AppRoutes.prophetStories,
        emoji: '📿',
      );
      _loaded = true;
    });
  }

  Future<void> _loadName(int dayOfYear) async {
    final raw = await rootBundle.loadString(
      'assets/data/asma_ul_husna_memorization.json',
    );
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    if (!mounted) return;
    if (list.isEmpty) {
      setState(() => _loaded = true);
      return;
    }
    final m = list[(dayOfYear ~/ 2) % list.length];
    setState(() {
      _todays = _Pick(
        kind: _Kind.name,
        titleEn: m['name'] as String? ?? '',
        titleAr: m['name_ar'] as String? ?? '',
        ar: m['name_ar'] as String? ?? '',
        translation: m['en'] as String? ?? '',
        route: AppRoutes.asmaUlHusna,
        emoji: '☪️',
      );
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _todays == null) return const SizedBox.shrink();
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final p = _todays!;

    final tagEn = p.kind == _Kind.prophet
        ? 'Prophet of the day'
        : 'Name of Allah today';
    final tagAr = p.kind == _Kind.prophet ? 'نبي اليوم' : 'اسم اليوم';

    return InkWell(
      onTap: () => context.push(p.route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: p.kind == _Kind.prophet
                ? [
                    AppColors.secondary.withAlpha(40),
                    AppColors.accent.withAlpha(28),
                  ]
                : [
                    AppColors.accent.withAlpha(52),
                    AppColors.secondary.withAlpha(28),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.secondary.withAlpha(110)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? '$tagAr — ${p.titleAr}'
                        : '$tagEn — ${p.titleEn}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (p.kind == _Kind.name)
                    Text(
                      p.ar,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textDark,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    )
                  else
                    Text(
                      isAr ? p.ar : p.translation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: isAr
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => ref.read(ttsServiceProvider).speakArabic(p.ar),
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              color: AppColors.textDark,
              tooltip: isAr ? 'استمع' : 'Listen',
            ),
          ],
        ),
      ),
    );
  }
}

enum _Kind { prophet, name }

class _Pick {
  const _Pick({
    required this.kind,
    required this.titleEn,
    required this.titleAr,
    required this.ar,
    required this.translation,
    required this.route,
    required this.emoji,
  });
  final _Kind kind;
  final String titleEn;
  final String titleAr;
  final String ar;
  final String translation;
  final String route;
  final String emoji;
}
