import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'q_bank_service.dart';

// =============================================================================
// Admin lint engine
//
// Walks the raw JSON of every question pool (not just the normalised
// projection used in the Q Bank monitor) and surfaces real content bugs:
//
//   error    — the question is broken and would crash or mislead a kid
//   warning  — content is inconsistent or low quality, will hurt UX
//   info     — best-practice suggestion (e.g. add a fun_fact)
//
// Each issue carries enough context that the operator can fix it in source
// or write an override patch. Cached as a FutureProvider so the dashboard
// can show a loading state.
// =============================================================================

enum LintSeverity { info, warning, error }

class LintIssue {
  const LintIssue({
    required this.severity,
    required this.code,
    required this.poolId,
    required this.questionId,
    required this.message,
  });

  final LintSeverity severity;
  final String code;
  final String poolId;
  final String questionId;
  final String message;
}

class LintReport {
  const LintReport({
    required this.issues,
    required this.totalChecked,
    required this.elapsed,
  });

  final List<LintIssue> issues;
  final int totalChecked;
  final Duration elapsed;

  int get errors =>
      issues.where((i) => i.severity == LintSeverity.error).length;
  int get warnings =>
      issues.where((i) => i.severity == LintSeverity.warning).length;
  int get infos => issues.where((i) => i.severity == LintSeverity.info).length;

  Map<String, List<LintIssue>> byPool() {
    final out = <String, List<LintIssue>>{};
    for (final i in issues) {
      out.putIfAbsent(i.poolId, () => []).add(i);
    }
    return out;
  }

