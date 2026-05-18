import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/auth_session_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/premium_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/billing_config.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/parental_gate.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// "Aziz Academy Plus" — the premium upgrade screen.
///
/// Premium unlocks the parent-convenience layer (cloud backup & sync,
/// advanced reports). Every learning activity, all family profiles, and
/// the no-ads / no-tracking promise stay free for everyone — a child's
/// learning is never paywalled.
///
/// Purchasing is a parent action, behind the parental gate.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _yearly = true; // yearly is the better-value default

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final premium = ref.watch(premiumProvider).value ?? PremiumState.free;
    final signedIn = ref.watch(authSessionProvider).value?.signedIn ?? false;

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
                        isArabic ? 'أكاديمية عزيز بلس' : 'Aziz Academy Plus',
                        style: AppTextStyles.headingMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Hero(isArabic: isArabic),
                const SizedBox(height: 20),
                if (premium.isPremium)
                  _AlreadyPlusCard(premium: premium, isArabic: isArabic)
                else ...[
                  _Benefits(isArabic: isArabic),
                  const SizedBox(height: 16),
                  _AlwaysFree(isArabic: isArabic),
                  const SizedBox(height: 20),
                  _PlanPicker(
                    yearly: _yearly,
                    isArabic: isArabic,
                    onChanged: (v) => setState(() => _yearly = v),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _subscribe(context, isArabic, signedIn),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isArabic ? 'الاشتراك الآن' : 'Subscribe now',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'يُدار الاشتراك من حساب الوالد. يمكن الإلغاء في أي وقت.'
                        : 'Managed from the parent account. Cancel anytime.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _subscribe(
    BuildContext context,
    bool isArabic,
    bool signedIn,
  ) async {
    // Subscriptions attach to a parent account — require sign-in first.
    if (!signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'أنشئ حساب وليّ الأمر أولاً من صفحة الحساب.'
                : 'Create a parent account first, from the Account page.',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: isArabic ? 'الحساب' : 'Account',
            onPressed: () => context.go(AppRoutes.account),
          ),
        ),
      );
      return;
    }
    final passed = await showParentalGate(context, arabic: isArabic);
    if (!passed || !context.mounted) return;

    if (!BillingConfig.checkoutReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'الاشتراك يُفتح قريباً جداً — شكراً لدعمك!'
                : 'Subscriptions open very soon — thanks for your support!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final url = _yearly
        ? BillingConfig.yearlyCheckoutUrl
        : BillingConfig.monthlyCheckoutUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          Text(
            isArabic ? 'أكاديمية عزيز بلس' : 'Aziz Academy Plus',
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'ادعم التطبيق، واحفظ تقدّم أطفالك في كل مكان.'
                : "Support the app, and keep your children's progress everywhere.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withAlpha(225),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isArabic ? 'ماذا يفتح بلس؟' : 'What Plus unlocks',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 10),
        _BenefitRow(
          emoji: '☁️',
          title: isArabic
              ? 'نسخ سحابي ومزامنة بين الأجهزة'
              : 'Cloud backup & cross-device sync',
          body: isArabic
              ? 'تقدّم أطفالك محفوظ في حسابك ويتنقّل بين كل أجهزتك.'
              : "Your children's progress is saved to your account and follows every device.",
        ),
        _BenefitRow(
          emoji: '📊',
          title: isArabic
              ? 'تقارير الوالدين المتقدّمة'
              : 'Advanced parent reports',
          body: isArabic
              ? 'تحليل أعمق لنقاط القوة والضعف لكل طفل عبر المواد.'
              : "Deeper analysis of each child's strengths and weak spots across subjects.",
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
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
      ),
    );
  }
}

class _AlwaysFree extends StatelessWidget {
  const _AlwaysFree({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💚', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'يبقى مجانياً للجميع' : 'Always free for everyone',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'كل الأنشطة التعليمية، وبطاقات العائلة، وبدون إعلانات وبدون تتبّع — تعلّم طفلك لا يُحجب أبداً خلف اشتراك.'
                      : "Every learning activity, family profiles, and no ads / no tracking — a child's learning is never put behind a paywall.",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
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

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.yearly,
    required this.isArabic,
    required this.onChanged,
  });

  final bool yearly;
  final bool isArabic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlanCard(
            selected: !yearly,
            title: isArabic ? 'شهري' : 'Monthly',
            price: BillingConfig.monthlyPrice,
            per: isArabic ? '/ شهر' : '/ month',
            badge: null,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanCard(
            selected: yearly,
            title: isArabic ? 'سنوي' : 'Yearly',
            price: BillingConfig.yearlyPrice,
            per: isArabic ? '/ سنة' : '/ year',
            badge: isArabic
                ? BillingConfig.yearlySavingsLabelAr
                : BillingConfig.yearlySavingsLabel,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.title,
    required this.price,
    required this.per,
    required this.badge,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String price;
  final String per;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withAlpha(46)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.glassBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.secondary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              per,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMedium,
                fontSize: 11,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlreadyPlusCard extends StatelessWidget {
  const _AlreadyPlusCard({required this.premium, required this.isArabic});

  final PremiumState premium;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final until = premium.until;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(120)),
      ),
      child: Column(
        children: [
          const Text('🌟', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(
            isArabic ? 'أنت عضو في بلس' : "You're a Plus member",
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'شكراً لدعمك أكاديمية عزيز 💚'
                : 'Thank you for supporting Aziz Academy 💚',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              fontSize: 12,
            ),
          ),
          if (until != null) ...[
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'يتجدّد في ${until.toLocal().toString().split(' ').first}'
                  : 'Renews on ${until.toLocal().toString().split(' ').first}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMedium,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
