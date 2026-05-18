import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/quran_recitation_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Home-screen banner that surfaces one Qur'an verse per day from the
/// short-surahs pack. Deterministic — picks `dayOfYear % totalVerses` so
/// every kid sees the same verse on the same day. Tap to open the full
/// Quran screen. Pure offline, no network.
class DailyVerseBanner extends ConsumerStatefulWidget {
  const DailyVerseBanner({super.key});

  @override
  ConsumerState<DailyVerseBanner> createState() => _DailyVerseBannerState();
}

class _DailyVerseBannerState extends ConsumerState<DailyVerseBanner> {
  _Verse? _todays;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/quran_short_surahs.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      final flat = <_Verse>[];
      for (final s in list) {
        final surahId = s['id'] as String? ?? '';
        final surahName = s['name'] as String? ?? '';
        final surahNameAr = s['name_ar'] as String? ?? surahName;
        final verses =
            (s['verses'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        for (final v in verses) {
          flat.add(
            _Verse(
              ar: v['ar'] as String? ?? '',
              en: v['en'] as String? ?? '',
              surahId: surahId,
              surahName: surahName,
              surahNameAr: surahNameAr,
              verseNumber: (v['n'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
      if (!mounted) return;
      if (flat.isEmpty) {
        setState(() => _loaded = true);
        return;
      }
      final now = DateTime.now();
      final dayOfYear = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(now.year)).inDays;
      final pick = flat[dayOfYear % flat.length];
      if (!mounted) return;
      setState(() {
        _todays = pick;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _todays == null) return const SizedBox.shrink();
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final v = _todays!;
    return InkWell(
      onTap: () => context.push(AppRoutes.quran),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withAlpha(48),
              AppColors.secondary.withAlpha(36),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withAlpha(120)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Text('📖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? 'آية اليوم — ${v.surahNameAr}'
                        : 'Verse of the day — ${v.surahName}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.ar,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textDark,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (!isAr) ...[
                    const SizedBox(height: 2),
                    Text(
                      v.en,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark.withAlpha(180),
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () async {
                try {
                  await ref.read(quranRecitationServiceProvider).playVerse(
                    surahId: v.surahId,
                    verseNumber: v.verseNumber,
                  );
                } catch (_) {
                  await ref.read(ttsServiceProvider).speakArabic(v.ar);
                }
              },
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

class _Verse {
  const _Verse({
    required this.ar,
    required this.en,
    required this.surahId,
    required this.surahName,
    required this.surahNameAr,
    required this.verseNumber,
  });
  final String ar;
  final String en;
  final String surahId;
  final String surahName;
  final String surahNameAr;
  final int verseNumber;
}
