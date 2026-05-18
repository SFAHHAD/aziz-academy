import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// English alphabet trainer — 26 letters A-Z with phonetic name, example
/// word + emoji, and the Arabic translation of the example. Mirrors the
/// Arabic alphabet screen. Tap a tile to highlight + see details. The
/// "listen" button hides when AI voices are off (real-audio-only policy
/// from v1.1.96); when real phonics audio is wired this becomes the
/// playback site.
class EnglishAlphabetScreen extends ConsumerStatefulWidget {
  const EnglishAlphabetScreen({super.key});

  @override
  ConsumerState<EnglishAlphabetScreen> createState() =>
      _EnglishAlphabetScreenState();
}

class _EnglishAlphabetScreenState
    extends ConsumerState<EnglishAlphabetScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? '🔤 الحروف الإنجليزية' : '🔤 English Letters'),
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
          if (_selected != null)
            _LetterDetail(letter: _selected!, arabic: isAr),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _alphabet.length,
              itemBuilder: (ctx, i) {
                final entry = _alphabet[i];
                final isSelected = _selected == entry.letter;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() => _selected = entry.letter);
                    // Speech is muted in real-audio-only mode (the
                    // default). If a parent enables AI voices, this
                    // letter gets pronounced.
                    ref.read(ttsServiceProvider).speakEnglish(entry.name);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(40)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.letter,
                            style: AppTextStyles.headingLarge.copyWith(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            entry.lower,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontFamily: 'JetBrainsMono',
                              color: AppColors.textDark.withAlpha(150),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterDetail extends StatelessWidget {
  const _LetterDetail({required this.letter, required this.arabic});
  final String letter;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final entry =
        _alphabet.firstWhere((e) => e.letter == letter);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withAlpha(36),
            AppColors.accent.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withAlpha(120)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary.withAlpha(140)),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.letter,
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontFamily: 'JetBrainsMono',
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic ? entry.nameAr : entry.name,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arabic
                      ? '${entry.emoji}  ${entry.exampleWord} = ${entry.exampleMeaningAr}'
                      : '${entry.emoji}  ${entry.exampleWord}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TtsSpeakerIcon(
            text: entry.exampleWord,
            arabic: false,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _LetterEntry {
  const _LetterEntry({
    required this.letter,
    required this.lower,
    required this.name,
    required this.nameAr,
    required this.exampleWord,
    required this.exampleMeaning,
    required this.exampleMeaningAr,
    required this.emoji,
  });
  final String letter;
  final String lower;
  final String name;
  final String nameAr;
  final String exampleWord;
  final String exampleMeaning;
  final String exampleMeaningAr;
  final String emoji;
}

const List<_LetterEntry> _alphabet = [
  _LetterEntry(letter: 'A', lower: 'a', name: 'A', nameAr: 'إيه',
      exampleWord: 'Apple', exampleMeaning: 'apple',
      exampleMeaningAr: 'تفاح', emoji: '🍎'),
  _LetterEntry(letter: 'B', lower: 'b', name: 'B', nameAr: 'بي',
      exampleWord: 'Ball', exampleMeaning: 'ball',
      exampleMeaningAr: 'كرة', emoji: '⚽'),
  _LetterEntry(letter: 'C', lower: 'c', name: 'C', nameAr: 'سي',
      exampleWord: 'Cat', exampleMeaning: 'cat',
      exampleMeaningAr: 'قطة', emoji: '🐱'),
  _LetterEntry(letter: 'D', lower: 'd', name: 'D', nameAr: 'دي',
      exampleWord: 'Dog', exampleMeaning: 'dog',
      exampleMeaningAr: 'كلب', emoji: '🐶'),
  _LetterEntry(letter: 'E', lower: 'e', name: 'E', nameAr: 'إي',
      exampleWord: 'Egg', exampleMeaning: 'egg',
      exampleMeaningAr: 'بيضة', emoji: '🥚'),
  _LetterEntry(letter: 'F', lower: 'f', name: 'F', nameAr: 'إف',
      exampleWord: 'Fish', exampleMeaning: 'fish',
      exampleMeaningAr: 'سمكة', emoji: '🐟'),
  _LetterEntry(letter: 'G', lower: 'g', name: 'G', nameAr: 'جي',
      exampleWord: 'Goat', exampleMeaning: 'goat',
      exampleMeaningAr: 'ماعز', emoji: '🐐'),
  _LetterEntry(letter: 'H', lower: 'h', name: 'H', nameAr: 'إتش',
      exampleWord: 'House', exampleMeaning: 'house',
      exampleMeaningAr: 'بيت', emoji: '🏠'),
  _LetterEntry(letter: 'I', lower: 'i', name: 'I', nameAr: 'آي',
      exampleWord: 'Ice', exampleMeaning: 'ice',
      exampleMeaningAr: 'ثلج', emoji: '🧊'),
  _LetterEntry(letter: 'J', lower: 'j', name: 'J', nameAr: 'جاي',
      exampleWord: 'Jam', exampleMeaning: 'jam',
      exampleMeaningAr: 'مربى', emoji: '🍯'),
  _LetterEntry(letter: 'K', lower: 'k', name: 'K', nameAr: 'كاي',
      exampleWord: 'Kite', exampleMeaning: 'kite',
      exampleMeaningAr: 'طائرة ورقية', emoji: '🪁'),
  _LetterEntry(letter: 'L', lower: 'l', name: 'L', nameAr: 'إل',
      exampleWord: 'Lion', exampleMeaning: 'lion',
      exampleMeaningAr: 'أسد', emoji: '🦁'),
  _LetterEntry(letter: 'M', lower: 'm', name: 'M', nameAr: 'إم',
      exampleWord: 'Moon', exampleMeaning: 'moon',
      exampleMeaningAr: 'قمر', emoji: '🌙'),
  _LetterEntry(letter: 'N', lower: 'n', name: 'N', nameAr: 'إن',
      exampleWord: 'Nest', exampleMeaning: 'nest',
      exampleMeaningAr: 'عش', emoji: '🪺'),
  _LetterEntry(letter: 'O', lower: 'o', name: 'O', nameAr: 'أو',
      exampleWord: 'Orange', exampleMeaning: 'orange',
      exampleMeaningAr: 'برتقال', emoji: '🍊'),
  _LetterEntry(letter: 'P', lower: 'p', name: 'P', nameAr: 'بي',
      exampleWord: 'Pen', exampleMeaning: 'pen',
      exampleMeaningAr: 'قلم', emoji: '🖊️'),
  _LetterEntry(letter: 'Q', lower: 'q', name: 'Q', nameAr: 'كيو',
      exampleWord: 'Queen', exampleMeaning: 'queen',
      exampleMeaningAr: 'ملكة', emoji: '👑'),
  _LetterEntry(letter: 'R', lower: 'r', name: 'R', nameAr: 'آر',
      exampleWord: 'Rain', exampleMeaning: 'rain',
      exampleMeaningAr: 'مطر', emoji: '🌧️'),
  _LetterEntry(letter: 'S', lower: 's', name: 'S', nameAr: 'إس',
      exampleWord: 'Sun', exampleMeaning: 'sun',
      exampleMeaningAr: 'شمس', emoji: '☀️'),
  _LetterEntry(letter: 'T', lower: 't', name: 'T', nameAr: 'تي',
      exampleWord: 'Tree', exampleMeaning: 'tree',
      exampleMeaningAr: 'شجرة', emoji: '🌳'),
  _LetterEntry(letter: 'U', lower: 'u', name: 'U', nameAr: 'يو',
      exampleWord: 'Umbrella', exampleMeaning: 'umbrella',
      exampleMeaningAr: 'مظلة', emoji: '☂️'),
  _LetterEntry(letter: 'V', lower: 'v', name: 'V', nameAr: 'في',
      exampleWord: 'Van', exampleMeaning: 'van',
      exampleMeaningAr: 'شاحنة صغيرة', emoji: '🚐'),
  _LetterEntry(letter: 'W', lower: 'w', name: 'W', nameAr: 'دبليو',
      exampleWord: 'Water', exampleMeaning: 'water',
      exampleMeaningAr: 'ماء', emoji: '💧'),
  _LetterEntry(letter: 'X', lower: 'x', name: 'X', nameAr: 'إكس',
      exampleWord: 'X-ray', exampleMeaning: 'x-ray',
      exampleMeaningAr: 'أشعة', emoji: '🩻'),
  _LetterEntry(letter: 'Y', lower: 'y', name: 'Y', nameAr: 'واي',
      exampleWord: 'Yarn', exampleMeaning: 'yarn',
      exampleMeaningAr: 'خيط', emoji: '🧶'),
  _LetterEntry(letter: 'Z', lower: 'z', name: 'Z', nameAr: 'زد',
      exampleWord: 'Zebra', exampleMeaning: 'zebra',
      exampleMeaningAr: 'حمار وحشي', emoji: '🦓'),
];
