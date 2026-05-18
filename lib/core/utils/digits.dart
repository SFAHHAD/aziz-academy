import 'package:flutter/widgets.dart';

const Map<String, String> _arabicDigits = {
  '0': '٠',
  '1': '١',
  '2': '٢',
  '3': '٣',
  '4': '٤',
  '5': '٥',
  '6': '٦',
  '7': '٧',
  '8': '٨',
  '9': '٩',
};

String _toArabicDigits(String s) {
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(_arabicDigits[ch] ?? ch);
  }
  return buf.toString();
}

/// Returns the input number/string with Arabic-Indic digits when [arabic] is
/// true, or unchanged Latin digits otherwise. Handles both raw ints and
/// pre-formatted strings (so `localizeDigits('12 / 30 صحيح', arabic: true)`
/// becomes `'١٢ / ٣٠ صحيح'`).
String localizeDigits(Object value, {required bool arabic}) {
  final s = value.toString();
  return arabic ? _toArabicDigits(s) : s;
}

/// Convenience reading the locale from the build context — use in widgets
/// where you don't already have an `isArabic` flag.
String localizeDigitsCtx(Object value, BuildContext context) {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  return localizeDigits(value, arabic: isAr);
}
