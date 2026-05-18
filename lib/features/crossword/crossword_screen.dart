import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Mini Crossword — pre-baked 7×7 grid in English / 5×5 in Arabic. Tap a
/// cell to focus; type with the on-screen keyboard. Solved when every
/// answer cell matches the puzzle. +٢🪙 per word, +٥🪙 perfect grid.
class CrosswordScreen extends ConsumerStatefulWidget {
  const CrosswordScreen({super.key});

  @override
  ConsumerState<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends ConsumerState<CrosswordScreen> {
  late _Puzzle _puzzle;
  late List<List<String>> _grid;
  int _selR = 0;
  int _selC = 0;
  bool _across = true;
  final Set<String> _solvedWords = {};
  bool _solved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isAr = Directionality.of(context) == TextDirection.rtl;
    _puzzle = isAr ? _arabicPuzzle : _englishPuzzle;
    _grid = List.generate(_puzzle.size, (_) => List.filled(_puzzle.size, ''));
    // Pick first non-block cell as selection.
    outer:
    for (var r = 0; r < _puzzle.size; r++) {
      for (var c = 0; c < _puzzle.size; c++) {
        if (_puzzle.solution[r][c] != null) {
          _selR = r;
          _selC = c;
          break outer;
        }
      }
    }
  }

  void _typeChar(String ch) {
    if (_solved) return;
    if (_puzzle.solution[_selR][_selC] == null) return;
    setState(() {
      _grid[_selR][_selC] = ch;
    });
    _checkWords();
    _advance();
  }

  void _backspace() {
    if (_solved) return;
    setState(() {
      if (_grid[_selR][_selC].isNotEmpty) {
        _grid[_selR][_selC] = '';
      } else {
        _retreat();
        _grid[_selR][_selC] = '';
      }
    });
  }

  void _advance() {
    var r = _selR;
    var c = _selC;
    for (var i = 0; i < _puzzle.size; i++) {
      if (_across) {
        c += 1;
        if (c >= _puzzle.size) break;
      } else {
        r += 1;
        if (r >= _puzzle.size) break;
      }
      if (_puzzle.solution[r][c] != null) {
        setState(() {
          _selR = r;
          _selC = c;
        });
        return;
      }
    }
  }

  void _retreat() {
    var r = _selR;
    var c = _selC;
    for (var i = 0; i < _puzzle.size; i++) {
      if (_across) {
        c -= 1;
        if (c < 0) break;
      } else {
        r -= 1;
        if (r < 0) break;
      }
      if (_puzzle.solution[r][c] != null) {
        setState(() {
          _selR = r;
          _selC = c;
        });
        return;
      }
    }
  }

