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

class SokobanScreen extends ConsumerStatefulWidget {
  const SokobanScreen({super.key});

  @override
  ConsumerState<SokobanScreen> createState() => _SokobanScreenState();
}

class _SokobanScreenState extends ConsumerState<SokobanScreen> {
  // # = wall, . = floor, T = target, B = box, P = player, * = box on target
  static const _levels = <List<String>>[
    ['######', '#.P..#', '#.B..#', '#...T#', '#....#', '######'],
    ['########', '#.P....#', '#.B.B..#', '#......#', '#.T...T#', '########'],
    [
      '########',
      '#......#',
      '#.P.B.T#',
      '#......#',
      '#.B....#',
      '#T.....#',
      '########',
    ],
    [
      '#########',
      '#..T....#',
      '#.......#',
      '#.B.P.B.#',
      '#.......#',
      '#....T..#',
      '#########',
    ],
    [
      '########',
      '#T.....#',
      '#..B...#',
      '#..P.B.#',
      '#......#',
      '#.....T#',
      '########',
    ],
  ];

  late int _level;
  late List<List<String>> _grid;
  late int _px, _py;
  int _moves = 0;
  bool _won = false;
  bool _awarded = false;

  @override
  void initState() {
    super.initState();
    _level = 0;
    _load(_level);
  }

  void _load(int n) {
    final src = _levels[n];
    _grid = src.map((row) => row.split('').toList()).toList();
    _moves = 0;
    _won = false;
    for (var r = 0; r < _grid.length; r++) {
      for (var c = 0; c < _grid[r].length; c++) {
        if (_grid[r][c] == 'P') {
          _px = c;
          _py = r;
          _grid[r][c] = '.';
        }
      }
    }
  }

  bool _isWall(int r, int c) {
    if (r < 0 || r >= _grid.length || c < 0 || c >= _grid[r].length) {
      return true;
    }
    return _grid[r][c] == '#';
  }

  bool _isBox(int r, int c) {
    if (r < 0 || r >= _grid.length || c < 0 || c >= _grid[r].length) {
      return false;
    }
    return _grid[r][c] == 'B' || _grid[r][c] == '*';
  }

  bool _isFloorOrTarget(int r, int c) {
    if (r < 0 || r >= _grid.length || c < 0 || c >= _grid[r].length) {
      return false;
    }
    final v = _grid[r][c];
    return v == '.' || v == 'T';
  }

  void _move(int dx, int dy) {
    if (_won) return;
    final nx = _px + dx;
    final ny = _py + dy;
    if (_isWall(ny, nx)) return;
    if (_isBox(ny, nx)) {
      final bx = nx + dx;
      final by = ny + dy;
      if (_isWall(by, bx)) return;
      if (_isBox(by, bx)) return;
      // push
      final boxOnTarget = _grid[ny][nx] == '*';
      _grid[ny][nx] = boxOnTarget ? 'T' : '.';
      final landingTarget = _grid[by][bx] == 'T';
      _grid[by][bx] = landingTarget ? '*' : 'B';
    } else if (!_isFloorOrTarget(ny, nx)) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _px = nx;
      _py = ny;
      _moves += 1;
      _checkWin();
    });
  }

  void _checkWin() {
    for (final row in _grid) {
      for (final cell in row) {
        if (cell == 'B') return;
      }
    }
    _won = true;
    _award();
  }

  void _next() {
    if (_level + 1 < _levels.length) {
      setState(() {
        _level += 1;
        _load(_level);
      });
    }
  }

  void _restart() {
    setState(() => _load(_level));
  }

  void _award() {
    if (_awarded) return;
    HapticFeedback.heavyImpact();
    final reward = (_level + 1) * 2;
    ref.read(coinProvider.notifier).award(reward);
    if (_level == _levels.length - 1) {
      _awarded = true;
      ref.read(coinProvider.notifier).award(10);
    }
  }

  Widget _cell(int r, int c) {
    final v = _grid[r][c];
    Color color;
    String? emoji;
    final isPlayer = r == _py && c == _px;
    if (v == '#') {
      color = AppColors.outline;
    } else if (v == 'T') {
      color = AppColors.surfaceContainer;
      emoji = '🎯';
    } else if (v == 'B') {
      color = AppColors.surfaceContainer;
      emoji = '📦';
    } else if (v == '*') {
      color = AppColors.success.withValues(alpha: 0.4);
      emoji = '📦';
    } else {
      color = AppColors.surfaceContainer;
    }
    if (isPlayer) emoji = '🧑';
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 22))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final rows = _grid.length;
    final cols = _grid[0].length;
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
          isAr ? 'دفع الصناديق' : 'Sokoban',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isAr ? 'إعادة' : 'Restart',
            onPressed: _restart,
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
                    ? 'ادفع الصناديق على الأهداف. لا تشد، فقط ادفع.'
                    : 'Push boxes onto targets. You can only push, not pull.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'المرحلة' : 'Level',
                    value:
                        '${localizeDigits(_level + 1, arabic: isAr)}/${localizeDigits(_levels.length, arabic: isAr)}',
                    color: AppColors.primary,
                  ),
                  _Pill(
                    label: isAr ? 'حركات' : 'Moves',
                    value: localizeDigits(_moves, arabic: isAr),
                    color: AppColors.textDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: cols / rows,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      children: [
                        for (int r = 0; r < rows; r++)
                          Expanded(
                            child: Row(
                              children: [
                                for (int c = 0; c < cols; c++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(1),
                                      child: _cell(r, c),
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
              if (_won)
                Column(
                  children: [
                    Text(
                      isAr ? '🏆 أحسنت!' : '🏆 Solved!',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_level + 1 < _levels.length)
                      ElevatedButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.skip_next),
                        label: Text(isAr ? 'المرحلة التالية' : 'Next level'),
                      )
                    else
                      Text(
                        isAr ? 'أنهيت كل المراحل!' : 'You finished all levels!',
                        style: AppTextStyles.bodyMedium,
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    IconButton.filled(
                      onPressed: () => _move(0, -1),
                      icon: const Icon(Icons.arrow_upward, size: 28),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: () => _move(-1, 0),
                          icon: const Icon(Icons.arrow_back, size: 28),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () => _move(0, 1),
                          icon: const Icon(Icons.arrow_downward, size: 28),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () => _move(1, 0),
                          icon: const Icon(Icons.arrow_forward, size: 28),
                        ),
                      ],
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
