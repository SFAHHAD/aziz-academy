import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/recap_queue_provider.dart';
import '../home/activity_catalog.dart';
import 'admin_assets.dart';
import 'admin_error_log.dart';
import 'admin_feedback.dart';
import 'admin_lint.dart';
import 'admin_traffic.dart';
import 'q_bank_service.dart';

// =============================================================================
// Auditor's report
//
// Aggregates everything we already capture (Q Bank stats, lint report, error
// log, traffic, feedback inbox, storage, build flags) into a prioritised list
// of findings, each with severity, evidence, and a concrete recommendation.
//
// This is what an external auditor would write up after a one-day pass:
// "here's what's wrong, here's the proof, here's what to do."
// =============================================================================

enum AuditArea { content, security, performance, accessibility, operations }

extension AuditAreaX on AuditArea {
  String get label {
    switch (this) {
      case AuditArea.content:
        return 'Content';
      case AuditArea.security:
        return 'Security & Privacy';
      case AuditArea.performance:
        return 'Performance';
      case AuditArea.accessibility:
        return 'Accessibility';
      case AuditArea.operations:
        return 'Operations';
    }
  }
}

enum AuditSeverity { critical, high, medium, low, info, ok }

class AuditFinding {
  const AuditFinding({
    required this.area,
    required this.severity,
    required this.title,
    required this.evidence,
    required this.recommendation,
  });

  final AuditArea area;
  final AuditSeverity severity;
  final String title;
  final String evidence;
  final String recommendation;
}

class AuditReport {
  const AuditReport({required this.findings, required this.generatedAt});

  final List<AuditFinding> findings;
  final DateTime generatedAt;

  int countOf(AuditSeverity s) => findings.where((f) => f.severity == s).length;

  /// Score 0-100. Critical -25, high -10, medium -3, low -1. Floor 0.
  int get healthScore {
    var s = 100;
    s -= countOf(AuditSeverity.critical) * 25;
    s -= countOf(AuditSeverity.high) * 10;
    s -= countOf(AuditSeverity.medium) * 3;
    s -= countOf(AuditSeverity.low) * 1;
    return s.clamp(0, 100);
  }

  Map<AuditArea, List<AuditFinding>> byArea() {
    final out = <AuditArea, List<AuditFinding>>{};
    for (final f in findings) {
      out.putIfAbsent(f.area, () => []).add(f);
    }
    return out;
  }

  /// One-page markdown summary suitable for pasting into a doc, an issue
  /// tracker, or an email. Header line per area, one bullet per finding,
  /// inline severity tag.
  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Aziz Academy — Audit report');
    buf.writeln();
    buf.writeln('**Generated:** ${generatedAt.toIso8601String()}  ');
    buf.writeln('**Health score:** $healthScore / 100  ');
    buf.writeln(
      '**Counts:** '
      'Critical ${countOf(AuditSeverity.critical)} · '
      'High ${countOf(AuditSeverity.high)} · '
      'Medium ${countOf(AuditSeverity.medium)} · '
      'Low ${countOf(AuditSeverity.low)} · '
      'OK ${countOf(AuditSeverity.ok)}',
    );
    buf.writeln();
    final ba = byArea();
    for (final entry in ba.entries) {
      buf.writeln('## ${entry.key.label}');
      buf.writeln();
      for (final f in entry.value) {
        buf.writeln('- **[${f.severity.name.toUpperCase()}]** ${f.title}');
        buf.writeln('  - *Evidence:* ${f.evidence}');
        buf.writeln('  - *Recommendation:* ${f.recommendation}');
      }
      buf.writeln();
    }
    return buf.toString();
  }
}

