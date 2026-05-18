/// Adaptive difficulty: orders [items] so the difficulty band closest to the
/// kid's [skill] (0..1 EMA) lands first, with other bands trailing by
/// skill-distance. Pure function — feed it any module's question list and a
/// [difficultyOf] extractor.
///
/// Skill bucketing matches the IQ provider for consistency:
///   skill < 0.4 → target difficulty 1 (easy)
///   skill < 0.7 → target 2 (medium)
///   else        → target 3 (hard)
List<T> adaptiveOrder<T>(
  List<T> items,
  double skill,
  int Function(T) difficultyOf,
) {
  final int target;
  if (skill < 0.4) {
    target = 1;
  } else if (skill < 0.7) {
    target = 2;
  } else {
    target = 3;
  }
  final ranked = [...items]
    ..sort(
      (a, b) => (difficultyOf(a) - target).abs().compareTo(
        (difficultyOf(b) - target).abs(),
      ),
    );
  return ranked;
}
