import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Feedback inbox
//
// Local-first: every submission from the in-app feedback form is appended to
// `admin_feedback_inbox_v1` in SharedPreferences. The admin dashboard reads
// from this list, lets the operator mark items resolved/archived, filter, and
// export the whole inbox as JSON.
//
// Because the app has no backend, "received feedback" only includes anything
// submitted on this device. For a multi-device pipeline, route the same
// payload through Formspree / a Vercel function and read back from there.
// =============================================================================

const _kInboxKey = 'admin_feedback_inbox_v1';

enum FeedbackKind { bug, idea, question, praise, other }

extension FeedbackKindX on FeedbackKind {
  String get label {
    switch (this) {
      case FeedbackKind.bug:
        return 'Bug';
      case FeedbackKind.idea:
        return 'Idea';
      case FeedbackKind.question:
        return 'Question';
      case FeedbackKind.praise:
        return 'Praise';
      case FeedbackKind.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FeedbackKind.bug:
        return '🐞';
      case FeedbackKind.idea:
        return '💡';
      case FeedbackKind.question:
        return '❓';
      case FeedbackKind.praise:
        return '🎉';
      case FeedbackKind.other:
        return '📨';
    }
  }

  static FeedbackKind fromName(String? n) {
    if (n == null) return FeedbackKind.other;
    for (final k in FeedbackKind.values) {
      if (k.name == n) return k;
    }
    return FeedbackKind.other;
  }
}

enum FeedbackStatus { open, resolved, archived }

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.status,
    required this.from,
    required this.message,
    required this.contact,
    required this.context,
  });

  final String id;
  final DateTime at;
  final FeedbackKind kind;
  final FeedbackStatus status;

  /// Free-form name the submitter typed. Optional.
  final String from;

  /// The actual message body.
  final String message;

  /// Optional email or phone the submitter left for follow-up.
  final String contact;

  /// Path / route the user was on when they submitted. Useful for triage.
  final String context;

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'kind': kind.name,
    'status': status.name,
    'from': from,
    'message': message,
    'contact': contact,
    'context': context,
  };

  factory FeedbackEntry.fromJson(Map<String, dynamic> m) => FeedbackEntry(
    id: m['id'] as String,
    at: DateTime.parse(m['at'] as String),
    kind: FeedbackKindX.fromName(m['kind'] as String?),
    status: _statusFrom(m['status'] as String?),
    from: (m['from'] as String?) ?? '',
    message: (m['message'] as String?) ?? '',
    contact: (m['contact'] as String?) ?? '',
    context: (m['context'] as String?) ?? '',
  );

  FeedbackEntry copyWith({FeedbackStatus? status}) => FeedbackEntry(
    id: id,
    at: at,
    kind: kind,
    status: status ?? this.status,
    from: from,
    message: message,
    contact: contact,
    context: context,
  );
}

FeedbackStatus _statusFrom(String? n) {
  if (n == null) return FeedbackStatus.open;
  for (final s in FeedbackStatus.values) {
    if (s.name == n) return s;
  }
  return FeedbackStatus.open;
}

class FeedbackInboxNotifier extends AsyncNotifier<List<FeedbackEntry>> {
  SharedPreferences? _prefs;

  @override
  Future<List<FeedbackEntry>> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _read();
  }

  List<FeedbackEntry> _read() {
    final raw = _prefs!.getString(_kInboxKey);
    if (raw == null) return <FeedbackEntry>[];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(FeedbackEntry.fromJson).toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    } catch (_) {
      return <FeedbackEntry>[];
    }
  }

  Future<void> _write(List<FeedbackEntry> list) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _kInboxKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(list);
  }

  Future<void> submit({
    required FeedbackKind kind,
    required String message,
    String from = '',
    String contact = '',
    String context = '',
  }) async {
    final entry = FeedbackEntry(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      at: DateTime.now(),
      kind: kind,
      status: FeedbackStatus.open,
      from: from.trim(),
      message: message.trim(),
      contact: contact.trim(),
      context: context,
    );
    final list = _read()..insert(0, entry);
    await _write(list);
  }

  Future<void> setStatus(String id, FeedbackStatus status) async {
    final list = _read()
        .map((e) => e.id == id ? e.copyWith(status: status) : e)
        .toList();
    await _write(list);
  }

  Future<void> remove(String id) async {
    final list = _read().where((e) => e.id != id).toList();
    await _write(list);
  }

  Future<void> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_kInboxKey);
    state = const AsyncData([]);
  }

  String exportJson() {
    final list = _read().map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}

final feedbackInboxProvider =
    AsyncNotifierProvider<FeedbackInboxNotifier, List<FeedbackEntry>>(
      FeedbackInboxNotifier.new,
    );