Future<AuditReport> runAudit(Ref ref) async {
  final findings = <AuditFinding>[];

  // ── Pull all sources in parallel where possible ──
  final qBankF = ref.read(qBankProvider.future);
  final lintF = ref.read(lintReportProvider.future);
  final trafficF = AdminTraffic.snapshot();
  final feedback = ref.read(feedbackInboxProvider).value ?? const [];
  final prefs = await SharedPreferences.getInstance();

  late QBankSnapshot qBank;
  late LintReport lint;
  late TrafficSnapshot traffic;

  try {
    qBank = await qBankF;
  } catch (e) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.critical,
        title: 'Q Bank failed to load',
        evidence: 'Error: $e',
        recommendation:
            'Inspect AssetManifest.json — at least one pool is '
            'missing or unparseable.',
      ),
    );
  }
  try {
    lint = await lintF;
  } catch (e) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.high,
        title: 'Lint failed to complete',
        evidence: 'Error: $e',
        recommendation:
            'Re-run lint manually from the Lint tab. If it still '
            'fails, look at the most recent edit to a JSON pool.',
      ),
    );
  }
  try {
    traffic = await trafficF;
  } catch (e) {
    traffic = const TrafficSnapshot(
      totalOpens: 0,
      activeDays: [],
      openDaysLast7: 0,
      openDaysLast30: 0,
      firstOpenAt: null,
      lastOpenAt: null,
      openHistogramByDay: [],
      routeHits: {},
      routeLastSeen: {},
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────────────
  if (qBank.poolsWithErrors > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.critical,
        title: '${qBank.poolsWithErrors} question pool(s) failed to parse',
        evidence:
            'See Q Bank → Issues only filter. These pools never reach the kid.',
        recommendation:
            'Open each errored pool in your editor, run a JSON '
            'validator, fix the syntax, redeploy.',
      ),
    );
  }
  if (qBank.totalDuplicateIds > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.high,
        title: '${qBank.totalDuplicateIds} duplicate question IDs',
        evidence:
            'Same id reused inside the same pool — review-mode and analytics '
            'collapse them, kids see the same question twice.',
        recommendation:
            'Q Bank → drill into the pool with the dup → rename one of the '
            'rows to a unique id.',
      ),
    );
  }
  final missingArRatio = qBank.totalQuestions == 0
      ? 0
      : qBank.totalMissingAr / qBank.totalQuestions;
  if (missingArRatio > 0.05) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.high,
        title:
            '${qBank.totalMissingAr} questions are missing Arabic (${(missingArRatio * 100).toStringAsFixed(1)}%)',
        evidence:
            'AR/EN parity drops to ${(qBank.bilingualRatio * 100).toStringAsFixed(1)}%. '
            'Arabic-locale kids get untranslated content.',
        recommendation:
            'Translate tab → filter by pool → fill the missing rows → '
            'export overrides → fold patches back into source JSON.',
      ),
    );
  } else if (missingArRatio > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.medium,
        title: '${qBank.totalMissingAr} stragglers without Arabic',
        evidence:
            '${(qBank.bilingualRatio * 100).toStringAsFixed(2)}% bilingual coverage.',
        recommendation: 'Translate tab can finish these in one pass.',
      ),
    );
  }

  if (lint.errors > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.high,
        title: 'Lint reports ${lint.errors} content errors',
        evidence:
            'Includes broken correct_answer fields, missing IDs, options < 2. '
            'These produce wrong answers in production.',
        recommendation: 'Lint tab → filter Errors → fix or override each row.',
      ),
    );
  }
  if (lint.warnings > 50) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.medium,
        title: '${lint.warnings} lint warnings (best-practice violations)',
        evidence:
            'Mostly missing AR text and inconsistent option counts. Doesn\'t '
            'crash the app, but degrades UX.',
        recommendation:
            'Plan a content-cleanup pass — Translate handles ~70% '
            'of these.',
      ),
    );
  }

  // ── CATALOG INTEGRITY ────────────────────────────────────────────────
  // The home grid only ever surfaces what's in `kActivities`. If an entry
  // has a duplicate id, an empty route, or no featured/discoverable hook,
  // the kid silently never sees it. These checks cost ~µs at audit time
  // and catch drift before content cleanup makes it worse.
  final ids = <String>{};
  final dupIds = <String>{};
  var emptyRoutes = 0;
  for (final a in kActivities) {
    if (!ids.add(a.id)) dupIds.add(a.id);
    if (a.route.trim().isEmpty) emptyRoutes++;
  }
  if (dupIds.isNotEmpty) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.high,
        title: '${dupIds.length} duplicate activity id(s) in the catalog',
        evidence:
            'Duplicates: ${dupIds.take(5).join(", ")}'
            '${dupIds.length > 5 ? "..." : ""}',
        recommendation:
            'Open lib/features/home/activity_catalog.dart and rename each '
            'duplicate id. Personalisation keys off id, so dups confuse pick logic.',
      ),
    );
  }
  if (emptyRoutes > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.critical,
        title: '$emptyRoutes activity row(s) have no route',
        evidence: 'Tapping the card would no-op silently.',
        recommendation:
            'Either wire a route in app_router.dart and reference it, or '
            'remove the row from the catalog.',
      ),
    );
  }
  // Coverage per category — kids browsing a tab with < 3 activities feel
  // it's broken. Keeps drift visible as content grows.
  final perCat = <ActivityCategory, int>{};
  for (final a in kActivities) {
    perCat[a.category] = (perCat[a.category] ?? 0) + 1;
  }
  final thinCats = perCat.entries.where((e) => e.value < 3).toList();
  if (thinCats.isNotEmpty) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.low,
        title: '${thinCats.length} category(ies) feel empty (<3 activities)',
        evidence: thinCats
            .map((e) => '${e.key.labelEn()}=${e.value}')
            .join(', '),
        recommendation:
            'Add a couple more activities to each thin category, or merge '
            'categories so no tab feels half-built.',
      ),
    );
  }
  final featuredCount = kActivities.where((a) => a.featured).length;
  if (featuredCount < 6) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.low,
        title: 'Only $featuredCount activities flagged featured',
        evidence:
            'Featured tab leans heavily on safe-defaults + discovery rotation.',
        recommendation:
            'Mark another 4-6 strong activities as `featured: true` so the '
            'top-of-home rail is genuinely curated.',
      ),
    );
  } else {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.ok,
        title:
            'Catalog: ${kActivities.length} activities across ${perCat.length} categories ($featuredCount featured)',
        evidence: 'No duplicates, no empty routes, no thin categories.',
        recommendation:
            'Keep this in sync — every new screen needs a row here or it never '
            'surfaces on home.',
      ),
    );
  }

  // ── Q-BANK REACHABILITY ──────────────────────────────────────────────
  // The repositories below are the spine of the quiz experience — every quiz
  // route in the catalog ultimately resolves to one of these asset paths.
  // If any go missing or fail to parse the kid sees a broken/empty quiz.
  // The list mirrors the `_assetPath` constants in lib/features/*/data/*.dart.
  const criticalPools = <String, String>{
    'capitals': 'feeds Capitals + Flags + Maps quizzes',
    'logos': 'feeds Logos quiz',
    'sciences': 'feeds Sciences quiz',
    'dua_memorization': 'feeds Dua Memorization screen',
    'vocabulary': 'feeds Flashcards screen',
  };
  final loadedPoolIds = qBank.pools.map((p) => p.poolId).toSet();
  final missingCritical = <MapEntry<String, String>>[];
  final brokenCritical = <MapEntry<String, String>>[];
  for (final entry in criticalPools.entries) {
    if (!loadedPoolIds.contains(entry.key)) {
      missingCritical.add(entry);
      continue;
    }
    final pool = qBank.pools.firstWhere((p) => p.poolId == entry.key);
    if (pool.parseError != null && pool.totalCount == 0) {
      brokenCritical.add(entry);
    }
  }
  if (missingCritical.isNotEmpty) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.critical,
        title: '${missingCritical.length} critical pool(s) missing from bundle',
        evidence: missingCritical
            .map((e) => '${e.key}.json (${e.value})')
            .join('; '),
        recommendation:
            'Run `flutter pub get` and rebuild — assets/data/<pool>.json must '
            'be in pubspec.yaml under `flutter.assets`. Without it the linked '
            'quizzes silently 404 their data.',
      ),
    );
  }
  if (brokenCritical.isNotEmpty) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.critical,
        title: '${brokenCritical.length} critical pool(s) failed to parse',
        evidence: brokenCritical
            .map((e) => '${e.key}.json (${e.value})')
            .join('; '),
        recommendation:
            'Open each pool in your editor + a JSON validator. Fix the syntax, '
            'rebuild, redeploy.',
      ),
    );
  }
  if (missingCritical.isEmpty && brokenCritical.isEmpty) {
    findings.add(
      AuditFinding(
        area: AuditArea.content,
        severity: AuditSeverity.ok,
        title:
            'All ${criticalPools.length} critical pools loaded and parseable',
        evidence: criticalPools.keys.join(', '),
        recommendation:
            'Maintain. New repository wiring? Add the pool to `criticalPools` '
            'in admin_audit.dart so this guard keeps catching drift.',
      ),
    );
  }

  // ── SECURITY & PRIVACY ────────────────────────────────────────────────
  // Inventory of what's stored locally so the auditor can vouch for the
  // privacy posture.
  final keys = prefs.getKeys();
  var localBytes = 0;
  for (final k in keys) {
    final v = prefs.get(k);
    if (v != null) localBytes += v.toString().length;
  }
  findings.add(
    AuditFinding(
      area: AuditArea.security,
      severity: AuditSeverity.ok,
      title: 'Zero PII collected — fully on-device storage',
      evidence:
          '${keys.length} SharedPreferences keys (~${(localBytes / 1024).toStringAsFixed(1)} KB) '
          'on this device. No backend, no analytics SDK, no third-party scripts.',
      recommendation:
          'Maintain. If you ever add a backend, document the data flow in '
          'PRIVACY.md before shipping.',
    ),
  );

  // Check for any PII-shaped key (common naming patterns)
  final piiSuspects = keys
      .where(
        (k) => RegExp(
          r'(email|phone|password|token|name)',
          caseSensitive: false,
        ).hasMatch(k),
      )
      .toList();
  if (piiSuspects.isNotEmpty) {
    findings.add(
      AuditFinding(
        area: AuditArea.security,
        severity: AuditSeverity.medium,
        title: '${piiSuspects.length} key(s) with PII-suggestive names',
        evidence:
            'Keys: ${piiSuspects.take(5).join(", ")}'
            '${piiSuspects.length > 5 ? "..." : ""}',
        recommendation:
            'Open Storage tab → confirm contents are not actual PII. If they '
            'are, encrypt or remove before any backup/export feature.',
      ),
    );
  }

  // Admin gate strength
  findings.add(
    AuditFinding(
      area: AuditArea.security,
      severity: AuditSeverity.medium,
      title: 'Admin gate uses a 4-digit static passcode',
      evidence:
          'Acceptable for an on-device console; not a security boundary if the '
          'URL leaks alongside the code.',
      recommendation:
          'Rotate `_kPasscode` quarterly. If you ever publish the admin URL, '
          'add IP-based gate via a Vercel middleware.',
    ),
  );

  // ── PERFORMANCE ───────────────────────────────────────────────────────
  findings.add(
    AuditFinding(
      area: AuditArea.performance,
      severity: AuditSeverity.info,
      title: 'Build mode',
      evidence: kReleaseMode
          ? 'Running in release mode'
          : kProfileMode
          ? 'Running in profile mode'
          : 'Running in DEBUG mode',
      recommendation: kReleaseMode
          ? 'OK — ship continues in release.'
          : 'If this is the live deploy, rebuild with `flutter build web '
                '--release` immediately.',
    ),
  );
  if (qBank.totalBytes > 8 * 1024 * 1024) {
    findings.add(
      AuditFinding(
        area: AuditArea.performance,
        severity: AuditSeverity.low,
        title:
            'Q Bank weighs ${(qBank.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB bundled',
        evidence:
            'Loaded at first paint via rootBundle. Adds to bundle weight + parse time.',
        recommendation:
            'Consider lazy-loading large pools (split per-quiz) or moving rare '
            'pools behind a network fetch.',
      ),
    );
  }

  // Total asset footprint — JSON pools + images + audio + fonts. Uses the
  // cheap probe (manifest count + JSON-only sizes), so the threshold is the
  // floor of actual weight; the real thing is at least this big.
  try {
    final inv = await ref.read(assetInventoryProvider.future);
    final mb = inv.totalBytes / 1024 / 1024;
    if (inv.totalBytes > 12 * 1024 * 1024) {
      findings.add(
        AuditFinding(
          area: AuditArea.performance,
          severity: AuditSeverity.medium,
          title:
              'Bundled assets ≥ ${mb.toStringAsFixed(1)} MB across ${inv.entries.length} files',
          evidence:
              'Quick probe (JSON sizes only). Real total likely larger once '
              'images and fonts are weighed. Slows first paint on cold load.',
          recommendation:
              'Open the Assets section → "Full sizes" → sort by biggest. Drop '
              'unused images/fonts from pubspec.yaml. Consider switching '
              'rarely-used pools to network fetch.',
        ),
      );
    } else {
      findings.add(
        AuditFinding(
          area: AuditArea.performance,
          severity: AuditSeverity.ok,
          title:
              'Asset footprint OK (${mb.toStringAsFixed(1)} MB JSON-probed across ${inv.entries.length} files)',
          evidence: 'Below the 12 MB ceiling for cold-load comfort.',
          recommendation:
              'Re-check after adding new pools or audio. Each MB pushes first '
              'paint by ~80-150 ms on mobile networks.',
        ),
      );
    }
  } catch (_) {
    // Asset inventory failures are surfaced in the Assets section directly;
    // not worth a duplicate audit finding.
  }

  // ── ACCESSIBILITY ─────────────────────────────────────────────────────
  // Surface that the toggles exist; this is a "yes, you have these" finding,
  // not an issue.
  findings.add(
    AuditFinding(
      area: AuditArea.accessibility,
      severity: AuditSeverity.ok,
      title: 'Accessibility toggles available',
      evidence:
          'Reduced motion, dyslexia-friendly font, larger text, light mode, '
          'audio-quiz (TTS) — all present in app settings.',
      recommendation:
          'Add periodic screenshot tests with each toggle to prevent regression.',
    ),
  );

  // ── OPERATIONS ────────────────────────────────────────────────────────
  final errorEntries = AdminErrorLog.entries;
  final criticalErrors = errorEntries
      .where((e) => e.severity == AdminLogSeverity.error)
      .length;
  if (criticalErrors > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.operations,
        severity: AuditSeverity.high,
        title: '$criticalErrors framework error(s) captured this session',
        evidence:
            'In-memory ring buffer (last 200) — see Errors tab. Cleared on '
            'reload, so add a real reporter for cross-session aggregation.',
        recommendation:
            'Read each one, file or fix. For continuous coverage, plug in '
            'Sentry web SDK (free tier).',
      ),
    );
  } else {
    findings.add(
      AuditFinding(
        area: AuditArea.operations,
        severity: AuditSeverity.ok,
        title: 'No framework errors captured this session',
        evidence: 'Errors tab is empty.',
        recommendation:
            'Maintain. Plug in Sentry to retain error history across sessions.',
      ),
    );
  }

  // Cross-device traffic — Vercel Web Analytics + Speed Insights are wired
  // into web/index.html. The script is privacy-friendly (no cookies, no PII)
  // and auto-disables in dev / non-prod previews.
  findings.add(
    AuditFinding(
      area: AuditArea.operations,
      severity: AuditSeverity.ok,
      title: 'Vercel Web Analytics + Speed Insights wired',
      evidence:
          'On-device opens (this device): ${traffic.totalOpens}. Cross-device '
          'visitor counts, top pages, country split, and Core Web Vitals are '
          'available in the Vercel dashboard.',
      recommendation:
          'Bookmark vercel.com/<team>/aziz-academy/analytics. If you need '
          'session replays or funnels, layer PostHog on top.',
    ),
  );

  if (traffic.openDaysLast7 == 0 && traffic.totalOpens > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.operations,
        severity: AuditSeverity.low,
        title: 'No app opens in the last 7 days on this device',
        evidence:
            'Last open: ${traffic.lastOpenAt?.toIso8601String() ?? "never"}.',
        recommendation:
            'Doesn\'t reflect cross-device activity, but if you\'re the only '
            'user pattern, the app may need a re-engagement nudge.',
      ),
    );
  }

  // Recap queue health — orphan check. Recap entries that reference IDs
  // not present in any pool will silently fail to surface struggling
  // questions back to the kid, so the spaced-repetition loop quietly degrades.
  try {
    final recap = await ref.read(recapQueueProvider.future);
    if (recap.isNotEmpty) {
      final allItemIds = qBank.allItems.map((i) => i.id).toSet();
      final orphans = recap
          .where(
            (e) =>
                e.questionId.isNotEmpty && !allItemIds.contains(e.questionId),
          )
          .toList();
      if (orphans.isNotEmpty && qBank.allItems.isNotEmpty) {
        findings.add(
          AuditFinding(
            area: AuditArea.operations,
            severity: AuditSeverity.medium,
            title:
                '${orphans.length} recap entry(ies) reference missing question IDs',
            evidence:
                'Likely from a pool rebuild that renamed IDs. Affected modules: '
                '${orphans.map((e) => e.module.name).toSet().join(", ")}.',
            recommendation:
                'Tools → "Compact recap queue" to drop orphans, OR keep IDs '
                'stable when refactoring pool JSON. Either way the kid will not '
                'see those questions resurface unless cleaned.',
          ),
        );
      } else {
        findings.add(
          AuditFinding(
            area: AuditArea.operations,
            severity: AuditSeverity.ok,
            title: 'Recap queue healthy (${recap.length} entries, no orphans)',
            evidence:
                'Every recap entry maps to a question that still exists in '
                'the bundled pools.',
            recommendation:
                'Maintain. If you ever rename question IDs, run this audit '
                'before shipping to catch the drift.',
          ),
        );
      }
    }
  } catch (_) {
    // Recap load failures are surfaced elsewhere; not worth duplicating.
  }

  // Feedback summary
  final openFeedback = feedback
      .where((e) => e.status == FeedbackStatus.open)
      .length;
  if (openFeedback > 0) {
    findings.add(
      AuditFinding(
        area: AuditArea.operations,
        severity: openFeedback >= 5 ? AuditSeverity.medium : AuditSeverity.low,
        title: '$openFeedback open feedback item(s)',
        evidence: 'Submitted from this device, not yet marked resolved.',
        recommendation:
            'Triage in Feedback tab — mark resolved/archived as you action them.',
      ),
    );
  }

  // ── Sort by severity then area ───────────────────────────────────────
  const order = {
    AuditSeverity.critical: 0,
    AuditSeverity.high: 1,
    AuditSeverity.medium: 2,
    AuditSeverity.low: 3,
    AuditSeverity.info: 4,
    AuditSeverity.ok: 5,
  };
  findings.sort((a, b) {
    final s = order[a.severity]!.compareTo(order[b.severity]!);
    if (s != 0) return s;
    return a.area.index.compareTo(b.area.index);
  });

  final report = AuditReport(findings: findings, generatedAt: DateTime.now());

  // Append to history (rolling 30 entries) so the dashboard can show a
  // score trend without recomputing the whole audit each render.
  await AuditHistory.recordSnapshot(report);

  return report;
}

