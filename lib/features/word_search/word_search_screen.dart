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

/// Word Search — drag a path across grid cells to spell one of the hidden
/// theme words. Pure procedural Dart, no images, no network. Five themed
/// puzzles cycle: Animals / Fruits / Body Parts / Colors / Sky.
class WordSearchScreen extends ConsumerStatefulWidget {
  const WordSearchScreen({super.key});

  @override
  ConsumerState<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends ConsumerState<WordSearchScreen> {
  static const int _gridSize = 8;

  static const _themes = <_Theme>[
    _Theme(
      label: 'Animals',
      labelAr: 'حيوانات',
      words: ['CAT', 'DOG', 'LION', 'BEAR', 'WOLF', 'FOX'],
    ),
    _Theme(
      label: 'Fruits',
      labelAr: 'فواكه',
      words: ['FIG', 'DATE', 'APPLE', 'PEAR', 'PLUM', 'KIWI'],
    ),
    _Theme(
      label: 'Body',
      labelAr: 'الجسم',
      words: ['EAR', 'EYE', 'NOSE', 'HAND', 'FOOT', 'KNEE'],
    ),
    _Theme(
      label: 'Colors',
      labelAr: 'ألوان',
      words: ['RED', 'BLUE', 'PINK', 'GOLD', 'GRAY', 'CYAN'],
    ),
    _Theme(
      label: 'Sky',
      labelAr: 'السماء',
      words: ['SUN', 'MOON', 'STAR', 'CLOUD', 'RAIN', 'WIND'],
    ),
  ];

  late _Puzzle _puzzle;
  final Set<String> _found = <String>{};
  final List<int> _selected = <int>[];
  int _themeIdx = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    setState(() {
      _puzzle = _Puzzle.generate(_themes[_themeIdx], _gridSize);
      _found.clear();
      _selected.clear();
    });
  }

  void _switchTheme(int idx) {
    setState(() {
      _themeIdx = idx;
    });
    _next();
  }

  void _onCellTap(int idx) {
    if (_selected.isNotEmpty && _selected.last == idx) {
      // Tap same cell again to commit
      _commit();
      return;
    }
    if (_selected.contains(idx)) return;
    setState(() => _selected.add(idx));
  }

  void _commit() {
    final word = _selected.map((i) => _puzzle.cells[i]).join();
    final reversed = word.split('').reversed.join();
    String? hit;
    for (final w in _puzzle.theme.words) {
      if (w == word || w == reversed) {
        hit = w;
        break;
      }
    }
    if (hit != null && !_found.contains(hit)) {
      setState(() {
        _found.add(hit!);
        _selected.clear();
      });
      ref.read(coinProvider.notifier).award(2);
      if (_found.length == _puzzle.theme.words.length) {
        ref.read(coinProvider.notifier).award(5);
      }
    } else {
      setState(() => _selected.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final theme = _puzzle.theme;
    final remaining = theme.words.where((w) => !_found.contains(w)).toList();
    final allFound = remaining.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'البحث عن الكلمات' : 'Word Search'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'لغز جديد' : 'New puzzle',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _next,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _themes.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(isAr ? _themes[i].labelAr : _themes[i].label),
                      selected: _themeIdx == i,
                      onSelected: (_) => _switchTheme(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final w in theme.words)
                      Text(
                        w,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _found.contains(w)
                              ? AppColors.success
                              : AppColors.textDark,
                          decoration: _found.contains(w)
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _gridSize * _gridSize,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                        ),
                    itemBuilder: (ctx, i) {
                      final ch = _puzzle.cells[i];
                      return _Cell(
                        letter: ch,
                        index: i,
                        selected: _selected.contains(i),
                        onTap: () => _onCellTap(i),
                      );
                    },
                  ),
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: Text(isAr ? 'مسح' : 'Clear'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _commit,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          _selected.map((i) => _puzzle.cells[i]).join(),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (allFound) ...[
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? '🎉 وجدت كل الكلمات (+${localizeDigits(5, arabic: true)} 🪙)'
                      : '🎉 Found them all! (+5 🪙)',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Theme {
  const _Theme({
    required this.label,
    required this.labelAr,
    required this.words,
  });
  final String label;
  final String labelAr;
  final List<String> words;
}

class _Puzzle {
  const _Puzzle({required this.theme, required this.cells});
  final _Theme theme;
  final List<String> cells;

  static _Puzzle generate(_Theme theme, int size) {
    final rng = math.Random();
    final cells = List<String>.filled(size * size, '');

    bool place(String word) {
      const dirs = [
        (1, 0), // right
        (0, 1), // down
        (1, 1), // diag down-right
      ];
      for (var attempt = 0; attempt < 60; attempt++) {
        final (dx, dy) = dirs[rng.nextInt(dirs.length)];
        final maxX = dx == 0 ? size - 1 : size - word.length;
        final maxY = dy == 0 ? size - 1 : size - word.length;
        if (maxX < 0 || maxY < 0) continue;
        final sx = rng.nextInt(maxX + 1);
        final sy = rng.nextInt(maxY + 1);
        var ok = true;
        for (var i = 0; i < word.length; i++) {
          final x = sx + i * dx;
          final y = sy + i * dy;
          final c = cells[y * size + x];
          if (c.isNotEmpty && c != word[i]) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        for (var i = 0; i < word.length; i++) {
          final x = sx + i * dx;
          final y = sy + i * dy;
          cells[y * size + x] = word[i];
        }
        return true;
      }
      return false;
    }

    for (final w in theme.words) {
      place(w);
    }
    const filler = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var i = 0; i < cells.length; i++) {
      if (cells[i].isEmpty) {
        cells[i] = filler[rng.nextInt(filler.length)];
      }
    }
    return _Puzzle(theme: theme, cells: cells);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.letter,
    required this.index,
    required this.selected,
    required this.onTap,
  });
  final String letter;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withAlpha(180)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.outline.withAlpha(60),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
