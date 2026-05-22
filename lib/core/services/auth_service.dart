import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

// =============================================================================
// Which sign-in providers the UI is allowed to OFFER.
//
// On Flutter web, signInWithOAuth performs a full redirect to Supabase's
// authorize endpoint. If the provider isn't enabled on the Supabase dashboard,
// the user lands on a raw JSON 400 page
// (`"Unsupported provider: provider is not enabled"`) — there is no exception
// to catch, so the only clean fix is to NOT show the button until the backend
// is configured.
//
// Flip a flag to `true` only AFTER enabling that provider in
// Supabase → Authentication → Providers, then rebuild + redeploy.
// Email always works out of the box; phone needs an SMS provider configured.
// =============================================================================
class AuthProviders {
  const AuthProviders._();

  /// Google OAuth — enable in Supabase, add Google Cloud OAuth client, then
  /// set this to true.
  static const bool google = false;

  /// Apple OAuth — needs an Apple Developer Services ID + key first.
  static const bool apple = false;

  /// Phone / SMS OTP — needs a Supabase SMS provider (e.g. Twilio) configured.
  static const bool phone = false;

  /// Email + password works with no extra setup.
  static const bool email = true;
}

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

  // ---------------------------------------------------------------------------
  // OAuth — Google, Apple
  //
  // Both rely on the Supabase project having the matching provider enabled in
  // Authentication → Providers. Google needs an OAuth client ID/secret from
  // Google Cloud Console; Apple needs a Sign-in-with-Apple service id + key.
  // The redirect URL Supabase generates must be allow-listed in each provider.
  //
  // On web: opens the provider in a new tab / redirect; flutter web returns to
  // the app once the OAuth round-trip completes via the same-origin callback.
  // On mobile: launches the system browser and returns via the configured deep
  // link scheme (see android/app/src/main/AndroidManifest.xml +
  // ios/Runner/Info.plist for the scheme registration).
  // ---------------------------------------------------------------------------

  Future<AuthResult> signInWithGoogle({String? redirectTo}) async {
    if (!supabaseReady) return const AuthResult.fail('backend_unavailable');
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.fail('oauth_failed');
    }
  }

  Future<AuthResult> signInWithApple({String? redirectTo}) async {
    if (!supabaseReady) return const AuthResult.fail('backend_unavailable');
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectTo,
      );
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.fail('oauth_failed');
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP
  //
  // [signInWithPhoneStart] sends an SMS containing a one-time code. The UI
  // then collects the code and calls [signInWithPhoneVerify] to complete the
  // sign-in. Supabase project must have a phone provider configured (Twilio,
  // MessageBird, Vonage). Phone numbers must include the country code (+965…).
  // ---------------------------------------------------------------------------

  Future<AuthResult> signInWithPhoneStart(String phoneE164) async {
    if (!supabaseReady) return const AuthResult.fail('backend_unavailable');
    try {
      await _client.auth.signInWithOtp(phone: phoneE164.trim());
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.fail('phone_send_failed');
    }
  }

  Future<AuthResult> signInWithPhoneVerify({
    required String phoneE164,
    required String otpCode,
  }) async {
    if (!supabaseReady) return const AuthResult.fail('backend_unavailable');
    try {
      await _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneE164.trim(),
        token: otpCode.trim(),
      );
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.fail('phone_verify_failed');
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


/// Cheap E.164 phone check (+ followed by 8–15 digits). Replace with a proper
/// libphonenumber check before launch in markets where users mistype freely.
bool isValidPhoneE164(String phone) {
  return RegExp(r'^\+\d{8,15}\$').hasMatch(phone.trim());
}
