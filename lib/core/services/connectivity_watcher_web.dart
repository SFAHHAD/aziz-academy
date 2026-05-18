// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html show window;

import 'package:flutter/foundation.dart';

void attach(ValueNotifier<bool> online) {
  try {
    online.value = html.window.navigator.onLine ?? true;
    html.window.onOnline.listen((_) => online.value = true);
    html.window.onOffline.listen((_) => online.value = false);
  } catch (_) {
    // Some embeddings (older Safari, restricted iframes) don't expose the
    // API. Default to "online" so the banner never wedges itself shut.
  }
}
