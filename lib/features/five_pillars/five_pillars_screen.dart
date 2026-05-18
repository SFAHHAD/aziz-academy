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

/// The Five Pillars of Islam — the foundational structure of Muslim
/// practice presented as a single overview screen. Each pillar links to
/// the related feature where the kid can go deeper (Salah → How to Pray,
/// Zakat → Sadaqah Jar). Static, offline.
class FivePillarsScreen extends ConsumerStatefulWidget {
  const FivePillarsScreen({super.key});

  @override
  ConsumerState<FivePillarsScreen> createState() => _FivePillarsScreenState();
}

class _FivePillarsScreenState extends ConsumerState<FivePillarsScreen> {
  List<_Pillar> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/five_pillars.json');
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _all = list.map(_Pillar.fromJson).toList();
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
        title: Text(isAr ? 'أركان الإسلام' : 'Five Pillars of Islam'),
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
              icon: Icons.mosque_outlined,
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withAlpha(46),
                        AppColors.secondary.withAlpha(28),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    isAr
                        ? 'الإسلام مبني على خمسة أركان — هي أساس حياة المسلم. اضغط على كل ركن لتتعلم المزيد.'
                        : 'Islam is built on five pillars — the foundation of a Muslim\'s life. Tap any pillar to learn more.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final p in _all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PillarCard(p: p, isAr: isAr),
                  ),
              ],
            ),
    );
  }
}

class _PillarCard extends ConsumerWidget {
  const _PillarCard({required this.p, required this.isAr});
  final _Pillar p;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(46),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.accent.withAlpha(140)),
                ),
                alignment: Alignment.center,
                child: Text(
                  localizeDigits(p.n, arabic: isAr),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? p.nameAr : p.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textDark,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isAr ? p.titleAr : p.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark.withAlpha(160),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(p.icon, style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? p.whatAr : p.what,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              height: 1.6,
            ),
          ),
          if (p.sayAr.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withAlpha(100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.sayAr,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.textDark,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        if (!isAr && p.say.isNotEmpty)
                          Text(
                            p.say,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark.withAlpha(180),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TtsSpeakerIcon(
                    text: p.sayAr,
                    size: 20,
                    tooltip: isAr ? 'استمع' : 'Listen',
                  ),
                ],
              ),
            ),
          ],
          if (p.linkRoute.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.push(p.linkRoute),
                icon: Icon(
                  isAr
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(
                  isAr
                      ? 'تعلَّم المزيد'
                      : 'Learn more — ${p.linkLabel}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pillar {
  const _Pillar({
    required this.id,
    required this.n,
    required this.name,
    required this.nameAr,
    required this.title,
    required this.titleAr,
    required this.what,
    required this.whatAr,
    required this.say,
    required this.sayAr,
    required this.icon,
    required this.linkRoute,
    required this.linkLabel,
  });
  final String id;
  final int n;
  final String name;
  final String nameAr;
  final String title;
  final String titleAr;
  final String what;
  final String whatAr;
  final String say;
  final String sayAr;
  final String icon;
  final String linkRoute;
  final String linkLabel;

  static _Pillar fromJson(Map<String, dynamic> j) => _Pillar(
    id: j['id'] as String? ?? '',
    n: (j['n'] as num?)?.toInt() ?? 0,
    name: j['name'] as String? ?? '',
    nameAr: j['name_ar'] as String? ?? '',
    title: j['title'] as String? ?? '',
    titleAr: j['title_ar'] as String? ?? '',
    what: j['what'] as String? ?? '',
    whatAr: j['what_ar'] as String? ?? '',
    say: j['say'] as String? ?? '',
    sayAr: j['say_ar'] as String? ?? '',
    icon: j['icon'] as String? ?? '🕌',
    linkRoute: j['link_route'] as String? ?? '',
    linkLabel: j['link_label'] as String? ?? '',
  );
}
