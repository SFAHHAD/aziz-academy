// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Hard-reload the page from the network. Used by the global error
/// boundary's "Reload" button when a widget build throws.
///
/// We use the no-arg form of `reload()` rather than the legacy
/// `reload(true)` (force reload) because modern browsers ignore the
/// argument and Vercel's must-revalidate headers + the SW killswitch
/// already guarantee a fresh bundle on every navigation.
void reloadApp() {
  html.window.location.reload();
}
