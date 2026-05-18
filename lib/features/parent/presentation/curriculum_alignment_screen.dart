import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Parent-facing static map of which Aziz Academy modules align to which
/// school subjects and which grade bands (KG–G6). Pure reference content,
/// no provider state, no persistence — helps parents see at a glance what
/// the app already covers vs. what their kid is studying at school.
class CurriculumAlignmentScreen extends StatelessWidget {
  const CurriculumAlignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'مواءمة المنهج' : 'Curriculum alignment'),
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
              context.go(AppRoutes.parent);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(36),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withAlpha(80)),
              ),
              child: Text(
                isAr
                    ? 'هذه المواءمة استرشادية تربط وحدات التطبيق بمستويات الصفوف والمواد المدرسية الشائعة. كل دولة لها منهج خاص بها — استخدم الجدول للاستئناس فقط.'
                    : 'This is an indicative map between Aziz Academy modules and common school subjects/grade bands. Curricula vary by country — use this as a guide, not a substitute for your school plan.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (final s in _subjects(isAr)) ...[
              _SubjectCard(subject: s),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              isAr ? 'مفتاح المستويات' : 'Grade band key',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GradePill(
                  label: isAr ? 'تمهيدي' : 'KG',
                  color: AppColors.secondary,
                ),
                _GradePill(
                  label: isAr ? 'الأول–الثاني' : 'G1–G2',
                  color: AppColors.primary,
                ),
                _GradePill(
                  label: isAr ? 'الثالث–الرابع' : 'G3–G4',
                  color: AppColors.accent,
                ),
                _GradePill(
                  label: isAr ? 'الخامس–السادس' : 'G5–G6',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<_Subject> _subjects(bool isAr) {
    return [
      _Subject(
        emoji: '🔢',
        name: isAr ? 'الرياضيات' : 'Math',
        modules: [
          _Module(
            title: isAr ? 'روابط الأعداد' : 'Number Bonds',
            route: AppRoutes.numberBonds,
            grades: 'KG–G2',
            note: isAr ? 'أكمل الـ ١٠ والـ ٢٠' : 'Make 10 and Make 20',
          ),
          _Module(
            title: isAr ? 'المنازل العشرية' : 'Place Value',
            route: AppRoutes.placeValue,
            grades: 'G1–G3',
            note: isAr ? 'عشرات وآحاد بمكعبات' : 'Tens and ones with blocks',
          ),
          _Module(
            title: isAr ? 'العد بالقفز' : 'Skip Counting',
            route: AppRoutes.skipCounting,
            grades: 'G1–G3',
            note: isAr ? 'العد بـ ٢ و ٥ و ١٠' : 'By 2s, 5s, and 10s',
          ),
          _Module(
            title: isAr ? 'الأشكال' : 'Shapes Basics',
            route: AppRoutes.shapesBasics,
            grades: 'KG–G2',
            note: isAr ? '١٢ شكلًا أساسيًا' : '12 fundamental shapes',
          ),
          _Module(
            title: isAr ? 'جدول الضرب' : 'Times Tables',
            route: AppRoutes.timesTables,
            grades: 'G2–G5',
            note: isAr ? 'تدريب طلاقة ١-١٢' : 'Fluency drill 1–12',
          ),
          _Module(
            title: isAr ? 'تحدي الرياضيات' : 'Math Quiz',
            route: AppRoutes.math,
            grades: 'G1–G6',
            note: isAr
                ? 'جمع وطرح وضرب وقسمة'
                : 'Add, subtract, multiply, divide',
          ),
          _Module(
            title: isAr ? 'مسائل كلامية' : 'Word Problems',
            route: AppRoutes.generalQuizIntro,
            grades: 'G3–G6',
            note: isAr ? 'مدمجة في معلومات عامة' : 'Inside General Knowledge',
          ),
        ],
      ),
      _Subject(
        emoji: '🔬',
        name: isAr ? 'العلوم' : 'Science',
        modules: [
          _Module(
            title: isAr ? 'العلوم' : 'Sciences',
            route: AppRoutes.sciences,
            grades: 'G2–G6',
            note: isAr
                ? 'فيزياء وأحياء وكيمياء وفلك'
                : 'Physics, biology, chemistry, astronomy',
          ),
          _Module(
            title: isAr ? 'الحيوانات والطبيعة' : 'Animals & Nature',
            route: AppRoutes.generalQuizIntro,
            grades: 'KG–G4',
            note: isAr ? 'مدمجة في معلومات عامة' : 'Inside General Knowledge',
          ),
        ],
      ),
      _Subject(
        emoji: '📖',
        name: isAr ? 'القراءة واللغة' : 'Reading & Language',
        modules: [
          _Module(
            title: isAr ? 'منطقة القراءة' : 'Reading Zone',
            route: AppRoutes.learningZone,
            grades: 'G1–G5',
            note: isAr
                ? 'قصص قصيرة بأسئلة فهم'
                : 'Short passages with comprehension',
          ),
          _Module(
            title: isAr ? 'الإملاء' : 'Spelling',
            route: AppRoutes.spelling,
            grades: 'G1–G4',
            note: isAr ? 'سهل / متوسط / صعب' : 'Easy / Medium / Hard',
          ),
          _Module(
            title: isAr ? 'المفردات' : 'Vocabulary',
            route: AppRoutes.generalQuizIntro,
            grades: 'G2–G6',
            note: isAr
                ? 'مرادفات وأضداد وتعابير'
                : 'Synonyms, antonyms, idioms',
          ),
        ],
      ),
      _Subject(
        emoji: '🌍',
        name: isAr ? 'الجغرافيا والاجتماعيات' : 'Geography & Social',
        modules: [
          _Module(
            title: isAr ? 'العواصم' : 'Capitals',
            route: AppRoutes.capitals,
            grades: 'G3–G6',
            note: isAr ? '١٥٠+ دولة' : '150+ countries',
          ),
          _Module(
            title: isAr ? 'الأعلام' : 'Flags',
            route: AppRoutes.flags,
            grades: 'G2–G6',
            note: isAr ? 'تعرّف بصري' : 'Visual recognition',
          ),
          _Module(
            title: isAr ? 'الجغرافيا العميقة' : 'Geography Deep-Dive',
            route: AppRoutes.generalQuizIntro,
            grades: 'G4–G6',
            note: isAr
                ? 'أنهار وجبال ومناخ وعملات'
                : 'Rivers, mountains, climate, currencies',
          ),
          _Module(
            title: isAr ? 'المعالم الشهيرة' : 'Famous Landmarks',
            route: AppRoutes.generalQuizIntro,
            grades: 'G3–G6',
            note: isAr ? 'مدمجة في معلومات عامة' : 'Inside General Knowledge',
          ),
        ],
      ),
      _Subject(
        emoji: '🕌',
        name: isAr ? 'التربية الإسلامية' : 'Islamic Studies',
        modules: [
          _Module(
            title: isAr ? 'سور قصيرة' : 'Short Surahs',
            route: AppRoutes.quran,
            grades: 'KG–G6',
            note: isAr ? '١٥ سورة مع تلاوة' : '15 surahs + recitation',
          ),
          _Module(
            title: isAr ? 'الحروف العربية' : 'Arabic Alphabet',
            route: AppRoutes.alphabet,
            grades: 'KG–G2',
            note: isAr ? '٢٨ حرفًا' : '28 letters',
          ),
          _Module(
            title: isAr ? 'الحروف الإنجليزية' : 'English Alphabet',
            route: AppRoutes.englishAlphabet,
            grades: 'KG–G2',
            note: isAr ? '٢٦ حرفًا من A إلى Z' : '26 letters A–Z',
          ),
          _Module(
            title: isAr ? 'مواقيت الصلاة' : 'Prayer Times',
            route: AppRoutes.prayerTimes,
            grades: 'G2–G6',
            note: isAr ? '١٤ مدينة' : '14 cities',
          ),
        ],
      ),
      _Subject(
        emoji: '🧠',
        name: isAr ? 'مهارات التفكير' : 'Thinking Skills',
        modules: [
          _Module(
            title: isAr ? 'تنمية الذكاء' : 'Brain Boost',
            route: AppRoutes.iq,
            grades: 'G1–G6',
            note: isAr
                ? 'منطق وأنماط وتشبيهات وذاكرة'
                : 'Logic, patterns, analogies, memory',
          ),
          _Module(
            title: isAr ? 'تحدي الزعيم' : 'Boss Rush',
            route: AppRoutes.bossRush,
            grades: 'G3–G6',
            note: isAr ? 'متعدد الوحدات' : 'Cross-module gauntlet',
          ),
        ],
      ),
      _Subject(
        emoji: '👨‍👩‍👧',
        name: isAr ? 'أدوات الأهل' : 'Parent Tools',
        modules: [
          _Module(
            title: isAr ? 'أوراق عمل قابلة للطباعة' : 'Printable Worksheet',
            route: AppRoutes.worksheet,
            grades: isAr ? 'كل المراحل' : 'All grades',
            note: isAr ? '١٠ أسئلة عشوائية + إجابات' : '10 random Qs + answers',
          ),
          _Module(
            title: isAr ? 'تقرير التقدم' : 'Progress Report',
            route: AppRoutes.progressReport,
            grades: isAr ? 'كل المراحل' : 'All grades',
            note: isAr ? 'قابل للمشاركة' : 'Shareable PNG',
          ),
        ],
      ),
    ];
  }
}

class _Subject {
  const _Subject({
    required this.emoji,
    required this.name,
    required this.modules,
  });
  final String emoji;
  final String name;
  final List<_Module> modules;
}

class _Module {
  const _Module({
    required this.title,
    required this.route,
    required this.grades,
    required this.note,
  });
  final String title;
  final String route;
  final String grades;
  final String note;
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});
  final _Subject subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(subject.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                subject.name,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final m in subject.modules) _ModuleRow(module: m),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module});
  final _Module module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(module.route),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.note,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark.withAlpha(160),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(36),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Text(
                module.grades,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDark,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textDark.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradePill extends StatelessWidget {
  const _GradePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textDark,
          fontSize: 12,
        ),
      ),
    );
  }
}
