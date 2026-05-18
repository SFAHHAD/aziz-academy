import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Printable progress report — captured as PNG and shared via the system
/// share sheet (iOS/Android print, browser print on web). One-page A4-ish
/// layout: child name, sessions, badges, skill-by-module bars.
class ProgressReportScreen extends ConsumerStatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  ConsumerState<ProgressReportScreen> createState() =>
      _ProgressReportScreenState();
}

class _ProgressReportScreenState extends ConsumerState<ProgressReportScreen> {
  final GlobalKey _shotKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      if (!mounted) return;
      final shareText = context.l10n.progressReportShareText;
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'image/png',
                name: 'aziz_academy_progress_report.png',
              ),
            ],
            text: shareText,
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/aziz_academy_progress_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path);
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: shareText,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final learner = ref.watch(learnerStateProvider).value;
    final ach = ref.watch(achievementProvider).value;
    final coins = ref.watch(coinProvider).value ?? 0;
    final profile = ref.watch(profileProvider).value;
    final name = (profile?.displayName ?? '').trim().isEmpty
        ? (isArabic ? 'صديقي' : 'Friend')
        : profile!.displayName;

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
                    const Text('🖨️', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'تقرير قابل للطباعة'
                            : 'Printable Progress Report',
                        style: AppTextStyles.headingMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _shotKey,
                  child: _ReportCard(
                    name: name,
                    arabic: isArabic,
                    learner: learner,
                    unlockedBadgeCount: ach?.unlockedBadges.length ?? 0,
                    totalBadgeCount: allBadges.length,
                    coins: coins,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(
                    isArabic ? 'مشاركة / طباعة' : 'Share / Print',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.name,
    required this.arabic,
    required this.learner,
    required this.unlockedBadgeCount,
    required this.totalBadgeCount,
    required this.coins,
  });

  final String name;
  final bool arabic;
  final LearnerState? learner;
  final int unlockedBadgeCount;
  final int totalBadgeCount;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final modules = (learner?.skillByModule.entries.toList() ?? const [])
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'Aziz Academy',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy,
                  fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                ),
              ),
              const Spacer(),
              Text(
                _todayString(),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.black54,
                  fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                ),
              ),
            ],
          ),
          const Divider(),
          Text(
            arabic ? 'تقرير تقدّم' : 'Progress Report',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.black54,
              fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
            ),
          ),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
              fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                emoji: '🎯',
                label: arabic ? 'جلسات' : 'Sessions',
                value: '${learner?.totalSessions ?? 0}',
              ),
              const SizedBox(width: 12),
              _Stat(
                emoji: '🏅',
                label: arabic ? 'شارات' : 'Badges',
                value: '$unlockedBadgeCount/$totalBadgeCount',
              ),
              const SizedBox(width: 12),
              _Stat(
                emoji: '🪙',
                label: arabic ? 'عملات' : 'Coins',
                value: '$coins',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            arabic ? 'الأقسام' : 'Subjects',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
              fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
            ),
          ),
          const SizedBox(height: 8),
          if (modules.isEmpty)
            Text(
              arabic
                  ? 'لا يوجد نشاط بعد — شجّع طفلك على تجربة قسم!'
                  : 'No activity yet — encourage trying a subject!',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.black54,
                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
              ),
            )
          else
            for (final e in modules) _ModuleBar(code: e.key, value: e.value),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              arabic
                  ? 'هذا التقرير مُولَّد على هذا الجهاز ولا يحتوي على أي بيانات شخصية تم رفعها.'
                  : 'This report is generated entirely on this device and contains no uploaded data.',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.black87,
                fontSize: 11,
                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.emoji, required this.label, required this.value});
  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy,
                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Colors.black54,
                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleBar extends StatelessWidget {
  const _ModuleBar({required this.code, required this.value});
  final String code;
  final double value; // 0..1

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    final label = _moduleLabel(code);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: const Color(0xFFEEEEEE),
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.primaryNavy,
                fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _moduleLabel(String code) {
    const m = {
      'capitals': 'Capitals',
      'flags': 'Flags',
      'logos': 'Logos',
      'math': 'Math',
      'sciences': 'Sciences',
      'iq': 'Brain Boost',
      'maps': 'Maps',
    };
    return m[code] ?? code;
  }
}
