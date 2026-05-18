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

/// 15-Puzzle — sliding tile puzzle on a 4×4 grid. Tiles 1–15 in order
/// with one empty cell; tap a tile adjacent to the empty cell to slide.
/// Solved when tiles read 1..15 left-to-right, top-to-bottom.
/// Scrambled by 60 random valid moves so every puzzle is solvable.
/// +٢🪙 solve, +٥🪙 fewer than 100 moves.
class FifteenPuzzleScreen extends ConsumerStatefulWidget {
  const FifteenPuzzleScreen({super.key});

  @override
  ConsumerState<FifteenPuzzleScreen> createState() =>
      _FifteenPuzzleScreenState();
}

class _FifteenPuzzleScreenState extends ConsumerState<FifteenPuzzleScreen> {
  static const int _n = 4;
  late List<int> _tiles; // 0..15; 0 represents the blank
  int _moves = 0;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  void _newPuzzle() {
    _tiles = [for (var i = 1; i < _n * _n; i++) i, 0];
    final rng = math.Random();
    for (var i = 0; i < 60; i++) {
      final empty = _tiles.indexOf(0);
      final r = empty ~/ _n;
      final c = empty % _n;
      final moves = <int>[];
      if (r > 0) moves.add(empty - _n);
      if (r < _n - 1) moves.add(empty + _n);
      if (c > 0) moves.add(empty - 1);
      if (c < _n - 1) moves.add(empty + 1);
      final pick = moves[rng.nextInt(moves.length)];
      final t = _tiles[empty];
      _tiles[empty] = _tiles[pick];
      _tiles[pick] = t;
    }
    _moves = 0;
    _solved = false;
    setState(() {});
  }

  void _tap(int idx) {
    if (_solved) return;
    final empty = _tiles.indexOf(0);
    final r1 = idx ~/ _n;
    final c1 = idx % _n;
    final r0 = empty ~/ _n;
    final c0 = empty % _n;
    final adj =
        (r1 == r0 && (c1 - c0).abs() == 1) ||
        (c1 == c0 && (r1 - r0).abs() == 1);
    if (!adj) return;
    HapticFeedback.selectionClick();
    setState(() {
      final t = _tiles[idx];
      _tiles[idx] = 0;
      _tiles[empty] = t;
      _moves += 1;
    });
    _checkWin();
  }

  void _checkWin() {
    for (var i = 0; i < _n * _n - 1; i++) {
      if (_tiles[i] != i + 1) return;
    }
    if (_tiles.last != 0) return;
    _solved = true;
    ref.read(coinProvider.notifier).award(2);
    if (_moves < 100) {
      ref.read(coinProvider.notifier).award(5);
    }
    setState(() {});
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
          isAr ? 'لغز ١٥' : '15-Puzzle',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          TextButton.icon(
            onPressed: _newPuzzle,
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
              Text(
                isAr
                    ? 'انقر مربعًا بجانب الفراغ ليتحرك. رتّبها ١-١٥!'
                    : 'Tap a tile next to the empty space. Sort 1–15!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${isAr ? "حركات" : "Moves"}: ${localizeDigits(_moves, arabic: isAr)}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
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
                      final v = _tiles[i];
                      if (v == 0) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }
                      final correct = v == i + 1;
                      return GestureDetector(
                        onTap: () => _tap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            gradient: correct
                                ? AppColors.goldGradient
                                : LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            localizeDigits(v, arabic: isAr),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_solved)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _moves < 100
                        ? (isAr ? '🎉 رائع! +٧🪙' : '🎉 Brilliant! +7🪙')
                        : (isAr ? '✅ أحسنت! +٢🪙' : '✅ Solved! +2🪙'),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.success,
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
