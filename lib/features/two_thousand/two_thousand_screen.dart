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

/// 2048 — slide tiles to merge equal numbers. Reach the 2048 tile to win.
/// 4×4 grid. +٢🪙 every time the highest tile doubles past 256, +٥🪙 first
/// time you cross 1024, +١٠🪙 reaching 2048.
class TwoThousandScreen extends ConsumerStatefulWidget {
  const TwoThousandScreen({super.key});

  @override
  ConsumerState<TwoThousandScreen> createState() => _TwoThousandScreenState();
}

class _TwoThousandScreenState extends ConsumerState<TwoThousandScreen> {
  static const int _n = 4;
  late List<List<int>> _grid;
  int _score = 0;
  int _best = 0;
  int _highest = 0;
  bool _won = false;
  bool _crossed1024 = false;
  bool _gameOver = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _grid = List.generate(_n, (_) => List.filled(_n, 0));
      _score = 0;
      _highest = 0;
      _won = false;
      _crossed1024 = false;
      _gameOver = false;
    });
    _spawn();
    _spawn();
  }

  void _spawn() {
    final empty = <math.Point<int>>[];
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c] == 0) empty.add(math.Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final p = empty[math.Random().nextInt(empty.length)];
    _grid[p.x][p.y] = math.Random().nextDouble() < 0.9 ? 2 : 4;
  }

  bool _slideRow(List<int> row) {
    final nz = row.where((v) => v != 0).toList();
    var moved = nz.length != row.where((v) => v != 0).length;
    final merged = <int>[];
    var i = 0;
    while (i < nz.length) {
      if (i + 1 < nz.length && nz[i] == nz[i + 1]) {
        final v = nz[i] * 2;
        merged.add(v);
        _score += v;
        if (v > _highest) _highest = v;
        if (v == 2048 && !_won) {
          _won = true;
          ref.read(coinProvider.notifier).award(10);
        }
        if (v >= 1024 && !_crossed1024) {
          _crossed1024 = true;
          ref.read(coinProvider.notifier).award(5);
        } else if (v >= 512 && v % 256 == 0) {
          ref.read(coinProvider.notifier).award(2);
        }
        i += 2;
        moved = true;
      } else {
        merged.add(nz[i]);
        i += 1;
      }
    }
    while (merged.length < _n) {
      merged.add(0);
    }
    var changed = false;
    for (var k = 0; k < _n; k++) {
      if (row[k] != merged[k]) changed = true;
      row[k] = merged[k];
    }
    return changed || moved;
  }

  void _move(_Dir d) {
    if (_gameOver) return;
    var changed = false;
    for (var i = 0; i < _n; i++) {
      List<int> line;
      if (d == _Dir.left) {
        line = _grid[i];
      } else if (d == _Dir.right) {
        line = _grid[i].reversed.toList();
      } else if (d == _Dir.up) {
        line = [for (var r = 0; r < _n; r++) _grid[r][i]];
      } else {
        line = [for (var r = _n - 1; r >= 0; r--) _grid[r][i]];
      }
      if (_slideRow(line)) changed = true;
      if (d == _Dir.right) line = line.reversed.toList();
      if (d == _Dir.up) {
        for (var r = 0; r < _n; r++) {
          _grid[r][i] = line[r];
        }
      } else if (d == _Dir.down) {
        for (var r = 0; r < _n; r++) {
          _grid[_n - 1 - r][i] = line[r];
        }
      } else {
        _grid[i] = line;
      }
    }
    if (changed) {
      HapticFeedback.selectionClick();
      _spawn();
      if (_score > _best) _best = _score;
      _gameOver = !_canMove();
      setState(() {});
    }
  }

  bool _canMove() {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c] == 0) return true;
        if (c + 1 < _n && _grid[r][c] == _grid[r][c + 1]) return true;
        if (r + 1 < _n && _grid[r][c] == _grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent ev) {
    if (ev is! KeyDownEvent) return KeyEventResult.ignored;
    final k = ev.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) _move(_Dir.left);
    if (k == LogicalKeyboardKey.arrowRight) _move(_Dir.right);
    if (k == LogicalKeyboardKey.arrowUp) _move(_Dir.up);
    if (k == LogicalKeyboardKey.arrowDown) _move(_Dir.down);
    return KeyEventResult.handled;
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
        title: Text(isAr ? '٢٠٤٨' : '2048', style: AppTextStyles.headingSmall),
        actions: [
          TextButton.icon(
            onPressed: _newGame,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: Text(
              isAr ? 'جديدة' : 'New',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(
                      label: isAr ? 'النقاط' : 'Score',
                      value: localizeDigits(_score, arabic: isAr),
                    ),
                    _Stat(
                      label: isAr ? 'الأفضل' : 'Best',
                      value: localizeDigits(_best, arabic: isAr),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'اسحب لدمج المربعات. اوصل إلى ٢٠٤٨!'
                      : 'Swipe to merge. Reach 2048 to win!',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onHorizontalDragEnd: (d) {
                      if (d.primaryVelocity == null) return;
                      if (d.primaryVelocity! > 0) {
                        _move(isAr ? _Dir.left : _Dir.right);
                      } else {
                        _move(isAr ? _Dir.right : _Dir.left);
                      }
                    },
                    onVerticalDragEnd: (d) {
                      if (d.primaryVelocity == null) return;
                      if (d.primaryVelocity! > 0) {
                        _move(_Dir.down);
                      } else {
                        _move(_Dir.up);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _n,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                            ),
                        itemCount: _n * _n,
                        itemBuilder: (context, i) {
                          final r = i ~/ _n;
                          final c = i % _n;
                          return _Tile(value: _grid[r][c], isAr: isAr);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_won)
                  Text(
                    isAr
                        ? '🎉 وصلت إلى ٢٠٤٨! +١٠🪙'
                        : '🎉 You reached 2048! +10🪙',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.success,
                    ),
                  )
                else if (_gameOver)
                  Text(
                    isAr ? 'انتهت اللعبة!' : 'Game over!',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Dir { left, right, up, down }

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.headingSmall),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.isAr});
  final int value;
  final bool isAr;

  Color _bg() {
    if (value == 0) return AppColors.surface;
    if (value == 2) return const Color(0xFFEEE4DA);
    if (value == 4) return const Color(0xFFEDE0C8);
    if (value == 8) return const Color(0xFFF2B179);
    if (value == 16) return const Color(0xFFF59563);
    if (value == 32) return const Color(0xFFF67C5F);
    if (value == 64) return const Color(0xFFF65E3B);
    if (value == 128) return const Color(0xFFEDCF72);
    if (value == 256) return const Color(0xFFEDCC61);
    if (value == 512) return const Color(0xFFEDC850);
    if (value == 1024) return const Color(0xFFEDC53F);
    return const Color(0xFFEDC22E);
  }

  Color _fg() {
    if (value <= 4) return const Color(0xFF776E65);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: value == 0
          ? const SizedBox.shrink()
          : Text(
              localizeDigits(value, arabic: isAr),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: value < 100
                    ? 28
                    : value < 1000
                    ? 24
                    : 18,
                color: _fg(),
              ),
            ),
    );
  }
}
