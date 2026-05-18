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

/// Pegs Solitaire — English ٣٣-hole cross. Tap a peg, then tap a
/// valid landing hole (٢ steps over a peg). The jumped peg is removed.
/// Win = ١ peg in the center hole. +٢🪙 first finish (≤ ٣ pegs left),
/// +٥🪙 ≤ ٢ left, +١٠🪙 perfect ١ peg in center.
class PegsScreen extends ConsumerStatefulWidget {
  const PegsScreen({super.key});

  @override
  ConsumerState<PegsScreen> createState() => _PegsScreenState();
}

class _PegsScreenState extends ConsumerState<PegsScreen> {
  // 7x7 grid: 0 = wall, 1 = peg, 2 = empty
  late List<List<int>> _g;
  int? _selR, _selC;
  int _moves = 0;
  bool _firstWin = false, _solved2 = false, _solved1Center = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  static const _layout = [
    '0011100',
    '0011100',
    '1111111',
    '1112111',
    '1111111',
    '0011100',
    '0011100',
  ];

  void _newGame() {
    setState(() {
      _g = List.generate(
        7,
        (r) => List.generate(
          7,
          (c) => int.parse(_layout[r][c].toString(), radix: 16),
        ),
      );
      _selR = null;
      _selC = null;
      _moves = 0;
    });
  }

  bool _validJump(int sr, int sc, int er, int ec) {
    if (_g[sr][sc] != 1 || _g[er][ec] != 2) return false;
    final dr = er - sr, dc = ec - sc;
    if (!((dr.abs() == 2 && dc == 0) || (dr == 0 && dc.abs() == 2))) {
      return false;
    }
    final mr = sr + dr ~/ 2, mc = sc + dc ~/ 2;
    return _g[mr][mc] == 1;
  }

  void _doJump(int sr, int sc, int er, int ec) {
    final mr = sr + (er - sr) ~/ 2, mc = sc + (ec - sc) ~/ 2;
    HapticFeedback.lightImpact();
    setState(() {
      _g[sr][sc] = 2;
      _g[mr][mc] = 2;
      _g[er][ec] = 1;
      _moves += 1;
      _selR = null;
      _selC = null;
      _checkEnd();
    });
  }

  bool _hasAnyMove() {
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 7; c++) {
        if (_g[r][c] != 1) continue;
        for (final d in const [
          [-2, 0],
          [2, 0],
          [0, -2],
          [0, 2],
        ]) {
          final nr = r + d[0], nc = c + d[1];
          if (nr >= 0 && nr < 7 && nc >= 0 && nc < 7) {
            if (_validJump(r, c, nr, nc)) return true;
          }
        }
      }
    }
    return false;
  }

  int _pegCount() {
    var n = 0;
    for (final row in _g) {
      for (final v in row) {
        if (v == 1) n++;
      }
    }
    return n;
  }

  void _checkEnd() {
    if (_hasAnyMove()) return;
    final n = _pegCount();
    if (n <= 3) {
      if (!_firstWin) {
        _firstWin = true;
        ref.read(coinProvider.notifier).award(2);
      }
    }
    if (n <= 2) {
      if (!_solved2) {
        _solved2 = true;
        ref.read(coinProvider.notifier).award(5);
      }
    }
    if (n == 1 && _g[3][3] == 1) {
      if (!_solved1Center) {
        _solved1Center = true;
        ref.read(coinProvider.notifier).award(10);
      }
    }
    HapticFeedback.heavyImpact();
  }

  void _onTap(int r, int c) {
    if (_g[r][c] == 0) return;
    if (_selR == null) {
      if (_g[r][c] == 1) {
        setState(() {
          _selR = r;
          _selC = c;
        });
      }
      return;
    }
    if (_selR == r && _selC == c) {
      setState(() {
        _selR = null;
        _selC = null;
      });
      return;
    }
    if (_g[r][c] == 2 && _validJump(_selR!, _selC!, r, c)) {
      _doJump(_selR!, _selC!, r, c);
    } else if (_g[r][c] == 1) {
      // Re-select
      setState(() {
        _selR = r;
        _selC = c;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final n = _pegCount();
    final stuck = !_hasAnyMove();
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
          isAr ? 'لعبة الأوتاد' : 'Pegs Solitaire',
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'اقفز بكل وتد فوق وتد مجاور إلى مكان فارغ. الهدف: وتد واحد في المنتصف.'
                    : 'Jump each peg over an adjacent peg into an empty hole. Goal: 1 peg in the center.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'أوتاد متبقية' : 'Pegs',
                    value: localizeDigits(n, arabic: isAr),
                  ),
                  _Pill(
                    label: isAr ? 'حركات' : 'Moves',
                    value: localizeDigits(_moves, arabic: isAr),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: 49,
                    itemBuilder: (context, i) {
                      final r = i ~/ 7;
                      final c = i % 7;
                      final v = _g[r][c];
                      if (v == 0) return const SizedBox.shrink();
                      final selected = _selR == r && _selC == c;
                      final canLand =
                          _selR != null &&
                          v == 2 &&
                          _validJump(_selR!, _selC!, r, c);
                      return GestureDetector(
                        onTap: () => _onTap(r, c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: v == 1
                                ? Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.warning,
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
                                  )
                                : canLand
                                ? Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (stuck) ...[
                const SizedBox(height: 12),
                Text(
                  n == 1 && _g[3][3] == 1
                      ? (isAr ? 'حلٌّ مثالي! 🎉' : 'Perfect solve! 🎉')
                      : (isAr
                            ? 'انتهت! تبقّى ${localizeDigits(n, arabic: true)} وتد'
                            : 'Stuck! $n pegs left'),
                  style: AppTextStyles.headingSmall,
                ),
              ],
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
