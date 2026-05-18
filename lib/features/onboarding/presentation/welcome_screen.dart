import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/auth_session_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/gender_picker.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/account/presentation/email_auth_sheet.dart';

/// First-launch onboarding: language → name → age band → parent account →
/// done. The parent-account step is where registration first appears, so a
/// new family meets it on launch instead of digging through menus. Marks
/// `onboardingCompleted` so subsequent launches skip straight to home.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  int _step = 0;
  final _name = TextEditingController();
  String _band = '8-10';
  String _avatar = '🦉';
  String _gender = Gender.unset;
  bool _working = false;

  static const _avatarOptions = ['🦉', '🦊', '🐼', '🐲', '🤖', '🦄'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Persists the child profile collected in steps 1-2. Runs before the
  /// account step so that, if the parent signs in, the cloud seed captures
  /// the real name/age rather than empty defaults.
  Future<void> _persistProfile() async {
    final fallbackName = context.l10n.onboardingDefaultName;
    final resolvedName = _name.text.trim().isEmpty
        ? fallbackName
        : _name.text.trim();
    await ref.read(profileProvider.notifier).setDisplayName(resolvedName);
    await ref.read(profileProvider.notifier).setAgeBand(_band);
    await ref.read(profileProvider.notifier).setGender(_gender);
    await ref
        .read(familyProfilesProvider.notifier)
        .updateSlot(
          0,
          name: resolvedName,
          ageBand: _band,
          avatarEmoji: _avatar,
          gender: _gender,
        );
  }

  Future<void> _goHome() async {
    await ref.read(appSettingsProvider.notifier).markOnboardingCompleted();
    if (mounted) context.go(AppRoutes.home);
  }

  /// Account step — "continue without an account": save and enter as guest.
  Future<void> _continueAsGuest() async {
    if (_working) return;
    setState(() => _working = true);
    await _persistProfile();
    await _goHome();
  }

  /// Account step — opens the parent sign-up / sign-in flow (the parental
  /// gate runs inside the sheet). If the parent ends up signed in, enter the
  /// app; otherwise stay so they can retry or continue as a guest.
  Future<void> _createParentAccount() async {
    if (_working) return;
    setState(() => _working = true);
    await _persistProfile();
    if (!mounted) return;
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    await showEmailAuthSheet(context, arabic: isArabic);
    if (!mounted) return;
    final session = ref.read(authSessionProvider).value;
    if (session?.signedIn ?? false) {
      await _goHome();
    } else {
      setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                _StepIndicator(step: _step, total: 4),
                const SizedBox(height: 24),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _stepBody(isArabic),
                  ),
                ),
                Row(
                  children: [
                    if (_step > 0 && !_working)
                      TextButton(
                        onPressed: () => setState(() => _step--),
                        child: Text(isArabic ? 'رجوع' : 'Back'),
                      ),
                    const Spacer(),
                    // Steps 0-2 advance with Next; the account step (3) has
                    // its own buttons (create account / continue as guest).
                    if (_step < 3)
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _step++),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(isArabic ? 'التالي' : 'Next'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(bool arabic) {
    switch (_step) {
      case 0:
        return _LanguageStep(
          key: const ValueKey('lang'),
          arabic: arabic,
          onPick: () => setState(() => _step = 1),
        );
      case 1:
        return _NameAvatarStep(
          key: const ValueKey('name'),
          arabic: arabic,
          name: _name,
          avatar: _avatar,
          options: _avatarOptions,
          onAvatar: (e) => setState(() => _avatar = e),
          gender: _gender,
          onGender: (g) => setState(() => _gender = g),
        );
      case 2:
        return _AgeStep(
          key: const ValueKey('age'),
          arabic: arabic,
          band: _band,
          onBand: (b) => setState(() => _band = b),
        );
      default:
        return _ParentStep(
          key: const ValueKey('parent'),
          arabic: arabic,
          childName: _name.text.trim(),
          working: _working,
          onCreateAccount: _createParentAccount,
          onGuest: _continueAsGuest,
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == step ? 28 : 12,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step ? AppColors.secondary : AppColors.disabled,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep({super.key, required this.arabic, required this.onPick});
  final bool arabic;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(localeProvider.notifier);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🌟', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          arabic ? 'مرحباً في أكاديمية عزيز!' : 'Welcome to Aziz Academy!',
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          arabic ? 'اختر لغتك' : 'Choose your language',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _LangCard(
              label: 'العربية',
              emoji: 'ع',
              onTap: () async {
                await notifier.setLocale('ar');
                onPick();
              },
            ),
            _LangCard(
              label: 'English',
              emoji: 'A',
              onTap: () async {
                await notifier.setLocale('en');
                onPick();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.label,
    required this.emoji,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.headingSmall),
          ],
        ),
      ),
    );
  }
}

class _NameAvatarStep extends StatelessWidget {
  const _NameAvatarStep({
    super.key,
    required this.arabic,
    required this.name,
    required this.avatar,
    required this.options,
    required this.onAvatar,
    required this.gender,
    required this.onGender,
  });

  final bool arabic;
  final TextEditingController name;
  final String avatar;
  final List<String> options;
  final void Function(String) onAvatar;
  final String gender;
  final void Function(String) onGender;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            arabic ? 'كيف نناديك؟' : 'What should we call you?',
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerLow,
              border: Border.all(color: AppColors.secondary, width: 3),
            ),
            child: Text(avatar, style: const TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: options.map((e) {
              final sel = e == avatar;
              return GestureDetector(
                onTap: () => onAvatar(e),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.secondary.withAlpha(60)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: sel ? AppColors.secondary : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: arabic ? 'اسمك (مثل: عزيز)' : 'Your name (e.g. Aziz)',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLength: 20,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              arabic ? 'هل أنت ولد أم بنت؟' : 'Are you a boy or a girl?',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GenderPicker(value: gender, arabic: arabic, onChanged: onGender),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              arabic
                  ? 'اسمك يبقى على هذا الجهاز فقط — لن يُرسل إلى أي مكان.'
                  : 'Your name stays only on this device — never uploaded anywhere.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({
    super.key,
    required this.arabic,
    required this.band,
    required this.onBand,
  });

  final bool arabic;
  final String band;
  final void Function(String) onBand;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎂', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          arabic ? 'كم عمرك؟' : 'How old are you?',
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 6),
        Text(
          arabic
              ? 'سنختار أسئلة مناسبة لعمرك.'
              : "We'll pick questions that fit your age.",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: const ['6-8', '8-10', '10-12'].map((b) {
            final sel = b == band;
            return GestureDetector(
              onTap: () => onBand(b),
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.secondary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? AppColors.secondary : AppColors.glassBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    b,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: sel ? AppColors.background : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Step 4 — the parent account step. This is the first place registration
/// appears in the app, so a new family sees the choice on launch rather than
/// discovering it buried in a menu. Account creation is a grown-up action;
/// the parental gate runs inside `showEmailAuthSheet`.
class _ParentStep extends StatelessWidget {
  const _ParentStep({
    super.key,
    required this.arabic,
    required this.childName,
    required this.working,
    required this.onCreateAccount,
    required this.onGuest,
  });

  final bool arabic;
  final String childName;
  final bool working;
  final VoidCallback onCreateAccount;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    final name = childName.isEmpty
        ? (arabic ? 'طفلك' : 'your child')
        : childName;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Text('☁️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 10),
          Text(
            arabic ? 'احفظ تقدّم $name' : "Save $name's progress",
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            arabic
                ? 'لوليّ الأمر: أنشئ حساباً مجانياً لحفظ النجوم والمستوى في السحابة — أو تابع كضيف وأضف الحساب لاحقاً.'
                : 'For grown-ups: create a free account to keep stars and levels safe in the cloud — or continue as a guest and add one later.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                _ParentBenefit(
                  emoji: '☁️',
                  text: arabic
                      ? 'نسخة احتياطية آمنة لا تضيع'
                      : 'A safe backup that is never lost',
                ),
                _ParentBenefit(
                  emoji: '📱',
                  text: arabic
                      ? 'نفس التقدّم على كل الأجهزة'
                      : 'The same progress on every device',
                ),
                _ParentBenefit(
                  emoji: '👨‍👩‍👧',
                  text: arabic
                      ? 'يتابع الوالدان تقدّم كل طفل'
                      : "Parents follow each child's progress",
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: working ? null : onCreateAccount,
            icon: working
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_done_rounded),
            label: Text(
              arabic
                  ? 'إنشاء حساب وليّ الأمر (مجاني)'
                  : 'Create a parent account (free)',
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: working ? null : onGuest,
            child: Text(
              arabic ? 'المتابعة بدون حساب' : 'Continue without an account',
            ),
          ),
          Text(
            arabic
                ? 'ينشئ الحساب وليّ الأمر بعد تأكيد بسيط للكبار. يمكن إضافته لاحقاً من شاشة الحساب.'
                : 'A grown-up sets this up after a quick check. You can also add it later from the Account screen.',
            textAlign: TextAlign.center,
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

class _ParentBenefit extends StatelessWidget {
  const _ParentBenefit({
    required this.emoji,
    required this.text,
    this.last = false,
  });

  final String emoji;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
