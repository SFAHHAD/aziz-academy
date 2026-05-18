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

/// Mini Sudoku — 4×4 grid divided into four 2×2 boxes. Digits 1-4 must
/// appear exactly once per row, column and box. +٣🪙 per solve, +٥🪙 if
/// solved without using the Hint button.
class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  late List<int> _solution;
  late List<int> _board;
  late List<bool> _given;
  int _selected = -1;
  bool _hintUsed = false;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  /// Generate a valid 4×4 Latin-square-with-2x2-boxes solution by starting
  /// from a base pattern and randomly permuting rows-within-band and
  /// columns-within-stack, plus a digit relabel.
  List<int> _generateSolution(math.Random rng) {
    var grid = <int>[1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];

    int idx(int r, int c) => r * 4 + c;

    void swapRows(int a, int b) {
      for (var c = 0; c < 4; c++) {
        final t = grid[idx(a, c)];
        grid[idx(a, c)] = grid[idx(b, c)];
        grid[idx(b, c)] = t;
      }
    }

    void swapCols(int a, int b) {
      for (var r = 0; r < 4; r++) {
        final t = grid[idx(r, a)];
        grid[idx(r, a)] = grid[idx(r, b)];
        grid[idx(r, b)] = t;
      }
    }

    if (rng.nextBool()) swapRows(0, 1);
    if (rng.nextBool()) swapRows(2, 3);
    if (rng.nextBool()) swapCols(0, 1);
    if (rng.nextBool()) swapCols(2, 3);

    final digits = [1, 2, 3, 4]..shuffle(rng);
    grid = grid.map((d) => digits[d - 1]).toList();
    return grid;
  }

  void _newPuzzle() {
    final rng = math.Random();
    final solution = _generateSolution(rng);
    final positions = List.generate(16, (i) => i)..shuffle(rng);
    final cluesToShow = 8 + rng.nextInt(2); // 8 or 9 clues
    final given = List.filled(16, false);
    for (var i = 0; i < cluesToShow; i++) {
      given[positions[i]] = true;
    }
    setState(() {
      _solution = solution;
      _given = given;
      _board = List.generate(16, (i) => given[i] ? solution[i] : 0);
      _selected = -1;
      _hintUsed = false;
      _solved = false;
    });
  }

  void _placeDigit(int d) {
    if (_selected < 0 || _given[_selected] || _solved) return;
    setState(() => _board[_selected] = d);
    _checkWin();
  }

  void _erase() {
    if (_selected < 0 || _given[_selected] || _solved) return;
    setState(() => _board[_selected] = 0);
  }

  void _hint() {
    if (_selected < 0 || _given[_selected] || _solved) return;
    setState(() {
      _board[_selected] = _solution[_selected];
      _hintUsed = true;
    });
    _checkWin();
  }

  void _checkWin() {
    for (var i = 0; i < 16; i++) {
      if (_board[i] != _solution[i]) return;
    }
    setState(() => _solved = true);
    ref.read(coinProvider.notifier).award(_hintUsed ? 3 : 8);
  }

  bool _hasConflict(int idx) {
    if (_board[idx] == 0) return false;
    final row = idx ~/ 4;
    final col = idx % 4;
    final box = (row ~/ 2) * 2 + (col ~/ 2);
    for (var i = 0; i < 16; i++) {
      if (i == idx) continue;
      if (_board[i] != _board[idx]) continue;
      final r = i ~/ 4;
      final c = i % 4;
      final b = (r ~/ 2) * 2 + (c ~/ 2);
      if (r == row || c == col || b == box) return true;
    }
    return false;
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
          isAr ? 'سودوكو ٤×٤' : 'Mini Sudoku',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          TextButton.icon(
            onPressed: _newPuzzle,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: Text(
              isAr ? 'جديد' : 'New',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'املأ الشبكة بالأرقام ١-٤ بحيث لا يتكرر رقم في صف أو عمود أو مربع.'
                    : 'Fill 1–4 so no digit repeats in any row, column or 2×2 box.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: _Board(
                  board: _board,
                  given: _given,
                  selected: _selected,
                  conflict: List.generate(16, _hasConflict),
                  onTap: (i) => setState(() => _selected = i),
                  isAr: isAr,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var d = 1; d <= 4; d++)
                    _ActionButton(
                      label: localizeDigits(d, arabic: isAr),
                      color: AppColors.primary,
                      onPressed: () => _placeDigit(d),
                    ),
                  _ActionButton(
                    label: isAr ? 'مسح' : 'Erase',
                    color: AppColors.warning,
                    onPressed: _erase,
                  ),
                  _ActionButton(
                    label: isAr ? 'تلميح' : 'Hint',
                    color: AppColors.accent,
                    onPressed: _hint,
                  ),
                ],
              ),
              const Spacer(),
              if (_solved)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success, width: 2),
                  ),
                  child: Text(
                    isAr
                        ? (_hintUsed
                              ? '🎉 أحسنت! +٣🪙'
                              : '🎉 رائع بدون تلميح! +٨🪙')
                        : (_hintUsed
                              ? '🎉 Solved! +3🪙'
                              : '🎉 Solved without hint! +8🪙'),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.success,
                    ),
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

class _Board extends StatelessWidget {
  const _Board({
    required this.board,
    required this.given,
    required this.selected,
    required this.conflict,
    required this.onTap,
    required this.isAr,
  });

  final List<int> board;
  final List<bool> given;
  final int selected;
  final List<bool> conflict;
  final void Function(int) onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textDark.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: 16,
        itemBuilder: (context, i) {
          final row = i ~/ 4;
          final col = i % 4;
          final v = board[i];
          final isSel = i == selected;
          final isGiven = given[i];
          final hasConflict = conflict[i];

          // Thicker border between 2×2 boxes.
          final borderRight = (col == 1)
              ? const BorderSide(color: AppColors.textDark, width: 1.5)
              : BorderSide(color: AppColors.textDark.withValues(alpha: 0.2));
          final borderBottom = (row == 1)
              ? const BorderSide(color: AppColors.textDark, width: 1.5)
              : BorderSide(color: AppColors.textDark.withValues(alpha: 0.2));

          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              decoration: BoxDecoration(
                color: isSel
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : (hasConflict
                          ? AppColors.error.withValues(alpha: 0.12)
                          : (isGiven
                                ? AppColors.textDark.withValues(alpha: 0.05)
                                : Colors.transparent)),
                border: Border(right: borderRight, bottom: borderBottom),
              ),
              alignment: Alignment.center,
              child: v == 0
                  ? const SizedBox.shrink()
                  : Text(
                      localizeDigits(v, arabic: isAr),
                      style: AppTextStyles.displayMedium.copyWith(
                        color: isGiven
                            ? AppColors.textDark
                            : (hasConflict
                                  ? AppColors.error
                                  : AppColors.primary),
                        fontWeight: isGiven ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
