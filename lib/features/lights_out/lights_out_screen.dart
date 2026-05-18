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

/// Lights Out 5×5 — toggle a cell + its orthogonal neighbours. Goal: turn
/// all lights off. Generates a solvable puzzle by starting from "all off"
/// and pressing 5–8 random buttons; reversing those clicks always solves.
/// +٢🪙 per solve, +٥🪙 if solved in ≤ pressed_count + 2 moves.
class LightsOutScreen extends ConsumerStatefulWidget {
  const LightsOutScreen({super.key});

  @override
  ConsumerState<LightsOutScreen> createState() => _LightsOutScreenState();
}

class _LightsOutScreenState extends ConsumerState<LightsOutScreen> {
  static const int _n = 5;
  late List<List<bool>> _grid;
  int _moves = 0;
  int _scrambleCount = 0;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  void _newPuzzle() {
    final rng = math.Random();
    _grid = List.generate(_n, (_) => List.filled(_n, false));
    _scrambleCount = 5 + rng.nextInt(4);
    final pressed = <math.Point<int>>{};
    while (pressed.length < _scrambleCount) {
      pressed.add(math.Point(rng.nextInt(_n), rng.nextInt(_n)));
    }
    for (final p in pressed) {
      _toggle(p.x, p.y);
    }
    _moves = 0;
    _solved = false;
    setState(() {});
  }

  void _toggle(int r, int c) {
    void flip(int x, int y) {
      if (x < 0 || x >= _n || y < 0 || y >= _n) return;
      _grid[x][y] = !_grid[x][y];
    }

    flip(r, c);
    flip(r - 1, c);
    flip(r + 1, c);
    flip(r, c - 1);
    flip(r, c + 1);
  }

  void _press(int r, int c) {
    if (_solved) return;
    HapticFeedback.selectionClick();
    setState(() {
      _toggle(r, c);
      _moves += 1;
    });
    _checkWin();
  }

  void _checkWin() {
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        if (_grid[r][c]) return;
      }
    }
    _solved = true;
    ref.read(coinProvider.notifier).award(2);
    if (_moves <= _scrambleCount + 2) {
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
          isAr ? 'إطفاء الأنوار' : 'Lights Out',
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
                    ? 'انقر مربعًا — يبدّل المربع وجيرانه. أطفئ كل الأنوار!'
                    : 'Tap a cell — it toggles itself and its neighbours.\nTurn every light off!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'الحركات' : 'Moves',
                    value: localizeDigits(_moves, arabic: isAr),
                  ),
                  _Pill(
                    label: isAr ? 'الهدف' : 'Target',
                    value:
                        '≤ ${localizeDigits(_scrambleCount + 2, arabic: isAr)}',
                  ),
                ],
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
                      final r = i ~/ _n;
                      final c = i % _n;
                      final on = _grid[r][c];
                      return GestureDetector(
                        onTap: () => _press(r, c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: on
                                ? AppColors.warning
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: on
                                ? [
                                    BoxShadow(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
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
                    _moves <= _scrambleCount + 2
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label  $value', style: AppTextStyles.labelLarge),
    );
  }
}
