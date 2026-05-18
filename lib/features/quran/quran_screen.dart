import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/quran_progress_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/quran_recitation_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Short-surah memorization screen — reads from `quran_short_surahs.json`,
/// shows verses bilingual (Arabic + English meaning), and offers a
/// fill-in-the-blank memorization quiz per surah.
class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  List<_Surah> _surahs = const [];
  bool _loading = true;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final byteData = await rootBundle.load(
        'assets/data/quran_short_surahs.json',
      );
      final str = utf8.decode(byteData.buffer.asUint8List());
      final list = jsonDecode(str) as List<dynamic>;
      setState(() {
        _surahs = list
            .map((e) => _Surah.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
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
        title: Text(isAr ? '📖 السور القصيرة' : '📖 Short Surahs'),
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
          : _surahs.isEmpty
          ? Center(
              child: Text(
                isAr ? 'لا تتوفر السور حالياً' : 'No surahs available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            )
          : Column(
              children: [
                // Memorization progress strip — shows X / N at a glance so
                // the kid sees their progress climb as they tick surahs.
                Consumer(
                  builder: (ctx, ref2, _) {
                    final memorized =
                        ref2.watch(quranProgressProvider).value ??
                            const <String>{};
                    final total = _surahs.length;
                    final done = memorized.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: AppColors.surfaceContainerLow,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAr
                                ? '${localizeDigits(done, arabic: true)} من ${localizeDigits(total, arabic: true)} سورة محفوظة'
                                : '$done / $total surahs memorized',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : done / total,
                                minHeight: 6,
                                color: AppColors.secondary,
                                backgroundColor:
                                    AppColors.outline.withAlpha(60),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 56,
                  child: Consumer(
                    builder: (ctx, ref2, _) {
                      final memorized =
                          ref2.watch(quranProgressProvider).value ??
                              const <String>{};
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (ctx, i) {
                          final s = _surahs[i];
                          final selected = i == _idx;
                          final isDone = memorized.contains(s.id);
                          final num =
                              QuranRecitationService.surahNumberFor(s.id);
                          final base = num == null
                              ? (isAr ? s.nameAr : s.name)
                              : '${localizeDigits(num, arabic: isAr)} · ${isAr ? s.nameAr : s.name}';
                          final label = isDone ? '★ $base' : base;
                          return Center(
                            child: ChoiceChip(
                              label: Text(label),
                              selected: selected,
                              selectedColor: isDone
                                  ? AppColors.secondary.withAlpha(80)
                                  : null,
                              onSelected: (_) =>
                                  setState(() => _idx = i),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemCount: _surahs.length,
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _SurahView(
                    surah: _surahs[_idx],
                    surahId: _surahs[_idx].id,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SurahView extends ConsumerStatefulWidget {
  const _SurahView({required this.surah, required this.surahId});
  final _Surah surah;
  final String surahId;

  @override
  ConsumerState<_SurahView> createState() => _SurahViewState();
}

class _SurahViewState extends ConsumerState<_SurahView> {
  bool _playingFull = false;
  int _currentVerse = 0;

  @override
  void didUpdateWidget(_SurahView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // User switched to a different surah while audio was playing — stop the
    // loop and reset highlight so the new surah doesn't show a phantom
    // playback indicator on the wrong verse.
    if (oldWidget.surahId != widget.surahId && _playingFull) {
      _stopFullSurah();
    }
  }

  @override
  void dispose() {
    // Stop any in-flight recitation so the audio doesn't keep playing after
    // the screen has been popped from the navigator.
    if (_playingFull) {
      ref.read(quranRecitationServiceProvider).stop();
    }
    super.dispose();
  }

  Future<void> _playFullSurah() async {
    final recit = ref.read(quranRecitationServiceProvider);
    setState(() {
      _playingFull = true;
      _currentVerse = 0;
    });
    try {
      for (var i = 0; i < widget.surah.verses.length; i++) {
        if (!mounted || !_playingFull) break;
        setState(() => _currentVerse = i);
        try {
          // playVerse awaits actual playback completion (built-in
          // onPlayerComplete future + 120s timeout), so we can chain verses
          // without polling.
          await recit.playVerse(
            surahId: widget.surahId,
            verseNumber: widget.surah.verses[i].n,
          );
        } catch (_) {
          // Network/CORS error — abort full-surah playback gracefully.
          break;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _playingFull = false;
          _currentVerse = 0;
        });
      }
    }
  }

  void _stopFullSurah() {
    setState(() => _playingFull = false);
    ref.read(quranRecitationServiceProvider).stop();
  }

  /// Repeat a single verse 3 times for memorization. Kids learning Quran
  /// hear → repeat back → hear → repeat. The button stays "active" via the
  /// current-verse highlight until the loop finishes.
  Future<void> _memorizeVerse(int verseNumber) async {
    final recit = ref.read(quranRecitationServiceProvider);
    final idx = widget.surah.verses.indexWhere((x) => x.n == verseNumber);
    if (idx < 0) return;
    setState(() {
      _playingFull = true;
      _currentVerse = idx;
    });
    try {
      for (var i = 0; i < 3; i++) {
        if (!mounted || !_playingFull) break;
        try {
          await recit.playVerse(
            surahId: widget.surahId,
            verseNumber: verseNumber,
          );
        } catch (_) {
          // CDN unreachable — fall back to TTS once, then stop the loop.
          await ref.read(ttsServiceProvider).speakArabic(
                widget.surah.verses[idx].ar,
              );
          break;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _playingFull = false;
          _currentVerse = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer(
                builder: (ctx, ref2, _) {
                  final memorized =
                      ref2.watch(quranProgressProvider).value ??
                          const <String>{};
                  final isDone = memorized.contains(widget.surahId);
                  return OutlinedButton.icon(
                    onPressed: () => ref2
                        .read(quranProgressProvider.notifier)
                        .toggle(widget.surahId),
                    icon: Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isDone ? AppColors.secondary : null,
                    ),
                    label: Text(
                      isDone
                          ? (isAr ? 'محفوظة' : 'Memorized')
                          : (isAr ? 'علِّم كمحفوظة' : 'Mark memorized'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _playingFull ? _stopFullSurah : _playFullSurah,
                icon: Icon(
                  _playingFull
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  _playingFull
                      ? (isAr ? 'إيقاف' : 'Stop')
                      : (isAr ? 'تشغيل السورة' : 'Play full'),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildVerseList(context)),
      ],
    );
  }

  Widget _buildVerseList(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: widget.surah.verses.length,
      itemBuilder: (ctx, i) {
        final v = widget.surah.verses[i];
        final highlighted = _playingFull && i == _currentVerse;
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Container(
            decoration: highlighted
                ? BoxDecoration(
                    color: AppColors.accent.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            padding: highlighted
                ? const EdgeInsets.all(8)
                : EdgeInsets.zero,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      v.n.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_outlined,
                      color: AppColors.secondary,
                    ),
                    tooltip: isAr ? 'استمع' : 'Listen',
                    onPressed: () async {
                      // Real reciter audio first (Mishary Alafasy via everyayah.com).
                      // Falls back to TTS if the network call fails (offline, CORS,
                      // or surah id not in the mapping).
                      try {
                        await ref.read(quranRecitationServiceProvider).playVerse(
                          surahId: widget.surahId,
                          verseNumber: v.n,
                        );
                      } catch (_) {
                        await ref.read(ttsServiceProvider).speakArabic(v.ar);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.repeat_rounded,
                      color: AppColors.accent,
                    ),
                    tooltip: isAr
                        ? 'احفظ — كرر ٣ مرات'
                        : 'Memorize — repeat 3×',
                    onPressed: () => _memorizeVerse(v.n),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                v.ar,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textDark,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                v.en,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              if (v.transliteration != null) ...[
                const SizedBox(height: 4),
                Text(
                  v.transliteration!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
          ),
        );
      },
    );
  }
}

class _Surah {
  const _Surah({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.verseCount,
    required this.verses,
  });
  final String id;
  final String name;
  final String nameAr;
  final int verseCount;
  final List<_Verse> verses;

  factory _Surah.fromJson(Map<String, dynamic> m) => _Surah(
    id: m['id'] as String,
    name: m['name'] as String,
    nameAr: m['name_ar'] as String,
    verseCount: (m['verse_count'] as num).toInt(),
    verses: (m['verses'] as List)
        .map((e) => _Verse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class _Verse {
  const _Verse({
    required this.n,
    required this.ar,
    required this.en,
    this.transliteration,
  });
  final int n;
  final String ar;
  final String en;
  final String? transliteration;

  factory _Verse.fromJson(Map<String, dynamic> m) => _Verse(
    n: (m['n'] as num).toInt(),
    ar: m['ar'] as String,
    en: m['en'] as String,
    transliteration: m['transliteration'] as String?,
  );
}
