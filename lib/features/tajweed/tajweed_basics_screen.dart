import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/widgets/real_audio_button.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/content_empty_state.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// "Tajweed Basics" — 10 foundational Tajweed rules with an Arabic
/// example word + TTS for each. Card layout, kid-friendly. Designed
/// to be the first stop for a kid learning to recite — broad strokes,
/// not a comprehensive ijazah curriculum.
class TajweedBasicsScreen extends ConsumerStatefulWidget {
  const TajweedBasicsScreen({super.key});

  @override
  ConsumerState<TajweedBasicsScreen> createState() =>
      _TajweedBasicsScreenState();
}

class _TajweedBasicsScreenState
    extends ConsumerState<TajweedBasicsScreen> {
  List<_Rule> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/tajweed_basics.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Rule.fromJson).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'أساسيات التجويد' : 'Tajweed Basics'),
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
                  icon: Icons.menu_book_rounded,
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _RuleCard(rule: _all[i], isAr: isAr),
                ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.isAr});
  final _Rule rule;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(40),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.secondary.withAlpha(140)),
                ),
                alignment: Alignment.center,
                child: Text(
                  localizeDigits(rule.n, arabic: isAr),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? rule.nameAr : rule.name,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(rule.icon, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr ? rule.ruleAr : rule.rule,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withAlpha(110)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'مثال:' : 'Example:',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textDark.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rule.exampleAr,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.textDark,
                          fontSize: 22,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        isAr
                            ? rule.exampleTranslit
                            : '${rule.exampleTranslit} — ${rule.exampleEn}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark.withAlpha(180),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                RealAudioButton(
                  category: 'tajweed',
                  id: rule.id,
                  arabicText: rule.exampleAr,
                  tooltip: isAr ? 'استمع' : 'Listen',
                ),
              ],
            ),
          ),
          if ((isAr ? rule.tipAr : rule.tip).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.secondary.withAlpha(80)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr ? rule.tipAr : rule.tip,
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
    );
  }
}

class _Rule {
  const _Rule({
    required this.id,
    required this.n,
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.rule,
    required this.ruleAr,
    required this.exampleAr,
    required this.exampleTranslit,
    required this.exampleEn,
    required this.tip,
    required this.tipAr,
  });

  final String id;
  final int n;
  final String name;
  final String nameAr;
  final String icon;
  final String rule;
  final String ruleAr;
  final String exampleAr;
  final String exampleTranslit;
  final String exampleEn;
  final String tip;
  final String tipAr;

  static _Rule fromJson(Map<String, dynamic> j) => _Rule(
        id: j['id'] as String? ?? '',
        n: (j['n'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        nameAr: j['name_ar'] as String? ?? '',
        icon: j['icon'] as String? ?? '📖',
        rule: j['rule'] as String? ?? '',
        ruleAr: j['rule_ar'] as String? ?? '',
        exampleAr: j['example_ar'] as String? ?? '',
        exampleTranslit: j['example_translit'] as String? ?? '',
        exampleEn: j['example_en'] as String? ?? '',
        tip: j['tip'] as String? ?? '',
        tipAr: j['tip_ar'] as String? ?? '',
      );
}
