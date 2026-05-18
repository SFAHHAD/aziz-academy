import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Q Bank service
//
// Loads every JSON pool bundled with the app, normalises the heterogeneous
// schemas into one record shape, and computes health metrics so the admin
// dashboard can monitor real content (not just live local state).
//
// All work happens in-process at runtime; nothing is uploaded.
// =============================================================================

/// One question across any pool, normalised. `primaryEn`/`primaryAr` is the
/// main display string (question / country / prompt / answer depending on
/// pool). Empty strings indicate a missing field.
class QBankItem {
  const QBankItem({
    required this.poolId,
    required this.id,
    required this.primaryEn,
    required this.primaryAr,
    required this.category,
    required this.categoryAr,
    required this.difficulty,
    required this.hasOptions,
    required this.hasFunFact,
    required this.hasArOptions,
    required this.hasArAnswer,
  });

  final String poolId;
  final String id;
  final String primaryEn;
  final String primaryAr;
  final String category;
  final String categoryAr;
  final int? difficulty;
  final bool hasOptions;
  final bool hasFunFact;
  final bool hasArOptions;
  final bool hasArAnswer;

  bool get isFullyBilingual =>
      primaryEn.isNotEmpty &&
      primaryAr.isNotEmpty &&
      hasArAnswer &&
      (!hasOptions || hasArOptions);
}

class QBankPoolStats {
  const QBankPoolStats({
    required this.poolId,
    required this.assetPath,
    required this.totalCount,
    required this.bilingualCount,
    required this.missingArCount,
    required this.duplicateIdCount,
    required this.difficultyHistogram,
    required this.categoryCounts,
    required this.byteSize,
    required this.parseError,
  });

  final String poolId;
  final String assetPath;
  final int totalCount;
  final int bilingualCount;
  final int missingArCount;
  final int duplicateIdCount;
  final Map<int, int> difficultyHistogram;
  final Map<String, int> categoryCounts;
  final int byteSize;
  final String? parseError;

  double get bilingualRatio =>
      totalCount == 0 ? 0 : bilingualCount / totalCount;
}

class QBankSnapshot {
  const QBankSnapshot({
    required this.pools,
    required this.totalQuestions,
    required this.totalBilingual,
    required this.totalMissingAr,
    required this.totalDuplicateIds,
    required this.totalBytes,
    required this.poolsWithErrors,
    required this.allItems,
  });

  final List<QBankPoolStats> pools;
  final int totalQuestions;
  final int totalBilingual;
  final int totalMissingAr;
  final int totalDuplicateIds;
  final int totalBytes;
  final int poolsWithErrors;
  final List<QBankItem> allItems;

  double get bilingualRatio =>
      totalQuestions == 0 ? 0 : totalBilingual / totalQuestions;
}

/// Pulled at runtime from `AssetManifest.json` so we don't have to maintain a
/// duplicate list of assets here. Only paths inside `assets/data/` are
/// considered to be Q Bank content.
Future<List<String>> _bundledQBankPaths() async {
  final manifest = await rootBundle.loadString('AssetManifest.json');
  final map = jsonDecode(manifest) as Map<String, dynamic>;
  return map.keys
      .where((k) => k.startsWith('assets/data/') && k.endsWith('.json'))
      .toList()
    ..sort();
}

QBankItem? _normalise(String poolId, dynamic raw) {
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  String s(String key) => (m[key] as String?)?.trim() ?? '';

  // Heterogeneous pool schemas — try a wider fallback chain. The first pair
  // that yields any non-empty primary text wins. Order is by frequency
  // across the 248 pools (question / country / prompt are the bulk; brand /
  // title / name / region cover the long tail).
  const primaryFallbacks = <List<String>>[
    ['question', 'question_ar'],
    ['country', 'country_ar'],
    ['prompt', 'prompt_ar'],
    ['text', 'text_ar'],
    ['brand', 'brand_ar'], // logos.json
    ['title', 'title_ar'], // learning_zone, dua, athkar
    ['name', 'name_ar'], // quran_short_surahs
    ['word', 'word_ar'], // vocabulary
    ['passage', 'passage_ar'], // learning_zone reading containers
    ['region', 'region_ar'], // maps (region only has EN today)
  ];
  String primaryEn = '';
  String primaryAr = '';
  for (final pair in primaryFallbacks) {
    final en = s(pair[0]);
    final ar = s(pair[1]);
    if (en.isNotEmpty || ar.isNotEmpty) {
      primaryEn = en;
      primaryAr = ar;
      break;
    }
  }

  // Answer / target — used to assess AR coverage even when the primary text
  // is the question rather than the answer. We only need the AR side; the EN
  // side is implied by the primary text. Order mirrors the schema variants.
  String answerAr = '';
  for (final key in const [
    'correct_answer_ar', // most quizzes
    'capital_ar', // capitals
    'answer_ar', // spelling
    'brand_ar', // logos (the "answer" is the brand name)
    'name_ar', // quran (surah name)
    'translation_ar', // dua (translation IS the AR understanding)
  ]) {
    final v = s(key);
    if (v.isNotEmpty) {
      answerAr = v;
      break;
    }
  }
  // Some pools (dua_memorization) have native Arabic in a bare `ar` field —
  // count it as the AR side of bilingual coverage when nothing else applies.
  if (answerAr.isEmpty) {
    answerAr = s('ar');
  }

  final id = s('id');
  if (id.isEmpty) return null;

  final hasOptions = m['options'] is List && (m['options'] as List).isNotEmpty;
  final hasArOptions =
      m['options_ar'] is List && (m['options_ar'] as List).isNotEmpty;

  final difficulty = m['difficulty'];
  final difficultyInt = difficulty is num ? difficulty.toInt() : null;

  return QBankItem(
    poolId: poolId,
    id: id,
    primaryEn: primaryEn,
    primaryAr: primaryAr,
    category: s('category'),
    categoryAr: s('category_ar'),
    difficulty: difficultyInt,
    hasOptions: hasOptions,
    hasFunFact: s('fun_fact').isNotEmpty || s('fun_fact_ar').isNotEmpty,
    hasArOptions: hasArOptions,
    hasArAnswer: answerAr.isNotEmpty,
  );
}

