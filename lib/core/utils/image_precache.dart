import 'package:flutter/material.dart';

/// Hot images that should be ready before the user lands on home.
/// Called from the splash "I'm ready" tap so the user gesture provides
/// the latency budget for the warmup. Failures are silent — missing
/// assets just fall back to lazy load.
const _hotImagePaths = <String>['assets/images/logo_final.png'];

Future<void> precacheHotImages(BuildContext context) async {
  for (final path in _hotImagePaths) {
    try {
      await precacheImage(AssetImage(path), context);
    } catch (_) {
      /* asset missing — silent fallback */
    }
  }
}
