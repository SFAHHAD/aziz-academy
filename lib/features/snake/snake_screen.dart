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

/// Classic Snake — 15×15 grid. Eat fruits to grow. +١🪙 every 5 fruits,
/// +٥🪙 if score reaches 20 (game length cap).
class SnakeScreen extends ConsumerStatefulWidget {
  const SnakeScreen({super.key});

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState();
}

enum _Dir { up, down, left, right }

class _SnakeScreenState extends ConsumerState<SnakeScreen> {
  static const int _grid = 15;
  static const Duration _tick = Duration(milliseconds: 220);

  late List<math.Point<int>> _snake;
  late math.Point<int> _food;
  _Dir _dir = _Dir.right;
  _Dir _nextDir = _Dir.right;
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  int _coinsAwarded = 0;
  Timer? _timer;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _reset() {
    _snake = [
      const math.Point(7, 7),
      const math.Point(6, 7),
      const math.Point(5, 7),
    ];
    _dir = _Dir.right;
    _nextDir = _Dir.right;
    _score = 0;
    _gameOver = false;
    _coinsAwarded = 0;
    _placeFood();
    setState(() {});
  }

  void _placeFood() {
    final rng = math.Random();
    while (true) {
      final p = math.Point(rng.nextInt(_grid), rng.nextInt(_grid));
      if (!_snake.contains(p)) {
        _food = p;
        return;
      }
    }
  }

  void _start() {
    if (_gameOver) _reset();
    _running = true;
    _focus.requestFocus();
    _timer = Timer.periodic(_tick, (_) => _step());
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _running = false;
    setState(() {});
  }

  void _step() {
    final head = _snake.first;
    _dir = _nextDir;
    final dx = switch (_dir) {
      _Dir.left => -1,
      _Dir.right => 1,
      _ => 0,
    };
    final dy = switch (_dir) {
      _Dir.up => -1,
      _Dir.down => 1,
      _ => 0,
    };
    final next = math.Point(head.x + dx, head.y + dy);

    if (next.x < 0 || next.x >= _grid || next.y < 0 || next.y >= _grid) {
      _endGame();
      return;
    }
    if (_snake.contains(next)) {
      _endGame();
      return;
    }

    _snake.insert(0, next);
    if (next == _food) {
      _score += 1;
      if (_score % 5 == 0) {
        ref.read(coinProvider.notifier).award(1);
        _coinsAwarded += 1;
      }
      if (_score >= 20) {
        ref.read(coinProvider.notifier).award(5);
        _coinsAwarded += 5;
        _endGame();
        return;
      }
      _placeFood();
    } else {
      _snake.removeLast();
    }
    setState(() {});
  }

  void _endGame() {
    _timer?.cancel();
    _running = false;
    _gameOver = true;
    setState(() {});
  }

  void _turn(_Dir d) {
    if (_dir == _Dir.up && d == _Dir.down) return;
    if (_dir == _Dir.down && d == _Dir.up) return;
    if (_dir == _Dir.left && d == _Dir.right) return;
    if (_dir == _Dir.right && d == _Dir.left) return;
    _nextDir = d;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent ev) {
    if (ev is! KeyDownEvent) return KeyEventResult.ignored;
    final k = ev.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) _turn(_Dir.up);
    if (k == LogicalKeyboardKey.arrowDown) _turn(_Dir.down);
    if (k == LogicalKeyboardKey.arrowLeft) _turn(_Dir.left);
    if (k == LogicalKeyboardKey.arrowRight) _turn(_Dir.right);
    return KeyEventResult.handled;
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
          isAr ? 'الثعبان' : 'Snake',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  isAr
                      ? 'كل ٢٠ تفاحة لتفوز! تجنّب الجدران وذيلك.'
                      : 'Eat 20 apples to win! Avoid walls and your own tail.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Pill(
                      label: isAr ? 'النقاط' : 'Score',
                      value: localizeDigits(_score, arabic: isAr),
                    ),
                    _Pill(
                      label: '🪙',
                      value: localizeDigits(_coinsAwarded, arabic: isAr),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onVerticalDragUpdate: (d) {
                      if (d.delta.dy < -2) _turn(_Dir.up);
                      if (d.delta.dy > 2) _turn(_Dir.down);
                    },
                    onHorizontalDragUpdate: (d) {
                      if (d.delta.dx < -2) _turn(_Dir.left);
                      if (d.delta.dx > 2) _turn(_Dir.right);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textDark.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _BoardPainter(
                          snake: _snake,
                          food: _food,
                          grid: _grid,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_running && !_gameOver)
                      ElevatedButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(isAr ? 'ابدأ' : 'Start'),
                      ),
                    if (_running)
                      ElevatedButton.icon(
                        onPressed: _pause,
                        icon: const Icon(Icons.pause),
                        label: Text(isAr ? 'إيقاف' : 'Pause'),
                      ),
                    if (_gameOver) ...[
                      ElevatedButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.replay),
                        label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (_gameOver)
                  Text(
                    _score >= 20
                        ? (isAr
                              ? '🎉 رائع! وصلت إلى ${localizeDigits(_score, arabic: true)}'
                              : '🎉 Amazing! You reached $_score')
                        : (isAr
                              ? 'انتهت اللعبة. النقاط: ${localizeDigits(_score, arabic: true)}'
                              : 'Game over. Score: $_score'),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                const Spacer(),
                _DPad(onTurn: _turn, isAr: isAr),
              ],
            ),
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

class _DPad extends StatelessWidget {
  const _DPad({required this.onTurn, required this.isAr});

  final void Function(_Dir) onTurn;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, _Dir d) => SizedBox(
      width: 56,
      height: 56,
      child: ElevatedButton(
        onPressed: () => onTurn(d),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerHigh,
          foregroundColor: AppColors.textDark,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Icon(icon),
      ),
    );

    return Column(
      children: [
        btn(Icons.keyboard_arrow_up, _Dir.up),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn(Icons.keyboard_arrow_left, _Dir.left),
            const SizedBox(width: 56),
            btn(Icons.keyboard_arrow_right, _Dir.right),
          ],
        ),
        const SizedBox(height: 6),
        btn(Icons.keyboard_arrow_down, _Dir.down),
      ],
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.snake, required this.food, required this.grid});

  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final int grid;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / grid;

    final foodPaint = Paint()..color = AppColors.error;
    canvas.drawCircle(
      Offset(food.x * cell + cell / 2, food.y * cell + cell / 2),
      cell * 0.4,
      foodPaint,
    );

    for (var i = 0; i < snake.length; i++) {
      final p = snake[i];
      final paint = Paint()
        ..color = i == 0 ? AppColors.primary : AppColors.secondary;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cell + 1, p.y * cell + 1, cell - 2, cell - 2),
        Radius.circular(cell * 0.2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.snake != snake || old.food != food;
}
