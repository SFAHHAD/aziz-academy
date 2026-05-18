import 'package:flutter/material.dart';

import 'package:aziz_academy/core/quiz/mc_quiz_screen.dart';
import 'package:aziz_academy/core/quiz/multiple_choice_engine.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';

/// "Hadith Quiz" — show the Arabic text of a hadith; the kid picks the
/// English meaning from 4 options. Distractors prefer the same category
/// (Manners, Faith, Family, …) for pedagogical difficulty.
class HadithQuizScreen extends StatelessWidget {
  const HadithQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MCQuizScreen<HadithQuizItem>(
      assetPath: 'assets/data/hadith_memorization.json',
      titleEn: 'Hadith Quiz',
      titleAr: 'اختبار الأحاديث',
      promptEn: 'What does this hadith mean?',
      promptAr: 'ماذا يعني هذا الحديث؟',
      fromJson: HadithQuizItem.fromJson,
      buildPromptCard: (item, isAr) => _HadithPromptCard(item: item, isAr: isAr),
      optionText: (option, isAr) =>
          isAr ? option.translationAr : option.translation,
      accent: AppColors.accent,
    );
  }
}

class _HadithPromptCard extends StatelessWidget {
  const _HadithPromptCard({required this.item, required this.isAr});
  final HadithQuizItem item;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          item.ar,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textDark,
            fontSize: 20,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? item.narratorAr : item.narrator,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textDark.withAlpha(160),
            fontWeight: FontWeight.w400,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        TtsSpeakerIcon(
          text: item.ar,
          tooltip: isAr ? 'استمع' : 'Listen',
        ),
      ],
    );
  }
}

class HadithQuizItem implements QuizItem {
  const HadithQuizItem({
    required this.id,
    required this.ar,
    required this.translation,
    required this.translationAr,
    required this.narrator,
    required this.narratorAr,
    required this.category,
  });

  @override
  final String id;
  @override
  final String category;
  final String ar;
  final String translation;
  final String translationAr;
  final String narrator;
  final String narratorAr;

  static HadithQuizItem fromJson(Map<String, dynamic> j) => HadithQuizItem(
        id: j['id'] as String? ?? '',
        ar: j['ar'] as String? ?? '',
        translation: j['translation'] as String? ?? '',
        translationAr: j['translation_ar'] as String? ?? '',
        narrator: j['narrator'] as String? ?? '',
        narratorAr: j['narrator_ar'] as String? ?? '',
        category: j['category'] as String? ?? '',
      );
}