Future<QBankSnapshot> loadQBankSnapshot() async {
  final paths = await _bundledQBankPaths();
  final pools = <QBankPoolStats>[];
  final allItems = <QBankItem>[];
  var totalBytes = 0;
  var poolsWithErrors = 0;

  for (final path in paths) {
    final poolId = path
        .replaceFirst('assets/data/', '')
        .replaceFirst(RegExp(r'\.json$'), '');
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (e) {
      pools.add(
        QBankPoolStats(
          poolId: poolId,
          assetPath: path,
          totalCount: 0,
          bilingualCount: 0,
          missingArCount: 0,
          duplicateIdCount: 0,
          difficultyHistogram: const {},
          categoryCounts: const {},
          byteSize: 0,
          parseError: 'load failed: $e',
        ),
      );
      poolsWithErrors++;
      continue;
    }
    totalBytes += raw.length;
    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (e) {
      pools.add(
        QBankPoolStats(
          poolId: poolId,
          assetPath: path,
          totalCount: 0,
          bilingualCount: 0,
          missingArCount: 0,
          duplicateIdCount: 0,
          difficultyHistogram: const {},
          categoryCounts: const {},
          byteSize: raw.length,
          parseError: 'parse failed: $e',
        ),
      );
      poolsWithErrors++;
      continue;
    }

    if (parsed is! List) {
      // Some files (e.g. logos.json, maps.json) are objects not arrays. Skip
      // counting individual items but record the file size so it's visible.
      pools.add(
        QBankPoolStats(
          poolId: poolId,
          assetPath: path,
          totalCount: 0,
          bilingualCount: 0,
          missingArCount: 0,
          duplicateIdCount: 0,
          difficultyHistogram: const {},
          categoryCounts: const {},
          byteSize: raw.length,
          parseError: 'non-array root (${parsed.runtimeType})',
        ),
      );
      poolsWithErrors++;
      continue;
    }

    final items = <QBankItem>[];
    final ids = <String, int>{};
    final difficultyHistogram = <int, int>{};
    final categoryCounts = <String, int>{};
    var bilingualCount = 0;
    var missingAr = 0;

    for (final raw in parsed) {
      final item = _normalise(poolId, raw);
      if (item == null) continue;
      items.add(item);
      ids[item.id] = (ids[item.id] ?? 0) + 1;
      if (item.difficulty != null) {
        difficultyHistogram[item.difficulty!] =
            (difficultyHistogram[item.difficulty!] ?? 0) + 1;
      }
      if (item.category.isNotEmpty) {
        categoryCounts[item.category] =
            (categoryCounts[item.category] ?? 0) + 1;
      }
      if (item.isFullyBilingual) {
        bilingualCount++;
      } else {
        missingAr++;
      }
    }
    final dupIds = ids.values
        .where((c) => c > 1)
        .fold<int>(0, (a, b) => a + b - 1);

    pools.add(
      QBankPoolStats(
        poolId: poolId,
        assetPath: path,
        totalCount: items.length,
        bilingualCount: bilingualCount,
        missingArCount: missingAr,
        duplicateIdCount: dupIds,
        difficultyHistogram: difficultyHistogram,
        categoryCounts: categoryCounts,
        byteSize: raw.length,
        parseError: null,
      ),
    );
    allItems.addAll(items);
  }

  pools.sort((a, b) => b.totalCount.compareTo(a.totalCount));
  return QBankSnapshot(
    pools: pools,
    totalQuestions: pools.fold<int>(0, (a, b) => a + b.totalCount),
    totalBilingual: pools.fold<int>(0, (a, b) => a + b.bilingualCount),
    totalMissingAr: pools.fold<int>(0, (a, b) => a + b.missingArCount),
    totalDuplicateIds: pools.fold<int>(0, (a, b) => a + b.duplicateIdCount),
    totalBytes: totalBytes,
    poolsWithErrors: poolsWithErrors,
    allItems: allItems,
  );
}

/// FutureProvider so the dashboard can show a loading state. Cached for the
/// lifetime of the screen — refresh by `ref.invalidate(qBankProvider)`.
final qBankProvider = FutureProvider<QBankSnapshot>(
  (ref) => loadQBankSnapshot(),
  name: 'qBankProvider',
);
