import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/account_provider.dart';
import 'package:aziz_academy/core/providers/auth_session_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/auth_service.dart';
import 'package:aziz_academy/core/services/sync_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/parental_gate.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/account/presentation/email_auth_sheet.dart';

/// Account hub.
///
/// Guest by default — no sign-up, fully playable. A **parent** can create
/// or sign in to an account (email today; Apple / Google once their OAuth
/// step in `ACCOUNTS_SETUP.md` is done) to back up and sync the kids'
/// progress. The child never signs in: account actions sit behind the
/// parental gate, keeping the app inside the App Store Kids Category rules.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final account = ref.watch(accountProvider).value;
    final session = ref.watch(authSessionProvider).value ?? AuthSession.guest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isArabic ? 'حساب الوالدين' : 'Parent account',
                        style: AppTextStyles.headingMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (session.signedIn) ...[
                  _SignedInCard(
                    email: session.email ?? '',
                    isArabic: isArabic,
                    onSignOut: () => _signOut(context, ref, isArabic),
                  ),
                  const SizedBox(height: 16),
                  _CloudBackupCard(isArabic: isArabic),
                ] else ...[
                  _GuestCard(
                    shortCode: account?.shortCode ?? '…',
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isArabic ? 'لماذا الحساب؟' : 'Why an account?',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  _Benefit(
                    emoji: '☁️',
                    title: isArabic ? 'نسخة احتياطية آمنة' : 'A safe backup',
                    body: isArabic
                        ? 'تقدّمك محفوظ على هذا الجهاز الآن. الحساب يحفظ نسخة في السحابة فلا يضيع أبداً.'
                        : 'Your progress is on this device today. An account keeps a cloud copy so it is never lost.',
                  ),
                  _Benefit(
                    emoji: '📱',
                    title: isArabic ? 'على كل أجهزتك' : 'On all your devices',
                    body: isArabic
                        ? 'العب على الهاتف وأكمل على الجهاز اللوحي — نفس النجوم والمستوى.'
                        : 'Play on the phone, continue on the tablet — same stars and level.',
                  ),
                  _Benefit(
                    emoji: '👨‍👩‍👧',
                    title: isArabic
                        ? 'متابعة الوالدين'
                        : 'Parents can follow along',
                    body: isArabic
                        ? 'يمكن لولي الأمر متابعة تقدّم أطفاله من حسابه.'
                        : "A parent can follow each child's progress from their account.",
                  ),
                  const SizedBox(height: 20),
                  _SignInSection(isArabic: isArabic),
                ],
                const SizedBox(height: 16),
                _PlusPromoCard(isArabic: isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
  ) async {
    final passed = await showParentalGate(context, arabic: isArabic);
    if (!passed || !context.mounted) return;
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'تم تسجيل الخروج' : 'Signed out'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// Signed-in card
// =============================================================================

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.email,
    required this.isArabic,
    required this.onSignOut,
  });

  final String email;
  final bool isArabic;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(46),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'حساب الوالدين' : 'Parent account',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تقدّم أطفالك محفوظ في حسابك.'
                        : "Your children's progress is saved to your account.",
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSignOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(isArabic ? 'تسجيل الخروج' : 'Sign out'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cloud backup card (signed-in state)
// =============================================================================

class _CloudBackupCard extends ConsumerStatefulWidget {
  const _CloudBackupCard({required this.isArabic});

  final bool isArabic;

  @override
  ConsumerState<_CloudBackupCard> createState() => _CloudBackupCardState();
}

class _CloudBackupCardState extends ConsumerState<_CloudBackupCard> {
  CloudInfo _info = const CloudInfo();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await ref.read(syncServiceProvider).cloudInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  String _formatStamp(DateTime utc) {
    final d = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _backUp() async {
    final ar = widget.isArabic;
    setState(() => _busy = true);
    final res = await ref.read(syncServiceProvider).push();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      _snack(ar ? 'تم حفظ نسخة في السحابة ✓' : 'Backed up to the cloud ✓');
      _loadInfo();
    } else {
      _snack(
        ar
            ? 'تعذّر النسخ الاحتياطي. حاول لاحقاً.'
            : 'Backup failed. Try again later.',
      );
    }
  }

  Future<void> _restore() async {
    final ar = widget.isArabic;
    final passed = await showParentalGate(context, arabic: ar);
    if (!passed || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(ar ? 'استعادة من السحابة؟' : 'Restore from cloud?'),
        content: Text(
          ar
              ? 'سيحلّ تقدّم النسخة السحابية محلّ تقدّم هذا الجهاز. لا يمكن التراجع.'
              : "The cloud copy will replace this device's progress. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ar ? 'استعادة' : 'Restore'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    final res = await ref.read(syncServiceProvider).pull();
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.status == SyncStatus.empty) {
      _snack(ar ? 'لا توجد نسخة سحابية بعد.' : 'No cloud copy yet.');
      return;
    }
    if (!res.ok) {
      _snack(
        ar
            ? 'تعذّرت الاستعادة. حاول لاحقاً.'
            : 'Restore failed. Try again later.',
      );
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(ar ? 'تمّت الاستعادة ✓' : 'Restored ✓'),
        content: Text(
          ar
              ? 'أغلق التطبيق وأعد فتحه لرؤية تقدّمك المُستعاد.'
              : 'Close and reopen the app to see your restored progress.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ar ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.isArabic;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_sync_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                ar ? 'النسخة السحابية' : 'Cloud backup',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _loading
                ? (ar ? 'جارٍ التحقق…' : 'Checking…')
                : _info.exists && _info.updatedAt != null
                ? (ar
                      ? 'آخر نسخة: ${_formatStamp(_info.updatedAt!)}'
                      : 'Last backup: ${_formatStamp(_info.updatedAt!)}')
                : (ar
                      ? 'لا توجد نسخة سحابية بعد — اضغط "نسخ احتياطي الآن".'
                      : 'No cloud copy yet — tap "Back up now".'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: _backUp,
              icon: const Icon(Icons.backup_rounded, size: 18),
              label: Text(ar ? 'نسخ احتياطي الآن' : 'Back up now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _info.exists ? _restore : null,
              icon: const Icon(Icons.cloud_download_rounded, size: 18),
              label: Text(ar ? 'استعادة من السحابة' : 'Restore from cloud'),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Aziz Academy Plus promo card
// =============================================================================

class _PlusPromoCard extends StatelessWidget {
  const _PlusPromoCard({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.premium),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(40),
              AppColors.secondary.withAlpha(28),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withAlpha(120)),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'أكاديمية عزيز بلس' : 'Aziz Academy Plus',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isArabic
                        ? 'نسخ سحابي وتقارير متقدّمة — من ١ د.ك / شهر'
                        : 'Cloud sync & advanced reports — from 1 KWD / month',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Guest card
// =============================================================================

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.shortCode, required this.isArabic});

  final String shortCode;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(46),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Text('👤', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'وضع الضيف' : 'Guest mode',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'لا حاجة للتسجيل — كل الأنشطة مفتوحة'
                      : 'No sign-up needed — every activity is open',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: $shortCode',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sign-in section (guest state)
// =============================================================================

class _SignInSection extends StatelessWidget {
  const _SignInSection({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isArabic ? 'حساب الوالدين' : 'Parent account',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'ينشئ ولي الأمر الحساب — وليس الطفل. سنطلب تأكيداً بسيطاً للكبار.'
                : 'A parent sets this up — not the child. We ask a quick grown-up check first.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => showEmailAuthSheet(context, arabic: isArabic),
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(
              isArabic
                  ? 'إنشاء حساب / تسجيل الدخول بالبريد'
                  : 'Create account / sign in with email',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SoonProviderButton(
                  icon: Icons.apple_rounded,
                  label: 'Apple',
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SoonProviderButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google',
                  isArabic: isArabic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Apple / Google button — present so parents see what's coming, but the
/// providers need a one-time OAuth setup by the app owner. Tapping
/// explains that honestly and points to the working email path.
class _SoonProviderButton extends StatelessWidget {
  const _SoonProviderButton({
    required this.icon,
    required this.label,
    required this.isArabic,
  });

  final IconData icon;
  final String label;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تسجيل الدخول عبر $label قيد الإعداد — استخدم البريد الآن.'
                  : '$label sign-in is being set up — use email for now.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 4),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Text(
            isArabic ? '(قريباً)' : '(soon)',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
