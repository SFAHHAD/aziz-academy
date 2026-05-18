import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which question IDs the kid has hearted. Stored on-device.
final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
  name: 'favoritesProvider',
);

const _kKey = 'favorites_v1';

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  SharedPreferences? _prefs;

  @override
  Future<Set<String>> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    return (_prefs!.getStringList(_kKey) ?? const <String>[]).toSet();
  }

  Future<void> toggle(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? <String>{};
    final next = Set<String>.from(cur);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = AsyncData(next);
    await _prefs!.setStringList(_kKey, next.toList());
  }

  bool isFavorite(String id) => (state.value ?? const <String>{}).contains(id);

  Future<void> clearAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    state = const AsyncData(<String>{});
    await _prefs!.remove(_kKey);
  }
}
