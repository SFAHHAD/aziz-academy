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

class BattleshipScreen extends ConsumerStatefulWidget {
  const BattleshipScreen({super.key});

  @override
  ConsumerState<BattleshipScreen> createState() => _BattleshipScreenState();
}

class _BattleshipScreenState extends ConsumerState<BattleshipScreen> {
  static const _size = 6;
  static const _ships = [3, 2, 2];

  late List<List<int>> _enemy;
  late List<List<int>> _player;
  late List<List<int>> _enemyHits;
  late List<List<int>> _playerHits;
  bool _gameOver = false;
  bool _playerWon = false;
  int _playerShots = 0;
  int _cpuShots = 0;
  bool _awarded = false;
  final List<List<int>> _cpuQueue = [];

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _enemy = List.generate(_size, (_) => List.filled(_size, 0));
    _player = List.generate(_size, (_) => List.filled(_size, 0));
    _enemyHits = List.generate(_size, (_) => List.filled(_size, 0));
    _playerHits = List.generate(_size, (_) => List.filled(_size, 0));
    _placeShips(_enemy);
    _placeShips(_player);
    _gameOver = false;
    _playerWon = false;
    _playerShots = 0;
    _cpuShots = 0;
    _awarded = false;
    _cpuQueue.clear();
  }

  void _placeShips(List<List<int>> grid) {
    final rng = math.Random();
    for (final len in _ships) {
      while (true) {
        final horiz = rng.nextBool();
        final r = rng.nextInt(horiz ? _size : _size - len + 1);
        final c = rng.nextInt(horiz ? _size - len + 1 : _size);
        var ok = true;
        for (var i = 0; i < len; i++) {
          final rr = horiz ? r : r + i;
          final cc = horiz ? c + i : c;
          if (grid[rr][cc] != 0) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        for (var i = 0; i < len; i++) {
          final rr = horiz ? r : r + i;
          final cc = horiz ? c + i : c;
          grid[rr][cc] = 1;
        }
        break;
      }
    }
  }

  bool _allSunk(List<List<int>> ships, List<List<int>> hits) {
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (ships[r][c] == 1 && hits[r][c] != 1) return false;
      }
    }
    return true;
  }

  void _playerTap(int r, int c) {
    if (_gameOver) return;
    if (_enemyHits[r][c] != 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _playerShots += 1;
      final hit = _enemy[r][c] == 1;
      _enemyHits[r][c] = hit ? 1 : 2;
    });
    if (_allSunk(_enemy, _enemyHits)) {
      setState(() {
        _gameOver = true;
        _playerWon = true;
        _award();
      });
      return;
    }
    Future.delayed(const Duration(milliseconds: 350), _cpuTurn);
  }

  void _cpuTurn() {
    if (_gameOver) return;
    final rng = math.Random();
    int r;
    int c;
    if (_cpuQueue.isNotEmpty) {
      final pick = _cpuQueue.removeAt(0);
      r = pick[0];
      c = pick[1];
      if (_playerHits[r][c] != 0) {
        _cpuTurn();
        return;
      }
    } else {
      do {
        r = rng.nextInt(_size);
        c = rng.nextInt(_size);
      } while (_playerHits[r][c] != 0);
    }
    setState(() {
      _cpuShots += 1;
      final hit = _player[r][c] == 1;
      _playerHits[r][c] = hit ? 1 : 2;
      if (hit) {
        for (final d in [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ]) {
          final nr = r + d[0];
          final nc = c + d[1];
          if (nr >= 0 &&
              nr < _size &&
              nc >= 0 &&
              nc < _size &&
              _playerHits[nr][nc] == 0) {
            _cpuQueue.add([nr, nc]);
          }
        }
      }
    });
    if (_allSunk(_player, _playerHits)) {
      setState(() {
        _gameOver = true;
        _playerWon = false;
      });
    }
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    final shipsCells = _ships.fold<int>(0, (a, b) => a + b);
    final misses = _playerShots - shipsCells;
    int reward;
    if (misses <= 8) {
      reward = 10;
    } else if (misses <= 16) {
      reward = 5;
    } else {
      reward = 2;
    }
    ref.read(coinProvider.notifier).award(reward);
  }

  Color _enemyCell(int r, int c) {
    final h = _enemyHits[r][c];
    if (h == 1) return AppColors.error;
    if (h == 2) return AppColors.surfaceContainer;
    return AppColors.primary.withValues(alpha: 0.4);
  }

  Color _playerCell(int r, int c) {
    final h = _playerHits[r][c];
    final ship = _player[r][c] == 1;
    if (h == 1) return AppColors.error;
    if (h == 2) return AppColors.surfaceContainer;
    return ship ? AppColors.success : AppColors.primary.withValues(alpha: 0.25);
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
          isAr ? 'حرب البحار' : 'Battleship',
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
                    ? 'اعثر على سفن العدو ٣ سفن. كل خانة بحمرة = إصابة.'
                    : 'Find enemy ships. Red = hit. Beat the CPU before they sink yours.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'طلقاتك' : 'Your shots',
                    value: localizeDigits(_playerShots, arabic: isAr),
                    color: AppColors.textDark,
                  ),
                  _Pill(
                    label: isAr ? 'العدو' : 'CPU shots',
                    value: localizeDigits(_cpuShots, arabic: isAr),
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'لوحة العدو' : 'Enemy waters',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 4),
              _Board(
                size: _size,
                cellColor: _enemyCell,
                onTap: _playerTap,
                disabled: _gameOver,
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'لوحتك' : 'Your fleet',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 4),
              _Board(
                size: _size,
                cellColor: _playerCell,
                onTap: (_, _) {},
                disabled: true,
              ),
              const SizedBox(height: 12),
              if (_gameOver)
                Column(
                  children: [
                    Text(
                      _playerWon
                          ? (isAr ? '🏆 لقد فزت!' : '🏆 You won!')
                          : (isAr ? '😢 خسرت' : '😢 You lost'),
                      style: AppTextStyles.headingMedium.copyWith(
                        color: _playerWon ? AppColors.success : AppColors.error,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.size,
    required this.cellColor,
    required this.onTap,
    required this.disabled,
  });
  final int size;
  final Color Function(int r, int c) cellColor;
  final void Function(int r, int c) onTap;
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            for (int r = 0; r < size; r++)
              Expanded(
                child: Row(
                  children: [
                    for (int c = 0; c < size; c++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: GestureDetector(
                            onTap: disabled ? null : () => onTap(r, c),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cellColor(r, c),
                                borderRadius: BorderRadius.circular(4),
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
