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

class TetrisLiteScreen extends ConsumerStatefulWidget {
  const TetrisLiteScreen({super.key});

  @override
  ConsumerState<TetrisLiteScreen> createState() => _TetrisLiteScreenState();
}

class _TetrisLiteScreenState extends ConsumerState<TetrisLiteScreen> {
  static const _w = 8;
  static const _h = 14;

  static const _shapes = <List<List<List<int>>>>[
    [
      [
        [1, 1, 1, 1],
      ],
      [
        [1],
        [1],
        [1],
        [1],
      ],
    ],
    [
      [
        [1, 1],
        [1, 1],
      ],
    ],
    [
      [
        [0, 1, 0],
        [1, 1, 1],
      ],
      [
        [1, 0],
        [1, 1],
        [1, 0],
      ],
      [
        [1, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 1],
        [1, 1],
        [0, 1],
      ],
    ],
    [
      [
        [0, 1, 1],
        [1, 1, 0],
      ],
      [
        [1, 0],
        [1, 1],
        [0, 1],
      ],
    ],
    [
      [
        [1, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 1],
        [1, 1],
        [1, 0],
      ],
    ],
    [
      [
        [1, 0],
        [1, 0],
        [1, 1],
      ],
      [
        [1, 1, 1],
        [1, 0, 0],
      ],
      [
        [1, 1],
        [0, 1],
        [0, 1],
      ],
      [
        [0, 0, 1],
        [1, 1, 1],
      ],
    ],
    [
      [
        [0, 1],
        [0, 1],
        [1, 1],
      ],
      [
        [1, 0, 0],
        [1, 1, 1],
      ],
      [
        [1, 1],
        [1, 0],
        [1, 0],
      ],
      [
        [1, 1, 1],
        [0, 0, 1],
      ],
    ],
  ];

