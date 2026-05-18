import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Typed in-app event bus. Every learning interaction emits an event here.
/// All agents (adaptive difficulty, tutor, encouragement, parent dashboard...)
/// listen to this stream rather than coupling to specific quiz screens.
///
/// Privacy: events live in memory + a rolling on-device persisted log via the
/// learner state store. Nothing leaves the device.
@immutable
class LearningEvent {
  const LearningEvent({
    required this.type,
    required this.module,
    required this.timestamp,
    this.questionId,
    this.category,
    this.correct,
    this.latencyMs,
    this.hintsUsed = 0,
    this.difficulty,
    this.score,
    this.streak,
    this.extra = const <String, Object?>{},
  });

  final LearningEventType type;
  final String module; // 'capitals' | 'flags' | 'sciences' | ...
  final DateTime timestamp;
  final String? questionId;
  final String? category;
  final bool? correct;
  final int? latencyMs;
  final int hintsUsed;
  final int? difficulty;
  final int? score;
  final int? streak;
  final Map<String, Object?> extra;
}

enum LearningEventType {
  sessionStarted,
  sessionEnded,
  questionStarted,
  questionAnswered,
  hintUsed,
  lifelineUsed,
  rageQuit,
  idleTimeout,
}

/// Singleton-ish broadcast stream — late-init at first use.
class EventBus {
  EventBus._();
  static final EventBus instance = EventBus._();

  final StreamController<LearningEvent> _ctrl =
      StreamController<LearningEvent>.broadcast();

  Stream<LearningEvent> get stream => _ctrl.stream;

  void emit(LearningEvent event) {
    if (_ctrl.isClosed) return;
    _ctrl.add(event);
  }
}

/// Convenience Riverpod handle so widgets/providers can fire events.
final eventBusProvider = Provider<EventBus>((ref) => EventBus.instance);

/// Streams the bus through Riverpod (for agents that listen reactively).
final learningEventStreamProvider = StreamProvider<LearningEvent>((ref) {
  return ref.watch(eventBusProvider).stream;
});
