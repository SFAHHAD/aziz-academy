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

class HigherLowerScreen extends ConsumerStatefulWidget {
  const HigherLowerScreen({super.key});

  @override
  ConsumerState<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends ConsumerState<HigherLowerScreen> {
  static const _suits = ['♠', '♥', '♦', '♣'];

  int _card = 7;
  int _suit = 0;
  int _streak = 0;
  int _high = 0;
  bool _running = false;
  bool _gameOver = false;
  String? _msg;
  int? _next;
  int? _nextSuit;
  bool _awarded = false;

  void _start() {
    setState(() {
      _running = true;
      _gameOver = false;
      _streak = 0;
      _msg = null;
      _next = null;
      _nextSuit = null;
      _awarded = false;
      final rng = math.Random();
      _card = 2 + rng.nextInt(12); // 2..13
      _suit = rng.nextInt(_suits.length);
    });
  }

  void _guess(bool higher) {
    if (!_running || _gameOver) return;
    HapticFeedback.lightImpact();
    final rng = math.Random();
    int next;
    do {
      next = 2 + rng.nextInt(12);
    } while (next == _card); // No ties to keep things simple.
    final correct = higher ? next > _card : next < _card;
    setState(() {
      _next = next;
      _nextSuit = rng.nextInt(_suits.length);
      _msg = correct
          ? '✅ ${higher ? 'Higher' : 'Lower'}!'
          : '❌ Wrong! Was $next';
      if (correct) {
        _streak += 1;
        if (_streak > _high) _high = _streak;
      } else {
        _running = false;
        _gameOver = true;
        _award();
      }
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        if (!_gameOver) {
          _card = next;
          _suit = _nextSuit!;
          _next = null;
          _nextSuit = null;
        }
      });
    });
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    int reward;
    if (_streak >= 8) {
      reward = 10;
    } else if (_streak >= 5) {
      reward = 5;
    } else if (_streak >= 3) {
      reward = 2;
    } else {
      reward = 0;
    }
    if (reward > 0) {
      ref.read(coinProvider.notifier).award(reward);
    }
  }

  String _cardLabel(int n) {
    switch (n) {
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return '$n';
    }
  }

  Color _suitColor(int s) {
    return (s == 1 || s == 2) ? AppColors.error : AppColors.textDark;
  }

  Widget _card3D({
    required int value,
    required int suit,
    bool faceDown = false,
  }) {
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        color: faceDown ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(2, 4),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: faceDown
          ? const Text('?', style: TextStyle(fontSize: 64, color: Colors.white))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _cardLabel(value),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: _suitColor(suit),
                  ),
                ),
                Text(
                  _suits[suit],
                  style: TextStyle(fontSize: 40, color: _suitColor(suit)),
                ),
              ],
            ),
    );
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
          isAr ? 'أعلى أم أقل' : 'Higher or Lower',
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
                    ? 'هل البطاقة التالية أعلى أم أقل؟ ٢ هي الأقل و١٣ (الملك) هي الأعلى.'
                    : 'Will the next card be higher or lower? 2 is lowest, 13 (King) is highest.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'متتالية' : 'Streak',
                    value: localizeDigits(_streak, arabic: isAr),
                    color: AppColors.success,
                  ),
                  _Pill(
                    label: isAr ? 'الأفضل' : 'Best',
                    value: localizeDigits(_high, arabic: isAr),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_running || _gameOver)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _card3D(value: _card, suit: _suit),
                    const SizedBox(width: 12),
                    if (_next != null)
                      _card3D(value: _next!, suit: _nextSuit ?? 0)
                    else if (_running)
                      _card3D(value: 0, suit: 0, faceDown: true),
                  ],
                ),
              const SizedBox(height: 16),
              if (_msg != null)
                Text(
                  _msg!,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: _msg!.startsWith('✅')
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              const Spacer(),
              if (_running && !_gameOver && _next == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _guess(false),
                      icon: const Icon(Icons.arrow_downward),
                      label: Text(isAr ? 'أقل' : 'Lower'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _guess(true),
                      icon: const Icon(Icons.arrow_upward),
                      label: Text(isAr ? 'أعلى' : 'Higher'),
                    ),
                  ],
                )
              else if (!_running)
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: Icon(_gameOver ? Icons.replay : Icons.play_arrow),
                  label: Text(
                    _gameOver
                        ? (isAr ? 'مرة أخرى' : 'Play again')
                        : (isAr ? 'ابدأ' : 'Start'),
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
