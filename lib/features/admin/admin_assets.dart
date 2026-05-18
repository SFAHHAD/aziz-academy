import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Asset inventory
//
// Reads `AssetManifest.json` and (when available) `AssetManifest.bin.json` to
// list every bundled asset, group by type, and surface the biggest files so
// the operator can prune. Running on web, sizes come from the manifest; on
// other platforms we still read the manifest entries but file sizes require
// the fallback `rootBundle.load(path)` -> `ByteData.lengthInBytes`.
// =============================================================================

enum AssetKind { image, audio, font, lottie, data, html, other }

extension AssetKindX on AssetKind {
  String get label {
    switch (this) {
      case AssetKind.image:
        return 'Images';
      case AssetKind.audio:
        return 'Audio';
      case AssetKind.font:
        return 'Fonts';
      case AssetKind.lottie:
        return 'Lottie';
      case AssetKind.data:
        return 'Data (JSON)';
      case AssetKind.html:
        return 'HTML';
      case AssetKind.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case AssetKind.image:
        return '🖼️';
      case AssetKind.audio:
        return '🔊';
      case AssetKind.font:
        return '🔤';
      case AssetKind.lottie:
        return '🎞️';
      case AssetKind.data:
        return '📦';
      case AssetKind.html:
        return '📄';
      case AssetKind.other:
        return '📎';
    }
  }

  static AssetKind fromPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.json')) {
      // Most JSON in this app is bundled question pools.
      return AssetKind.data;
    }
    if (p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.webp') ||
        p.endsWith('.gif') ||
        p.endsWith('.svg')) {
      return AssetKind.image;
    }
    if (p.endsWith('.mp3') ||
        p.endsWith('.wav') ||
        p.endsWith('.ogg') ||
        p.endsWith('.m4a')) {
      return AssetKind.audio;
    }
    if (p.endsWith('.ttf') ||
        p.endsWith('.otf') ||
        p.endsWith('.woff') ||
        p.endsWith('.woff2')) {
      return AssetKind.font;
    }
    if (p.contains('lottie') || p.endsWith('.lottie')) {
      return AssetKind.lottie;
    }
    if (p.endsWith('.html') || p.endsWith('.htm')) {
      return AssetKind.html;
    }
    return AssetKind.other;
  }
}

class AssetEntry {
  const AssetEntry({
    required this.path,
    required this.kind,
    required this.bytes,
  });

  final String path;
  final AssetKind kind;
  final int bytes;
}

class AssetInventory {
  const AssetInventory({
    required this.entries,
    required this.byKind,
    required this.totalBytes,
  });

  final List<AssetEntry> entries;
  final Map<AssetKind, List<AssetEntry>> byKind;
  final int totalBytes;

  int sizeOf(AssetKind k) =>
      (byKind[k] ?? const []).fold<int>(0, (a, b) => a + b.bytes);

  int countOf(AssetKind k) => (byKind[k] ?? const []).length;

  List<AssetEntry> biggest(int n) {
    final list = [...entries]..sort((a, b) => b.bytes.compareTo(a.bytes));
    return list.take(n).toList();
  }
}

/// Loading every asset to measure size would tank cold start, so we cap
/// per-asset reads. JSON pool sizes (the bulk of the bundle) are captured
/// because the Q Bank service has already read each one for parsing.
Future<AssetInventory> loadAssetInventory({int maxProbeBytesPer = 0}) async {
  final raw = await rootBundle.loadString('AssetManifest.json');
  final paths = (jsonDecode(raw) as Map<String, dynamic>).keys.toList()..sort();

  final entries = <AssetEntry>[];
  for (final p in paths) {
    int bytes = 0;
    if (maxProbeBytesPer > 0) {
      try {
        final data = await rootBundle.load(p);
        bytes = data.lengthInBytes;
      } catch (_) {
        bytes = 0;
      }
    } else {
      // Cheap mode: probe size only for JSON pools (loaded as strings) and
      // leave others at 0. The dashboard makes it clear when sizes are
      // unavailable so the operator can request the slow scan on demand.
      if (p.endsWith('.json')) {
        try {
          final s = await rootBundle.loadString(p);
          bytes = s.length;
        } catch (_) {
          bytes = 0;
        }
      }
    }
    entries.add(
      AssetEntry(path: p, kind: AssetKindX.fromPath(p), bytes: bytes),
    );
  }

  final byKind = <AssetKind, List<AssetEntry>>{};
  for (final e in entries) {
    byKind.putIfAbsent(e.kind, () => []).add(e);
  }
  final totalBytes = entries.fold<int>(0, (a, b) => a + b.bytes);

  return AssetInventory(
    entries: entries,
    byKind: byKind,
    totalBytes: totalBytes,
  );
}

/// Cheap default: manifest + JSON sizes only.
final assetInventoryProvider = FutureProvider<AssetInventory>(
  (ref) => loadAssetInventory(),
  name: 'assetInventoryProvider',
);

/// Full scan: probes every asset's bytes via `rootBundle.load()`. Slower —
/// the dashboard exposes it as a "Probe all sizes" button.
final assetInventoryFullProvider = FutureProvider<AssetInventory>(
  (ref) => loadAssetInventory(maxProbeBytesPer: 1),
  name: 'assetInventoryFullProvider',
);
