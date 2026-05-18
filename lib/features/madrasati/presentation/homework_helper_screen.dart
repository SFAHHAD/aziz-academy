import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// "Madrasati" Homework Helper — non-quiz study mode for school subjects.
/// Pulls 5 review-style questions and shows them with the correct answer
/// inline (it's an explainer, not a test). Helps with homework prep.
class HomeworkHelperScreen extends ConsumerStatefulWidget {
  const HomeworkHelperScreen({super.key});

  @override
  ConsumerState<HomeworkHelperScreen> createState() =>
      _HomeworkHelperScreenState();
}

enum _Subject { sciences, capitals }

class _HomeworkHelperScreenState extends ConsumerState<HomeworkHelperScreen> {
  _Subject? _subject;
  List<QuizQuestion> _questions = const [];
  bool _loading = false;

  Future<void> _pick(_Subject s) async {
    setState(() {
      _subject = s;
      _loading = true;
      _questions = const [];
    });
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    List<QuizQuestion> all;
    switch (s) {
      case _Subject.sciences:
        all = await ref
            .read(sciencesRepositoryProvider)
            .loadQuestions(arabic: isArabic);
        break;
      case _Subject.capitals:
        all = await ref
            .read(capitalsRepositoryProvider)
            .loadQuestions(arabic: isArabic);
        break;
    }
    all.shuffle();
    if (mounted) {
      setState(() {
        _questions = all.take(5).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    const Text('📚', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'مساعدة الواجبات' : 'Homework Helper',
                        style: AppTextStyles.headingMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'اختر مادة لمراجعتها — تظهر الإجابات لتساعدك على الفهم.'
                      : 'Pick a subject — answers are shown so you can study, not be tested.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SubjectChip(
                      label: isArabic ? 'علوم' : 'Sciences',
                      emoji: '🔬',
                      selected: _subject == _Subject.sciences,
                      onTap: () => _pick(_Subject.sciences),
                    ),
                    _SubjectChip(
                      label: isArabic ? 'عواصم' : 'Capitals',
                      emoji: '🌍',
                      selected: _subject == _Subject.capitals,
                      onTap: () => _pick(_Subject.capitals),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_subject == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isArabic
                          ? 'اختر مادة لتبدأ المذاكرة.'
                          : 'Pick a subject to start studying.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                else
                  for (int i = 0; i < _questions.length; i++)
                    _StudyCard(
                      index: i + 1,
                      q: _questions[i],
                      arabic: isArabic,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withAlpha(60)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.glassBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.index,
    required this.q,
    required this.arabic,
  });
  final int index;
  final QuizQuestion q;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(q.question, style: AppTextStyles.headingSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    q.correctAnswer,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (q.funFact.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${q.funFact}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
