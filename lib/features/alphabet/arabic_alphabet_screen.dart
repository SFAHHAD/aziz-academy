import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Arabic alphabet trainer — 28 letters + harakat. Tap a letter to hear it
/// read aloud and see an example word. Pure display + TTS, no canvas
/// drawing yet (deferred — needs gesture-tracking widget). Designed for
/// pre-readers and ages 4-7 picking up the script.
class ArabicAlphabetScreen extends ConsumerStatefulWidget {
  const ArabicAlphabetScreen({super.key});

  @override
  ConsumerState<ArabicAlphabetScreen> createState() =>
      _ArabicAlphabetScreenState();
}

class _ArabicAlphabetScreenState extends ConsumerState<ArabicAlphabetScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? '🔤 الحروف العربية' : '🔤 Arabic Letters'),
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
                    ref.read(ttsServiceProvider).speakArabic(entry.letter);
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
                      child: Text(
                        entry.letter,
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textDark,
                          fontSize: 36,
                        ),
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

class _LetterDetail extends ConsumerWidget {
  const _LetterDetail({required this.letter, required this.arabic});
  final String letter;
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = _alphabet.firstWhere(
      (e) => e.letter == letter,
      orElse: () => _alphabet.first,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(28),
            AppColors.secondary.withAlpha(28),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(letter, style: const TextStyle(fontSize: 64, height: 1)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic ? entry.nameAr : entry.name,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${arabic ? "مثال" : "Example"}:  ${entry.exampleWord}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                Text(
                  arabic ? entry.exampleMeaningAr : entry.exampleMeaning,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          TtsSpeakerIcon(
            text: entry.exampleWord,
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
    required this.name,
    required this.nameAr,
    required this.exampleWord,
    required this.exampleMeaning,
    required this.exampleMeaningAr,
  });
  final String letter;
  final String name;
  final String nameAr;
  final String exampleWord;
  final String exampleMeaning;
  final String exampleMeaningAr;
}

const List<_LetterEntry> _alphabet = [
  _LetterEntry(
    letter: 'ا',
    name: 'Alif',
    nameAr: 'ألف',
    exampleWord: 'أسد',
    exampleMeaning: 'lion',
    exampleMeaningAr: 'أسد',
  ),
  _LetterEntry(
    letter: 'ب',
    name: 'Ba',
    nameAr: 'باء',
    exampleWord: 'باب',
    exampleMeaning: 'door',
    exampleMeaningAr: 'باب',
  ),
  _LetterEntry(
    letter: 'ت',
    name: 'Ta',
    nameAr: 'تاء',
    exampleWord: 'تفاح',
    exampleMeaning: 'apple',
    exampleMeaningAr: 'تفاح',
  ),
  _LetterEntry(
    letter: 'ث',
    name: 'Tha',
    nameAr: 'ثاء',
    exampleWord: 'ثعلب',
    exampleMeaning: 'fox',
    exampleMeaningAr: 'ثعلب',
  ),
  _LetterEntry(
    letter: 'ج',
    name: 'Jeem',
    nameAr: 'جيم',
    exampleWord: 'جمل',
    exampleMeaning: 'camel',
    exampleMeaningAr: 'جمل',
  ),
  _LetterEntry(
    letter: 'ح',
    name: 'Ha',
    nameAr: 'حاء',
    exampleWord: 'حصان',
    exampleMeaning: 'horse',
    exampleMeaningAr: 'حصان',
  ),
  _LetterEntry(
    letter: 'خ',
    name: 'Kha',
    nameAr: 'خاء',
    exampleWord: 'خبز',
    exampleMeaning: 'bread',
    exampleMeaningAr: 'خبز',
  ),
  _LetterEntry(
    letter: 'د',
    name: 'Dal',
    nameAr: 'دال',
    exampleWord: 'دب',
    exampleMeaning: 'bear',
    exampleMeaningAr: 'دب',
  ),
  _LetterEntry(
    letter: 'ذ',
    name: 'Dhal',
    nameAr: 'ذال',
    exampleWord: 'ذهب',
    exampleMeaning: 'gold',
    exampleMeaningAr: 'ذهب',
  ),
  _LetterEntry(
    letter: 'ر',
    name: 'Ra',
    nameAr: 'راء',
    exampleWord: 'رمان',
    exampleMeaning: 'pomegranate',
    exampleMeaningAr: 'رمان',
  ),
  _LetterEntry(
    letter: 'ز',
    name: 'Zay',
    nameAr: 'زاي',
    exampleWord: 'زرافة',
    exampleMeaning: 'giraffe',
    exampleMeaningAr: 'زرافة',
  ),
  _LetterEntry(
    letter: 'س',
    name: 'Seen',
    nameAr: 'سين',
    exampleWord: 'سمك',
    exampleMeaning: 'fish',
    exampleMeaningAr: 'سمك',
  ),
  _LetterEntry(
    letter: 'ش',
    name: 'Sheen',
    nameAr: 'شين',
    exampleWord: 'شمس',
    exampleMeaning: 'sun',
    exampleMeaningAr: 'شمس',
  ),
  _LetterEntry(
    letter: 'ص',
    name: 'Sad',
    nameAr: 'صاد',
    exampleWord: 'صقر',
    exampleMeaning: 'falcon',
    exampleMeaningAr: 'صقر',
  ),
  _LetterEntry(
    letter: 'ض',
    name: 'Dad',
    nameAr: 'ضاد',
    exampleWord: 'ضفدع',
    exampleMeaning: 'frog',
    exampleMeaningAr: 'ضفدع',
  ),
  _LetterEntry(
    letter: 'ط',
    name: 'Ta (heavy)',
    nameAr: 'طاء',
    exampleWord: 'طائر',
    exampleMeaning: 'bird',
    exampleMeaningAr: 'طائر',
  ),
  _LetterEntry(
    letter: 'ظ',
    name: 'Dha',
    nameAr: 'ظاء',
    exampleWord: 'ظل',
    exampleMeaning: 'shadow',
    exampleMeaningAr: 'ظل',
  ),
  _LetterEntry(
    letter: 'ع',
    name: 'Ayn',
    nameAr: 'عين',
    exampleWord: 'عين',
    exampleMeaning: 'eye',
    exampleMeaningAr: 'عين',
  ),
  _LetterEntry(
    letter: 'غ',
    name: 'Ghayn',
    nameAr: 'غين',
    exampleWord: 'غزال',
    exampleMeaning: 'gazelle',
    exampleMeaningAr: 'غزال',
  ),
  _LetterEntry(
    letter: 'ف',
    name: 'Fa',
    nameAr: 'فاء',
    exampleWord: 'فيل',
    exampleMeaning: 'elephant',
    exampleMeaningAr: 'فيل',
  ),
  _LetterEntry(
    letter: 'ق',
    name: 'Qaf',
    nameAr: 'قاف',
    exampleWord: 'قمر',
    exampleMeaning: 'moon',
    exampleMeaningAr: 'قمر',
  ),
  _LetterEntry(
    letter: 'ك',
    name: 'Kaf',
    nameAr: 'كاف',
    exampleWord: 'كتاب',
    exampleMeaning: 'book',
    exampleMeaningAr: 'كتاب',
  ),
  _LetterEntry(
    letter: 'ل',
    name: 'Lam',
    nameAr: 'لام',
    exampleWord: 'ليمون',
    exampleMeaning: 'lemon',
    exampleMeaningAr: 'ليمون',
  ),
  _LetterEntry(
    letter: 'م',
    name: 'Meem',
    nameAr: 'ميم',
    exampleWord: 'موز',
    exampleMeaning: 'banana',
    exampleMeaningAr: 'موز',
  ),
  _LetterEntry(
    letter: 'ن',
    name: 'Noon',
    nameAr: 'نون',
    exampleWord: 'نهر',
    exampleMeaning: 'river',
    exampleMeaningAr: 'نهر',
  ),
  _LetterEntry(
    letter: 'ه',
    name: 'Ha',
    nameAr: 'هاء',
    exampleWord: 'هلال',
    exampleMeaning: 'crescent',
    exampleMeaningAr: 'هلال',
  ),
  _LetterEntry(
    letter: 'و',
    name: 'Waw',
    nameAr: 'واو',
    exampleWord: 'وردة',
    exampleMeaning: 'rose',
    exampleMeaningAr: 'وردة',
  ),
  _LetterEntry(
    letter: 'ي',
    name: 'Ya',
    nameAr: 'ياء',
    exampleWord: 'يد',
    exampleMeaning: 'hand',
    exampleMeaningAr: 'يد',
  ),
];
