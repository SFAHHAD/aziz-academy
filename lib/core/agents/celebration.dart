/// C4 — Celebration agent. Decides which celebration tier to fire and caps
/// celebrations per session to avoid alert fatigue.
class CelebrationTier {
  const CelebrationTier(this.name, this.intensity);
  final String name;
  // 0 = silent, 1 = subtle, 2 = confetti emoji, 3 = full animated badge.
  final int intensity;
}

class CelebrationAgent {
  CelebrationAgent();

  int _firedThisSession = 0;
  static const int _capPerSession = 3;

  void resetSession() => _firedThisSession = 0;

  /// Returns null when we should *not* celebrate (cap reached or trivial win).
  CelebrationTier? maybeCelebrate({
    required int correctStreak,
    required bool perfectScore,
    required bool newPersonalBest,
  }) {
    if (_firedThisSession >= _capPerSession) return null;

    if (newPersonalBest) {
      _firedThisSession += 1;
      return const CelebrationTier('personal_best', 3);
    }
    if (perfectScore) {
      _firedThisSession += 1;
      return const CelebrationTier('perfect', 3);
    }
    if (correctStreak == 5) {
      _firedThisSession += 1;
      return const CelebrationTier('streak_5', 2);
    }
    if (correctStreak == 10) {
      _firedThisSession += 1;
      return const CelebrationTier('streak_10', 3);
    }
    return null;
  }
}
