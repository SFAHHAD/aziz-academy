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

class PigDiceScreen extends ConsumerStatefulWidget {
  const PigDiceScreen({super.key});

  @override
  ConsumerState<PigDiceScreen> createState() => _PigDiceScreenState();
}

class _PigDiceScreenState extends ConsumerState<PigDiceScreen> {
  static const _target = 50;

  int _player = 0;
  int _cpu = 0;
  int _turnTotal = 0;
  int _lastRoll = 0;
  bool _playerTurn = true;
  bool _gameOver = false;
  bool _playerWon = false;
  bool _awarded = false;
  String? _msg;

  void _newGame() {
    setState(() {
      _player = 0;
      _cpu = 0;
      _turnTotal = 0;
      _lastRoll = 0;
      _playerTurn = true;
      _gameOver = false;
      _playerWon = false;
      _awarded = false;
      _msg = null;
    });
  }

  void _roll() {
    if (_gameOver || !_playerTurn) return;
    HapticFeedback.lightImpact();
    final rng = math.Random();
    final r = 1 + rng.nextInt(6);
    setState(() {
      _lastRoll = r;
      if (r == 1) {
        _msg = 'Pig out! Turn lost.';
        _turnTotal = 0;
        _playerTurn = false;
      } else {
        _turnTotal += r;
        _msg = null;
      }
    });
    if (!_playerTurn) {
      Future.delayed(const Duration(milliseconds: 700), _cpuTurn);
    }
  }

  void _hold() {
    if (_gameOver || !_playerTurn) return;
    HapticFeedback.lightImpact();
    setState(() {
      _player += _turnTotal;
      _turnTotal = 0;
      if (_player >= _target) {
        _gameOver = true;
        _playerWon = true;
        _award();
      } else {
        _playerTurn = false;
      }
    });
    if (!_gameOver) {
      Future.delayed(const Duration(milliseconds: 600), _cpuTurn);
    }
  }

  Future<void> _cpuTurn() async {
    if (_gameOver) return;
    var turn = 0;
    while (true) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted || _gameOver) return;
      final rng = math.Random();
      final r = 1 + rng.nextInt(6);
      setState(() {
        _lastRoll = r;
      });
      if (r == 1) {
        setState(() {
          turn = 0;
          _msg = 'CPU pigged out!';
        });
        break;
      }
      turn += r;
      setState(() => _turnTotal = turn);
      // Strategy: hold at 20+ or if would win.
      if (turn >= 20 || _cpu + turn >= _target) {
        setState(() {
          _cpu += turn;
          _turnTotal = 0;
        });
        if (_cpu >= _target) {
          setState(() {
            _gameOver = true;
            _playerWon = false;
          });
          return;
        }
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _turnTotal = 0;
      _playerTurn = true;
      _msg ??= 'Your turn';
    });
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    ref.read(coinProvider.notifier).award(5);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
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
          isAr ? 'لعبة النرد (الخنزير)' : 'Pig Dice',
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
                    ? 'ارمِ النرد. لكن إذا ظهر ١، تخسر دور الجولة. أمسك لتثبت النقاط. أول من يصل ٥٠ يفوز.'
                    : 'Roll dice. Rolling a 1 ends your turn with no points. Hold to bank your turn total. First to 50 wins.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScorePanel(
                    label: isAr ? 'أنت' : 'You',
                    score: _player,
                    target: _target,
                    isActive: _playerTurn && !_gameOver,
                    color: AppColors.success,
                    isAr: isAr,
                  ),
                  _ScorePanel(
                    label: isAr ? 'الجهاز' : 'CPU',
                    score: _cpu,
                    target: _target,
                    isActive: !_playerTurn && !_gameOver,
                    color: AppColors.error,
                    isAr: isAr,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _lastRoll == 0
                      ? '🎲'
                      : isAr
                      ? localizeDigits(_lastRoll, arabic: true)
                      : '$_lastRoll',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: 48,
                    color: _lastRoll == 1
                        ? AppColors.error
                        : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'مجموع الدور: ${localizeDigits(_turnTotal, arabic: true)}'
                    : 'Turn total: $_turnTotal',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (_msg != null) ...[
                const SizedBox(height: 6),
                Text(
                  _msg!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_gameOver)
                Column(
                  children: [
                    Text(
                      _playerWon
                          ? (isAr ? '🏆 أنت الفائز!' : '🏆 You won!')
                          : (isAr ? '😢 فاز الجهاز' : '😢 CPU won'),
                      style: AppTextStyles.headingMedium.copyWith(
                        color: _playerWon ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _newGame,
                      icon: const Icon(Icons.replay),
                      label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _playerTurn ? _roll : null,
                      icon: const Icon(Icons.casino),
                      label: Text(isAr ? 'ارمِ' : 'Roll'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _playerTurn && _turnTotal > 0 ? _hold : null,
                      icon: const Icon(Icons.savings),
                      label: Text(isAr ? 'أمسك' : 'Hold'),
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

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.label,
    required this.score,
    required this.target,
    required this.isActive,
    required this.color,
    required this.isAr,
  });
  final String label;
  final int score;
  final int target;
  final bool isActive;
  final Color color;
  final bool isAr;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(
            '${localizeDigits(score, arabic: isAr)}/${localizeDigits(target, arabic: isAr)}',
            style: AppTextStyles.headingMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