  /// Pretty JSON of the full report — pasteable into a tracker, diff-able
  /// across runs to confirm fixes actually fixed.
  String exportJson() {
    final asMaps = issues
        .map(
          (i) => {
            'severity': i.severity.name,
            'code': i.code,
            'pool': i.poolId,
            'id': i.questionId,
            'message': i.message,
          },
        )
        .toList();
    final root = {
      'generated_at': DateTime.now().toIso8601String(),
      'totals': {
        'errors': errors,
        'warnings': warnings,
        'infos': infos,
        'checked': totalChecked,
        'elapsed_ms': elapsed.inMilliseconds,
      },
      'issues': asMaps,
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }
}

Future<LintReport> runLint() async {
  final sw = Stopwatch()..start();
  final manifest = await rootBundle.loadString('AssetManifest.json');
  final paths =
      (jsonDecode(manifest) as Map<String, dynamic>).keys
          .where((k) => k.startsWith('assets/data/') && k.endsWith('.json'))
          .toList()
        ..sort();

  final issues = <LintIssue>[];
  var checked = 0;
  // Cross-pool tracking. Map<questionId, list of pools that own it>. After
  // walking everything, any id with >1 pool is a global duplicate.
  final globalIds = <String, List<String>>{};
  // Per-pool: counts of correct-answer position (0..n-1) so we can flag
  // questions that always put the right answer in position 0 (a known
  // gameable pattern when authors copy templates).
  final correctPosByPool = <String, Map<int, int>>{};

  for (final path in paths) {
    final poolId = path
        .replaceFirst('assets/data/', '')
        .replaceFirst(RegExp(r'\.json$'), '');
    final raw = await rootBundle.loadString(path);
    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (e) {
      issues.add(
        LintIssue(
          severity: LintSeverity.error,
          code: 'parse_error',
          poolId: poolId,
          questionId: '',
          message: 'JSON parse failed: $e',
        ),
      );
      continue;
    }
    if (parsed is! List) continue;
    final seenIds = <String>{};
    for (final raw in parsed) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final id = (m['id'] as String?)?.trim() ?? '';
      checked++;

      if (id.isEmpty) {
        issues.add(
          LintIssue(
            severity: LintSeverity.error,
            code: 'missing_id',
            poolId: poolId,
            questionId: '(unknown)',
            message: 'Question has no `id` field',
          ),
        );
        continue;
      }
      if (!seenIds.add(id)) {
        issues.add(
          LintIssue(
            severity: LintSeverity.error,
            code: 'duplicate_id',
            poolId: poolId,
            questionId: id,
            message: 'Duplicate id within pool',
          ),
        );
      }
      globalIds.putIfAbsent(id, () => []).add(poolId);

      // Primary text — at least one of question/country/prompt/answer must
      // be set, both EN and AR.
      final hasEn = _hasAny(m, const [
        'question',
        'country',
        'prompt',
        'answer',
        'text',
      ]);
      final hasAr = _hasAny(m, const [
        'question_ar',
        'country_ar',
        'prompt_ar',
        'answer_ar',
        'text_ar',
      ]);
      if (!hasEn) {
        issues.add(
          LintIssue(
            severity: LintSeverity.error,
            code: 'missing_en_text',
            poolId: poolId,
            questionId: id,
            message: 'No English text (question/country/prompt/answer)',
          ),
        );
      }
      if (!hasAr) {
        issues.add(
          LintIssue(
            severity: LintSeverity.warning,
            code: 'missing_ar_text',
            poolId: poolId,
            questionId: id,
            message: 'Arabic primary text missing',
          ),
        );
      }

      // Options validation — only matters for pools that use them.
      final options = m['options'];
      final optionsAr = m['options_ar'];
      final correct =
          (m['correct_answer'] as String?) ?? (m['answer'] as String?);
      final correctAr =
          (m['correct_answer_ar'] as String?) ?? (m['answer_ar'] as String?);

      if (options is List) {
        if (options.length < 2) {
          issues.add(
            LintIssue(
              severity: LintSeverity.error,
              code: 'too_few_options',
              poolId: poolId,
              questionId: id,
              message: 'Only ${options.length} option(s) — quizzes expect ≥2',
            ),
          );
        } else if (options.length != 4) {
          issues.add(
            LintIssue(
              severity: LintSeverity.info,
              code: 'unusual_option_count',
              poolId: poolId,
              questionId: id,
              message: '${options.length} options (most pools use 4)',
            ),
          );
        }

        // Duplicate option text
        final seen = <String>{};
        for (final opt in options) {
          final t = (opt as Object?)?.toString().trim() ?? '';
          if (t.isEmpty) continue;
          if (!seen.add(t)) {
            issues.add(
              LintIssue(
                severity: LintSeverity.warning,
                code: 'duplicate_option',
                poolId: poolId,
                questionId: id,
                message: 'Duplicate option "$t"',
              ),
            );
          }
        }

        // correct_answer must appear in options
        if (correct != null &&
            correct.isNotEmpty &&
            !options.any((o) => o.toString().trim() == correct.trim())) {
          issues.add(
            LintIssue(
              severity: LintSeverity.error,
              code: 'correct_not_in_options',
              poolId: poolId,
              questionId: id,
              message: '`correct_answer` "$correct" not in options',
            ),
          );
        }
      }

      if (optionsAr is List && options is List) {
        if (optionsAr.length != options.length) {
          issues.add(
            LintIssue(
              severity: LintSeverity.warning,
              code: 'options_ar_length_mismatch',
              poolId: poolId,
              questionId: id,
              message:
                  'options=${options.length} but options_ar=${optionsAr.length}',
            ),
          );
        }
        if (correctAr != null &&
            correctAr.isNotEmpty &&
            !optionsAr.any((o) => o.toString().trim() == correctAr.trim())) {
          issues.add(
            LintIssue(
              severity: LintSeverity.warning,
              code: 'correct_ar_not_in_options_ar',
              poolId: poolId,
              questionId: id,
              message: '`correct_answer_ar` "$correctAr" not in options_ar',
            ),
          );
        }
      }

      // Untranslated rows: AR equals EN. Allow short tokens (numbers, names)
      // that legitimately match across languages, e.g. "10" or "BMW".
      final qEn = (m['question'] as String?)?.trim() ?? '';
      final qAr = (m['question_ar'] as String?)?.trim() ?? '';
      if (qEn.isNotEmpty && qEn == qAr && qEn.length > 6) {
        issues.add(
          LintIssue(
            severity: LintSeverity.warning,
            code: 'ar_equals_en',
            poolId: poolId,
            questionId: id,
            message:
                'Arabic question identical to English (likely untranslated)',
          ),
        );
      }

      // Reading level — Flesch-Kincaid grade-level on EN text. Tuned for
      // false-positive avoidance:
      //   - skip very short questions (≤ 8 words) — short prompts trip the
      //     "words per sentence" multiplier even when the language is simple
      //   - skip if the question is one big proper-noun ("What is the
      //     capital of Liechtenstein?") — those inflate syllable count
      //     without being hard for kids
      //   - threshold raised from 7.5 → 8.5 so warnings actually mean
      //     "rewrite this", not "your question contains Ecuador"
      if (qEn.length > 30) {
        final words = qEn
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();
        final mostlyProperNoun =
            words.length >= 4 &&
            words.where((w) => RegExp(r'^[A-Z]').hasMatch(w)).length /
                    words.length >
                0.45;
        if (words.length > 8 && !mostlyProperNoun) {
          final grade = _fleschKincaidGrade(qEn);
          if (grade > 8.5) {
            issues.add(
              LintIssue(
                severity: LintSeverity.warning,
                code: 'reading_level_too_high',
                poolId: poolId,
                questionId: id,
                message:
                    'EN text reads at grade ${grade.toStringAsFixed(1)} '
                    '(target ≤ 8.0 for ages 6-12).',
              ),
            );
          }
        }
      }

      // Long text — kids 6-12 read slowly; question over 220 EN chars or
      // 280 AR chars likely won't fit on a phone screen and frustrates the
      // reader. Tuned from the longest correctly-rendering questions across
      // the bank.
      if (qEn.length > 220) {
        issues.add(
          LintIssue(
            severity: LintSeverity.warning,
            code: 'long_text_en',
            poolId: poolId,
            questionId: id,
            message:
                'English question is ${qEn.length} chars (>220). '
                'Trim for readability on phones.',
          ),
        );
      }
      if (qAr.length > 280) {
        issues.add(
          LintIssue(
            severity: LintSeverity.warning,
            code: 'long_text_ar',
            poolId: poolId,
            questionId: id,
            message:
                'Arabic question is ${qAr.length} chars (>280). '
                'Trim for readability.',
          ),
        );
      }

      // Emoji-only / no-letters question — caught by checking that the EN
      // text has at least one ASCII letter. Pure-emoji questions don't help
      // kids learn vocabulary and break TTS.
      if (qEn.isNotEmpty && !RegExp(r'[A-Za-z]').hasMatch(qEn)) {
        issues.add(
          LintIssue(
            severity: LintSeverity.warning,
            code: 'no_letters_en',
            poolId: poolId,
            questionId: id,
            message: 'English question has no letters — emoji-only? "$qEn"',
          ),
        );
      }

      // Suspicious answer position: track where the correct answer landed
      // for later analysis. We don't emit per-question, but aggregate at the
      // end of the file walk.
      if (options is List && correct != null && correct.isNotEmpty) {
        final pos = options.toList().indexWhere(
          (o) => o.toString().trim() == correct.trim(),
        );
        if (pos >= 0) {
          correctPosByPool
              .putIfAbsent(poolId, () => <int, int>{})
              .update(pos, (n) => n + 1, ifAbsent: () => 1);
        }
      }

      // Difficulty sanity
      final difficulty = m['difficulty'];
      if (difficulty != null) {
        if (difficulty is! num) {
          issues.add(
            LintIssue(
              severity: LintSeverity.warning,
              code: 'difficulty_not_numeric',
              poolId: poolId,
              questionId: id,
              message:
                  '`difficulty` is ${difficulty.runtimeType}, not a number',
            ),
          );
        } else if (difficulty < 1 || difficulty > 5) {
          issues.add(
            LintIssue(
              severity: LintSeverity.info,
              code: 'difficulty_out_of_band',
              poolId: poolId,
              questionId: id,
              message: '`difficulty`=$difficulty — expected 1..5',
            ),
          );
        }
      }

      // Best-practice: encourage fun_fact
      final funEn = (m['fun_fact'] as String?)?.trim() ?? '';
      final funAr = (m['fun_fact_ar'] as String?)?.trim() ?? '';
      final hasFun = funEn.isNotEmpty || funAr.isNotEmpty;
      if (!hasFun && options is List) {
        issues.add(
          LintIssue(
            severity: LintSeverity.info,
            code: 'no_fun_fact',
            poolId: poolId,
            questionId: id,
            message: 'No fun_fact — kids miss the explainer',
          ),
        );
      } else if (funEn.isNotEmpty && funEn.length < 12) {
        issues.add(
          LintIssue(
            severity: LintSeverity.info,
            code: 'fun_fact_too_short',
            poolId: poolId,
            questionId: id,
            message:
                'fun_fact is only ${funEn.length} chars — likely missing the '
                'explainer ("$funEn").',
          ),
        );
      }

      // Placeholder / TODO leftovers in either language. Catches authors who
      // pushed a stub without filling it in.
      final placeholderRe = RegExp(
        r'\b(todo|tbd|fixme|xxx|placeholder|lorem ipsum)\b',
        caseSensitive: false,
      );
      final concat = '$qEn|$qAr|$funEn|$funAr';
      if (placeholderRe.hasMatch(concat)) {
        issues.add(
          LintIssue(
            severity: LintSeverity.error,
            code: 'placeholder_text',
            poolId: poolId,
            questionId: id,
            message:
                'Placeholder text (TODO/TBD/lorem ipsum/etc) detected — '
                'unfinished question shipped.',
          ),
        );
      }

      // SHOUTING question — text in all-caps Latin letters. Reads as anger /
      // marketing; not appropriate for a kid quiz tone.
      if (qEn.length > 12 &&
          qEn == qEn.toUpperCase() &&
          RegExp(r'[A-Z]').hasMatch(qEn)) {
        issues.add(
          LintIssue(
            severity: LintSeverity.info,
            code: 'shouting_caps',
            poolId: poolId,
            questionId: id,
            message: 'Question is ALL CAPS — soften the tone.',
          ),
        );
      }
    }
  }

