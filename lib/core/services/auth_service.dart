import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

/// Result of an auth attempt — a flat, UI-friendly outcome so screens
/// never have to catch Supabase exceptions themselves.
class AuthResult {
  const AuthResult._({
    required this.success,
    this.messageKey,
    this.needsConfirmation = false,
  });

  /// Signed in — a session is live.
  const AuthResult.ok() : this._(success: true);

  /// Sign-up accepted, but the account must be confirmed via the email
  /// Supabase just sent before the parent can sign in.
  const AuthResult.confirmEmail() : this._(success: true, needsConfirmation: true);

  /// Failed — [messageKey] tells the UI which bilingual message to show.
  const AuthResult.fail(String messageKey)
    : this._(success: false, messageKey: messageKey);

  final bool success;

  /// A stable key the UI maps to a bilingual message. Null on success.
  final String? messageKey;

  /// True when sign-up needs email confirmation before sign-in works.
  final bool needsConfirmation;
}

/// Thin wrapper over Supabase Auth. Phase 1b ships **email** parent
/// accounts; the Apple / Google methods are stubbed pending the OAuth
/// credentials only the project owner can create (see ACCOUNTS_SETUP.md).
///
/// Every method is safe to call when [supabaseReady] is false — it simply
/// returns a `backend_unavailable` failure instead of throwing.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  bool get isAvailable => supabaseReady;

  User? get currentUser =>
      supabaseReady ? _client.auth.currentUser : null;

  bool get isSignedIn => currentUser != null;

  String? get email => currentUser?.email;

  /// Emits on every auth state change (sign-in, sign-out, token refresh).
  Stream<AuthState> get onAuthStateChange => supabaseReady
      ? _client.auth.onAuthStateChange
      : const Stream<AuthState>.empty();

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (!supabaseReady) return const AuthResult.fail('backend_unavailable');
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      // No session yet → Supabase requires email confirmation first.
      if (res.session == null && res.user != null) {
        return const AuthResult.confirmEmail();
      }
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.fail('unknown');
    }
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!supabaseReady) return const AuthResult.fail('backend_unavailable');
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.fail('unknown');
    }
  }

  Future<void> signOut() async {
    if (!supabaseReady) return;
    try {
      await _client.auth.signOut();
    } catch (_) {
      // A failed sign-out (already signed out, network) is non-fatal.
    }
  }

  /// Maps a Supabase [AuthException] to a stable UI message key.
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'email_in_use';
    }
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials')) {
      return 'bad_credentials';
    }
    if (msg.contains('password')) return 'weak_password';
    if (msg.contains('email')) return 'bad_email';
    return 'unknown';
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Basic email shape check — enough to catch typos before a round-trip.
bool isValidEmail(String email) {
  final e = email.trim();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
}

/// Minimum password rule, surfaced in the UI before submit.
bool isAcceptablePassword(String password) => password.length >= 8;
