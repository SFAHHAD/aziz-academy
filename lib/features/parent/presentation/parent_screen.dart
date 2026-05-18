import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/features/iq/presentation/widgets/bb_weekly_recap.dart';
import 'package:aziz_academy/features/parent/presentation/widgets/mastery_insights_card.dart';
import 'package:aziz_academy/features/parent/presentation/widgets/study_heatmap.dart';
import 'package:aziz_academy/features/parent/presentation/widgets/this_week_summary_card.dart';
import 'package:aziz_academy/core/agents/mistake_pattern.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/quran_recitation_service.dart';
import 'package:aziz_academy/core/widgets/voice_picker_dialog.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/features/parent/presentation/stats_export.dart';
import 'package:aziz_academy/core/providers/cosmetics_provider.dart';
import 'package:aziz_academy/core/providers/favorites_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/widgets/kid_emoji.dart';

/// E1 — Parent Dashboard. Plain-language weekly story generated from learner
/// state. PIN-gated by a 4-digit math challenge to keep kids out.
class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _unlocked
            ? _DashboardBody(onBack: () => context.go(AppRoutes.home))
            : _ParentGate(onUnlock: () => setState(() => _unlocked = true)),
      ),
    );
  }
}

/// Tiny "are you a grown-up?" gate. Three-digit number summing question.
/// Not security — just a kid speed-bump.
class _ParentGate extends StatefulWidget {
  const _ParentGate({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  State<_ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<_ParentGate> {
  late final int _a;
  late final int _b;
  final _c = TextEditingController();
  String? _err;

  @override
  void initState() {
    super.initState();
    final r = DateTime.now().millisecond;
    _a = 11 + (r % 17);
    _b = 7 + ((r * 3) % 19);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _check() {
    final v = int.tryParse(_c.text.trim()) ?? -1;
    if (v == _a + _b) {
      widget.onUnlock();
    } else {
      setState(() => _err = context.l10n.parentGateTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              tooltip: context.l10n.commonBack,
              onPressed: () => GoRouter.of(context).go(AppRoutes.home),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const Spacer(),
          KidEmoji.named('lock', size: 72),
          const SizedBox(height: 12),
          Text(
            context.l10n.parentArea,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.parentGatePrompt(_a, _b),
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '?',
                errorText: _err,
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _check(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _check,
            child: Text(context.l10n.parentGateUnlock),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerStateProvider).value;
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    if (learner == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CenteredBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.l10n.commonBack,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.parentDashboard,
                style: AppTextStyles.headingMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StoryCard(learner: learner, arabic: isArabic),
          const SizedBox(height: 16),
          ThisWeekSummaryCard(arabic: isArabic),
          const SizedBox(height: 20),
          _ParentLinks(arabic: isArabic),
          const SizedBox(height: 20),
          _SkillStrip(learner: learner),
          const SizedBox(height: 20),
          _BrainBoostRadar(learner: learner, arabic: isArabic),
          const SizedBox(height: 20),
          _MistakeBlock(learner: learner),
          const SizedBox(height: 20),
          _ParentSettings(arabic: isArabic),
          const SizedBox(height: 20),
          _PrivacyNote(),
          const SizedBox(height: 20),
          _DangerZone(),
        ],
      ),
    );
  }
}

class _DangerZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                context.l10n.parentResetProfile,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.parentResetProfileDescription,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(context.l10n.parentResetEverything),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.parentResetConfirmTitle),
        content: Text(context.l10n.parentResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.backupCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.parentResetConfirmYes),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Force-rebuild dependent providers via reset on the ones we own.
    await ref.read(learnerStateProvider.notifier).reset();
    await ref.read(favoritesProvider.notifier).clearAll();
    await ref.read(cosmeticsProvider.notifier).reset();
    await ref.read(coinProvider.notifier).resetTo(30);
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(context.l10n.parentResetSuccess)));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) context.go(AppRoutes.home);
      });
    }
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.learner, required this.arabic});
  final LearnerState learner;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final story = _buildStory(learner);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2C5C), Color(0xFF1B4F8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.parentThisWeek,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _buildStory(LearnerState s) {
    if (s.totalSessions == 0) {
      return 'Your child hasn\'t played yet. Once they do, this card will summarize what they\'re learning and where they need a hand.';
    }
    final last7 = s.recentSessions
        .where((sess) => DateTime.now().difference(sess.endedAt).inDays <= 7)
        .toList();
    final played = last7.length;
    final correctTotal = last7.fold<int>(0, (a, b) => a + b.score);
    final totalTotal = last7.fold<int>(0, (a, b) => a + b.total);
    final accPct = totalTotal == 0
        ? 0
        : ((correctTotal / totalTotal) * 100).round();

    final strongest = s.skillByModule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final strong = strongest.isEmpty ? null : strongest.first.key;
    final weakest = s.skillByModule.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weak = weakest.isEmpty ? null : weakest.first.key;

    final pieces = <String>[
      'This week your child played $played short rounds.',
      if (totalTotal > 0) 'Overall they answered $accPct% correctly.',
      if (strong != null) 'Their strongest area is $strong.',
      if (weak != null && weak != strong)
        'They could use a little help on $weak — try one short round together this week.',
      if (s.frustrationLevel >= 0.5)
        'They had a few frustrating moments — gentle praise goes a long way right now.',
    ];
    return pieces.join(' ');
  }
}

