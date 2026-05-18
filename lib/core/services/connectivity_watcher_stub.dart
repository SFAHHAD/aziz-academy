import 'package:flutter/foundation.dart';

/// Non-web stub — there's no browser online/offline state to listen to, and
/// the app currently only ships to web, so default to "always online" so the
/// banner never accidentally shows in tests or on hypothetical mobile.
void attach(ValueNotifier<bool> online) {
  // intentional no-op
}
