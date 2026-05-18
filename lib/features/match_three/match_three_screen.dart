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

class MatchThreeScreen extends ConsumerStatefulWidget {
  const MatchThreeScreen({super.key});

  @override
  ConsumerState<MatchThreeScreen> createState() => _MatchThreeScreenState();
}

class _MatchThreeScreenState extends ConsumerState<MatchThreeScreen> {
  static const _n = 6;
  static const _gems = ['💎', '🔶', '🟢', '🔵', '🟣'];
  static const _duration = 75;

  late List<List<int>> _grid;
  Timer? _ticker;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  int? _selR;
  int? _selC;
  bool _busy = false;
  bool _w50 = false, _w120 = false, _w250 = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _grid = _newGrid();
      _seconds = _duration;
      _score = 0;
      _running = true;
      _selR = null;
      _selC = null;
      _busy = false;
      _w50 = _w120 = _w250 = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds -= 1;
        if (_seconds <= 0) {
          _running = false;
          t.cancel();
          _award();
        }
      });
    });
  }

  List<List<int>> _newGrid() {
    final rng = math.Random();
    final g = List.generate(
      _n,
      (_) => List.generate(_n, (_) => rng.nextInt(_gems.length)),
    );
    // Avoid initial matches
    while (_findMatches(g).isNotEmpty) {
      for (final p in _findMatches(g)) {
        g[p[0]][p[1]] = rng.nextInt(_gems.length);
      }
    }
    return g;
  }

  Set<List<int>> _findMatches(List<List<int>> g) {
    final out = <String>{};
    final cells = <List<int>>{};
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n - 2; c++) {
        if (g[r][c] != -1 && g[r][c] == g[r][c + 1] && g[r][c] == g[r][c + 2]) {
          for (var k = 0; k < 3; k++) {
            final key = '$r,${c + k}';
            if (out.add(key)) cells.add([r, c + k]);
          }
        }
      }
    }
    for (var c = 0; c < _n; c++) {
      for (var r = 0; r < _n - 2; r++) {
        if (g[r][c] != -1 && g[r][c] == g[r + 1][c] && g[r][c] == g[r + 2][c]) {
          for (var k = 0; k < 3; k++) {
            final key = '${r + k},$c';
            if (out.add(key)) cells.add([r + k, c]);
          }
        }
      }
    }
    return cells;
  }

  Future<void> _tap(int r, int c) async {
    if (!_running || _busy) return;
    HapticFeedback.lightImpact();
    if (_selR == null) {
      setState(() {
        _selR = r;
        _selC = c;
      });
      return;
    }
    final pr = _selR!;
    final pc = _selC!;
    final adj =
        (r == pr && (c - pc).abs() == 1) || (c == pc && (r - pr).abs() == 1);
    if (!adj) {
      setState(() {
        _selR = r;
        _selC = c;
      });
      return;
    }
    _busy = true;
    setState(() {
      final tmp = _grid[pr][pc];
      _grid[pr][pc] = _grid[r][c];
      _grid[r][c] = tmp;
      _selR = null;
      _selC = null;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    final matches = _findMatches(_grid);
    if (matches.isEmpty) {
      // Swap back
      setState(() {
        final tmp = _grid[pr][pc];
        _grid[pr][pc] = _grid[r][c];
        _grid[r][c] = tmp;
      });
      _busy = false;
      return;
    }
    await _cascade();
    _busy = false;
  }

  Future<void> _cascade() async {
    while (_running) {
      final matches = _findMatches(_grid);
      if (matches.isEmpty) break;
      setState(() {
        for (final p in matches) {
          _grid[p[0]][p[1]] = -1;
          _score += 2;
        }
      });
      await Future.delayed(const Duration(milliseconds: 220));
      // Gravity: drop gems down
      setState(() {
        for (var c = 0; c < _n; c++) {
          final stack = <int>[];
          for (var r = _n - 1; r >= 0; r--) {
            if (_grid[r][c] != -1) stack.add(_grid[r][c]);
          }
          for (var r = 0; r < _n; r++) {
            final i = _n - 1 - r;
            _grid[i][c] = r < stack.length
                ? stack[r]
                : math.Random().nextInt(_gems.length);
          }
        }
      });
      await Future.delayed(const Duration(milliseconds: 220));
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 50 && !_w50) {
      _w50 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 120 && !_w120) {
      _w120 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 250 && !_w250) {
      _w250 = true;
      ref.read(coinProvider.notifier).award(10);
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
          isAr ? 'مطابقة الجواهر' : 'Match Three',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'بدّل جوهرتين متجاورتين لتشكيل ٣ متطابقة في صف أو عمود.'
                    : 'Swap two adjacent gems to line up 3+ in a row or column.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'الوقت' : 'Time',
                    value: localizeDigits(_seconds, arabic: isAr),
                    color: _seconds <= 10
                        ? AppColors.error
                        : AppColors.textDark,
                  ),
                  _Pill(
                    label: isAr ? 'النقاط' : 'Score',
                    value: localizeDigits(_score, arabic: isAr),
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _running
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children: [
                              for (int r = 0; r < _n; r++)
                                Expanded(
                                  child: Row(
                                    children: [
                                      for (int c = 0; c < _n; c++)
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: GestureDetector(
                                              onTap: () => _tap(r, c),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (_selR == r && _selC == c)
                                                      ? AppColors.primary
                                                            .withValues(
                                                              alpha: 0.5,
                                                            )
                                                      : AppColors.background
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                alignment: Alignment.center,
                                                child: _grid[r][c] == -1
                                                    ? const SizedBox.shrink()
                                                    : Text(
                                                        _gems[_grid[r][c]],
                                                        style: const TextStyle(
                                                          fontSize: 28,
                                                        ),
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
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_seconds <= 0)
                                Text(
                                  isAr
                                      ? 'النقاط النهائية: ${localizeDigits(_score, arabic: true)}'
                                      : 'Final score: $_score',
                                  style: AppTextStyles.headingMedium.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _start,
                                icon: Icon(
                                  _seconds <= 0
                                      ? Icons.replay
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  _seconds <= 0
                                      ? (isAr ? 'مرة أخرى' : 'Play again')
                                      : (isAr ? 'ابدأ' : 'Start'),
                                ),
                              ),
                            ],
                          ),
                        ),
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
