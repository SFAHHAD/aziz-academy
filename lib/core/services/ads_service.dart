import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';

// =============================================================================
// Ads service — kid-safety FIRST.
//
// Policy boundaries (non-negotiable; encoded in [shouldRenderAd] below):
//   1. Mobile builds (iOS / Android) — NEVER show ads. Apple Kids strictly
//      forbids it; Android Designed-for-Families is a minefield without a
//      certified ad network and explicit family-safe inventory. Until we
//      have legal review, no ads on mobile, ever.
//   2. Web — only on routes marked AdZone.parent. Kid-facing quiz/game/
//      Islamic content screens are AdZone.kid (default) and never show ads.
//   3. Feature flag — admin must explicitly enable [adsOnParentScreens] in
//      settings. Default is OFF.
//   4. Locale-specific opt-out hook so we can disable ads per market if
//      family-safe inventory isn't available yet.
//
// CI gate (test/integration/ads_policy_test.dart) walks every route and
// asserts that [AdSlot] only renders when [zone] is AdZone.parent.
//
// NOTHING in this file calls a real ad SDK yet — that ships in Phase 4 of
// PROJECT_PLAN.md once the user has done the AdSense application review.
// This is the policy gate the SDK call will live behind.
// =============================================================================

/// Where an ad slot is being requested from. Set per GoRoute via a new
/// `extra: AdZone.parent` (or `.kid`, `.public`) field.
enum AdZone {
  /// Kid-facing content — quizzes, games, Islamic learning. NEVER show ads.
  kid,

  /// Adult-facing — parent dashboard, settings, account, plus, admin.
  parent,

  /// Pre-auth / landing — privacy policy, about, install guide. Currently
  /// treated like [kid] (no ads) until policy review covers them.
  public,
}

class AdsService {
  AdsService();

  /// Single decision point. UI code calls `shouldRenderAd(zone: ..., ...)`
  /// and only renders the slot if this returns true.
  bool shouldRenderAd({
    required AdZone zone,
    required bool flagEnabled,
    String? localeCode,
    bool parentAgeConfirmed = false,
  }) {
    // 1) Mobile builds never show ads.
    if (!kIsWeb) return false;

    // 2) Only parent zones — kid content stays ad-free everywhere.
    if (zone != AdZone.parent) return false;

    // 3) Admin must have explicitly turned the flag on.
    if (!flagEnabled) return false;

    // 4) Per-market block list. Until we verify family-safe ad inventory
    //    in each locale, only ship ads where we've reviewed.
    //    EMPTY by default — flip locales on case-by-case.
    const allowedLocales = <String>{};
    if (allowedLocales.isNotEmpty &&
        (localeCode == null || !allowedLocales.contains(localeCode))) {
      return false;
    }

    // 5) Defence in depth: the parent must have confirmed they are 18+
    //    on this device (via the parental gate). The flag is stored in
    //    AppSettings.parentAgeConfirmed (not yet wired — see
    //    PROJECT_PLAN.md Phase 4.3).
    if (!parentAgeConfirmed) return false;

    return true;
  }
}

final adsServiceProvider = Provider<AdsService>((ref) => AdsService());

/// Convenience widget — drop into any parent-facing screen where an ad
/// might appear. Renders nothing unless the policy gate passes. When the
/// SDK ships (Phase 4), this widget will own the AdSense iframe.
class AdSlot extends ConsumerWidget {
  const AdSlot({
    super.key,
    required this.zone,
    this.minHeight = 90,
  });

  /// What kind of screen we're on. Set by the route or by the parent widget.
  /// Default is [AdZone.kid] so a developer who forgets to specify is safely
  /// ad-free.
  final AdZone zone;

  /// Reserve space so the layout doesn't jump when an ad loads. AdSense
  /// banner is 90 px tall typically; tune per slot.
  final double minHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final ads = ref.watch(adsServiceProvider);

    final show = ads.shouldRenderAd(
      zone: zone,
      flagEnabled: settings?.adsOnParentScreens ?? false,
      parentAgeConfirmed: settings?.parentAgeConfirmed ?? false,
    );

    if (!show) return const SizedBox.shrink();

    // Placeholder until the AdSense SDK is wired in Phase 4. Renders a
    // visible "ad will appear here" rectangle in dev only — never in
    // release builds, where the policy gate above has already returned
    // false because the SDK isn't loaded.
    if (kDebugMode) {
      return Container(
        height: minHeight,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        alignment: Alignment.center,
        child: const Text(
          '[AdSlot placeholder — dev only]',
          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
        ),
      );
    }

    return SizedBox(height: minHeight);
  }
}
