import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/real_audio_button.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Morning + Evening dhikr (Athkar) — short canonical adhkar from Hisn
/// al-Muslim. Pure static content, two tabs (Morning / Evening), per-line
/// 🔊 button using the device TTS, optional repeat counter shown for items
/// that have a sunnah count (e.g., x٣ or x١٠٠). No network, no plugins
/// beyond flutter_tts (already used by Quran/Alphabet screens).
class AthkarScreen extends ConsumerStatefulWidget {
  const AthkarScreen({super.key});

  @override
  ConsumerState<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends ConsumerState<AthkarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'الأذكار' : 'Athkar'),
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
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.textDark,
          unselectedLabelColor: AppColors.textDark.withAlpha(140),
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: isAr ? 'الصباح ☀️' : 'Morning ☀️'),
            Tab(text: isAr ? 'المساء 🌙' : 'Evening 🌙'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AthkarList(items: _morning, section: 'morning', isAr: isAr),
          _AthkarList(items: _evening, section: 'evening', isAr: isAr),
        ],
      ),
    );
  }
}

class _AthkarList extends ConsumerWidget {
  const _AthkarList({
    required this.items,
    required this.section,
    required this.isAr,
  });
  final List<_Dhikr> items;

  /// `'morning'` or `'evening'` — used to derive the audio asset id
  /// (`morning_NN.mp3` / `evening_NN.mp3`) for [RealAudioButton].
  final String section;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withAlpha(80)),
            ),
            child: Text(
              isAr
                  ? 'أذكار قصيرة من حصن المسلم. اضغط 🔊 لسماع الذكر، والعدّاد يبيّن مرات التكرار المسنونة.'
                  : 'Short adhkar from Hisn al-Muslim. Tap 🔊 to hear it; the counter shows the sunnah repetition count.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
          );
        }
        final d = items[i - 1];
        return _DhikrCard(
          d: d,
          isAr: isAr,
          audioId: '${section}_${(i).toString().padLeft(2, '0')}',
        );
      },
    );
  }
}

class _DhikrCard extends ConsumerStatefulWidget {
  const _DhikrCard({
    required this.d,
    required this.isAr,
    required this.audioId,
  });
  final _Dhikr d;
  final bool isAr;

  /// `'morning_03'` or `'evening_02'` — passed to [RealAudioButton] so the
  /// 🔊 plays the corresponding `assets/audio/azkar/<id>.mp3` once shipped.
  final String audioId;

  @override
  ConsumerState<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends ConsumerState<_DhikrCard> {
  int _tapped = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final remaining = d.repeat - _tapped;
    final done = remaining <= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppColors.success.withAlpha(140)
              : AppColors.outline.withAlpha(80),
          width: done ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.isAr ? d.titleAr : d.title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ),
          Text(
            d.ar,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textDark,
              fontSize: 18,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            d.translation,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark.withAlpha(180),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              RealAudioButton(
                category: 'azkar',
                id: widget.audioId,
                arabicText: d.ar,
                size: 20,
                filledTonal: true,
                tooltip: widget.isAr ? 'استمع' : 'Listen',
              ),
              const Spacer(),
              if (d.repeat > 1)
                GestureDetector(
                  onTap: () {
                    if (_tapped < d.repeat) {
                      setState(() => _tapped += 1);
                    } else {
                      setState(() => _tapped = 0);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.success.withAlpha(40)
                          : AppColors.accent.withAlpha(36),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: done
                            ? AppColors.success.withAlpha(160)
                            : AppColors.accent.withAlpha(120),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(done ? '✓ ' : '× '),
                        Text(
                          done
                              ? (widget.isAr ? 'تمّ' : 'done')
                              : '${localizeDigits(_tapped, arabic: widget.isAr)} / ${localizeDigits(d.repeat, arabic: widget.isAr)}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dhikr {
  const _Dhikr({
    required this.ar,
    required this.translation,
    this.title = '',
    this.titleAr = '',
    this.repeat = 1,
  });
  final String ar;
  final String translation;
  final String title;
  final String titleAr;
  final int repeat;
}

const _morning = <_Dhikr>[
  _Dhikr(
    titleAr: 'آية الكرسي',
    title: 'Ayat al-Kursi',
    ar: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
    translation:
        'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence...',
  ),
  _Dhikr(
    titleAr: 'تسبيح الصباح',
    title: 'Morning glorification',
    ar: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    translation:
        'We have entered the morning and the dominion belongs to Allah; praise is to Allah; none has the right to be worshipped but Him alone.',
  ),
  _Dhikr(
    titleAr: 'سيد الاستغفار',
    title: 'Master supplication for forgiveness',
    ar: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
    translation:
        'O Allah, You are my Lord, none has the right to be worshipped except You. You created me, and I am Your slave, and I keep Your covenant as much as I can.',
  ),
  _Dhikr(
    ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    translation: 'Glory and praise be to Allah.',
    repeat: 100,
  ),
  _Dhikr(
    ar: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    translation:
        'None has the right to be worshipped except Allah alone, with no partner. To Him belongs the dominion and praise, and He has power over all things.',
    repeat: 10,
  ),
  _Dhikr(
    ar: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ',
    translation:
        'In the name of Allah with whose name nothing is harmed on earth or in the heavens; He is the All-Hearing, the All-Knowing.',
    repeat: 3,
  ),
  _Dhikr(
    ar: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
    translation:
        'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.',
    repeat: 3,
  ),
  _Dhikr(
    ar: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ',
    translation:
        'O Allah, grant my body health; O Allah, grant my hearing health; O Allah, grant my sight health. None has the right to be worshipped but You.',
    repeat: 3,
  ),
];

const _evening = <_Dhikr>[
  _Dhikr(
    titleAr: 'آية الكرسي',
    title: 'Ayat al-Kursi',
    ar: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
    translation:
        'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence...',
  ),
  _Dhikr(
    titleAr: 'تسبيح المساء',
    title: 'Evening glorification',
    ar: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    translation:
        'We have entered the evening and the dominion belongs to Allah; praise is to Allah; none has the right to be worshipped but Him alone.',
  ),
  _Dhikr(
    ar: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    translation:
        'I seek refuge in the perfect words of Allah from the evil of what He has created.',
    repeat: 3,
  ),
  _Dhikr(
    ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    translation: 'Glory and praise be to Allah.',
    repeat: 100,
  ),
  _Dhikr(
    ar: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ',
    translation:
        'In the name of Allah with whose name nothing is harmed on earth or in the heavens; He is the All-Hearing, the All-Knowing.',
    repeat: 3,
  ),
  _Dhikr(
    ar: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
    translation:
        'O Allah, by You we enter the evening, and by You we enter the morning; by You we live, by You we die, and to You is the return.',
  ),
  _Dhikr(
    ar: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
    translation:
        'O Allah, I ask You for pardon and well-being in this life and the next.',
  ),
];
