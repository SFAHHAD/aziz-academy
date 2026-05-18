import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/router/app_router.dart';

/// B1 — Learning Path agent. Produces an ordered "next-up" queue of 3 items
/// the child should play next.
///
/// Inputs (from LearnerState):
///   • per-module skill (low skill → review)
///   • days since last play of each module (stale → suggest)
///   • recent miss rate
class NextUp {
  const NextUp({
    required this.module,
    required this.route,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  final String module;
  final String route;
  final String title;
  final String subtitle;
  final String emoji;
}

class _ModuleMeta {
  const _ModuleMeta(
    this.module,
    this.route,
    this.titleEn,
    this.titleAr,
    this.emoji,
  );
  final String module;
  final String route;
  final String titleEn;
  final String titleAr;
  final String emoji;
}

const _modules = <_ModuleMeta>[
  _ModuleMeta('capitals', AppRoutes.capitals, 'Capitals', 'العواصم', '🏛️'),
  _ModuleMeta('flags', AppRoutes.flags, 'Flags', 'الأعلام', '🚩'),
  _ModuleMeta('sciences', AppRoutes.sciences, 'Sciences', 'العلوم', '🔬'),
  _ModuleMeta('math', AppRoutes.math, 'Math', 'الرياضيات', '🔢'),
  _ModuleMeta('iq', AppRoutes.iq, 'IQ', 'الذكاء', '🧠'),
  _ModuleMeta('logos', AppRoutes.logos, 'Logos', 'الشعارات', '🏷️'),
  _ModuleMeta(
    'general_quiz',
    AppRoutes.generalQuizIntro,
    'General',
    'المعلومات العامة',
    '🌍',
  ),
];

List<NextUp> nextUp(LearnerState s, {required bool arabic, int limit = 3}) {
  final now = DateTime.now();
  final scored = _modules.map((m) {
    final skill = s.skillFor(m.module);
    // Days since module last played (best-effort from session list).
    final lastSession = s.recentSessions
        .where((sess) => sess.module == m.module)
        .fold<DateTime?>(null, (a, b) {
          if (a == null) return b.endedAt;
          return b.endedAt.isAfter(a) ? b.endedAt : a;
        });
    final daysSince = lastSession == null
        ? 30.0
        : now.difference(lastSession).inHours / 24.0;
    // Score = (1 - skill) * 1.5 + min(daysSince, 14)/14
    final score = (1 - skill) * 1.5 + (daysSince.clamp(0.0, 14.0) / 14.0);
    final reasonEn = _reasonEn(skill: skill, daysSince: daysSince);
    final reasonAr = _reasonAr(skill: skill, daysSince: daysSince);
    return _Scored(
      meta: m,
      score: score,
      subtitle: arabic ? reasonAr : reasonEn,
    );
  }).toList()..sort((a, b) => b.score.compareTo(a.score));

  return scored.take(limit).map((sc) {
    return NextUp(
      module: sc.meta.module,
      route: sc.meta.route,
      title: arabic ? sc.meta.titleAr : sc.meta.titleEn,
      subtitle: sc.subtitle,
      emoji: sc.meta.emoji,
    );
  }).toList();
}

class _Scored {
  _Scored({required this.meta, required this.score, required this.subtitle});
  final _ModuleMeta meta;
  final double score;
  final String subtitle;
}

String _reasonEn({required double skill, required double daysSince}) {
  if (skill < 0.45) return 'Quick review will help.';
  if (daysSince > 5) return 'Hasn\'t been played in a while.';
  if (skill > 0.78) return 'You\'re strong here — try the harder ones.';
  return 'Good practice today.';
}

String _reasonAr({required double skill, required double daysSince}) {
  if (skill < 0.45) return 'مراجعة سريعة ستفيدك.';
  if (daysSince > 5) return 'لم تلعب هنا منذ فترة.';
  if (skill > 0.78) return 'أنت قوي هنا — جرب الأصعب.';
  return 'تدريب جيد لليوم.';
}