class _SkillStrip extends StatelessWidget {
  const _SkillStrip({required this.learner});
  final LearnerState learner;

  @override
  Widget build(BuildContext context) {
    final entries = learner.skillByModule.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.parentSkillByTopic,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(e.key, style: AppTextStyles.bodyMedium),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(
                          e.value < 0.45
                              ? AppColors.error
                              : (e.value > 0.78
                                    ? const Color(0xFF6BBF59)
                                    : AppColors.secondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(e.value * 100).round()}%',
                    style: AppTextStyles.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeBlock extends StatelessWidget {
  const _MistakeBlock({required this.learner});
  final LearnerState learner;

  @override
  Widget build(BuildContext context) {
    final hot = hotMistakePatterns(learner, minMisses: 2);
    if (hot.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.parentStuckHeading,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 8),
          ...hot
              .take(5)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    context.l10n.parentStuckRow(
                      p.module,
                      p.category,
                      p.missCount,
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.parentPrivacyHeading,
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.parentPrivacyNote,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

Future<void> _showBrainBoostDisclaimer(BuildContext context) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      title: Text(
        l10n.brainBoostDisclaimerTitle,
        style: AppTextStyles.headingSmall,
      ),
      content: Text(
        l10n.brainBoostDisclaimerBody,
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.brainBoostDisclaimerOk),
        ),
      ],
    ),
  );
}

class _BrainBoostRadar extends StatelessWidget {
  const _BrainBoostRadar({required this.learner, required this.arabic});
  final LearnerState learner;
  final bool arabic;

  static const _axesEn = [
    'Patterns',
    'Mental Math',
    'Analogies',
    'Logic',
    'Spatial',
    'Memory',
  ];
  static const _axesAr = [
    'الأنماط',
    'حساب ذهني',
    'تشابه',
    'منطق',
    'مكاني',
    'ذاكرة',
  ];
  static const _axesData = [
    'Patterns',
    'Mental Math',
    'Analogies',
    'Logic',
    'Spatial',
    'Memory',
  ];

