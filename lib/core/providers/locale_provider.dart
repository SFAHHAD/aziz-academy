import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Locale provider — persisted EN ↔ AR toggle
// =============================================================================

const _kLocaleKey = 'app_locale';

/// Provides the current app locale. Defaults to Arabic.
/// Toggle with [LocaleNotifier.toggle].
final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
  name: 'localeProvider',
);

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved == 'en') return const Locale('en');
    return const Locale('ar'); // default: Arabic
  }

  Future<void> toggle() async {
    final current = state.value ?? const Locale('ar');
    final next =
        current.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, next.languageCode);
  }

  bool get isArabic => state.value?.languageCode == 'ar';
}
