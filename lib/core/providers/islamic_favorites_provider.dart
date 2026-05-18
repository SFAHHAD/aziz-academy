import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kinds of bookmarkable Islamic content. The kind is encoded in the
/// storage key so a single provider can host favorites for every screen.
enum IslamicFavKind {
  hadith,
  asma,
  prophet,
}

extension on IslamicFavKind {
  String get storageKey {
    switch (this) {
      case IslamicFavKind.hadith:
        return 'islamic_fav_hadith_v1';
      case IslamicFavKind.asma:
        return 'islamic_fav_asma_v1';
      case IslamicFavKind.prophet:
        return 'islamic_fav_prophet_v1';
    }
  }
}

/// Set of bookmarked item IDs for each Islamic content kind. Tap the heart
/// on a Hadith / Asma / Prophet card → ID is added; tap again → removed.
/// Persists to SharedPreferences per kind so favorites survive reloads.
///
/// Separated from `favoritesProvider` (which already exists for quiz IDs)
/// so the two domains can't accidentally collide on namespacing.
final islamicFavoritesProvider = AsyncNotifierProvider<
    IslamicFavoritesNotifier,
    Map<IslamicFavKind, Set<String>>>(
  IslamicFavoritesNotifier.new,
  name: 'islamicFavoritesProvider',
);

class IslamicFavoritesNotifier
    extends AsyncNotifier<Map<IslamicFavKind, Set<String>>> {
  SharedPreferences? _prefs;

  @override
  Future<Map<IslamicFavKind, Set<String>>> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    return {
      for (final k in IslamicFavKind.values) k: _decode(k),
    };
  }

  Set<String> _decode(IslamicFavKind kind) {
    final raw = _prefs!.getString(kind.storageKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _persist(IslamicFavKind kind, Set<String> ids) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(kind.storageKey, jsonEncode(ids.toList()));
  }

  bool isFavorite(IslamicFavKind kind, String id) {
    final s = state.value?[kind];
    return s != null && s.contains(id);
  }

  Future<void> toggle(IslamicFavKind kind, String id) async {
    final cur = state.value ?? <IslamicFavKind, Set<String>>{};
    final set = Set<String>.from(cur[kind] ?? const <String>{});
    if (!set.add(id)) {
      set.remove(id);
    }
    final next = Map<IslamicFavKind, Set<String>>.from(cur);
    next[kind] = set;
    state = AsyncData(next);
    await _persist(kind, set);
  }
}
