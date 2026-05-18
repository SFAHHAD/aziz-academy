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

/// Mastermind / Code Breaker — guess the secret 4-color code in ١٠ tries.
/// Feedback per guess: black peg = right color in right slot,
/// white peg = right color but wrong slot.
/// +٢🪙 first solve, +٥🪙 solve in ≤ ٦ tries, +١٠🪙 solve in ≤ ٤ tries.
class MastermindScreen extends ConsumerStatefulWidget {
  const MastermindScreen({super.key});

  @override
  ConsumerState<MastermindScreen> createState() => _MastermindScreenState();
}

class _MastermindScreenState extends ConsumerState<MastermindScreen> {
  static const _palette = <Color>[
    Color(0xFFE53935), // red
    Color(0xFFFB8C00), // orange
    Color(0xFFFDD835), // yellow
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFF8E24AA), // purple
  ];
  static const _maxTries = 10;
  static const _slots = 4;

  final List<int> _secret = [];
  final List<List<int>> _guesses = [];
  final List<List<int>> _feedback = []; // [black, white]
  List<int> _current = List<int>.filled(_slots, -1);
  bool _won = false;
  bool _lost = false;
  int _selectedSlot = 0;
  bool _firstWin = false, _solved6 = false, _solved4 = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final rng = math.Random();
    setState(() {
      _secret
        ..clear()
        ..addAll(
          List<int>.generate(_slots, (_) => rng.nextInt(_palette.length)),
        );
      _guesses.clear();
      _feedback.clear();
      _current = List<int>.filled(_slots, -1);
      _won = false;
      _lost = false;
      _selectedSlot = 0;
    });
  }

  void _pickColor(int color) {
    if (_won || _lost) return;
    HapticFeedback.selectionClick();
    setState(() {
      _current[_selectedSlot] = color;
      _selectedSlot = (_selectedSlot + 1) % _slots;
    });
  }

  void _submit() {
    if (_current.contains(-1)) return;
    final guess = List<int>.from(_current);
    int black = 0, white = 0;
    final secCounts = <int, int>{};
    final gusCounts = <int, int>{};
    for (var i = 0; i < _slots; i++) {
      if (guess[i] == _secret[i]) {
        black += 1;
      } else {
        secCounts[_secret[i]] = (secCounts[_secret[i]] ?? 0) + 1;
        gusCounts[guess[i]] = (gusCounts[guess[i]] ?? 0) + 1;
      }
    }
    for (final entry in gusCounts.entries) {
      white += math.min(entry.value, secCounts[entry.key] ?? 0);
    }
    setState(() {
      _guesses.add(guess);
      _feedback.add([black, white]);
      _current = List<int>.filled(_slots, -1);
      _selectedSlot = 0;
      if (black == _slots) {
        _won = true;
        _award();
      } else if (_guesses.length >= _maxTries) {
        _lost = true;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (!_firstWin) {
      _firstWin = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (!_solved6 && _guesses.length <= 6) {
      _solved6 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (!_solved4 && _guesses.length <= 4) {
      _solved4 = true;
      ref.read(coinProvider.notifier).award(10);
    }
  }

  Widget _peg(int? color, {double size = 28, bool selected = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color == null ? AppColors.surfaceContainerHigh : _palette[color],
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outline,
          width: selected ? 2 : 1,
        ),
      ),
    );
  }

  Widget _feedbackPegs(int black, int white) {
    final pegs = <Widget>[];
    for (var i = 0; i < black; i++) {
      pegs.add(_smallPeg(AppColors.success));
    }
    for (var i = 0; i < white; i++) {
      pegs.add(_smallPeg(AppColors.warning));
    }
    while (pegs.length < _slots) {
      pegs.add(_smallPeg(AppColors.surfaceContainerHigh));
    }
    return Wrap(spacing: 4, runSpacing: 4, children: pegs);
  }

  Widget _smallPeg(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final triesLeft = _maxTries - _guesses.length;
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
          isAr ? 'كاسر الشيفرة' : 'Code Breaker',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isAr ? 'لعبة جديدة' : 'New game',
            onPressed: _newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'احزر الشيفرة المكونة من ٤ ألوان. النقطة الخضراء = اللون والمكان صحيحان، النقطة الذهبية = اللون صحيح والمكان خطأ.'
                    : 'Guess the 4-color code. Green peg = right color & spot, gold peg = right color but wrong spot.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${isAr ? "محاولات متبقية" : "Tries left"}: ${localizeDigits(triesLeft, arabic: isAr)}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _guesses.length,
                  itemBuilder: (context, idx) {
                    final i = _guesses.length - 1 - idx;
                    final g = _guesses[i];
                    final f = _feedback[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${localizeDigits(i + 1, arabic: isAr)}.',
                            style: AppTextStyles.labelSmall,
                          ),
                          const SizedBox(width: 8),
                          for (final c in g) ...[
                            _peg(c, size: 24),
                            const SizedBox(width: 4),
                          ],
                          const SizedBox(width: 8),
                          SizedBox(width: 36, child: _feedbackPegs(f[0], f[1])),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_won) ...[
                Text(
                  isAr
                      ? 'فزت في ${localizeDigits(_guesses.length, arabic: true)} محاولة! 🎉'
                      : 'Solved in $_guesses.length tries! 🎉',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (_lost) ...[
                Text(
                  isAr ? 'انتهت المحاولات' : 'Out of tries',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'الشيفرة: ' : 'Code: ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    for (final c in _secret) ...[
                      _peg(c, size: 18),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Current guess row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slots; i++) ...[
                      GestureDetector(
                        onTap: () => setState(() => _selectedSlot = i),
                        child: _peg(
                          _current[i] == -1 ? null : _current[i],
                          selected: i == _selectedSlot,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _current.contains(-1) ? null : _submit,
                      child: Text(isAr ? 'تحقق' : 'Submit'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    for (var c = 0; c < _palette.length; c++)
                      GestureDetector(
                        onTap: () => _pickColor(c),
                        child: _peg(c, size: 36),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