  @override
  Widget build(BuildContext context) {
    final values = _axesData
        .map((c) => learner.skillForCategory('iq', c))
        .toList(growable: false);
    final hasAny = values.any((v) => v != 0.5);
    final labels = arabic ? _axesAr : _axesEn;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KidEmoji.named('brain', size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  arabic ? 'مهارات تنمية الذكاء' : 'Brain Boost skills',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              Builder(
                builder: (ctx) {
                  return IconButton(
                    tooltip: arabic ? 'عن هذا القسم' : 'About this section',
                    onPressed: () => _showBrainBoostDisclaimer(ctx),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.secondary,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            arabic
                ? 'متوسط الدقة لكل مجال — يبقى على الجهاز فقط، ولا يقارن بأي طفل آخر.'
                : 'Average accuracy per category — stays on this device, never compared with other children.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  arabic
                      ? 'لا توجد بيانات بعد — العب جولة من قسم تنمية الذكاء.'
                      : 'No data yet — play a Brain Boost round to see this chart.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _RadarPainter(values: values, labels: labels),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 36;

    // Grid rings (4 levels: 25% / 50% / 75% / 100%).
    final gridPaint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var k = 1; k <= 4; k++) {
      final r = radius * (k / 4);
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = _vertex(center, r, i, n);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes spokes.
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, _vertex(center, radius, i, n), gridPaint);
    }

    // Filled value polygon.
    final fillPaint = Paint()
      ..color = AppColors.secondary.withAlpha(80)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final valuePath = Path();
    for (var i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final p = _vertex(center, radius * v, i, n);
      if (i == 0) {
        valuePath.moveTo(p.dx, p.dy);
      } else {
        valuePath.lineTo(p.dx, p.dy);
      }
    }
    valuePath.close();
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, strokePaint);

    // Vertex dots.
    final dotPaint = Paint()..color = AppColors.secondary;
    for (var i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      canvas.drawCircle(_vertex(center, radius * v, i, n), 3.5, dotPaint);
    }

    // Axis labels.
    for (var i = 0; i < n; i++) {
      final p = _vertex(center, radius + 22, i, n);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textDark),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      )..layout(maxWidth: 90);
      final dx = p.dx - tp.width / 2;
      final dy = p.dy - tp.height / 2;
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  Offset _vertex(Offset center, double r, int i, int n) {
    // Start at 12 o'clock, go clockwise.
    final angle = -math.pi / 2 + (i * 2 * math.pi / n);
    return Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values || old.labels != labels;
}

/// Parent quick-links: weekly digest, printable progress report, CSV export.
class _ParentLinks extends ConsumerWidget {
  const _ParentLinks({required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const BrainBoostWeeklyRecap(),
        const SizedBox(height: 12),
        const StudyHeatmap(),
        const SizedBox(height: 12),
        MasteryInsightsCard(arabic: arabic),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.weeklyDigest),
                icon: KidEmoji.named('calendar', size: 18),
                label: Text(arabic ? 'الملخص الأسبوعي' : 'Weekly digest'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.progressReport),
                icon: KidEmoji.named('printer', size: 18),
                label: Text(arabic ? 'تقرير للطباعة' : 'Printable report'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final l = ref.read(learnerStateProvider).value;
              final a = ref.read(achievementProvider).value;
              if (l == null || a == null) return;
              await shareStatsCsv(learner: l, ach: a);
            },
            icon: KidEmoji.named('chart', size: 18),
            label: Text(arabic ? 'تصدير CSV' : 'Export stats CSV'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.worksheet),
            icon: KidEmoji.named('memo', size: 18),
            label: Text(
              arabic ? 'ورقة عمل قابلة للطباعة' : 'Printable worksheet',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.familyCompare),
            icon: const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 18)),
            label: Text(arabic ? 'مقارنة الإخوة' : 'Compare siblings'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.curriculumAlignment),
            icon: KidEmoji.named('graduation', size: 18),
            label: Text(arabic ? 'مواءمة المنهج' : 'Curriculum alignment'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.installGuide),
            icon: KidEmoji.named('phone', size: 18),
            label: Text(
              arabic ? 'تثبيت التطبيق على الهاتف' : 'Install app on phone',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.forSchools),
            icon: const Text('🏫', style: TextStyle(fontSize: 18)),
            label: Text(arabic ? 'للمدارس' : 'For schools'),
          ),
        ),
      ],
    );
  }
}

