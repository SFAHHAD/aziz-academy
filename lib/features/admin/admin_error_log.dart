import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight in-process error capture for the admin console.
///
/// Wired in from `main()` via [AdminErrorLog.install]. Holds the last 200
/// errors in memory and persists the most recent 50 to SharedPreferences so
/// the operator can review crashes that happened in previous sessions —
/// useful when a kid bounces from the app right after an exception fires.
///
/// Nothing leaves the device. Replaces the "errors vanish into the dev
/// console" hole without bringing in a third-party SDK.
class AdminErrorLog {
  AdminErrorLog._();

  static const _capacity = 200;
  static const _persistCapacity = 50;
  static const _kStoreKey = 'admin_error_log_v1';

  static final List<AdminLogEntry> _entries = <AdminLogEntry>[];
  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  static List<AdminLogEntry> get entries => List.unmodifiable(_entries);
  static ValueListenable<int> get revision => _revision;

  /// Set Flutter + zone error handlers to feed this log. Idempotent.
  static bool _installed = false;
  static void install() {
    if (_installed) return;
    _installed = true;
    // Rehydrate persisted log first so cross-session errors are visible.
    _restore();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      add(
        AdminLogEntry(
          at: DateTime.now(),
          severity: AdminLogSeverity.error,
          source: 'flutter',
          message: details.exceptionAsString(),
          stack: details.stack?.toString() ?? '',
          library: details.library ?? '',
        ),
      );
      previous?.call(details);
    };
    // Catch uncaught async errors (futures that throw with no .catchError,
    // platform-channel failures, callbacks that bubble up to the engine).
    // These don't go through FlutterError.onError, so without this hook
    // they would silently fall on the floor in release.
    final previousAsync = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      add(
        AdminLogEntry(
          at: DateTime.now(),
          severity: AdminLogSeverity.error,
          source: 'async',
          message: error.toString(),
          stack: stack.toString(),
          library: '',
        ),
      );
      // Returning true tells the engine the error was handled; false means
      // continue to the default handler. We delegate to the previous hook
      // if one was set, otherwise return true to swallow (we've logged).
      return previousAsync?.call(error, stack) ?? true;
    };
  }

  static Future<void> _restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kStoreKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      // Restore newest-first ordering — matches in-memory insertion order.
      final restored = list.map(AdminLogEntry.fromJson).toList();
      _entries
        ..clear()
        ..addAll(restored);
      _revision.value = _revision.value + 1;
    } catch (_) {
      // Corrupt storage shouldn't block startup. Wipe + ignore.
      try {
        final p = await SharedPreferences.getInstance();
        await p.remove(_kStoreKey);
      } catch (_) {}
    }
  }

  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = _entries
          .take(_persistCapacity)
          .map((e) => e.toJson())
          .toList();
      await p.setString(_kStoreKey, jsonEncode(list));
    } catch (_) {
      // Best-effort. We never want logging to crash the app.
    }
  }

  static void add(AdminLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > _capacity) {
      _entries.removeRange(_capacity, _entries.length);
    }
    _revision.value = _revision.value + 1;
    // Fire-and-forget; persistence isn't on the hot path.
    _persist();
  }

  /// Convenience for non-Flutter call sites (e.g. async network/IO).
  static void warn(String message, {String source = 'app', Object? error}) {
    add(
      AdminLogEntry(
        at: DateTime.now(),
        severity: AdminLogSeverity.warning,
        source: source,
        message: message,
        stack: error?.toString() ?? '',
        library: '',
      ),
    );
  }

  static void info(String message, {String source = 'app'}) {
    add(
      AdminLogEntry(
        at: DateTime.now(),
        severity: AdminLogSeverity.info,
        source: source,
        message: message,
        stack: '',
        library: '',
      ),
    );
  }

  static Future<void> clear() async {
    _entries.clear();
    _revision.value = _revision.value + 1;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kStoreKey);
    } catch (_) {}
  }
}

enum AdminLogSeverity { info, warning, error }

class AdminLogEntry {
  const AdminLogEntry({
    required this.at,
    required this.severity,
    required this.source,
    required this.message,
    required this.stack,
    required this.library,
  });

  final DateTime at;
  final AdminLogSeverity severity;
  final String source;
  final String message;
  final String stack;
  final String library;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'sev': severity.name,
    'src': source,
    'msg': message,
    'stk': stack,
    'lib': library,
  };

  static AdminLogEntry fromJson(Map<String, dynamic> m) => AdminLogEntry(
    at: DateTime.tryParse(m['at'] as String? ?? '') ?? DateTime.now(),
    severity: _sevFromName(m['sev'] as String?),
    source: (m['src'] as String?) ?? '',
    message: (m['msg'] as String?) ?? '',
    stack: (m['stk'] as String?) ?? '',
    library: (m['lib'] as String?) ?? '',
  );

  static AdminLogSeverity _sevFromName(String? n) {
    if (n == null) return AdminLogSeverity.info;
    for (final s in AdminLogSeverity.values) {
      if (s.name == n) return s;
    }
    return AdminLogSeverity.info;
  }
}
