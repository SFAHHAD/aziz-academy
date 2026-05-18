import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Locale provider — persisted language selection.
// =============================================================================

const _kLocaleKey = 'app_locale';

/// The full set of locales the app currently supports. Add a new entry here
/// (and corresponding `lib/l10n/app_<code>.arb`) to onboard a new language.
const List<Locale> kSupportedLocales = [Locale('ar'), Locale('en')];

const Locale _kDefaultLocale = Locale('ar');

bool _isSupported(String code) =>
    kSupportedLocales.any((l) => l.languageCode == code);

/// Provides the current app locale. Defaults to Arabic.
/// Mutate with [LocaleNotifier.setLocale] (or the legacy [toggle]).
final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
  name: 'localeProvider',
);

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null && _isSupported(saved)) return Locale(saved);
    return _kDefaultLocale;
  }

  /// Switches to [code] if it's a supported locale; no-op otherwise.
  Future<void> setLocale(String code) async {
    if (!_isSupported(code)) return;
    final current = state.value;
    if (current?.languageCode == code) return;
    state = AsyncData(Locale(code));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, code);
  }

  /// Cycles to the next supported locale in [kSupportedLocales]. Kept for the
  /// existing top-bar pill which only swaps EN ↔ AR today.
  Future<void> toggle() async {
    final current = state.value ?? _kDefaultLocale;
    final idx = kSupportedLocales.indexWhere(
      (l) => l.languageCode == current.languageCode,
    );
    final next = kSupportedLocales[(idx + 1) % kSupportedLocales.length];
    await setLocale(next.languageCode);
  }

  bool get isArabic => state.value?.languageCode == 'ar';
}