  // Cross-pool: ids that appear in more than one pool. Common when a pool
  // is forked or copy-pasted; can break analytics that key by id.
  globalIds.forEach((id, pools) {
    if (pools.length > 1) {
      final uniquePools = pools.toSet().toList()..sort();
      if (uniquePools.length > 1) {
        for (final p in uniquePools) {
          issues.add(
            LintIssue(
              severity: LintSeverity.warning,
              code: 'cross_pool_duplicate_id',
              poolId: p,
              questionId: id,
              message:
                  'ID "$id" also appears in: ${uniquePools.where((x) => x != p).join(", ")}',
            ),
          );
        }
      }
    }
  });

  // Per-pool answer-position skew. If >70% of correct answers are in the
  // same slot AND we have ≥10 questions, flag the pool — kids who guess by
  // pattern would beat the quiz without learning.
  correctPosByPool.forEach((pool, hist) {
    final total = hist.values.fold<int>(0, (a, b) => a + b);
    if (total < 10) return;
    final maxEntry = hist.entries.reduce((a, b) => a.value > b.value ? a : b);
    final ratio = maxEntry.value / total;
    if (ratio >= 0.7) {
      issues.add(
        LintIssue(
          severity: LintSeverity.info,
          code: 'answer_position_skew',
          poolId: pool,
          questionId: '(pool)',
          message:
              '${(ratio * 100).toStringAsFixed(0)}% of correct answers sit in '
              'position ${maxEntry.key} (${maxEntry.value}/$total). Shuffle.',
        ),
      );
    }
  });

