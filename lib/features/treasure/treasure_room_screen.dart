import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Tap-a-chest gambling-free coin loot loop. Each chest costs 30 coins to
/// open and rewards [10..80] coins with a long-tail bias toward small wins
/// (so the expected value sits just above zero — no addictive chase, just a
/// fun "open the box" moment after a lesson). Three chests visible at once.
class TreasureRoomScreen extends ConsumerStatefulWidget {
  const TreasureRoomScreen({super.key});

  @override
  ConsumerState<TreasureRoomScreen> createState() => _TreasureRoomScreenState();
}

class _TreasureRoomScreenState extends ConsumerState<TreasureRoomScreen> {
  static const int _chestCost = 30;
  static const List<int> _rewardTiers = [10, 15, 20, 30, 50, 80];
  static const List<int> _rewardWeights = [40, 25, 15, 10, 7, 3];

  final _rng = math.Random();
  final List<_ChestState> _chests = List.generate(
    3,
    (_) => const _ChestState(),
  );
  String? _resultBanner;
  bool _arabic = true;

  int _rollReward() {
    final total = _rewardWeights.reduce((a, b) => a + b);
    final roll = _rng.nextInt(total);
    var acc = 0;
    for (var i = 0; i < _rewardTiers.length; i++) {
      acc += _rewardWeights[i];
      if (roll < acc) return _rewardTiers[i];
    }
    return _rewardTiers.first;
  }

  Future<void> _openChest(int idx) async {
    final coinNotifier = ref.read(coinProvider.notifier);
    final balance = ref.read(coinProvider).value ?? 0;
    if (balance < _chestCost) {
      HapticFeedback.lightImpact();
      setState(
        () => _resultBanner = _arabic
            ? 'تحتاج $_chestCost عملة'
            : 'You need $_chestCost coins',
      );
      return;
    }
    final paid = await coinNotifier.spend(_chestCost);
    if (!paid) return;
    final reward = _rollReward();
    await coinNotifier.award(reward);
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).playCorrectSound();
    setState(() {
      _chests[idx] = _ChestState(opened: true, reward: reward);
      _resultBanner = _arabic ? '🪙 +$reward' : '🪙 +$reward';
    });
  }

  void _resetChests() {
    setState(() {
      for (var i = 0; i < _chests.length; i++) {
        _chests[i] = const _ChestState();
      }
      _resultBanner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    _arabic = Directionality.of(context) == TextDirection.rtl;
    final balance = ref.watch(coinProvider).value ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(_arabic ? '🎁 غرفة الكنز' : '🎁 Treasure Room'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            _arabic
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withAlpha(110)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 8),
                    Text(
                      localizeDigits(balance, arabic: _arabic),
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _arabic
                    ? 'افتح صندوقاً واكسب عملات. كل صندوق $_chestCost عملة.'
                    : 'Open a chest to win coins. Each chest costs $_chestCost.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: List.generate(_chests.length, (i) {
                    final chest = _chests[i];
                    return _ChestTile(
                      state: chest,
                      onTap: chest.opened ? null : () => _openChest(i),
                    );
                  }),
                ),
              ),
              if (_resultBanner != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _resultBanner!,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_arabic ? 'صناديق جديدة' : 'New chests'),
                  onPressed: _chests.every((c) => c.opened)
                      ? _resetChests
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChestState {
  const _ChestState({this.opened = false, this.reward = 0});
  final bool opened;
  final int reward;
}

class _ChestTile extends StatelessWidget {
  const _ChestTile({required this.state, required this.onTap});
  final _ChestState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final closed = !state.opened;
    return Semantics(
      button: true,
      label: closed ? 'صندوق مغلق' : 'صندوق مفتوح: ${state.reward} عملة',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: closed
                ? [
                    AppColors.primary.withAlpha(60),
                    AppColors.primary.withAlpha(110),
                  ]
                : [
                    AppColors.accent.withAlpha(70),
                    AppColors.accent.withAlpha(140),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (closed ? AppColors.primary : AppColors.accent).withAlpha(
              180,
            ),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    closed ? '🎁' : '🪙',
                    style: const TextStyle(fontSize: 56),
                  ),
                  if (state.opened) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${state.reward}',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
