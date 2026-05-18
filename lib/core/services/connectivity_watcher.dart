import 'package:flutter/foundation.dart';

import 'connectivity_watcher_stub.dart'
    if (dart.library.html) 'connectivity_watcher_web.dart'
    as impl;

/// Web-only connectivity probe.
///
/// Uses the browser's `navigator.onLine` + `online`/`offline` events so the
/// UI can show a banner when the kid loses connectivity (audio playback,
/// font fetches, future map tiles all break silently otherwise). On non-web
/// platforms `online` is always true — we don't ship to mobile yet, and the
/// connectivity_plus dance is heavier than the value at this stage.
class ConnectivityWatcher {
  ConnectivityWatcher._() {
    impl.attach(online);
  }

  static final instance = ConnectivityWatcher._();

  final ValueNotifier<bool> online = ValueNotifier(true);
}
