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

class DotsBoxesScreen extends ConsumerStatefulWidget {
  const DotsBoxesScreen({super.key});

  @override
  ConsumerState<DotsBoxesScreen> createState() => _DotsBoxesScreenState();
}

class _DotsBoxesScreenState extends ConsumerState<DotsBoxesScreen> {
  static const _n = 4;

  late List<List<bool>> _h;
  late List<List<bool>> _v;
  late List<List<int>> _owner;
  bool _playerTurn = true;
  int _playerScore = 0;
  int _cpuScore = 0;
  bool _gameOver = false;
  bool _awarded = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _h = List.generate(_n + 1, (_) => List.filled(_n, false));
    _v = List.generate(_n, (_) => List.filled(_n + 1, false));
    _owner = List.generate(_n, (_) => List.filled(_n, 0));
    _playerTurn = true;
    _playerScore = 0;
    _cpuScore = 0;
    _gameOver = false;
    _awarded = false;
  }

  int _boxSides(int r, int c) {
    var n = 0;
    if (_h[r][c]) n++;
    if (_h[r + 1][c]) n++;
    if (_v[r][c]) n++;
    if (_v[r][c + 1]) n++;
    return n;
  }

  bool _placeH(int r, int c, int player) {
    if (_h[r][c]) return false;
    _h[r][c] = true;
    var claimed = false;
    if (r > 0 && _boxSides(r - 1, c) == 4) {
      _owner[r - 1][c] = player;
      claimed = true;
    }
    if (r < _n && _boxSides(r, c) == 4) {
      _owner[r][c] = player;
      claimed = true;
    }
    return claimed;
  }

  bool _placeV(int r, int c, int player) {
    if (_v[r][c]) return false;
    _v[r][c] = true;
    var claimed = false;
    if (c > 0 && _boxSides(r, c - 1) == 4) {
      _owner[r][c - 1] = player;
      claimed = true;
    }
    if (c < _n && _boxSides(r, c) == 4) {
      _owner[r][c] = player;
      claimed = true;
    }
    return claimed;
  }

  void _checkOver() {
    var total = 0;
    var p = 0;
    var cpu = 0;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_owner[r][c] == 1) p++;
        if (_owner[r][c] == 2) cpu++;
        if (_owner[r][c] != 0) total++;
      }
    }
    _playerScore = p;
    _cpuScore = cpu;
    if (total == _n * _n) {
      _gameOver = true;
      if (_playerScore > _cpuScore) _award();
    }
  }

  void _tapH(int r, int c) {
    if (_gameOver || !_playerTurn || _h[r][c]) return;
    HapticFeedback.lightImpact();
    setState(() {
      final claimed = _placeH(r, c, 1);
      _checkOver();
      if (!claimed) _playerTurn = false;
    });
    if (!_playerTurn && !_gameOver) {
      Future.delayed(const Duration(milliseconds: 350), _cpuMove);
    }
  }

  void _tapV(int r, int c) {
    if (_gameOver || !_playerTurn || _v[r][c]) return;
    HapticFeedback.lightImpact();
    setState(() {
      final claimed = _placeV(r, c, 1);
      _checkOver();
      if (!claimed) _playerTurn = false;
    });
    if (!_playerTurn && !_gameOver) {
      Future.delayed(const Duration(milliseconds: 350), _cpuMove);
    }
  }

  /// Pick a move that closes a box if possible; else a "safe" move
  /// that doesn't leave a 3-sided box for the player; else any random.
  ({String type, int r, int c})? _pickCpuMove() {
    final closing = <({String type, int r, int c})>[];
    final safe = <({String type, int r, int c})>[];
    final any = <({String type, int r, int c})>[];
    for (var r = 0; r <= _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_h[r][c]) continue;
        any.add((type: 'h', r: r, c: c));
        var closes = false;
        var leaves3 = false;
        if (r > 0) {
          final s = _boxSides(r - 1, c);
          if (s == 3) closes = true;
          if (s == 2) leaves3 = true;
        }
        if (r < _n) {
          final s = _boxSides(r, c);
          if (s == 3) closes = true;
          if (s == 2) leaves3 = true;
        }
        if (closes) {
          closing.add((type: 'h', r: r, c: c));
        } else if (!leaves3) {
          safe.add((type: 'h', r: r, c: c));
        }
      }
    }
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c <= _n; c++) {
        if (_v[r][c]) continue;
        any.add((type: 'v', r: r, c: c));
        var closes = false;
        var leaves3 = false;
        if (c > 0) {
          final s = _boxSides(r, c - 1);
          if (s == 3) closes = true;
          if (s == 2) leaves3 = true;
        }
        if (c < _n) {
          final s = _boxSides(r, c);
          if (s == 3) closes = true;
          if (s == 2) leaves3 = true;
        }
        if (closes) {
          closing.add((type: 'v', r: r, c: c));
        } else if (!leaves3) {
          safe.add((type: 'v', r: r, c: c));
        }
      }
    }
    final rng = math.Random();
    if (closing.isNotEmpty) return closing[rng.nextInt(closing.length)];
    if (safe.isNotEmpty) return safe[rng.nextInt(safe.length)];
    if (any.isNotEmpty) return any[rng.nextInt(any.length)];
    return null;
  }

  void _cpuMove() {
    if (_gameOver) return;
    final move = _pickCpuMove();
    if (move == null) return;
    setState(() {
      bool claimed;
      if (move.type == 'h') {
        claimed = _placeH(move.r, move.c, 2);
      } else {
        claimed = _placeV(move.r, move.c, 2);
      }
      _checkOver();
      if (claimed && !_gameOver) {
        Future.delayed(const Duration(milliseconds: 350), _cpuMove);
      } else {
        _playerTurn = true;
      }
    });
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    final margin = _playerScore - _cpuScore;
    int reward;
    if (margin >= 8) {
      reward = 10;
    } else if (margin >= 4) {
      reward = 5;
    } else {
      reward = 2;
    }
    ref.read(coinProvider.notifier).award(reward);
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
          isAr ? 'النقاط والصناديق' : 'Dots and Boxes',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_newGame),
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
                    ? 'ارسم خطًا. أكمل الصندوق لتربحه ولتلعب مرة أخرى.'
                    : 'Draw a line. Close a box to claim it and play again.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'أنت' : 'You',
                    value: localizeDigits(_playerScore, arabic: isAr),
                    color: AppColors.success,
                  ),
                  _Pill(
                    label: isAr ? 'العدو' : 'CPU',
                    value: localizeDigits(_cpuScore, arabic: isAr),
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _gameOver
                    ? (_playerScore > _cpuScore
                          ? (isAr ? '🏆 فزت' : '🏆 You won')
                          : _playerScore < _cpuScore
                          ? (isAr ? '😢 خسرت' : '😢 You lost')
                          : (isAr ? 'تعادل' : 'Draw'))
                    : (_playerTurn
                          ? (isAr ? 'دورك' : 'Your turn')
                          : (isAr ? 'دور العدو…' : 'CPU thinking…')),
                style: AppTextStyles.headingSmall.copyWith(
                  color: _playerTurn || _gameOver
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final size = math.min(c.maxWidth, c.maxHeight);
                      final step = size / _n;
                      final dot = step * 0.18;
                      return SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          children: [
                            for (int r = 0; r < _n; r++)
                              for (int cc = 0; cc < _n; cc++)
                                Positioned(
                                  left: cc * step + dot,
                                  top: r * step + dot,
                                  width: step - dot * 2,
                                  height: step - dot * 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _owner[r][cc] == 1
                                          ? AppColors.success.withValues(
                                              alpha: 0.4,
                                            )
                                          : _owner[r][cc] == 2
                                          ? AppColors.error.withValues(
                                              alpha: 0.4,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            for (int r = 0; r <= _n; r++)
                              for (int cc = 0; cc < _n; cc++)
                                Positioned(
                                  left: cc * step + dot,
                                  top: r * step - dot * 0.6,
                                  width: step - dot * 2,
                                  height: dot * 1.2,
                                  child: GestureDetector(
                                    onTap: () => _tapH(r, cc),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _h[r][cc]
                                            ? AppColors.primary
                                            : AppColors.surfaceContainer,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                            for (int r = 0; r < _n; r++)
                              for (int cc = 0; cc <= _n; cc++)
                                Positioned(
                                  left: cc * step - dot * 0.6,
                                  top: r * step + dot,
                                  width: dot * 1.2,
                                  height: step - dot * 2,
                                  child: GestureDetector(
                                    onTap: () => _tapV(r, cc),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _v[r][cc]
                                            ? AppColors.primary
                                            : AppColors.surfaceContainer,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                            for (int r = 0; r <= _n; r++)
                              for (int cc = 0; cc <= _n; cc++)
                                Positioned(
                                  left: cc * step - dot * 0.6,
                                  top: r * step - dot * 0.6,
                                  width: dot * 1.2,
                                  height: dot * 1.2,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_gameOver)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(_newGame),
                    icon: const Icon(Icons.replay),
                    label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                  ),
                ),
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
