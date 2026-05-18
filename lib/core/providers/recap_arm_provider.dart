import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';

/// One-shot payload for the next quiz session (cleared after use).
class RecapArm {
  const RecapArm({required this.entries});

  final List<RecapEntry> entries;

  RecapModule get module => entries.first.module;

  List<String> get ids => entries.map((e) => e.questionId).toList();
}

final recapArmProvider =
    NotifierProvider<RecapArmNotifier, RecapArm?>(RecapArmNotifier.new);

class RecapArmNotifier extends Notifier<RecapArm?> {
  @override
  RecapArm? build() => null;

  void arm(RecapArm payload) => state = payload;

  void clear() => state = null;
}
