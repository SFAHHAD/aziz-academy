import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Home-screen banner that surfaces one hadith per day from the memorization
/// pack. Deterministic — picks `dayOfYear % totalHadiths` so every kid sees
/// the same hadith on the same day. Tap to open the Hadith memorization
/// screen. Pure offline, no network.
class DailyHadithBanner extends ConsumerStatefulWidget {
  const DailyHadithBanner({super.key});

  @override
  ConsumerState<DailyHadithBanner> createState() => _DailyHadithBannerState();
}

class _DailyHadithBannerState extends ConsumerState<DailyHadithBanner> {
  _Pick? _todays;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/hadith_memorization.json',
      );
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _loaded = true);
        return;
      }
      final now = DateTime.now();
      final dayOfYear = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(now.year)).inDays;
      final m = list[dayOfYear % list.length];
      if (!mounted) return;
      setState(() {
        _todays = _Pick(
          ar: m['ar'] as String? ?? '',
          translation: m['translation'] as String? ?? '',
          titleEn: m['title'] as String? ?? '',
          titleAr: m['title_ar'] as String? ?? '',
        );
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
    final p = _todays!;
    return InkWell(
      onTap: () => context.push(AppRoutes.hadithMemorization),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withAlpha(46),
              AppColors.accent.withAlpha(28),
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
              child: const Text('📜', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr
                        ? 'حديث اليوم — ${p.titleAr}'
                        : 'Hadith of the day — ${p.titleEn}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.ar,
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
                      p.translation,
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
            // v1.1.96 "real audio only": only show the speak button when the
            // parent has explicitly re-enabled AI voices. Otherwise the icon
            // looks interactive but does nothing — confusing for kids.
            if (ref.watch(appSettingsProvider).value?.ttsEnabled ?? false)
              IconButton(
                onPressed: () =>
                    ref.read(ttsServiceProvider).speakArabic(p.ar),
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

class _Pick {
  const _Pick({
    required this.ar,
    required this.translation,
    required this.titleEn,
    required this.titleAr,
  });
  final String ar;
  final String translation;
  final String titleEn;
  final String titleAr;
}
