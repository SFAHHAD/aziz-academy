import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/auth_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/features/account/presentation/multi_provider_auth_sheet.dart';

// =============================================================================
// Welcome / register screen v2
//
// Replaces the legacy welcome flow. Hero illustration on top, brand title,
// then three prominent CTAs (Continue with Google / Apple / Phone) plus an
// email path and a "continue as guest" link.
//
// No parental gate before signup — adult provider auth IS the consent
// (per docs/AUTH_AND_GATE.md).
//
// Wires to AuthService methods scaffolded in lib/core/services/auth_service.dart.
// =============================================================================

class WelcomeScreenV2 extends ConsumerWidget {
  const WelcomeScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 720;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Hero illustration — use the existing splash character.
                      Center(
                        child: Container(
                          width: wide ? 220 : 180,
                          height: wide ? 220 : 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.30),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/aziz_character.png',
                              width: wide ? 180 : 144,
                              height: wide ? 180 : 144,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.account_circle,
                                size: wide ? 180 : 144,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isAr ? 'أكاديمية عزيز' : 'Aziz Academy',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr
                            ? 'تعلَّم، العب، اكتشف — معاً.'
                            : 'Learn, play, discover — together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Primary CTAs
                      _ProviderButton(
                        label: isAr
                            ? 'المتابعة باستخدام Google'
                            : 'Continue with Google',
                        icon: Icons.g_translate,
                        bg: Colors.white,
                        fg: const Color(0xFF1F1F1F),
                        onTap: () => _signInWith(
                          context, ref,
                          (s) => s.signInWithGoogle(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProviderButton(
                        label: isAr
                            ? 'المتابعة باستخدام Apple'
                            : 'Continue with Apple',
                        icon: Icons.apple,
                        bg: Colors.black,
                        fg: Colors.white,
                        onTap: () => _signInWith(
                          context, ref,
                          (s) => s.signInWithApple(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProviderButton(
                        label:
                            isAr ? 'المتابعة بالهاتف' : 'Continue with Phone',
                        icon: Icons.phone_iphone,
                        bg: AppColors.primary,
                        fg: Colors.white,
                        onTap: () => MultiProviderAuthSheet.show(context),
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.16))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            isAr ? 'أو' : 'or',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55)),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.16))),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                MultiProviderAuthSheet.show(context),
                            icon: const Icon(Icons.alternate_email, size: 18),
                            label: Text(isAr
                                ? 'البريد الإلكتروني'
                                : 'Use email'),
                          ),
                          TextButton.icon(
                            onPressed: () => _continueAsGuest(context),
                            icon: const Icon(Icons.bedtime_outlined, size: 18),
                            label: Text(isAr
                                ? 'المتابعة كزائر'
                                : 'Continue as guest'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          isAr
                              ? 'بالمتابعة، أنت توافق على سياسة الخصوصية وشروط الاستخدام.'
                              : 'By continuing, you agree to our Privacy Policy and Terms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _signInWith(BuildContext context, WidgetRef ref,
      Future<AuthResult> Function(AuthService) op) async {
    final res = await op(ref.read(authServiceProvider));
    if (!context.mounted) return;
    if (res.success) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sign-in failed — try a different method.'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  void _continueAsGuest(BuildContext context) {
    context.go(AppRoutes.home);
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 22),
        label: Text(label),
      ),
    );
  }
}
