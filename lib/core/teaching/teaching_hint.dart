/// Bilingual mini-lesson surface for "you picked wrong, here's why"
/// teaching moments. A pure data class with an Arabic + English line
/// so the engine layer stays free of widget/locale concerns.
///
/// Used by Number Bonds, Place Value, and Skip Counting — any quiz
/// where a kid picks a wrong option deserves a tiny explanation
/// instead of just a red shake.
class TeachingHint {
  const TeachingHint({required this.en, required this.ar});

  final String en;
  final String ar;

  String forLocale({required bool arabic}) => arabic ? ar : en;
}
