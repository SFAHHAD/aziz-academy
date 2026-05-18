import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/data/madrasati_data.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/school_models.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

// =============================================================================
// مدرستي — main screen
// Manages: stage picker → grade picker → subject picker → chapter picker
// Chapter tap → SchoolQuizScreen via GoRouter
// =============================================================================

class MadrasatiScreen extends StatefulWidget {
  const MadrasatiScreen({super.key});

  @override
  State<MadrasatiScreen> createState() => _MadrasatiScreenState();
}

class _MadrasatiScreenState extends State<MadrasatiScreen> {
  SchoolStage? _stage;
  SchoolGrade? _grade;
  SchoolSubject? _subject;

  void _pop() {
    setState(() {
      if (_subject != null) {
        _subject = null;
      } else if (_grade != null) {
        _grade = null;
      } else if (_stage != null) {
        _stage = null;
      } else {
        context.go(AppRoutes.home);
      }
    });
  }

  String get _title {
    if (_subject != null) return _subject!.name;
    if (_grade != null) return _grade!.name;
    if (_stage != null) return _stage!.name;
    return 'مدرستي';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _pop(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CenteredBody(
            wide: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(title: _title, onBack: _pop),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_subject != null) return _ChapterView(subject: _subject!);
    if (_grade != null) {
      return _SubjectView(
        grade: _grade!,
        onSubject: (s) => setState(() => _subject = s),
      );
    }
    if (_stage != null) {
      return _GradeView(
        stage: _stage!,
        onGrade: (g) => setState(() => _grade = g),
      );
    }
    return _StageView(onStage: (s) => setState(() => _stage = s));
  }
}

// =============================================================================
// Top Bar
// =============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.commonBack,
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('🏫', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// =============================================================================
// Stage View — 4 stage cards
// =============================================================================

class _StageView extends StatelessWidget {
  const _StageView({required this.onStage});

  final ValueChanged<SchoolStage> onStage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'اختر مرحلتك الدراسية',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ...madrasatiStages.map(
          (stage) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _StageCard(stage: stage, onTap: () => onStage(stage)),
          ),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage, required this.onTap});

  final SchoolStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = stage.grades.isEmpty;
    return GestureDetector(
      onTap: isEmpty ? null : onTap,
      child: Opacity(
        opacity: isEmpty ? 0.55 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [stage.color.withAlpha(200), stage.color.withAlpha(130)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: stage.color.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(stage.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty
                          ? 'قريباً ...'
                          : '${localizeDigitsCtx(stage.grades.length, context)} صف دراسي',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEmpty)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Grade View — list of grades in selected stage
// =============================================================================

class _GradeView extends StatelessWidget {
  const _GradeView({required this.stage, required this.onGrade});

  final SchoolStage stage;
  final ValueChanged<SchoolGrade> onGrade;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: stage.grades.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final grade = stage.grades[i];
        return _GradeCard(
          grade: grade,
          stageColor: stage.color,
          onTap: () => onGrade(grade),
        );
      },
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.stageColor,
    required this.onTap,
  });

  final SchoolGrade grade;
  final Color stageColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subjectCount = grade.subjects.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: stageColor.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stageColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  localizeDigitsCtx(
                    madrasatiStages.indexWhere(
                          (s) => s.grades.contains(grade),
                        ) +
                        1,
                    context,
                  ),
                  style: TextStyle(
                    color: stageColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.name,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${localizeDigitsCtx(subjectCount, context)} مادة دراسية',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: stageColor, size: 26),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Subject View — grid of subjects for a grade
// =============================================================================

class _SubjectView extends StatelessWidget {
  const _SubjectView({required this.grade, required this.onSubject});

  final SchoolGrade grade;
  final ValueChanged<SchoolSubject> onSubject;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 130,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: grade.subjects.length,
      itemBuilder: (context, i) {
        final subject = grade.subjects[i];
        return _SubjectCard(
          subject: subject,
          onTap: subject.chapters.isEmpty ? null : () => onSubject(subject),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});

  final SchoolSubject subject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: subject.color.withAlpha(80)),
            boxShadow: locked
                ? null
                : [
                    BoxShadow(
                      color: subject.color.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(subject.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  subject.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locked
                    ? 'قريباً'
                    : '${localizeDigitsCtx(subject.totalQuestions, context)} سؤال',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: subject.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Chapter View — list of chapters for a subject
// =============================================================================

class _ChapterView extends StatelessWidget {
  const _ChapterView({required this.subject});

  final SchoolSubject subject;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: subject.chapters.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final chapter = subject.chapters[i];
        return _ChapterCard(chapter: chapter, subject: subject, index: i + 1);
      },
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.subject,
    required this.index,
  });

  final SchoolChapter chapter;
  final SchoolSubject subject;
  final int index;

  @override
  Widget build(BuildContext context) {
    final questions = chapter.questions
        .map((q) => q.toQuizQuestion(subject.name))
        .toList();

    return GestureDetector(
      onTap: chapter.hasContent
          ? () => context.push(
              AppRoutes.schoolQuiz,
              extra: _SchoolQuizArgs(
                chapterName: chapter.name,
                subjectName: subject.name,
                subjectEmoji: subject.emoji,
                color: subject.color,
                questions: questions,
              ),
            )
          : null,
      child: Opacity(
        opacity: chapter.hasContent ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: subject.color.withAlpha(100)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: subject.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    localizeDigitsCtx(index, context),
                    style: TextStyle(
                      color: subject.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapter.hasContent
                          ? '${chapter.questions.length} سؤال'
                          : 'قريباً',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: chapter.hasContent
                            ? subject.color
                            : AppColors.textMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (chapter.hasContent)
                Icon(
                  Icons.play_circle_filled_rounded,
                  color: subject.color,
                  size: 30,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Args passed to SchoolQuizScreen
// =============================================================================

class _SchoolQuizArgs {
  const _SchoolQuizArgs({
    required this.chapterName,
    required this.subjectName,
    required this.subjectEmoji,
    required this.color,
    required this.questions,
  });

  final String chapterName;
  final String subjectName;
  final String subjectEmoji;
  final Color color;
  final List<QuizQuestion> questions;
}

// Export _SchoolQuizArgs so SchoolQuizScreen can use it
typedef SchoolQuizArgs = _SchoolQuizArgs;