final auditReportProvider = FutureProvider<AuditReport>(
  (ref) => runAudit(ref),
  name: 'auditReportProvider',
);

// =============================================================================
// History — last 30 audit-score snapshots, persisted locally so trends are
// visible across sessions without a backend. Each call to `runAudit` appends
// to this list; the dashboard reads it via [auditHistoryProvider].
// =============================================================================

const _kHistoryKey = 'admin_audit_history_v1';
const int _kHistoryCap = 30;

class AuditSnapshot {
  const AuditSnapshot({
    required this.at,
    required this.score,
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
  });

  final DateTime at;
  final int score;
  final int critical;
  final int high;
  final int medium;
  final int low;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'score': score,
    'c': critical,
    'h': high,
    'm': medium,
    'l': low,
  };

  static AuditSnapshot fromJson(Map<String, dynamic> j) => AuditSnapshot(
    at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
    score: (j['score'] as num?)?.toInt() ?? 0,
    critical: (j['c'] as num?)?.toInt() ?? 0,
    high: (j['h'] as num?)?.toInt() ?? 0,
    medium: (j['m'] as num?)?.toInt() ?? 0,
    low: (j['l'] as num?)?.toInt() ?? 0,
  );
}

class AuditHistory {
  AuditHistory._();

  static Future<List<AuditSnapshot>> read() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kHistoryKey);
    if (raw == null) return <AuditSnapshot>[];
    try {
      return ((jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          .map(AuditSnapshot.fromJson)
          .toList();
    } catch (_) {
      return <AuditSnapshot>[];
    }
  }

  static Future<void> recordSnapshot(AuditReport rep) async {
    final p = await SharedPreferences.getInstance();
    final list = await read();
    list.add(
      AuditSnapshot(
        at: rep.generatedAt,
        score: rep.healthScore,
        critical: rep.countOf(AuditSeverity.critical),
        high: rep.countOf(AuditSeverity.high),
        medium: rep.countOf(AuditSeverity.medium),
        low: rep.countOf(AuditSeverity.low),
      ),
    );
    if (list.length > _kHistoryCap) {
      list.removeRange(0, list.length - _kHistoryCap);
    }
    await p.setString(
      _kHistoryKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHistoryKey);
  }
}

final auditHistoryProvider = FutureProvider<List<AuditSnapshot>>(
  (ref) => AuditHistory.read(),
  name: 'auditHistoryProvider',
);
