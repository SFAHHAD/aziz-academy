import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] that no-ops on web/desktop and
/// silently swallows MissingPluginException on platforms where the
/// vibrator service isn't available. Quiz screens can call these without
/// guarding for platform.
class Haptics {
  const Haptics._();

  static Future<void> light() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      /* swallow */
    }
  }

  static Future<void> medium() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    if (kIsWeb) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
