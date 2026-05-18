import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the learner's coin balance — the in-game currency that powers
/// lifelines (50/50, Skip, Hint). Awarded for correct answers and quiz
/// completion; spent on lifeline activations.
///
/// All persistence is local via SharedPreferences. No accounts, no backend —
/// the app stays offline-first and kid-safe.
final coinProvider = AsyncNotifierProvider<CoinNotifier, int>(CoinNotifier.new);

const String _coinPrefsKey = 'coin_balance_v1';
const int _starterCoins = 30;

class CoinNotifier extends AsyncNotifier<int> {
  SharedPreferences? _prefs;

  @override
  Future<int> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (!_prefs!.containsKey(_coinPrefsKey)) {
      await _prefs!.setInt(_coinPrefsKey, _starterCoins);
      return _starterCoins;
    }
    return _prefs!.getInt(_coinPrefsKey) ?? _starterCoins;
  }

  Future<void> award(int coins) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (coins <= 0) return;
    final next = (state.value ?? 0) + coins;
    state = AsyncData(next);
    await _prefs!.setInt(_coinPrefsKey, next);
  }

  /// Spends coins if affordable; returns true on success, false otherwise.
  Future<bool> spend(int coins) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? 0;
    if (cur < coins) return false;
    final next = cur - coins;
    state = AsyncData(next);
    await _prefs!.setInt(_coinPrefsKey, next);
    return true;
  }

  /// Hard-reset to a fresh starter balance. Used by Reset Profile.
  Future<void> resetTo(int balance) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(balance);
    await _prefs!.setInt(_coinPrefsKey, balance);
  }
}

/// Cost table for each lifeline kind. Keep these tunable in one place.
class LifelineCost {
  static const int fiftyFifty = 10;
  static const int skip = 8;
  static const int hint = 5;
}
