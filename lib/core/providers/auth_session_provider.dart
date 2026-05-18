import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

/// A flat, UI-facing view of the current auth session. Screens watch this
/// instead of touching Supabase directly.
class AuthSession {
  const AuthSession({this.signedIn = false, this.email});

  final bool signedIn;
  final String? email;

  static const guest = AuthSession();
}

/// Reactive auth session. Emits the current state immediately and again on
/// every sign-in / sign-out. When the backend SDK is not initialised
/// ([supabaseReady] false) it emits a single guest session — so the app,
/// and widget tests that pump it without `main()`, behave correctly.
final authSessionProvider = StreamProvider<AuthSession>((ref) {
  if (!supabaseReady) {
    return Stream<AuthSession>.value(AuthSession.guest);
  }
  final client = Supabase.instance.client;

  AuthSession current() {
    final user = client.auth.currentUser;
    return user == null
        ? AuthSession.guest
        : AuthSession(signedIn: true, email: user.email);
  }

  // Yield the current state immediately, then re-derive on every auth
  // event. The leading yield guarantees a synchronous first value.
  Stream<AuthSession> stream() async* {
    yield current();
    yield* client.auth.onAuthStateChange.map((_) => current());
  }

  return stream();
});

/// Convenience: true when a parent is signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider).value?.signedIn ?? false;
});
