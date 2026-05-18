/// Centralized prophet honorifics — apply consistently across all quiz
/// content and UI strings.
///
/// Pattern:
///   honorific('Muhammad') → 'ﷺ'
///   honorific('Adam') → 'عليه السلام'
///   honorificFor(['Adam','Hud','Saleh']) → 'عليهم السلام'
///
/// Used by content authors when assembling fun-fact strings, and by UI
/// widgets that compose prophet names dynamically.
const String _ms = 'ﷺ';
const String _alayhi = 'عليه السلام';
const String _alayhim = 'عليهم السلام';

const Set<String> _muhammadAliases = {
  'Muhammad',
  'Mohammed',
  'Muhammed',
  'محمد',
  'مُحَمَّد',
};

String arabicHonorific(String prophetName) {
  if (_muhammadAliases.contains(prophetName.trim())) return _ms;
  return _alayhi;
}

String arabicHonorificMany() => _alayhim;

/// Apply the right honorific to a single prophet name, returning
/// `name + " " + honorific` — handy when composing one-off lines.
String withHonorific(String prophetName) =>
    '$prophetName ${arabicHonorific(prophetName)}';

/// Standardized Quran citation template:
///   quranCitation(name: 'Al-Fil', number: 105, ayah: 1, arabic: false)
///     → 'Surah Al-Fil (105) — Ayah 1'
///   arabic=true uses Arabic-Indic digits and the Arabic name pattern.
String quranCitation({
  required String name,
  required int number,
  int? ayah,
  required bool arabic,
}) {
  String digits(int n) {
    if (!arabic) return n.toString();
    const m = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => m[int.parse(c)]).join();
  }

  if (arabic) {
    final base = 'سورة $name (${digits(number)})';
    return ayah == null ? base : '$base — آية ${digits(ayah)}';
  }
  final base = 'Surah $name ($number)';
  return ayah == null ? base : '$base — Ayah $ayah';
}
