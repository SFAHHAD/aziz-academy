import 'dart:async';
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

class CupShuffleScreen extends ConsumerStatefulWidget {
  const CupShuffleScreen({super.key});

  @override
  ConsumerState<CupShuffleScreen> createState() => _CupShuffleScreenState();
}

enum _Phase { idle, reveal, shuffling, guess, result }

class _CupShuffleScreenState extends ConsumerState<CupShuffleScreen> {
  static const _rounds = 8;

  int _round = 0;
  int _score = 0;
  bool _gameOver = false;
  bool _awarded = false;

  /// Positions[i] tells which CUP currently sits at position i (0,1,2).
  List<int> _positions = [0, 1, 2];
  int _ballCup = 0; // which cup hides the ball
  _Phase _phase = _Phase.idle;
  int? _highlightSwapA;
  int? _highlightSwapB;
  int? _selectedPos;
  bool _revealResult = false;

  void _startRound() async {
    setState(() {
      _positions = [0, 1, 2];
      _ballCup = math.Random().nextInt(3);
      _phase = _Phase.reveal;
      _selectedPos = null;
      _revealResult = false;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _phase = _Phase.shuffling);
    final shuffleCount = 3 + _round; // 3..10
    for (var i = 0; i < shuffleCount; i++) {
      final rng = math.Random();
      var a = rng.nextInt(3);
      var b = rng.nextInt(3);
      while (a == b) {
        b = rng.nextInt(3);
      }
      setState(() {
        _highlightSwapA = a;
        _highlightSwapB = b;
        final tmp = _positions[a];
        _positions[a] = _positions[b];
        _positions[b] = tmp;
      });
      final swapDelay = math.max(
        150,
        380 - _round * 22,
      ); // faster as rounds go up
      await Future.delayed(Duration(milliseconds: swapDelay));
      if (!mounted) return;
    }
    setState(() {
      _highlightSwapA = null;
      _highlightSwapB = null;
      _phase = _Phase.guess;
    });
  }

  void _guess(int posIdx) {
    if (_phase != _Phase.guess) return;
    HapticFeedback.lightImpact();
    final cupAtPos = _positions[posIdx];
    final correct = cupAtPos == _ballCup;
    setState(() {
      _selectedPos = posIdx;
      _phase = _Phase.result;
      _revealResult = true;
      if (correct) _score += 1;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _round += 1;
        if (_round >= _rounds) {
          _gameOver = true;
          _phase = _Phase.idle;
          _award();
        } else {
          _startRound();
        }
      });
    });
  }

  void _newGame() {
    setState(() {
      _round = 0;
      _score = 0;
      _gameOver = false;
      _awarded = false;
    });
    _startRound();
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    int reward;
    if (_score >= 8) {
      reward = 10;
    } else if (_score >= 6) {
      reward = 5;
    } else if (_score >= 4) {
      reward = 2;
    } else {
      reward = 0;
    }
    if (reward > 0) {
      ref.read(coinProvider.notifier).award(reward);
    }
  }

  Widget _cup(int posIdx) {
    final cupId = _positions[posIdx];
    final showBall = _phase == _Phase.reveal && cupId == _ballCup;
    final showResult =
        _phase == _Phase.result && _revealResult && cupId == _ballCup;
    final highlighted = _highlightSwapA == posIdx || _highlightSwapB == posIdx;
    final selected = _selectedPos == posIdx;
    return GestureDetector(
      onTap: _phase == _Phase.guess ? () => _guess(posIdx) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.3)
              : selected
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              showBall || showResult ? '🥄' : '🥤',
              style: const TextStyle(fontSize: 60),
            ),
            if (showBall || showResult)
              const Positioned(
                bottom: 6,
                child: Text('⚪', style: TextStyle(fontSize: 22)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final bannerText = switch (_phase) {
      _Phase.idle => isAr ? 'اضغط ابدأ' : 'Tap Start',
      _Phase.reveal =>
        isAr ? 'تذكّر مكان الكرة!' : 'Watch where the ball goes!',
      _Phase.shuffling => isAr ? 'تخلط الأكواب…' : 'Shuffling…',
      _Phase.guess => isAr ? 'أين الكرة؟' : 'Where is the ball?',
      _Phase.result =>
        _selectedPos != null && _positions[_selectedPos!] == _ballCup
            ? (isAr ? '✅ صحيح!' : '✅ Correct!')
            : (isAr ? '❌ خطأ' : '❌ Wrong'),
    };
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
          isAr ? 'تتبع الكرة' : 'Cup Shuffle',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'انتبه إلى الكوب الذي يخفي الكرة، ثم اضغط عليه بعد الخلط.'
                    : 'Watch the cup hiding the ball, then tap it after the shuffle.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'الجولة' : 'Round',
                    value:
                        '${localizeDigits(_round + (_gameOver ? 0 : (_phase == _Phase.idle ? 0 : 1)), arabic: isAr)}/${localizeDigits(_rounds, arabic: isAr)}',
                    color: AppColors.textDark,
                  ),
                  _Pill(
                    label: isAr ? 'النقاط' : 'Score',
                    value: localizeDigits(_score, arabic: isAr),
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                bannerText,
                style: AppTextStyles.headingSmall.copyWith(
                  color: _phase == _Phase.result
                      ? (_selectedPos != null &&
                                _positions[_selectedPos!] == _ballCup
                            ? AppColors.success
                            : AppColors.error)
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [_cup(0), _cup(1), _cup(2)],
              ),
              const Spacer(),
              if (_phase == _Phase.idle)
                ElevatedButton.icon(
                  onPressed: _newGame,
                  icon: Icon(_gameOver ? Icons.replay : Icons.play_arrow),
                  label: Text(
                    _gameOver
                        ? (isAr ? 'مرة أخرى' : 'Play again')
                        : (isAr ? 'ابدأ' : 'Start'),
                  ),
                ),
              if (_gameOver)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isAr
                        ? 'النتيجة: ${localizeDigits(_score, arabic: true)}/${localizeDigits(_rounds, arabic: true)}'
                        : 'Final: $_score/$_rounds',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(width: 6),
          Text(value, style: AppTextStyles.headingSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
