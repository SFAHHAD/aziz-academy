import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/qbank_drafts_provider.dart';
import 'package:aziz_academy/core/services/feature_flags_service.dart';

// =============================================================================
// Feature flags admin section
//
// Bulk on/off control for sections, games, and gated features. Lives at the
// /x9k2-admin-portal under a new "Flags" tab. Non-admins see a not-authorised
// card; admins see grouped toggles, one per row, with optimistic UI + server
// confirmation.
//
// Side effects to know:
//   - Flipping a section flag hides every tile + route that gates on it
//     within ~one app reload (or immediately on web — we invalidate the
//     provider so listeners rebuild).
//   - The set of valid keys is defined by the seed in
//     supabase/migrations/2026_05_18b_feature_flags.sql. Adding a new
//     toggleable section means inserting a new row there.
// =============================================================================

class FeatureFlagsAdminSection extends ConsumerWidget {
  const FeatureFlagsAdminSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    return isAdminAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not check admin: $e')),
      data: (isAdmin) {
        if (!isAdmin) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'Not authorised — only allow-listed admins can toggle flags.'),
              ),
            ),
          );
        }
        final flagsAsync = ref.watch(allFeatureFlagsProvider);
        return flagsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Load failed: $e')),
          data: (flags) => _Body(flags: flags),
        );
      },
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.flags});
  final List<FeatureFlag> flags;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  // Optimistic local override so the UI feels instant.
  final Map<String, FeatureTier> _override = {};

  FeatureTier _currentTier(FeatureFlag f) => _override[f.key] ?? f.tier;

  Future<void> _setTier(FeatureFlag f, FeatureTier t) async {
    setState(() => _override[f.key] = t);
    final ok = await ref
        .read(featureFlagsServiceProvider)
        .setTier(key: f.key, tier: t);
    if (!mounted) return;
    if (!ok) {
      setState(() => _override.remove(f.key));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not update ${f.key}'),
        backgroundColor: Colors.red.shade700,
      ));
      return;
    }
    ref.invalidate(allFeatureFlagsProvider);
    ref.invalidate(visibleFeatureKeysProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${f.labelEn} → ${t.name.toUpperCase()}'),
      duration: const Duration(milliseconds: 1500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Group by category for readable layout.
    final grouped = <String, List<FeatureFlag>>{};
    for (final f in widget.flags) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    final categoryOrder = ['section', 'game', 'feature', 'admin'];
    final sortedCategories = grouped.keys.toList()
      ..sort((a, b) {
        final ia = categoryOrder.indexOf(a);
        final ib = categoryOrder.indexOf(b);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allFeatureFlagsProvider);
        ref.invalidate(visibleFeatureKeysProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Off-toggling a section hides its tile + blocks its route '
                      'for ALL users within one app reload. Use as a kill switch '
                      'for buggy or experimental features.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final cat in sortedCategories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
              child: Text(
                cat.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final f in grouped[cat]!) ...[
                    ListTile(
                      title: Text(f.labelEn),
                      subtitle: Row(
                        children: [
                          Text(f.labelAr,
                              style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.key,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      trailing: SegmentedButton<FeatureTier>(
                        segments: const [
                          ButtonSegment(
                            value: FeatureTier.off,
                            label: Text('Off'),
                          ),
                          ButtonSegment(
                            value: FeatureTier.free,
                            label: Text('Free'),
                          ),
                          ButtonSegment(
                            value: FeatureTier.pro,
                            label: Text('Pro'),
                          ),
                        ],
                        selected: {_currentTier(f)},
                        onSelectionChanged: (set) {
                          if (set.isNotEmpty) _setTier(f, set.first);
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                    if (f != grouped[cat]!.last) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Convenience wrapper for any section tile — hides itself when flag is off.
// =============================================================================

class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    super.key,
    required this.flagKey,
    required this.child,
    this.fallback,
  });

  /// The feature_flags.key column.
  final String flagKey;

  /// Rendered when the flag is enabled.
  final Widget child;

  /// Rendered when the flag is disabled. Default: shrink to nothing.
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = featureEnabled(ref, flagKey);
    if (enabled) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
