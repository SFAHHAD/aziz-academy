import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Generic "walk through N steps" screen used by the Salah and Wudu
/// step-by-step guides. Each step has a title, body, an optional
/// "what to say" phrase with TTS, and an optional kid-friendly tip.
/// The accent color theming separates the two visually (Salah=accent,
/// Wudu=secondary). Steps come from a JSON asset path.
class StepGuideScreen extends ConsumerStatefulWidget {
  const StepGuideScreen({
    super.key,
    required this.assetPath,
    required this.titleEn,
    required this.titleAr,
    required this.accent,
    required this.emptyIcon,
    this.fallbackIcon = '🕌',
  });

  final String assetPath;
  final String titleEn;
  final String titleAr;
  final Color accent;
  final IconData emptyIcon;
  final String fallbackIcon;

  @override
  ConsumerState<StepGuideScreen> createState() => _StepGuideScreenState();
}

class _StepGuideScreenState extends ConsumerState<StepGuideScreen> {
  List<GuideStep> _all = const [];
  int _idx = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(widget.assetPath);
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list
            .map((j) => GuideStep.fromJson(j, fallbackIcon: widget.fallbackIcon))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _go(int delta) {
    final n = (_idx + delta).clamp(0, _all.length - 1);
    setState(() => _idx = n);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? widget.titleAr : widget.titleEn),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? ContentEmptyState(
                  icon: widget.emptyIcon,
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : _buildBody(isAr),
    );
  }

  Widget _buildBody(bool isAr) {
    final step = _all[_idx];
    final progress = (_idx + 1) / _all.length;
    return Column(
      children: [
        Semantics(
          label: isAr
              ? 'الخطوة ${_idx + 1} من ${_all.length}'
              : 'Step ${_idx + 1} of ${_all.length}',
          container: true,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            color: widget.accent,
            backgroundColor: AppColors.outline.withAlpha(60),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accent.withAlpha(46),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.accent.withAlpha(140)),
                ),
                alignment: Alignment.center,
                child: Text(
                  localizeDigits(step.n, arabic: isAr),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? step.titleAr : step.title,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(step.icon, style: const TextStyle(fontSize: 32)),
            ],
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Text(
                isAr ? step.whatAr : step.what,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textDark,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              if (step.sayAr.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.accent.withAlpha(120)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🗣️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'تقول:' : 'Say:',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textDark.withAlpha(180),
                            ),
                          ),
                          const Spacer(),
                          TtsSpeakerIcon(
                            text: step.sayAr,
                            size: 20,
                            tooltip: isAr ? 'استمع' : 'Listen',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.sayAr,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.textDark,
                          fontSize: 18,
                          height: 1.7,
                        ),
                      ),
                      if (!isAr && step.say.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          step.say,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDark.withAlpha(180),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if ((isAr ? step.tipAr : step.tip).isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withAlpha(80)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr ? step.tipAr : step.tip,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _idx > 0 ? () => _go(-1) : null,
                    icon: Icon(
                      isAr
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    label: Text(isAr ? 'السابق' : 'Previous'),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.outline.withAlpha(80)),
                  ),
                  child: Text(
                    '${localizeDigits(_idx + 1, arabic: isAr)} / ${localizeDigits(_all.length, arabic: isAr)}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _idx < _all.length - 1 ? () => _go(1) : null,
                    icon: Icon(
                      isAr
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(isAr ? 'التالي' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GuideStep {
  const GuideStep({
    required this.id,
    required this.n,
    required this.title,
    required this.titleAr,
    required this.what,
    required this.whatAr,
    required this.say,
    required this.sayAr,
    required this.tip,
    required this.tipAr,
    required this.icon,
  });

  final String id;
  final int n;
  final String title;
  final String titleAr;
  final String what;
  final String whatAr;
  final String say;
  final String sayAr;
  final String tip;
  final String tipAr;
  final String icon;

  static GuideStep fromJson(
    Map<String, dynamic> j, {
    String fallbackIcon = '🕌',
  }) =>
      GuideStep(
        id: j['id'] as String? ?? '',
        n: (j['n'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        titleAr: j['title_ar'] as String? ?? '',
        what: j['what'] as String? ?? '',
        whatAr: j['what_ar'] as String? ?? '',
        say: j['say'] as String? ?? '',
        sayAr: j['say_ar'] as String? ?? '',
        tip: j['tip'] as String? ?? '',
        tipAr: j['tip_ar'] as String? ?? '',
        icon: j['icon'] as String? ?? fallbackIcon,
      );
}
