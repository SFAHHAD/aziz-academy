import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/router/app_router.dart';

/// C1 — Reward & Quest agent. Replaces the calendar-based dailyMissionFor()
/// with a child-state-aware mission picker. Falls back gracefully when the
/// learner has no history (cold start).
class DailyQuest {
  const DailyQuest({
    required this.module,
    required this.route,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.ctaAr,
    required this.ctaEn,
  });

  final String module;
  final String route;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String ctaAr;
  final String ctaEn;
}

DailyQuest dynamicDailyQuest(LearnerState s, DateTime now) {
  // Cold start: no sessions yet → calendar fallback (sciences day-1 etc.)
  if (s.totalSessions == 0) {
    final bucket = (now.millisecondsSinceEpoch ~/ 86400000) % 5;
    return _calendarFallback(bucket);
  }

  // Frustration high → suggest a confidence-boost easy round.
  if (s.frustrationLevel >= 0.5) {
    return const DailyQuest(
      module: 'capitals',
      route: AppRoutes.capitals,
      titleAr: 'مهمة اليوم',
      titleEn: 'Today\'s Mission',
      subtitleAr: 'جولة هادئة لرفع الثقة — العواصم.',
      subtitleEn: 'A calm round to build confidence — Capitals.',
      ctaAr: 'لنبدأ',
      ctaEn: 'Let\'s go',
    );
  }

  // Otherwise: target the weakest module, but rotate so we don't hit the same
  // module two days in a row (simple parity on day index).
  final weak = s.weakestModules(limit: 2);
  if (weak.isEmpty) return _calendarFallback(0);

  final dayIdx = now.millisecondsSinceEpoch ~/ 86400000;
  final pickIdx = weak.length > 1 ? dayIdx % weak.length : 0;
  final module = weak[pickIdx];

  return _buildForModule(module);
}

DailyQuest _calendarFallback(int bucket) {
  switch (bucket) {
    case 0:
      return _buildForModule('sciences');
    case 1:
      return _buildForModule('capitals');
    case 2:
      return _buildForModule('flags');
    case 3:
      return _buildForModule('math');
    default:
      return _buildForModule('iq');
  }
}

DailyQuest _buildForModule(String module) {
  switch (module) {
    case 'capitals':
      return const DailyQuest(
        module: 'capitals',
        route: AppRoutes.capitals,
        titleAr: 'مهمة اليوم: العواصم',
        titleEn: 'Today: Capitals',
        subtitleAr: 'جولة لتذكر عواصم العالم.',
        subtitleEn: 'A quick world-capitals round.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
    case 'flags':
      return const DailyQuest(
        module: 'flags',
        route: AppRoutes.flags,
        titleAr: 'مهمة اليوم: الأعلام',
        titleEn: 'Today: Flags',
        subtitleAr: 'تعرّف على أعلام دول جديدة.',
        subtitleEn: 'Spot some flags you\'ve never seen.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
    case 'math':
      return const DailyQuest(
        module: 'math',
        route: AppRoutes.math,
        titleAr: 'مهمة اليوم: الرياضيات',
        titleEn: 'Today: Math',
        subtitleAr: 'تمارين سريعة تشحذ الذهن.',
        subtitleEn: 'Quick brain-warmers.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
    case 'iq':
      return const DailyQuest(
        module: 'iq',
        route: AppRoutes.iq,
        titleAr: 'مهمة اليوم: الذكاء',
        titleEn: 'Today: IQ',
        subtitleAr: 'ألغاز تنطلق بها يومك.',
        subtitleEn: 'Brain teasers to start the day.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
    case 'general_quiz':
      return const DailyQuest(
        module: 'general_quiz',
        route: AppRoutes.generalQuizIntro,
        titleAr: 'مهمة اليوم: معلومات عامة',
        titleEn: 'Today: General Knowledge',
        subtitleAr: 'حقائق ممتعة من كل مكان.',
        subtitleEn: 'Fun facts from everywhere.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
    case 'logos':
      return const DailyQuest(
        module: 'logos',
        route: AppRoutes.logos,
        titleAr: 'مهمة اليوم: الشعارات',
        titleEn: 'Today: Logos',
        subtitleAr: 'تعرّف على شعارات شهيرة.',
        subtitleEn: 'Identify famous logos.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
    default:
      return const DailyQuest(
        module: 'sciences',
        route: AppRoutes.sciences,
        titleAr: 'مهمة اليوم: العلوم',
        titleEn: 'Today: Sciences',
        subtitleAr: 'تجربة سريعة في عالم العلوم.',
        subtitleEn: 'A quick trip into science.',
        ctaAr: 'ابدأ',
        ctaEn: 'Start',
      );
  }
}
