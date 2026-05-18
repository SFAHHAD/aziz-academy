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
import 'package:aziz_academy/core/l10n/badge_l10n.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// Achievement certificate — renders a printable card showing the child's
/// name, badge count, and unlocked badges. The card is wrapped in a
/// RepaintBoundary so it can be captured as PNG and shared via the platform
/// share sheet (parents can save / print / send to family).
class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  final GlobalKey _shotKey = GlobalKey();
  bool _busy = false;

  Future<void> _shareCertificate() async {
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
      final shareText = context.l10n.certificateShareText;
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'image/png',
                name: 'aziz_academy_certificate.png',
              ),
            ],
            text: shareText,
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/aziz_academy_certificate_${DateTime.now().millisecondsSinceEpoch}.png';
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
    final ach = ref.watch(achievementProvider).value;
    final profile = ref.watch(profileProvider).value;
    final learner = ref.watch(learnerStateProvider).value;
    final unlocked = ach?.unlockedBadges ?? const <BadgeId>{};
    final name = (profile?.displayName ?? '').trim().isEmpty
        ? (isArabic ? 'صديقي' : 'Friend')
        : profile!.displayName;
    final l10n = context.l10n;

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
                      onPressed: () => context.go(AppRoutes.trophy),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    const Text('📜', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'شهادة الإنجاز' : 'Certificate',
                        style: AppTextStyles.headingMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _shotKey,
                  child: _CertificateCard(
                    name: name,
                    unlocked: unlocked,
                    sessions: learner?.totalSessions ?? 0,
                    arabic: isArabic,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _shareCertificate,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_rounded),
                    label: Text(
                      isArabic ? 'مشاركة الشهادة' : 'Share certificate',
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'الشهادة محفوظة على هذا الجهاز فقط — أنت تختار مع من تشاركها.'
                      : 'Saved only to this device — you choose who to share it with.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.name,
    required this.unlocked,
    required this.sessions,
    required this.arabic,
    required this.l10n,
  });
  final String name;
  final Set<BadgeId> unlocked;
  final int sessions;
  final bool arabic;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6E0), Color(0xFFFFE7B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            arabic ? 'شهادة إنجاز' : 'Certificate of Achievement',
            style: AppTextStyles.headingMedium.copyWith(
              color: const Color(0xFF7B5417),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            arabic ? 'تُمنح إلى' : 'Awarded to',
            style: AppTextStyles.labelMedium.copyWith(
              color: const Color(0xFF7B5417),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTextStyles.headingLarge.copyWith(
              color: const Color(0xFF5C2C0F),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            arabic
                ? 'حصل على ${unlocked.length} شارة من ${allBadges.length}\nبعد $sessions جلسة تعلم على Aziz Academy'
                : 'Earned ${unlocked.length} of ${allBadges.length} badges\nacross $sessions learning sessions on Aziz Academy',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF7B5417),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final def in allBadges.where((b) => unlocked.contains(b.id)))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: def.color.withAlpha(140)),
                  ),
                  child: Text(
                    '${def.emoji} ${l10n.badgeName(def.id)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFF5C2C0F),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'Aziz Academy 🌟',
              style: AppTextStyles.labelMedium.copyWith(
                color: const Color(0xFF7B5417),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
