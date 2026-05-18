import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-question hint state — tracks which question IDs have had a hint
/// revealed in the current session. Quiz screens can check this to (a)
/// strike out one wrong option, (b) halve the coin reward when grading.
///
/// State is intentionally session-scoped, not persisted.
class HintState {
  const HintState({this.usedFor = const <String>{}});
  final Set<String> usedFor;

  bool wasUsed(String questionId) => usedFor.contains(questionId);

  HintState copyWith({Set<String>? usedFor}) =>
      HintState(usedFor: usedFor ?? this.usedFor);
}

final hintProvider = NotifierProvider<HintNotifier, HintState>(
  HintNotifier.new,
  name: 'hintProvider',
);

class HintNotifier extends Notifier<HintState> {
  @override
  HintState build() => const HintState();

  void use(String questionId) {
    if (state.usedFor.contains(questionId)) return;
    state = state.copyWith(usedFor: {...state.usedFor, questionId});
  }

  void resetSession() {
    state = const HintState();
  }
}
