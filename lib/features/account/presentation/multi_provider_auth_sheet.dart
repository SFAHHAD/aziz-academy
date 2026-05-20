import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/services/auth_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';

// =============================================================================
// Multi-provider auth sheet
//
// Replaces the email-only auth path with a four-method picker:
//
//   ┌─────────────────────────────┐
//   │   Continue with Google      │  ← big primary
//   │   Continue with Apple       │
//   │   Continue with Phone       │
//   ├─────────────────────────────┤
//   │   Sign in with email        │  ← collapsed by default
//   └─────────────────────────────┘
//
// Per AUTH_AND_GATE.md the parental gate does NOT sit in front of signup any
// more. It moves to high-stakes ops (sign-in to an existing account, delete
// account, ads toggle). This sheet therefore offers signup paths directly.
//
// Each Continue-with-X button calls into the AuthService method scaffolded
// in lib/core/services/auth_service.dart. The Supabase providers must be
// enabled on the dashboard side — see docs/AUTH_AND_GATE.md for the
// one-time setup.
// =============================================================================

class MultiProviderAuthSheet extends ConsumerStatefulWidget {
  const MultiProviderAuthSheet({super.key});

  /// Convenience for callers:
  ///   showModalBottomSheet(
  ///     context: ctx,
  ///     isScrollControlled: true,
  ///     builder: (_) => const MultiProviderAuthSheet(),
  ///   );
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MultiProviderAuthSheet(),
    );
  }

  @override
  ConsumerState<MultiProviderAuthSheet> createState() =>
      _MultiProviderAuthSheetState();
}

enum _Mode { picker, email, phone }

class _MultiProviderAuthSheetState
    extends ConsumerState<MultiProviderAuthSheet> {
  _Mode _mode = _Mode.picker;
  bool _busy = false;
  String? _error;

  // Email form
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _emailIsSignup = false;

  // Phone form
  final _phone = TextEditingController(text: '+');
  final _otp = TextEditingController();
  bool _phoneOtpSent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _runAuth(Future<AuthResult> Function() op,
      {String? onConfirmEmailMessage}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await op();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success) {
      if (res.needsConfirmation) {
        setState(() => _error = onConfirmEmailMessage ??
            'Check your inbox to confirm the address.');
        return;
      }
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _error = _humanError(res.messageKey));
  }

  String _humanError(String? key) {
    switch (key) {
      case 'backend_unavailable':
        return 'The account service is offline right now. Try again in a moment.';
      case 'email_in_use':
        return 'That email already has an account. Use sign-in instead.';
      case 'bad_credentials':
        return 'Email or password is wrong.';
      case 'weak_password':
        return 'Password must be at least 8 characters.';
      case 'bad_email':
        return 'That doesn\'t look like a valid email.';
      case 'oauth_failed':
        return 'Couldn\'t complete the sign-in popup. Try again, or use email.';
      case 'phone_send_failed':
        return 'Couldn\'t send the code. Check the number and try again.';
      case 'phone_verify_failed':
        return 'That code didn\'t match. Try again or request a new one.';
      default:
        return 'Something went wrong. Try again, or use a different method.';
    }
  }

  // ---------------------------------------------------------------------------
  // Provider taps
  // ---------------------------------------------------------------------------

  Future<void> _onGoogle() async {
    final svc = ref.read(authServiceProvider);
    await _runAuth(() => svc.signInWithGoogle());
  }

  Future<void> _onApple() async {
    final svc = ref.read(authServiceProvider);
    await _runAuth(() => svc.signInWithApple());
  }

  Future<void> _onPhoneSend() async {
    final phone = _phone.text.trim();
    if (!isValidPhoneE164(phone)) {
      setState(() => _error = 'Enter your phone in international format, like +96550000000.');
      return;
    }
    final svc = ref.read(authServiceProvider);
    setState(() => _busy = true);
    final res = await svc.signInWithPhoneStart(phone);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = res.success ? null : _humanError(res.messageKey);
      if (res.success) _phoneOtpSent = true;
    });
  }

  Future<void> _onPhoneVerify() async {
    final svc = ref.read(authServiceProvider);
    await _runAuth(() => svc.signInWithPhoneVerify(
          phoneE164: _phone.text.trim(),
          otpCode: _otp.text.trim(),
        ));
  }

  Future<void> _onEmail() async {
    final email = _email.text.trim();
    final pw = _password.text;
    if (!isValidEmail(email)) {
      setState(() => _error = 'That doesn\'t look like a valid email.');
      return;
    }
    if (!isAcceptablePassword(pw)) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    final svc = ref.read(authServiceProvider);
    await _runAuth(
      () => _emailIsSignup
          ? svc.signUpWithEmail(email: email, password: pw)
          : svc.signInWithEmail(email: email, password: pw),
      onConfirmEmailMessage:
          'Check your inbox to confirm the email — then come back and sign in.',
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
        child: Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.background,
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (_mode == _Mode.picker) ..._buildPicker(context),
              if (_mode == _Mode.email) ..._buildEmail(context),
              if (_mode == _Mode.phone) ..._buildPhone(context),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.35)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPicker(BuildContext context) => [
        const Text(
          'Welcome — pick a sign-in method',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Parent accounts only. Your kids tap a profile — they don\'t sign in.',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 18),
        _BigButton(
          label: 'Continue with Google',
          icon: Icons.g_translate,
          color: const Color(0xFFFFFFFF),
          fg: const Color(0xFF1F1F1F),
          onTap: _busy ? null : _onGoogle,
        ),
        const SizedBox(height: 10),
        _BigButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          color: const Color(0xFF000000),
          fg: const Color(0xFFFFFFFF),
          onTap: _busy ? null : _onApple,
        ),
        const SizedBox(height: 10),
        _BigButton(
          label: 'Continue with Phone',
          icon: Icons.phone_iphone,
          color: const Color(0xFF1B2A6B),
          fg: const Color(0xFFFFFFFF),
          onTap: _busy ? null : () => setState(() => _mode = _Mode.phone),
        ),
        const SizedBox(height: 14),
        Row(children: const [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('or', style: TextStyle(color: Colors.white54)),
          ),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _busy ? null : () => setState(() => _mode = _Mode.email),
          icon: const Icon(Icons.alternate_email, size: 18),
          label: const Text('Use email and password'),
        ),
      ];

  List<Widget> _buildEmail(BuildContext context) => [
        Row(children: [
          IconButton(
            onPressed: _busy ? null : () => setState(() => _mode = _Mode.picker),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          Text(_emailIsSignup ? 'Create account' : 'Sign in',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _onEmail,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_emailIsSignup ? 'Create account' : 'Sign in'),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _emailIsSignup = !_emailIsSignup;
                    _error = null;
                  }),
          child: Text(_emailIsSignup
              ? 'Have an account? Sign in.'
              : 'New? Create an account.'),
        ),
      ];

  List<Widget> _buildPhone(BuildContext context) => [
        Row(children: [
          IconButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _mode = _Mode.picker;
                      _phoneOtpSent = false;
                    }),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          const Text('Continue with phone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        const Text(
          'Use the international format with country code, e.g. +96550000000.',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          enabled: !_phoneOtpSent,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
        if (_phoneOtpSent) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(labelText: 'Code from SMS'),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy
              ? null
              : (_phoneOtpSent ? _onPhoneVerify : _onPhoneSend),
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_phoneOtpSent ? 'Verify code' : 'Send code'),
        ),
        if (_phoneOtpSent)
          TextButton(
            onPressed:
                _busy ? null : () => setState(() => _phoneOtpSent = false),
            child: const Text('Change phone number'),
          ),
      ];
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