/// Parent settings: sound volume, adaptive difficulty, accessibility.
class _ParentSettings extends ConsumerWidget {
  const _ParentSettings({required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();
    final notifier = ref.read(appSettingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚙️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                arabic ? 'الإعدادات' : 'Settings',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sound enable + volume slider together
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  arabic ? 'الصوت' : 'Sound',
                  style: AppTextStyles.labelMedium,
                ),
              ),
              Switch(
                value: settings.soundEnabled,
                onChanged: notifier.setSoundEnabled,
              ),
            ],
          ),
          if (settings.soundEnabled)
            Slider(
              value: settings.soundVolume,
              onChanged: notifier.setSoundVolume,
              divisions: 10,
              label: '${(settings.soundVolume * 100).round()}%',
            ),
          const SizedBox(height: 4),
          // Real-audio-only policy banner. From v1.1.96 onwards we ship
          // with AI voices off by default; Quran continues to use a real
          // reciter (everyayah CDN). Real recitations for Hadith / Azkar
          // are on the roadmap — the speak buttons on those screens are
          // hidden until they ship.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withAlpha(110)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎙️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    arabic
                        ? 'سياسة الصوت: القرآن بتلاوة حقيقية فقط. تلاوات حقيقية '
                            'للأحاديث والأذكار قادمة قريبًا. الأصوات الاصطناعية '
                            'موقفة افتراضيًا — يمكن تفعيلها أدناه إن أردت.'
                        : 'Audio policy: Quran plays only real reciter audio. '
                            'Real hadith / azkar recitation is coming soon. AI '
                            'voices are OFF by default — toggle below to enable.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            secondary:
                const Icon(Icons.record_voice_over_outlined, size: 20),
            title: Text(
              arabic
                  ? 'الأصوات الاصطناعية (TTS)'
                  : 'AI voices (TTS)',
              style: AppTextStyles.labelMedium,
            ),
            subtitle: Text(
              arabic
                  ? 'متوقفة افتراضيًا. تفعيلها يعرض زر النطق على كل البطاقات.'
                  : 'Off by default. Turning on shows the speak button on every card.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: AppColors.textDark.withAlpha(150),
              ),
            ),
            value: settings.ttsEnabled,
            onChanged: notifier.setTtsEnabled,
          ),
          if (settings.ttsEnabled) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showVoicePickerSheet(context, arabic: true),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(
                      arabic ? 'صوت العربية' : 'Arabic voice',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showVoicePickerSheet(context, arabic: false),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(
                      arabic ? 'صوت الإنجليزية' : 'English voice',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: settings.preferredReciter,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.menu_book_rounded, size: 18),
                labelText: arabic ? 'القارئ' : 'Quran reciter',
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final entry in kReciters.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      arabic ? entry.value.ar : entry.value.en,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) notifier.setPreferredReciter(v);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              secondary: const Icon(Icons.auto_awesome_rounded, size: 20),
              title: Text(
                arabic ? 'أصوات سحابية (طبيعية)' : 'Cloud voices (Neural)',
                style: AppTextStyles.labelMedium,
              ),
              subtitle: Text(
                arabic
                    ? 'يستخدم خدمة سحابية لأصوات أعلى جودة. يحتاج إلى مفتاح Azure على الخادم.'
                    : 'Routes speech through cloud Neural TTS (Azure). Requires AZURE_TTS_KEY on the server.',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  color: AppColors.textDark.withAlpha(150),
                ),
              ),
              value: settings.cloudVoices,
              onChanged: notifier.setCloudVoices,
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              arabic ? 'صعوبة تكيّفية' : 'Adaptive difficulty',
              style: AppTextStyles.labelMedium,
            ),
            subtitle: Text(
              arabic
                  ? 'يرفع/يخفض الأسئلة حسب أداء طفلك.'
                  : 'Auto-adjusts questions to your child\'s level.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
                fontSize: 11,
              ),
            ),
            value: settings.adaptiveDifficulty,
            onChanged: notifier.setAdaptiveDifficulty,
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              arabic ? 'حركة مخفّفة' : 'Reduced motion',
              style: AppTextStyles.labelMedium,
            ),
            value: settings.reducedMotion,
            onChanged: notifier.setReducedMotion,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              arabic ? 'نص أكبر' : 'Larger text',
              style: AppTextStyles.labelMedium,
            ),
            value: settings.largerText,
            onChanged: notifier.setLargerText,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              arabic
                  ? 'وضع التدريب (بدون عقوبة)'
                  : 'Practice mode (no penalty)',
              style: AppTextStyles.labelMedium,
            ),
            value: settings.practiceMode,
            onChanged: notifier.setPracticeMode,
          ),
        ],
      ),
    );
  }
}
