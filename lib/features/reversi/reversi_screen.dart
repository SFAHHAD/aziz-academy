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

/// Reversi (Othello) — flip the most stones. Player is dark,
/// CPU is light. Greedy CPU picks max-flip moves with corner
/// preference. +٢🪙 first win, +٥🪙 win by ١٠+, +١٠🪙 win by ٢٠+.
class ReversiScreen extends ConsumerStatefulWidget {
  const ReversiScreen({super.key});

  @override
  ConsumerState<ReversiScreen> createState() => _ReversiScreenState();
}

class _ReversiScreenState extends ConsumerState<ReversiScreen> {
  static const int _n = 8;
  // 0 = empty, 1 = dark (player), 2 = light (CPU)
  late List<List<int>> _b;
  int _turn = 1; // dark moves first
  bool _gameOver = false;
  bool _firstWin = false, _won10 = false, _won20 = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    setState(() {
      _b = List.generate(_n, (_) => List<int>.filled(_n, 0));
      _b[3][3] = 2;
      _b[3][4] = 1;
      _b[4][3] = 1;
      _b[4][4] = 2;
      _turn = 1;
      _gameOver = false;
    });
  }

  static const _dirs = <List<int>>[
    [0, 1],
    [1, 0],
    [0, -1],
    [-1, 0],
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  List<List<int>> _flipsFor(List<List<int>> b, int r, int c, int p) {
    if (b[r][c] != 0) return const [];
    final opp = p == 1 ? 2 : 1;
    final out = <List<int>>[];
    for (final d in _dirs) {
      var rr = r + d[0], cc = c + d[1];
      final line = <List<int>>[];
      while (rr >= 0 && rr < _n && cc >= 0 && cc < _n && b[rr][cc] == opp) {
        line.add([rr, cc]);
        rr += d[0];
        cc += d[1];
      }
      if (line.isNotEmpty &&
          rr >= 0 &&
          rr < _n &&
          cc >= 0 &&
          cc < _n &&
          b[rr][cc] == p) {
        out.addAll(line);
      }
    }
    return out;
  }

  bool _hasAnyMove(List<List<int>> b, int p) {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_flipsFor(b, r, c, p).isNotEmpty) return true;
      }
    }
    return false;
  }

  int _score(int p) {
    var s = 0;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_b[r][c] == p) s++;
      }
    }
    return s;
  }

  void _play(int r, int c, int p) {
    final flips = _flipsFor(_b, r, c, p);
    if (flips.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _b[r][c] = p;
      for (final f in flips) {
        _b[f[0]][f[1]] = p;
      }
      _advanceTurn();
    });
  }

  void _advanceTurn() {
    final next = _turn == 1 ? 2 : 1;
    if (_hasAnyMove(_b, next)) {
      _turn = next;
      if (_turn == 2) Future.delayed(const Duration(milliseconds: 300), _cpu);
    } else if (_hasAnyMove(_b, _turn)) {
      // Opponent skipped; current player plays again
      // (turn unchanged)
    } else {
      _gameOver = true;
      _award();
    }
  }

  void _cpu() {
    if (_gameOver) return;
    if (_turn != 2) return;
    final moves = <List<int>>[];
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final f = _flipsFor(_b, r, c, 2);
        if (f.isNotEmpty) {
          // Heuristic: corners first
          var weight = f.length;
          if ((r == 0 || r == 7) && (c == 0 || c == 7)) weight += 100;
          // Penalize cells adjacent to corners (X-squares)
          if ((r == 1 && c == 1) ||
              (r == 1 && c == 6) ||
              (r == 6 && c == 1) ||
              (r == 6 && c == 6)) {
            weight -= 8;
          }
          moves.add([r, c, weight]);
        }
      }
    }
    if (moves.isEmpty) {
      _advanceTurn();
      return;
    }
    moves.sort((a, b) => b[2].compareTo(a[2]));
    final pick = moves.first;
    _play(pick[0], pick[1], 2);
  }

  void _award() {
    HapticFeedback.heavyImpact();
    final pl = _score(1);
    final cp = _score(2);
    if (pl > cp) {
      if (!_firstWin) {
        _firstWin = true;
        ref.read(coinProvider.notifier).award(2);
      }
      if (!_won10 && (pl - cp) >= 10) {
        _won10 = true;
        ref.read(coinProvider.notifier).award(5);
      }
      if (!_won20 && (pl - cp) >= 20) {
        _won20 = true;
        ref.read(coinProvider.notifier).award(10);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final pl = _score(1);
    final cp = _score(2);
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
          isAr ? 'ريفرسي' : 'Reversi',
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
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'أنت ⚫' : 'You ⚫',
                    value: localizeDigits(pl, arabic: isAr),
                  ),
                  _Pill(
                    label: isAr ? 'الحاسب ⚪' : 'CPU ⚪',
                    value: localizeDigits(cp, arabic: isAr),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _gameOver
                    ? (pl > cp
                          ? (isAr ? 'فزت! 🎉' : 'You won! 🎉')
                          : pl < cp
                          ? (isAr ? 'فاز الحاسب' : 'CPU won')
                          : (isAr ? 'تعادل' : 'Tie'))
                    : (_turn == 1
                          ? (isAr ? 'دورك' : 'Your turn')
                          : (isAr ? 'دور الحاسب' : "CPU's turn")),
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _n,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemCount: _n * _n,
                    itemBuilder: (context, i) {
                      final r = i ~/ _n;
                      final c = i % _n;
                      final v = _b[r][c];
                      final canPlay =
                          !_gameOver &&
                          _turn == 1 &&
                          _flipsFor(_b, r, c, 1).isNotEmpty;
                      return GestureDetector(
                        onTap: canPlay ? () => _play(r, c, 1) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F6B36),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: v == 0
                                ? (canPlay
                                      ? Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null)
                                : Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: v == 1
                                          ? Colors.black87
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
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
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;
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
          Text(value, style: AppTextStyles.headingSmall),
        ],
      ),
    );
  }
}
