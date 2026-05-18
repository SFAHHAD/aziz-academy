import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/sadaqah_jar_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Visual sadaqah jar — kids tap to add to a daily/weekly charity savings
/// goal. Pure habit tracker; no real money, no in-app purchase. Mirrors a
/// real-world sadaqah box at home.
class SadaqahJarScreen extends ConsumerStatefulWidget {
  const SadaqahJarScreen({super.key});

  @override
  ConsumerState<SadaqahJarScreen> createState() => _SadaqahJarScreenState();
}

class _SadaqahJarScreenState extends ConsumerState<SadaqahJarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _drop(int n) async {
    await ref.read(sadaqahJarProvider.notifier).drop(n);
    _bounce.forward(from: 0);
  }

  Future<void> _editGoal() async {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final cur = ref.read(sadaqahJarProvider).value;
    final ctrl = TextEditingController(text: '${cur?.goal ?? 100}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حدّد الهدف' : 'Set goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: isAr ? 'عدد القطع' : 'Number of coins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await ref.read(sadaqahJarProvider.notifier).setGoal(result);
    }
  }

  Future<void> _empty() async {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إفراغ الجرّة؟' : 'Empty the jar?'),
        content: Text(
          isAr
              ? 'هذا يصفّر العدّاد. متابعة؟'
              : 'This resets the counter. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'نعم' : 'Yes'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sadaqahJarProvider.notifier).empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final jar = ref.watch(sadaqahJarProvider).value ?? const SadaqahJarState();
    final pct = (jar.progress * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'جرّة الصدقة' : 'Sadaqah Jar'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'الهدف' : 'Goal',
            icon: const Icon(Icons.flag_rounded),
            onPressed: _editGoal,
          ),
          IconButton(
            tooltip: isAr ? 'إفراغ' : 'Empty',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _empty,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(36),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withAlpha(80)),
                ),
                child: Text(
                  isAr
                      ? 'تتبّع لطيف لعادة الصدقة. لا أموال حقيقية ولا تحويلات — اكتسب عادة العطاء بالعدّ والتذكير. ضع جرّة حقيقية في البيت وزِدها كلما زدت العدّاد هنا.'
                      : 'A gentle tracker for the habit of charity. No real money, no transfers — build the giving habit by counting at home. Place a real jar at home and add to it whenever you tap below.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.08)
                      .chain(CurveTween(curve: Curves.elasticOut))
                      .animate(_bounce),
                  child: _Jar(progress: jar.progress, isAr: isAr),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? '${localizeDigits(jar.dropped, arabic: true)} / ${localizeDigits(jar.goal, arabic: true)}  •  ${localizeDigits(pct, arabic: true)}٪'
                    : '${jar.dropped} / ${jar.goal}  •  $pct%',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              if (jar.goalMet) ...[
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? '🎉 وصلتَ الهدف، بارك الله فيك!'
                      : '🎉 Goal met — barakallahu feek!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final v in [1, 5, 10, 25])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton.tonal(
                          onPressed: () => _drop(v),
                          child: Text(
                            '+${localizeDigits(v, arabic: isAr)}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({required this.progress, required this.isAr});
  final double progress;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = constraints.biggest.shortestSide;
        final fillH = size * 0.7 * progress;
        return Center(
          child: SizedBox(
            width: size * 0.7,
            height: size * 0.85,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(180),
                      width: 4,
                    ),
                    color: AppColors.surfaceContainerLow,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  height: fillH,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent.withAlpha(160),
                        AppColors.accent.withAlpha(220),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(22),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text('🪙', style: TextStyle(fontSize: 56)),
                ),
                Positioned(
                  top: -8,
                  child: Container(
                    width: size * 0.45,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
