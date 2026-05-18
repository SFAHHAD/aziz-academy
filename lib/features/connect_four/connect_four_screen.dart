import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Connect Four — 7 columns × 6 rows. Kid is Yellow (1), CPU is Red (2).
/// Three difficulties: Easy random, Medium 1-ply heuristic, Hard
/// minimax-with-alpha-beta limited depth. +٢🪙 win, +١🪙 draw.
class ConnectFourScreen extends ConsumerStatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  ConsumerState<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

enum _Diff { easy, medium, hard }

class _ConnectFourScreenState extends ConsumerState<ConnectFourScreen> {
  static const int _cols = 7;
  static const int _rows = 6;

  late List<List<int>> _board; // [col][row], row 0 = bottom
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;
  bool _busy = false;
  String? _result;
  _Diff _diff = _Diff.medium;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    setState(() {
      _board = List.generate(_cols, (_) => <int>[]);
      _result = null;
      _busy = false;
    });
  }

  bool _canDrop(List<List<int>> b, int col) => b[col].length < _rows;

  void _drop(List<List<int>> b, int col, int who) {
    b[col].add(who);
  }

  void _undo(List<List<int>> b, int col) {
    b[col].removeLast();
  }

  int _winner(List<List<int>> b) {
    int at(int c, int r) =>
        (r >= 0 && r < _rows && c >= 0 && c < _cols && r < b[c].length)
        ? b[c][r]
        : 0;

    bool four(int c, int r, int dc, int dr) {
      final v = at(c, r);
      if (v == 0) return false;
      for (var i = 1; i < 4; i++) {
        if (at(c + dc * i, r + dr * i) != v) return false;
      }
      return true;
    }

    for (var c = 0; c < _cols; c++) {
      for (var r = 0; r < _rows; r++) {
        for (final d in const [
          [1, 0],
          [0, 1],
          [1, 1],
          [1, -1],
        ]) {
          if (four(c, r, d[0], d[1])) return at(c, r);
        }
      }
    }
    return 0;
  }

  bool _full(List<List<int>> b) => b.every((col) => col.length == _rows);

  Future<void> _userTap(int col) async {
    if (_busy || _result != null) return;
    if (!_canDrop(_board, col)) return;
    setState(() {
      _drop(_board, col, 1);
      _busy = true;
    });
    if (_check()) return;
    await Future.delayed(const Duration(milliseconds: 350));
    final cpuCol = _cpuMove();
    if (cpuCol >= 0) {
      setState(() => _drop(_board, cpuCol, 2));
    }
    if (_check()) return;
    setState(() => _busy = false);
  }

  bool _check() {
    final w = _winner(_board);
    if (w == 1) {
      _result = 'win';
      _wins += 1;
      ref.read(coinProvider.notifier).award(2);
      setState(() {});
      return true;
    }
    if (w == 2) {
      _result = 'lose';
      _losses += 1;
      setState(() {});
      return true;
    }
    if (_full(_board)) {
      _result = 'draw';
      _draws += 1;
      ref.read(coinProvider.notifier).award(1);
      setState(() {});
      return true;
    }
    return false;
  }

  int _cpuMove() {
    final available = List.generate(
      _cols,
      (i) => i,
    ).where((c) => _canDrop(_board, c)).toList();
    if (available.isEmpty) return -1;

    if (_diff == _Diff.easy) {
      return available[math.Random().nextInt(available.length)];
    }

    // For medium and hard, first check immediate wins/blocks.
    for (final c in available) {
      _drop(_board, c, 2);
      if (_winner(_board) == 2) {
        _undo(_board, c);
        return c;
      }
      _undo(_board, c);
    }
    for (final c in available) {
      _drop(_board, c, 1);
      if (_winner(_board) == 1) {
        _undo(_board, c);
        return c;
      }
      _undo(_board, c);
    }

    if (_diff == _Diff.medium) {
      // Prefer center.
      available.sort((a, b) => (3 - a).abs().compareTo((3 - b).abs()));
      return available.first;
    }

    // Hard: depth-4 minimax with alpha-beta. CPU = 2 maximizes.
    int best = available.first;
    var bestScore = -100000;
    for (final c in available) {
      _drop(_board, c, 2);
      final s = _minimax(3, false, -100000, 100000);
      _undo(_board, c);
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return best;
  }

  int _minimax(int depth, bool maximizing, int alpha, int beta) {
    final w = _winner(_board);
    if (w == 2) return 1000 + depth;
    if (w == 1) return -1000 - depth;
    if (depth == 0 || _full(_board)) return _evaluate();

    final cols = List.generate(
      _cols,
      (i) => i,
    ).where((c) => _canDrop(_board, c)).toList();
    cols.sort((a, b) => (3 - a).abs().compareTo((3 - b).abs()));

    if (maximizing) {
      var v = -100000;
      for (final c in cols) {
        _drop(_board, c, 2);
        v = math.max(v, _minimax(depth - 1, false, alpha, beta));
        _undo(_board, c);
        alpha = math.max(alpha, v);
        if (alpha >= beta) break;
      }
      return v;
    } else {
      var v = 100000;
      for (final c in cols) {
        _drop(_board, c, 1);
        v = math.min(v, _minimax(depth - 1, true, alpha, beta));
        _undo(_board, c);
        beta = math.min(beta, v);
        if (alpha >= beta) break;
      }
      return v;
    }
  }

  int _evaluate() {
    int at(int c, int r) => (r < _board[c].length) ? _board[c][r] : 0;

    int scoreLine(List<int> line) {
      final cpu = line.where((v) => v == 2).length;
      final kid = line.where((v) => v == 1).length;
      final empty = line.where((v) => v == 0).length;
      if (cpu > 0 && kid > 0) return 0;
      if (cpu == 3 && empty == 1) return 50;
      if (cpu == 2 && empty == 2) return 10;
      if (kid == 3 && empty == 1) return -50;
      if (kid == 2 && empty == 2) return -10;
      return 0;
    }

    var score = 0;
    for (var c = 0; c < _cols; c++) {
      for (var r = 0; r < _rows; r++) {
        for (final d in const [
          [1, 0],
          [0, 1],
          [1, 1],
          [1, -1],
        ]) {
          final line = <int>[];
          for (var i = 0; i < 4; i++) {
            final cc = c + d[0] * i;
            final rr = r + d[1] * i;
            if (cc < 0 || cc >= _cols || rr < 0 || rr >= _rows) {
              break;
            }
            line.add(at(cc, rr));
          }
          if (line.length == 4) score += scoreLine(line);
        }
      }
    }
    // Centre bias.
    for (var r = 0; r < _board[3].length; r++) {
      if (_board[3][r] == 2) score += 3;
      if (_board[3][r] == 1) score -= 3;
    }
    return score;
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
          isAr ? 'وصل أربعة' : 'Connect Four',
          style: AppTextStyles.headingSmall,
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<_Diff>(
                segments: [
                  ButtonSegment(
                    value: _Diff.easy,
                    label: Text(isAr ? 'سهل' : 'Easy'),
                  ),
                  ButtonSegment(
                    value: _Diff.medium,
                    label: Text(isAr ? 'متوسط' : 'Medium'),
                  ),
                  ButtonSegment(
                    value: _Diff.hard,
                    label: Text(isAr ? 'صعب' : 'Hard'),
                  ),
                ],
                selected: {_diff},
                onSelectionChanged: (s) {
                  setState(() {
                    _diff = s.first;
                    _newGame();
                  });
                },
              ),
              const SizedBox(height: 12),
              _ScoreRow(
                wins: _wins,
                losses: _losses,
                draws: _draws,
                isAr: isAr,
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: _cols / (_rows + 0.6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _Grid(
                    board: _board,
                    cols: _cols,
                    rows: _rows,
                    onDrop: _userTap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        (_result == 'win'
                                ? AppColors.success
                                : (_result == 'draw'
                                      ? AppColors.warning
                                      : AppColors.error))
                            .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _result == 'win'
                        ? (isAr ? '🎉 فزت! +٢🪙' : '🎉 You win! +2🪙')
                        : (_result == 'draw'
                              ? (isAr ? '🤝 تعادل +١🪙' : '🤝 Draw +1🪙')
                              : (isAr ? 'حاول مرة أخرى!' : 'Try again!')),
                    style: AppTextStyles.headingSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.isAr,
  });
  final int wins;
  final int losses;
  final int draws;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, int v, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$label  $v', style: AppTextStyles.labelLarge),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        pill(isAr ? 'فوز' : 'W', wins, AppColors.success),
        pill(isAr ? 'خسارة' : 'L', losses, AppColors.error),
        pill(isAr ? 'تعادل' : 'D', draws, AppColors.warning),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.board,
    required this.cols,
    required this.rows,
    required this.onDrop,
  });

  final List<List<int>> board;
  final int cols;
  final int rows;
  final void Function(int) onDrop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cellW = c.maxWidth / cols;
        return Column(
          children: [
            // Drop-buttons row.
            SizedBox(
              height: cellW * 0.6,
              child: Row(
                children: [
                  for (var col = 0; col < cols; col++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onDrop(col),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Grid (top row first, so iterate row from rows-1 down to 0).
            Expanded(
              child: Column(
                children: [
                  for (var r = rows - 1; r >= 0; r--)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < cols; col++)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => onDrop(col),
                                child: _Disk(
                                  value: r < board[col].length
                                      ? board[col][r]
                                      : 0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Disk extends StatelessWidget {
  const _Disk({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = value == 1
        ? AppColors.warning
        : (value == 2 ? AppColors.error : AppColors.background);
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textDark.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
    );
  }
}