  void _checkWords() {
    for (final w in _puzzle.words) {
      if (_solvedWords.contains(w.id)) continue;
      var ok = true;
      for (var i = 0; i < w.answer.length; i++) {
        final r = w.row + (w.across ? 0 : i);
        final c = w.col + (w.across ? i : 0);
        if (_grid[r][c] != w.answer[i]) {
          ok = false;
          break;
        }
      }
      if (ok) {
        _solvedWords.add(w.id);
        ref.read(coinProvider.notifier).award(2);
      }
    }
    if (_solvedWords.length == _puzzle.words.length) {
      _solved = true;
      ref.read(coinProvider.notifier).award(5);
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
          isAr ? 'كلمات متقاطعة' : 'Mini Crossword',
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
                    ? 'انقر خانة لتختارها، ثم اكتب الحرف من الأسفل.'
                    : 'Tap a cell, then type with the keyboard below.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1,
                child: _Grid(
                  puzzle: _puzzle,
                  values: _grid,
                  selR: _selR,
                  selC: _selC,
                  onTap: (r, c) {
                    if (_puzzle.solution[r][c] == null) return;
                    setState(() {
                      if (r == _selR && c == _selC) {
                        _across = !_across;
                      } else {
                        _selR = r;
                        _selC = c;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              _ClueBar(
                puzzle: _puzzle,
                across: _across,
                selR: _selR,
                selC: _selC,
              ),
              const Spacer(),
              if (_solved)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isAr ? '🎉 رائع! حللت الشبكة!' : '🎉 Grid solved!',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
              _Keyboard(
                arabic: isAr,
                onChar: _typeChar,
                onBackspace: _backspace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Puzzle {
  const _Puzzle({
    required this.size,
    required this.solution,
    required this.numbers,
    required this.words,
  });
  final int size;
  // null = block; otherwise the correct letter for that cell.
  final List<List<String?>> solution;
  // Cell number to display (1-based) or 0 for none.
  final List<List<int>> numbers;
  final List<_Word> words;
}

class _Word {
  const _Word({
    required this.id,
    required this.row,
    required this.col,
    required this.across,
    required this.answer,
    required this.clueEn,
    required this.clueAr,
    required this.number,
  });
  final String id;
  final int row;
  final int col;
  final bool across;
  final List<String> answer;
  final String clueEn;
  final String clueAr;
  final int number;
}

// ─── English 7×7 puzzle ────────────────────────────────────────────────
final _englishPuzzle = _Puzzle(
  size: 7,
  solution: const [
    ['L', 'I', 'O', 'N', null, null, null],
    [null, null, null, 'I', null, null, null],
    [null, null, null, 'L', 'A', 'M', 'P'],
    [null, null, null, 'E', null, null, null],
    [null, 'S', 'T', 'A', 'R', null, null],
    [null, null, null, null, null, null, null],
    ['M', 'O', 'O', 'N', null, null, null],
  ],
  numbers: const [
    [1, 0, 0, 2, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 3, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 4, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [5, 0, 0, 0, 0, 0, 0],
  ],
  words: [
    _Word(
      id: 'a1',
      row: 0,
      col: 0,
      across: true,
      answer: const ['L', 'I', 'O', 'N'],
      clueEn: 'King of the jungle',
      clueAr: 'ملك الغابة',
      number: 1,
    ),
    _Word(
      id: 'd2',
      row: 0,
      col: 3,
      across: false,
      answer: const ['N', 'I', 'L', 'E'],
      clueEn: 'Longest river in Africa',
      clueAr: 'أطول نهر في أفريقيا',
      number: 2,
    ),
    _Word(
      id: 'a3',
      row: 2,
      col: 3,
      across: true,
      answer: const ['L', 'A', 'M', 'P'],
      clueEn: 'Aladdin found one',
      clueAr: 'وجد علاء الدين واحدًا منه',
      number: 3,
    ),
    _Word(
      id: 'a4',
      row: 4,
      col: 1,
      across: true,
      answer: const ['S', 'T', 'A', 'R'],
      clueEn: 'Twinkles at night',
      clueAr: 'يلمع في الليل',
      number: 4,
    ),
    _Word(
      id: 'a5',
      row: 6,
      col: 0,
      across: true,
      answer: const ['M', 'O', 'O', 'N'],
      clueEn: 'Earth\'s satellite',
      clueAr: 'قمر الأرض',
      number: 5,
    ),
  ],
);

// ─── Arabic 5×5 puzzle ────────────────────────────────────────────────
final _arabicPuzzle = _Puzzle(
  size: 5,
  solution: const [
    ['ق', 'م', 'ر', null, null],
    [null, null, 'و', null, null],
    [null, 'ا', 'ض', 'ح', null],
    [null, null, 'ة', null, null],
    [null, null, null, null, null],
  ],
  numbers: const [
    [1, 0, 2, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 3, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ],
  words: [
    _Word(
      id: 'a1',
      row: 0,
      col: 0,
      across: true,
      answer: const ['ق', 'م', 'ر'],
      clueEn: 'The moon (3 letters)',
      clueAr: 'يضيء الليل (٣ حروف)',
      number: 1,
    ),
    _Word(
      id: 'd2',
      row: 0,
      col: 2,
      across: false,
      answer: const ['ر', 'و', 'ض', 'ة'],
      clueEn: 'A garden (4 letters)',
      clueAr: 'حديقة جميلة (٤ حروف)',
      number: 2,
    ),
    _Word(
      id: 'a3',
      row: 2,
      col: 1,
      across: true,
      answer: const ['ا', 'ض', 'ح'],
      clueEn: 'Clear / obvious',
      clueAr: 'بيِّن وظاهر',
      number: 3,
    ),
  ],
);

class _Grid extends StatelessWidget {
  const _Grid({
    required this.puzzle,
    required this.values,
    required this.selR,
    required this.selC,
    required this.onTap,
  });
  final _Puzzle puzzle;
  final List<List<String>> values;
  final int selR;
  final int selC;
  final void Function(int r, int c) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var r = 0; r < puzzle.size; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < puzzle.size; c++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(r, c),
                        child: _Cell(
                          letter: puzzle.solution[r][c],
                          value: values[r][c],
                          number: puzzle.numbers[r][c],
                          selected: r == selR && c == selC,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.letter,
    required this.value,
    required this.number,
    required this.selected,
  });
  final String? letter;
  final String value;
  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (letter == null) {
      return Container(
        margin: const EdgeInsets.all(0.5),
        color: AppColors.textDark.withValues(alpha: 0.15),
      );
    }
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.35)
            : AppColors.surface,
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          if (number > 0)
            Positioned(
              left: 2,
              top: 0,
              child: Text(
                '$number',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
              ),
            ),
          Center(
            child: Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClueBar extends StatelessWidget {
  const _ClueBar({
    required this.puzzle,
    required this.across,
    required this.selR,
    required this.selC,
  });
  final _Puzzle puzzle;
  final bool across;
  final int selR;
  final int selC;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final word =
        _wordAt(puzzle, selR, selC, across) ??
        _wordAt(puzzle, selR, selC, !across);
    if (word == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${word.number}. ${isAr ? word.clueAr : word.clueEn}',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

_Word? _wordAt(_Puzzle p, int r, int c, bool across) {
  for (final w in p.words) {
    if (w.across != across) continue;
    if (across) {
      if (w.row != r) continue;
      if (c >= w.col && c < w.col + w.answer.length) return w;
    } else {
      if (w.col != c) continue;
      if (r >= w.row && r < w.row + w.answer.length) return w;
    }
  }
  return null;
}

class _Keyboard extends StatelessWidget {
  const _Keyboard({
    required this.arabic,
    required this.onChar,
    required this.onBackspace,
  });
  final bool arabic;
  final void Function(String) onChar;
  final VoidCallback onBackspace;

  static const _enRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static const _arRows = [
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج'],
    ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك'],
    ['ئ', 'ء', 'ؤ', 'ر', 'لا', 'ى', 'ة', 'و', 'ز', 'ظ', 'د', 'ذ'],
  ];

  @override
  Widget build(BuildContext context) {
    final rows = arabic ? _arRows : _enRows;
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .map<Widget>(
                    (k) => _Key(
                      label: k,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChar(k);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            width: 120,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onBackspace();
              },
              icon: const Icon(Icons.backspace_outlined, size: 16),
              label: Text(arabic ? 'حذف' : 'Erase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                foregroundColor: AppColors.textDark,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: SizedBox(
        width: 30,
        height: 38,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            foregroundColor: AppColors.textDark,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(label, style: AppTextStyles.labelMedium),
        ),
      ),
    );
  }
}
