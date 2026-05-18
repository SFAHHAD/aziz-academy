import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

class PenaltyShootoutScreen extends ConsumerStatefulWidget {
  const PenaltyShootoutScreen({super.key});

  @override
  ConsumerState<PenaltyShootoutScreen> createState() =>
      _PenaltyShootoutScreenState();
}

enum _Direction { left, center, right }

class _PenaltyShootoutScreenState extends ConsumerState<PenaltyShootoutScreen> {
  static const _kicks = 5;
  int _round = 0; // 0..(2*_kicks - 1)
  int _playerScore = 0;
  int _cpuScore = 0;
  bool _gameOver = false;
  bool _awarded = false;
  String? _msg;
  _Direction? _lastShot;
  _Direction? _lastSave;

  bool get _playerShoots => _round.isEven;

  void _newGame() {
    setState(() {
      _round = 0;
      _playerScore = 0;
      _cpuScore = 0;
      _gameOver = false;
      _awarded = false;
      _msg = null;
      _lastShot = null;
      _lastSave = null;
    });
  }

  void _playerKick(_Direction shot) {
    if (_gameOver || !_playerShoots) return;
    HapticFeedback.lightImpact();
    final rng = math.Random();
    final dive = _Direction.values[rng.nextInt(_Direction.values.length)];
    final scored = dive != shot;
    setState(() {
      _lastShot = shot;
      _lastSave = dive;
      _msg = scored ? '⚽ Goal!' : '🥅 Saved!';
      if (scored) _playerScore += 1;
      _round += 1;
      _check();
    });
  }

  void _playerDive(_Direction dive) {
    if (_gameOver || _playerShoots) return;
    HapticFeedback.lightImpact();
    final rng = math.Random();
    final shot = _Direction.values[rng.nextInt(_Direction.values.length)];
    final cpuScored = dive != shot;
    setState(() {
      _lastShot = shot;
      _lastSave = dive;
      _msg = cpuScored ? '😢 CPU scored!' : '🧤 You saved it!';
      if (cpuScored) _cpuScore += 1;
      _round += 1;
      _check();
    });
  }

  void _check() {
    final left = (2 * _kicks) - _round;
    if (_playerScore - _cpuScore > left || _cpuScore - _playerScore > left) {
      _gameOver = true;
      if (_playerScore > _cpuScore) _award();
      return;
    }
    if (_round >= 2 * _kicks) {
      // After 5+5, do sudden-death pairs.
      if (_playerScore != _cpuScore) {
        _gameOver = true;
        if (_playerScore > _cpuScore) _award();
      }
    }
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    ref.read(coinProvider.notifier).award(5);
  }

  String _dirLabel(_Direction d, bool isAr) {
    switch (d) {
      case _Direction.left:
        return isAr ? 'يسار' : 'Left';
      case _Direction.center:
        return isAr ? 'وسط' : 'Center';
      case _Direction.right:
        return isAr ? 'يمين' : 'Right';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final action = _playerShoots ? _playerKick : _playerDive;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr ? Icons.arrow_forward : Icons.arrow_back,
            color: AppColors.textDark,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          isAr ? 'ركلات الترجيح' : 'Penalty Shootout',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _newGame),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'تبادل ركلات الترجيح ضد الكمبيوتر. ٥ ركلات لكل لاعب، ثم موت مفاجئ.'
                    : 'Trade penalty kicks with the CPU. 5 each, then sudden death.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScorePanel(
                    label: isAr ? 'أنت' : 'You',
                    score: _playerScore,
                    color: AppColors.success,
                    isAr: isAr,
                  ),
                  Text('⚽', style: TextStyle(fontSize: 32)),
                  _ScorePanel(
                    label: isAr ? 'الجهاز' : 'CPU',
                    score: _cpuScore,
                    color: AppColors.error,
                    isAr: isAr,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _gameOver
                          ? (_playerScore > _cpuScore
                                ? (isAr ? '🏆 لقد فزت!' : '🏆 You won!')
                                : (isAr ? '😢 خسرت' : '😢 You lost'))
                          : (_playerShoots
                                ? (isAr
                                      ? 'سدد! اختر اتجاهك'
                                      : 'Your kick! Pick a direction')
                                : (isAr
                                      ? 'احرس! تنبأ باتجاه الخصم'
                                      : 'Save! Guess the CPU direction')),
                      style: AppTextStyles.headingSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 8),
                      Text(_msg!, style: AppTextStyles.bodyMedium),
                    ],
                    if (_lastShot != null && _lastSave != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'تسديدة: ${_dirLabel(_lastShot!, isAr)} | حارس: ${_dirLabel(_lastSave!, isAr)}'
                            : 'Shot: ${_dirLabel(_lastShot!, isAr)}  |  Keeper: ${_dirLabel(_lastSave!, isAr)}',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'الجولة: ${localizeDigits(_round + 1, arabic: true)}'
                    : 'Round: ${_round + 1}',
                style: AppTextStyles.labelSmall,
              ),
              const Spacer(),
              if (_gameOver)
                ElevatedButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.replay),
                  label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DirButton(
                      icon: Icons.arrow_back,
                      label: _dirLabel(_Direction.left, isAr),
                      onPressed: () => action(_Direction.left),
                    ),
                    _DirButton(
                      icon: Icons.arrow_upward,
                      label: _dirLabel(_Direction.center, isAr),
                      onPressed: () => action(_Direction.center),
                    ),
                    _DirButton(
                      icon: Icons.arrow_forward,
                      label: _dirLabel(_Direction.right, isAr),
                      onPressed: () => action(_Direction.right),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirButton extends StatelessWidget {
  const _DirButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(onPressed: onPressed, icon: Icon(icon, size: 28)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.label,
    required this.score,
    required this.color,
    required this.isAr,
  });
  final String label;
  final int score;
  final Color color;
  final bool isAr;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(
            localizeDigits(score, arabic: isAr),
            style: AppTextStyles.headingLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