  static const _colors = [
    Color(0xFF00BCD4),
    Color(0xFFFFD600),
    Color(0xFF9C27B0),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFF3F51B5),
  ];

  late List<List<int>> _grid;
  Timer? _ticker;
  int _piece = 0;
  int _rot = 0;
  int _px = 0;
  int _py = 0;
  int _score = 0;
  int _lines = 0;
  int _level = 1;
  bool _running = false;
  bool _gameOver = false;
  bool _w10 = false, _w25 = false, _w50 = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _reset() {
    _grid = List.generate(_h, (_) => List.filled(_w, 0));
    _score = 0;
    _lines = 0;
    _level = 1;
    _gameOver = false;
    _running = false;
    _w10 = _w25 = _w50 = false;
    _spawn();
  }

  Duration get _tickInterval =>
      Duration(milliseconds: math.max(120, 600 - (_level - 1) * 60));

  void _spawn() {
    final rng = math.Random();
    _piece = rng.nextInt(_shapes.length);
    _rot = 0;
    final shape = _shapes[_piece][_rot];
    _px = (_w - shape[0].length) ~/ 2;
    _py = 0;
    if (_collides(shape, _px, _py)) {
      _gameOver = true;
      _running = false;
      _ticker?.cancel();
      _award();
    }
  }

  bool _collides(List<List<int>> shape, int x, int y) {
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final nx = x + c;
        final ny = y + r;
        if (nx < 0 || nx >= _w || ny >= _h) return true;
        if (ny >= 0 && _grid[ny][nx] != 0) return true;
      }
    }
    return false;
  }

  void _merge() {
    final shape = _shapes[_piece][_rot];
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final ny = _py + r;
        if (ny >= 0 && ny < _h) _grid[ny][_px + c] = _piece + 1;
      }
    }
    _clear();
    _spawn();
  }

  void _clear() {
    final keep = <List<int>>[];
    var cleared = 0;
    for (final row in _grid) {
      if (row.every((v) => v != 0)) {
        cleared++;
      } else {
        keep.add(row);
      }
    }
    if (cleared > 0) {
      HapticFeedback.lightImpact();
      _lines += cleared;
      _score += [0, 40, 100, 300, 1200][cleared] * _level;
      _level = 1 + _lines ~/ 5;
      while (keep.length < _h) {
        keep.insert(0, List.filled(_w, 0));
      }
      _grid = keep;
      _ticker?.cancel();
      _ticker = Timer.periodic(_tickInterval, (_) => _step());
    }
  }

  void _step() {
    if (!_running || _gameOver) return;
    setState(() {
      final shape = _shapes[_piece][_rot];
      if (!_collides(shape, _px, _py + 1)) {
        _py += 1;
      } else {
        _merge();
      }
    });
  }

  void _move(int dx) {
    if (!_running || _gameOver) return;
    setState(() {
      final shape = _shapes[_piece][_rot];
      if (!_collides(shape, _px + dx, _py)) _px += dx;
    });
  }

  void _rotate() {
    if (!_running || _gameOver) return;
    setState(() {
      final next = (_rot + 1) % _shapes[_piece].length;
      final shape = _shapes[_piece][next];
      if (!_collides(shape, _px, _py)) _rot = next;
    });
  }

  void _drop() {
    if (!_running || _gameOver) return;
    setState(() {
      final shape = _shapes[_piece][_rot];
      while (!_collides(shape, _px, _py + 1)) {
        _py += 1;
      }
      _merge();
    });
  }

  void _start() {
    setState(_reset);
    _running = true;
    _ticker = Timer.periodic(_tickInterval, (_) => _step());
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_lines >= 5 && !_w10) {
      _w10 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_lines >= 10 && !_w25) {
      _w25 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_lines >= 20 && !_w50) {
      _w50 = true;
      ref.read(coinProvider.notifier).award(10);
    }
  }

  Color _cellColor(int r, int c) {
    final v = _grid[r][c];
    if (v != 0) return _colors[v - 1];
    final shape = _shapes[_piece][_rot];
    final lr = r - _py;
    final lc = c - _px;
    if (lr >= 0 &&
        lr < shape.length &&
        lc >= 0 &&
        lc < shape[lr].length &&
        shape[lr][lc] == 1) {
      return _colors[_piece];
    }
    return Colors.transparent;
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
          isAr ? 'تتريس' : 'Tetris-lite',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'النقاط' : 'Score',
                    value: localizeDigits(_score, arabic: isAr),
                    color: AppColors.success,
                  ),
                  _Pill(
                    label: isAr ? 'السطور' : 'Lines',
                    value: localizeDigits(_lines, arabic: isAr),
                    color: AppColors.textDark,
                  ),
                  _Pill(
                    label: isAr ? 'المستوى' : 'Level',
                    value: localizeDigits(_level, arabic: isAr),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: _w / _h,
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
                                      padding: const EdgeInsets.all(1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              _cellColor(r, c) ==
                                                  Colors.transparent
                                              ? AppColors.background.withValues(
                                                  alpha: 0.4,
                                                )
                                              : _cellColor(r, c),
                                          borderRadius: BorderRadius.circular(
                                            2,
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
              const SizedBox(height: 12),
              if (!_running)
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: Icon(_gameOver ? Icons.replay : Icons.play_arrow),
                  label: Text(
                    _gameOver
                        ? (isAr ? 'مرة أخرى' : 'Play again')
                        : (isAr ? 'ابدأ' : 'Start'),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CtrlButton(
                      icon: Icons.arrow_left,
                      onPressed: () => _move(-1),
                    ),
                    _CtrlButton(icon: Icons.rotate_right, onPressed: _rotate),
                    _CtrlButton(icon: Icons.arrow_drop_down, onPressed: _step),
                    _CtrlButton(
                      icon: Icons.keyboard_double_arrow_down,
                      onPressed: _drop,
                    ),
                    _CtrlButton(
                      icon: Icons.arrow_right,
                      onPressed: () => _move(1),
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

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return IconButton.filled(onPressed: onPressed, icon: Icon(icon, size: 28));
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
