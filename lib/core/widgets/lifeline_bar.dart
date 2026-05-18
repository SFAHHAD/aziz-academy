import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';

typedef OnFiftyFifty = void Function(List<String> hiddenOptions);
typedef OnSkip = void Function();
typedef OnHint = void Function(String hintText);

/// Shared lifeline bar: 50/50, Skip, Hint — coin-driven. Disables itself when
/// the question is already answered or coins are insufficient. Fires the
/// caller-supplied callbacks so each quiz screen can wire the effect into its
/// own session state.
class LifelineBar extends ConsumerWidget {
  const LifelineBar({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.locked,
    required this.onFiftyFifty,
    required this.onSkip,
    required this.onHint,
    this.usedFiftyFifty = false,
    this.usedSkip = false,
    this.usedHint = false,
  });

  final List<String> options;
  final String correctAnswer;
  final bool locked;
  final OnFiftyFifty onFiftyFifty;
  final OnSkip onSkip;
  final OnHint onHint;
  final bool usedFiftyFifty;
  final bool usedSkip;
  final bool usedHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsAsync = ref.watch(coinProvider);
    final coins = coinsAsync.value ?? 0;
    final l10n = context.l10n;

    Future<void> trySpend(int cost, VoidCallback onPaid) async {
      if (locked) return;
      final ok = await ref.read(coinProvider.notifier).spend(cost);
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(l10n.lifelineNotEnoughCoins),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      HapticFeedback.lightImpact();
      onPaid();
    }

    void doFiftyFifty() {
      final wrong = options
          .where((o) => o.trim() != correctAnswer.trim())
          .toList();
      wrong.shuffle(math.Random());
      onFiftyFifty(wrong.take(2).toList());
    }

    void doHint() {
      // Reveal first 1-2 letters of the correct answer as a clue.
      final ans = correctAnswer.trim();
      final cutoff = ans.length <= 4 ? 1 : 2;
      final masked =
          ans.substring(0, cutoff) +
          ans.substring(cutoff).replaceAll(RegExp(r'\S'), '•');
      onHint(masked);
    }

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Coin balance pill ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  localizeDigitsCtx(coins, context),
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
          ),

          _LifelineButton(
            emoji: '50',
            label: l10n.lifelineFiftyFifty,
            cost: LifelineCost.fiftyFifty,
            disabled:
                locked || usedFiftyFifty || coins < LifelineCost.fiftyFifty,
            onTap: () => trySpend(LifelineCost.fiftyFifty, doFiftyFifty),
          ),
          _LifelineButton(
            emoji: '⏭️',
            label: l10n.lifelineSkip,
            cost: LifelineCost.skip,
            disabled: locked || usedSkip || coins < LifelineCost.skip,
            onTap: () => trySpend(LifelineCost.skip, onSkip),
          ),
          _LifelineButton(
            emoji: '💡',
            label: l10n.lifelineHint,
            cost: LifelineCost.hint,
            disabled: locked || usedHint || coins < LifelineCost.hint,
            onTap: () => trySpend(LifelineCost.hint, doHint),
          ),
        ],
      ),
    );
  }
}

class _LifelineButton extends StatelessWidget {
  const _LifelineButton({
    required this.emoji,
    required this.label,
    required this.cost,
    required this.disabled,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int cost;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label · ${localizeDigitsCtx(cost, context)} 🪙',
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: disabled
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: disabled ? null : onTap,
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 22,
                  color: disabled ? AppColors.disabled : AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
