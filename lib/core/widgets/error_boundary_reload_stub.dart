// Non-web stub. The web counterpart in error_boundary_reload_web.dart
// performs window.location.reload(). On native platforms we have no
// browser to reload, so this is a no-op — the bilingual error card on
// native simply hides the Reload button (kIsWeb guard).
void reloadApp() {}