  // Sort: errors first, then warnings, then info; within tier by pool then id.
  issues.sort((a, b) {
    final s = b.severity.index.compareTo(a.severity.index);
    if (s != 0) return s;
    final p = a.poolId.compareTo(b.poolId);
    if (p != 0) return p;
    return a.questionId.compareTo(b.questionId);
  });

  return LintReport(issues: issues, totalChecked: checked, elapsed: sw.elapsed);
}

bool _hasAny(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return true;
  }
  return false;
}

/// Approximate Flesch-Kincaid grade level. Designed for English; not
/// meaningful for Arabic (different morphology), so we only call it on the
/// EN side. Returns 0..14 typically; we floor at 0 to avoid scary negatives
/// on toddler-grade prompts.
///
///   grade ≈ 0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59
double _fleschKincaidGrade(String text) {
  final t = text.trim();
  if (t.isEmpty) return 0;
  final sentences = RegExp(r'[.!?؟]+').allMatches(t).length.clamp(1, 1 << 30);
  final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return 0;
  final syllables = words.fold<int>(0, (a, w) => a + _syllablesIn(w));
  final grade =
      0.39 * (words.length / sentences) +
      11.8 * (syllables / words.length) -
      15.59;
  return grade < 0 ? 0 : grade;
}

/// Crude syllable counter. Counts groups of vowels in the lowercase form,
/// drops a trailing silent "e", and clamps to ≥1.
int _syllablesIn(String word) {
  final w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (w.isEmpty) return 1;
  final groups = RegExp(r'[aeiouy]+').allMatches(w).length;
  var n = groups;
  if (w.endsWith('e') && groups > 1) n -= 1;
  return n < 1 ? 1 : n;
}

/// FutureProvider so the lint section can show a loading state and the
/// dashboard can refresh on demand.
final lintReportProvider = FutureProvider<LintReport>(
  (ref) => runLint(),
  name: 'lintReportProvider',
);

/// All items missing AR — used by the translation workbench. Re-derived from
/// the q-bank snapshot (cheap; already cached).
List<QBankItem> missingArItems(QBankSnapshot snap) {
  return snap.allItems
      .where((it) => it.primaryEn.isNotEmpty && it.primaryAr.isEmpty)
      .toList();
}
