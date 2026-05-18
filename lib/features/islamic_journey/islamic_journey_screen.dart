import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/islamic_favorites_provider.dart';
import 'package:aziz_academy/core/providers/quran_progress_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// "My Islamic Journey" — single-screen progress overview across Quran
/// memorization, Hadith / 99 Names / Prophet favorites. Reads from the
/// existing favorites + Quran progress providers; no new persistence.
/// Designed so a parent can screenshot it and share / celebrate progress.
class IslamicJourneyScreen extends ConsumerStatefulWidget {
  const IslamicJourneyScreen({super.key});

  @override
  ConsumerState<IslamicJourneyScreen> createState() =>
      _IslamicJourneyScreenState();
}

class _IslamicJourneyScreenState
    extends ConsumerState<IslamicJourneyScreen> {
  int _hadithTotal = 0;
  int _asmaTotal = 0;
  int _prophetTotal = 0;
  int _surahTotal = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  /// Read the totals once from the bundled JSON so the "X / N" denominators
  /// reflect reality even if content packs get expanded later.
  Future<void> _loadTotals() async {
    try {
      final hadith = await rootBundle
          .loadString('assets/data/hadith_memorization.json');
      final asma = await rootBundle
          .loadString('assets/data/asma_ul_husna_memorization.json');
      final prophets =
          await rootBundle.loadString('assets/data/prophet_stories.json');
      final surahs =
          await rootBundle.loadString('assets/data/quran_short_surahs.json');
      if (!mounted) return;
      setState(() {
        _hadithTotal = (jsonDecode(hadith) as List).length;
        _asmaTotal = (jsonDecode(asma) as List).length;
        _prophetTotal = (jsonDecode(prophets) as List).length;
        _surahTotal = (jsonDecode(surahs) as List).length;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    final favs = ref.watch(islamicFavoritesProvider).value ??
        const <IslamicFavKind, Set<String>>{};
    final hadithDone = favs[IslamicFavKind.hadith]?.length ?? 0;
    final asmaDone = favs[IslamicFavKind.asma]?.length ?? 0;
    final prophetDone = favs[IslamicFavKind.prophet]?.length ?? 0;
    final memorized = ref.watch(quranProgressProvider).value ??
        const <String>{};
    final surahDone = memorized.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'رحلتي الإسلامية' : 'My Islamic Journey'),
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
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _heroCard(
                  isAr: isAr,
                  totalDone: hadithDone + asmaDone + prophetDone + surahDone,
                ),
                const SizedBox(height: 14),
                _progressCard(
                  isAr: isAr,
                  emoji: '📖',
                  titleEn: 'Surahs memorized',
                  titleAr: 'سور محفوظة',
                  done: surahDone,
                  total: _surahTotal,
                  color: AppColors.secondary,
                  route: AppRoutes.quran,
                ),
                const SizedBox(height: 10),
                _progressCard(
                  isAr: isAr,
                  emoji: '📜',
                  titleEn: 'Hadiths bookmarked',
                  titleAr: 'أحاديث مفضلة',
                  done: hadithDone,
                  total: _hadithTotal,
                  color: AppColors.accent,
                  route: AppRoutes.hadithMemorization,
                ),
                const SizedBox(height: 10),
                _progressCard(
                  isAr: isAr,
                  emoji: '☪️',
                  titleEn: 'Names of Allah loved',
                  titleAr: 'أسماء الله المفضلة',
                  done: asmaDone,
                  total: _asmaTotal,
                  color: AppColors.primary,
                  route: AppRoutes.asmaUlHusna,
                ),
                const SizedBox(height: 10),
                _progressCard(
                  isAr: isAr,
                  emoji: '📿',
                  titleEn: 'Prophets bookmarked',
                  titleAr: 'أنبياء مفضلون',
                  done: prophetDone,
                  total: _prophetTotal,
                  color: AppColors.success,
                  route: AppRoutes.prophetStories,
                ),
                const SizedBox(height: 20),
                _encouragement(
                  isAr: isAr,
                  totalDone:
                      hadithDone + asmaDone + prophetDone + surahDone,
                ),
                const SizedBox(height: 18),
                _quickActions(isAr),
              ],
            ),
    );
  }

  Widget _quickActions(bool isAr) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _quickChip(
          isAr: isAr,
          emoji: '🌟',
          labelEn: 'Daily Wisdom',
          labelAr: 'سؤال اليوم',
          route: AppRoutes.dailyWisdomQuiz,
        ),
        _quickChip(
          isAr: isAr,
          emoji: '🔍',
          labelEn: 'Search',
          labelAr: 'بحث',
          route: AppRoutes.islamicSearch,
        ),
        _quickChip(
          isAr: isAr,
          emoji: '📖',
          labelEn: 'Tajweed',
          labelAr: 'التجويد',
          route: AppRoutes.tajweedBasics,
        ),
        _quickChip(
          isAr: isAr,
          emoji: '🎯',
          labelEn: '99 Names Quiz',
          labelAr: 'اختبار الأسماء',
          route: AppRoutes.asmaUlHusnaQuiz,
        ),
        _quickChip(
          isAr: isAr,
          emoji: '📜',
          labelEn: 'Hadith Quiz',
          labelAr: 'اختبار الأحاديث',
          route: AppRoutes.hadithQuiz,
        ),
        _quickChip(
          isAr: isAr,
          emoji: '📿',
          labelEn: 'Prophet Quiz',
          labelAr: 'اختبار الأنبياء',
          route: AppRoutes.prophetQuiz,
        ),
      ],
    );
  }

  Widget _quickChip({
    required bool isAr,
    required String emoji,
    required String labelEn,
    required String labelAr,
    required String route,
  }) {
    return ActionChip(
      onPressed: () => context.push(route),
      avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
      label: Text(isAr ? labelAr : labelEn),
      backgroundColor: AppColors.surfaceContainerLow,
      side: BorderSide(color: AppColors.outline.withAlpha(80)),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _heroCard({required bool isAr, required int totalDone}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withAlpha(46),
            AppColors.accent.withAlpha(32),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withAlpha(120)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(60),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary.withAlpha(160)),
            ),
            alignment: Alignment.center,
            child: const Text('🕌', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'إنجازاتك' : 'Your achievements',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
                Text(
                  localizeDigits(totalDone, arabic: isAr),
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.textDark,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                Text(
                  isAr
                      ? 'إنجاز إسلامي'
                      : 'Islamic milestones unlocked',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard({
    required bool isAr,
    required String emoji,
    required String titleEn,
    required String titleAr,
    required int done,
    required int total,
    required Color color,
    required String route,
  }) {
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAr ? titleAr : titleEn,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textDark,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  isAr
                      ? '${localizeDigits(done, arabic: true)} / ${localizeDigits(total, arabic: true)}'
                      : '$done / $total',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isAr
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.textDark.withAlpha(140),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: color,
                backgroundColor: AppColors.outline.withAlpha(60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encouragement({required bool isAr, required int totalDone}) {
    final ({String en, String ar}) msg;
    if (totalDone == 0) {
      msg = (
        en: 'Start your journey — tap any card above.',
        ar: 'ابدأ رحلتك — اضغط على أي بطاقة بالأعلى.',
      );
    } else if (totalDone < 5) {
      msg = (
        en: 'A great start! Every small step counts.',
        ar: 'بداية رائعة! كل خطوة صغيرة لها قيمة.',
      );
    } else if (totalDone < 20) {
      msg = (
        en: 'You\'re building a beautiful habit. Keep going!',
        ar: 'أنت تبني عادة رائعة. استمر!',
      );
    } else {
      msg = (
        en: 'Allahu Akbar — incredible progress, MashaAllah!',
        ar: 'الله أكبر — تقدم رائع، ما شاء الله!',
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Text('💚', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr ? msg.ar : msg.en,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
