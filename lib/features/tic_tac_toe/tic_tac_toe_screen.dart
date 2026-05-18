import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Tic-Tac-Toe vs CPU — kid plays X, CPU plays O. Three CPU difficulties:
/// Easy = random, Medium = blocks immediate threats, Hard = minimax.
/// Pure Dart, no images. +٢🪙 win, +١🪙 draw, no penalty for loss.
class TicTacToeScreen extends ConsumerStatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

enum _Diff { easy, medium, hard }

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen> {
  List<String> _board = List.filled(9, '');
  bool _xTurn = true;
  String? _winner;
  bool _draw = false;
  _Diff _diff = _Diff.medium;
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;

  void _reset() {
    setState(() {
      _board = List.filled(9, '');
      _xTurn = true;
      _winner = null;
      _draw = false;
    });
  }

  void _tap(int i) {
    if (_board[i].isNotEmpty || _winner != null || !_xTurn) return;
    setState(() {
      _board[i] = 'X';
      _xTurn = false;
    });
    _evaluate();
    if (_winner == null && !_draw) {
      Future.delayed(const Duration(milliseconds: 300), _cpuMove);
    }
  }

  void _cpuMove() {
    if (_winner != null || _draw) return;
    final move = switch (_diff) {
      _Diff.easy => _randomMove(),
      _Diff.medium => _mediumMove(),
      _Diff.hard => _bestMove(),
    };
    if (move == -1) return;
    setState(() {
      _board[move] = 'O';
      _xTurn = true;
    });
    _evaluate();
  }

  int _randomMove() {
    final empties = [
      for (var i = 0; i < 9; i++)
        if (_board[i].isEmpty) i,
    ];
    if (empties.isEmpty) return -1;
    return empties[math.Random().nextInt(empties.length)];
  }

  int _mediumMove() {
    // 1) Win if can. 2) Block X. 3) Take center. 4) Random.
    for (var i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        _board[i] = 'O';
        if (_checkWin('O')) {
          _board[i] = '';
          return i;
        }
        _board[i] = '';
      }
    }
    for (var i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        _board[i] = 'X';
        if (_checkWin('X')) {
          _board[i] = '';
          return i;
        }
        _board[i] = '';
      }
    }
    if (_board[4].isEmpty) return 4;
    return _randomMove();
  }

  int _bestMove() {
    var best = -1;
    var bestScore = -1000;
    for (var i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        _board[i] = 'O';
        final s = _minimax(false);
        _board[i] = '';
        if (s > bestScore) {
          bestScore = s;
          best = i;
        }
      }
    }
    return best;
  }

  int _minimax(bool maxing) {
    if (_checkWin('O')) return 10;
    if (_checkWin('X')) return -10;
    if (!_board.contains('')) return 0;
    if (maxing) {
      var best = -1000;
      for (var i = 0; i < 9; i++) {
        if (_board[i].isEmpty) {
          _board[i] = 'O';
          best = math.max(best, _minimax(false));
          _board[i] = '';
        }
      }
      return best;
    } else {
      var best = 1000;
      for (var i = 0; i < 9; i++) {
        if (_board[i].isEmpty) {
          _board[i] = 'X';
          best = math.min(best, _minimax(true));
          _board[i] = '';
        }
      }
      return best;
    }
  }

  bool _checkWin(String s) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final l in lines) {
      if (_board[l[0]] == s && _board[l[1]] == s && _board[l[2]] == s) {
        return true;
      }
    }
    return false;
  }

  void _evaluate() {
    if (_checkWin('X')) {
      setState(() {
        _winner = 'X';
        _wins += 1;
      });
      ref.read(coinProvider.notifier).award(2);
    } else if (_checkWin('O')) {
      setState(() {
        _winner = 'O';
        _losses += 1;
      });
    } else if (!_board.contains('')) {
      setState(() {
        _draw = true;
        _draws += 1;
      });
      ref.read(coinProvider.notifier).award(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'إكس وأو' : 'Tic-Tac-Toe'),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final d in _Diff.values)
                    ChoiceChip(
                      label: Text(_diffLabel(d, isAr)),
                      selected: _diff == d,
                      onSelected: (_) => setState(() {
                        _diff = d;
                        _reset();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAr
                      ? 'فوز: ${localizeDigits(_wins, arabic: true)} • خسارة: ${localizeDigits(_losses, arabic: true)} • تعادل: ${localizeDigits(_draws, arabic: true)}'
                      : 'W: $_wins • L: $_losses • D: $_draws',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemBuilder: (ctx, i) {
                      final v = _board[i];
                      return InkWell(
                        onTap: () => _tap(i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.outline.withAlpha(80),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            v,
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: v == 'X'
                                  ? AppColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_winner != null || _draw) ...[
                Text(
                  _winner == 'X'
                      ? (isAr ? '🎉 فزت! +٢🪙' : '🎉 You won! +2🪙')
                      : _winner == 'O'
                      ? (isAr ? '🤖 فاز الكمبيوتر' : '🤖 CPU won')
                      : (isAr ? '🤝 تعادل +١🪙' : '🤝 Draw +1🪙'),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.replay_rounded),
                label: Text(isAr ? 'لعبة جديدة' : 'New game'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _diffLabel(_Diff d, bool isAr) {
    switch (d) {
      case _Diff.easy:
        return isAr ? 'سهل' : 'Easy';
      case _Diff.medium:
        return isAr ? 'متوسط' : 'Medium';
      case _Diff.hard:
        return isAr ? 'صعب' : 'Hard';
    }
  }
}
