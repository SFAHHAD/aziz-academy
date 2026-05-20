import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/qbank_drafts_provider.dart';
import 'package:aziz_academy/core/services/ads_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';

// =============================================================================
// Ads admin section — Phase 4 control surface.
//
// Even though the AdSense SDK isn't wired yet, this UI controls:
//   - The master flag (adsOnParentScreens) — when on, AdSlot widgets render
//     on parent-zone routes. Kid zones NEVER render ads regardless.
//   - The age-confirmed flag (parentAgeConfirmed) — required for any slot
//     to render. Normally set via the parental gate on first ad-bearing
//     screen visit; admin can flip it manually here for testing.
//   - A test-render switch that triggers an AdSlot preview in the dashboard.
//
// Kid-safety policy is enforced server-side by AdsService.shouldRenderAd():
// changing the toggles here cannot accidentally show ads on a kid screen.
// =============================================================================

class AdsAdminSection extends ConsumerWidget {
  const AdsAdminSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    return isAdminAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Admin check failed: $e')),
      data: (isAdmin) {
        if (!isAdmin) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'Not authorised. Only admin_users can manage ads.'),
              ),
            ),
          );
        }
        return const _AdsControlsBody();
      },
    );
  }
}

class _AdsControlsBody extends ConsumerWidget {
  const _AdsControlsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final adsOn = settings?.adsOnParentScreens ?? false;
    final ageOk = settings?.parentAgeConfirmed ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Policy banner
        Card(
          color: Colors.deepOrange.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    color: Colors.deepOrange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Kid-safety policy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ads NEVER render on kid-facing screens (quizzes, '
                        'games, Islamic content). Mobile builds (iOS Kids / '
                        'Android DFF) never show ads at all. Only web parent '
                        'screens are eligible, and only if BOTH switches '
                        'below are ON.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Master switches
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Text(
            'CONTROLS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: adsOn,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .setAdsOnParentScreens(v),
                title: const Text('Ads on parent screens (web only)'),
                subtitle: const Text(
                    'Master switch. Turning off hides every AdSlot.'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: ageOk,
                onChanged: (v) => ref
                    .read(appSettingsProvider.notifier)
                    .setParentAgeConfirmed(v),
                title: const Text('Parent age confirmed (18+)'),
                subtitle: const Text(
                    'Defence in depth. Normally set automatically by the '
                    'parental gate the first time a parent visits an '
                    'ad-bearing screen.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Test preview
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Text(
            'PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Below is an AdSlot widget in the parent zone. It only '
                  'renders when both toggles above are ON AND the build is '
                  'web. On mobile or with toggles off, you\'ll see nothing.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const AdSlot(zone: AdZone.parent, minHeight: 90),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Revenue placeholder
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Text(
            'REVENUE (placeholder)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stat(label: 'Revenue this month', value: '— (not configured)'),
                _Stat(label: 'eCPM', value: '—'),
                _Stat(label: 'Impressions', value: '—'),
                _Stat(label: 'Top placement', value: '—'),
                const SizedBox(height: 10),
                Text(
                  'Configure AdSense API credentials in Vercel env '
                  '(ADSENSE_CLIENT_ID, ADSENSE_API_KEY) to enable this '
                  'dashboard. Until then this is empty.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Zone reference
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Text(
            'ZONE REFERENCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ZoneRow(
                  zone: 'AdZone.kid',
                  label: 'Quizzes, games, Islamic content',
                  ads: '❌ Never',
                ),
                Divider(height: 12),
                _ZoneRow(
                  zone: 'AdZone.parent',
                  label: 'Parent dashboard, settings, Plus, account',
                  ads: '✅ When both toggles ON',
                ),
                Divider(height: 12),
                _ZoneRow(
                  zone: 'AdZone.public',
                  label: 'Privacy, About, Install guide',
                  ads: '❌ Hidden by default (policy review pending)',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
          ],
        ),
      );
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.label, required this.ads});
  final String zone, label, ads;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(zone,
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'monospace', color: Colors.cyanAccent)),
          ),
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(ads,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}
