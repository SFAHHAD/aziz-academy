import 'package:flutter/material.dart';

import 'package:aziz_academy/core/quiz/mc_quiz_screen.dart';
import 'package:aziz_academy/core/quiz/multiple_choice_engine.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// "Prophet Quiz" — show a prophet's lesson; the kid picks which prophet
/// it belongs to from 4 names. Lessons stay short and kid-friendly so
/// the quiz is about recognition, not reading speed.
class ProphetQuizScreen extends StatelessWidget {
  const ProphetQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MCQuizScreen<ProphetQuizItem>(
      assetPath: 'assets/data/prophet_stories.json',
      titleEn: 'Prophet Quiz',
      titleAr: 'اختبار الأنبياء',
      promptEn: 'Which prophet does this lesson belong to?',
      promptAr: 'لأي نبي تنتمي هذه العبرة؟',
      fromJson: ProphetQuizItem.fromJson,
      buildPromptCard: (item, isAr) => _ProphetPromptCard(item: item, isAr: isAr),
      optionText: (option, isAr) => isAr ? option.nameAr : option.name,
      accent: AppColors.success,
    );
  }
}

class _ProphetPromptCard extends StatelessWidget {
  const _ProphetPromptCard({required this.item, required this.isAr});
  final ProphetQuizItem item;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '"${isAr ? item.lessonAr : item.lesson}"',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textDark,
          fontSize: 16,
          height: 1.6,
          fontStyle: FontStyle.normal,
        ),
      ),
    );
  }
}

class ProphetQuizItem implements QuizItem {
  const ProphetQuizItem({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.lesson,
    required this.lessonAr,
    required this.category,
  });

  @override
  final String id;
  @override
  final String category;
  final String name;
  final String nameAr;
  final String lesson;
  final String lessonAr;

  static ProphetQuizItem fromJson(Map<String, dynamic> j) => ProphetQuizItem(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        nameAr: j['name_ar'] as String? ?? '',
        lesson: j['lesson'] as String? ?? '',
        lessonAr: j['lesson_ar'] as String? ?? '',
        // Prophets share a single category effectively — use era so
        // distractors cluster around contemporaneous prophets.
        category: j['era'] as String? ?? '',
      );
}
