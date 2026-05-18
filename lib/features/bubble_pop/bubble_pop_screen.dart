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

class BubblePopScreen extends ConsumerStatefulWidget {
  const BubblePopScreen({super.key});

  @override
  ConsumerState<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends ConsumerState<BubblePopScreen> {
  static const _w = 8;
  static const _h = 8;
  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFFBC02D),
  ];

  late List<List<int>> _grid;
  int _score = 0;
  bool _gameOver = false;
  bool _awarded = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final rng = math.Random();
    _grid = List.generate(
      _h,
      (_) => List.generate(_w, (_) => 1 + rng.nextInt(_colors.length)),
    );
    _score = 0;
    _gameOver = false;
    _awarded = false;
  }

  List<List<int>> _flood(int r, int c) {
    final color = _grid[r][c];
    if (color == 0) return [];
    final found = <List<int>>[];
    final stack = <List<int>>[
      [r, c],
    ];
    final seen = <int>{};
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final pr = p[0];
      final pc = p[1];
      final key = pr * _w + pc;
      if (seen.contains(key)) continue;
      seen.add(key);
      if (pr < 0 || pr >= _h || pc < 0 || pc >= _w) continue;
      if (_grid[pr][pc] != color) continue;
      found.add([pr, pc]);
      stack.add([pr - 1, pc]);
      stack.add([pr + 1, pc]);
      stack.add([pr, pc - 1]);
      stack.add([pr, pc + 1]);
    }
    return found;
  }

  void _tap(int r, int c) {
    if (_gameOver || _grid[r][c] == 0) return;
    final group = _flood(r, c);
    if (group.length < 2) return;
    HapticFeedback.lightImpact();
    setState(() {
      for (final p in group) {
        _grid[p[0]][p[1]] = 0;
      }
      _score += group.length * (group.length - 1);
      _gravityAndCompact();
      _checkOver();
      if (_gameOver) _award();
    });
  }

  void _gravityAndCompact() {
    for (var c = 0; c < _w; c++) {
      final col = <int>[];
      for (var r = _h - 1; r >= 0; r--) {
        if (_grid[r][c] != 0) col.add(_grid[r][c]);
      }
      for (var r = 0; r < _h; r++) {
        final i = _h - 1 - r;
        _grid[i][c] = r < col.length ? col[r] : 0;
      }
    }
    final keepCols = <int>[];
    for (var c = 0; c < _w; c++) {
      var any = false;
      for (var r = 0; r < _h; r++) {
        if (_grid[r][c] != 0) {
          any = true;
          break;
        }
      }
      if (any) keepCols.add(c);
    }
    if (keepCols.length == _w) return;
    final newGrid = List.generate(_h, (_) => List.filled(_w, 0));
    for (var nc = 0; nc < keepCols.length; nc++) {
      for (var r = 0; r < _h; r++) {
        newGrid[r][nc] = _grid[r][keepCols[nc]];
      }
    }
    _grid = newGrid;
  }

  void _checkOver() {
    for (var r = 0; r < _h; r++) {
      for (var c = 0; c < _w; c++) {
        if (_grid[r][c] == 0) continue;
        final g = _flood(r, c);
        if (g.length >= 2) return;
      }
    }
    _gameOver = true;
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    int reward;
    if (_score >= 200) {
      reward = 10;
    } else if (_score >= 100) {
      reward = 5;
    } else if (_score >= 40) {
      reward = 2;
    } else {
      reward = 0;
    }
    if (reward > 0) {
      ref.read(coinProvider.notifier).award(reward);
    }
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
          isAr ? 'فقاعات' : 'Bubble Pop',
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
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'اضغط مجموعة من فقاعتين أو أكثر بنفس اللون.'
                    : 'Tap a group of 2+ same-colored bubbles to pop them.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _Pill(
                label: isAr ? 'النقاط' : 'Score',
                value: localizeDigits(_score, arabic: isAr),
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      children: [
                        for (int r = 0; r < _h; r++)
                          Expanded(
                            child: Row(
                              children: [
                                for (int c = 0; c < _w; c++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.5),
                                      child: GestureDetector(
                                        onTap: () => _tap(r, c),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _grid[r][c] == 0
                                                ? Colors.transparent
                                                : _colors[_grid[r][c] - 1],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_gameOver)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Text(
                        isAr
                            ? 'انتهت اللعبة! النقاط: ${localizeDigits(_score, arabic: true)}'
                            : 'Game over! Score: $_score',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => setState(_newGame),
                        icon: const Icon(Icons.replay),
                        label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                      ),
                    ],
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
