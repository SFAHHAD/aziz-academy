import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/services/auth_service.dart';
import 'package:aziz_academy/core/services/sync_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/parental_gate.dart';

/// Opens the parent email sign-up / sign-in flow.
///
/// This is the single registration entry point — used by both the Account
/// screen and onboarding, so the flow is identical wherever a parent
/// reaches it. It always runs the parental gate first (account creation
/// is a grown-up action), then shows the email sheet.
Future<void> showEmailAuthSheet(
  BuildContext context, {
  required bool arabic,
}) async {
  final passed = await showParentalGate(context, arabic: arabic);
  if (!passed || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    builder: (_) => _EmailAuthSheet(isArabic: arabic),
  );
}

class _EmailAuthSheet extends ConsumerStatefulWidget {
  const _EmailAuthSheet({required this.isArabic});

  final bool isArabic;

  @override
  ConsumerState<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends ConsumerState<_EmailAuthSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUpMode = true;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _msg(String key) {
    final ar = widget.isArabic;
    switch (key) {
      case 'backend_unavailable':
        return ar
            ? 'الخدمة غير متاحة حالياً. حاول لاحقاً.'
            : 'Service unavailable right now. Try again later.';
      case 'email_in_use':
        return ar
            ? 'هذا البريد مسجّل بالفعل — سجّل الدخول بدلاً من ذلك.'
            : 'This email already has an account — sign in instead.';
      case 'bad_credentials':
        return ar
            ? 'البريد أو كلمة المرور غير صحيحة.'
            : 'Wrong email or password.';
      case 'weak_password':
        return ar
            ? 'كلمة المرور قصيرة (٨ أحرف على الأقل).'
            : 'Password is too short (8+ characters).';
      case 'bad_email':
        return ar ? 'تحقّق من صيغة البريد.' : 'Check the email address.';
      default:
        return ar
            ? 'حدث خطأ ما. حاول مرة أخرى.'
            : 'Something went wrong. Try again.';
    }
  }

  Future<void> _submit() async {
    final ar = widget.isArabic;
    final email = _email.text.trim();
    final pw = _password.text;
    setState(() {
      _error = null;
      _notice = null;
    });
    if (!isValidEmail(email)) {
      setState(() => _error = _msg('bad_email'));
      return;
    }
    if (!isAcceptablePassword(pw)) {
      setState(() => _error = _msg('weak_password'));
      return;
    }

    setState(() => _busy = true);
    final auth = ref.read(authServiceProvider);
    final result = _signUpMode
        ? await auth.signUpWithEmail(email: email, password: pw)
        : await auth.signInWithEmail(email: email, password: pw);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      setState(() => _error = _msg(result.messageKey ?? 'unknown'));
      return;
    }
    if (result.needsConfirmation) {
      // Sign-up accepted but a confirmation email must be opened first.
      setState(() {
        _notice = ar
            ? 'أرسلنا رسالة تأكيد إلى بريدك. افتحها ثم سجّل الدخول.'
            : 'We sent a confirmation email. Open it, then sign in.';
        _signUpMode = false;
      });
      return;
    }
    // Live session. Seed the cloud from this device only if the account
    // has no backup yet — safe, never overwrites another device.
    unawaited(ref.read(syncServiceProvider).seedIfEmpty());
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ar ? 'تم تسجيل الدخول ✓' : 'Signed in ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _signUpMode
                  ? (ar ? 'إنشاء حساب وليّ الأمر' : 'Create a parent account')
                  : (ar ? 'تسجيل الدخول' : 'Sign in'),
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: ar ? 'البريد الإلكتروني' : 'Email',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: ar ? 'كلمة المرور' : 'Password',
                helperText: ar ? '٨ أحرف على الأقل' : 'At least 8 characters',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (_notice != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(36),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _notice!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _signUpMode
                          ? (ar ? 'إنشاء الحساب' : 'Create account')
                          : (ar ? 'تسجيل الدخول' : 'Sign in'),
                    ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _signUpMode = !_signUpMode;
                      _error = null;
                      _notice = null;
                    }),
              child: Text(
                _signUpMode
                    ? (ar
                          ? 'لديّ حساب بالفعل — تسجيل الدخول'
                          : 'I already have an account — sign in')
                    : (ar
                          ? 'ليس لديّ حساب — إنشاء حساب'
                          : 'No account yet — create one'),
              ),
            ),
            Text(
              ar
                  ? 'بريدك يُستخدم للحساب فقط — لا إعلانات، لا تتبّع.'
                  : 'Your email is used only for the account — no ads, no tracking.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMedium,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
