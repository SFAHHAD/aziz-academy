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

class ShapeMatchScreen extends ConsumerStatefulWidget {
  const ShapeMatchScreen({super.key});

  @override
  ConsumerState<ShapeMatchScreen> createState() => _ShapeMatchScreenState();
}

enum _Shape { circle, square, triangle, star, heart, diamond }

class _Tile {
  const _Tile(this.shape, this.color);
  final _Shape shape;
  final Color color;
}

const _palette = <Color>[
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
];

class _ShapeMatchScreenState extends ConsumerState<ShapeMatchScreen> {
  static const _duration = 60;
  static const _gridSize = 9;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  _Tile _target = const _Tile(_Shape.circle, Color(0xFFE53935));
  List<_Tile> _grid = const [];
  String? _msg;
  bool _w12 = false, _w24 = false, _w40 = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _seconds = _duration;
      _score = 0;
      _running = true;
      _msg = null;
    });
    _newRound();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
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

  void _newRound() {
    if (!_running) return;
    final shapes = _Shape.values;
    final target = _Tile(
      shapes[_rng.nextInt(shapes.length)],
      _palette[_rng.nextInt(_palette.length)],
    );
    final cells = <_Tile>[target];
    while (cells.length < _gridSize) {
      final t = _Tile(
        shapes[_rng.nextInt(shapes.length)],
        _palette[_rng.nextInt(_palette.length)],
      );
      // distinct from target on shape OR color
      if (t.shape != target.shape || t.color != target.color) cells.add(t);
    }
    cells.shuffle(_rng);
    setState(() {
      _target = target;
      _grid = cells;
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    final t = _grid[idx];
    if (t.shape == _target.shape && t.color == _target.color) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && _running) _newRound();
      });
    } else {
      setState(() => _msg = '❌');
      Timer(const Duration(milliseconds: 350), () {
        if (mounted && _running) setState(() => _msg = null);
      });
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 12 && !_w12) {
      _w12 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 24 && !_w24) {
      _w24 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 40 && !_w40) {
      _w40 = true;
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
          isAr ? 'مطابقة الأشكال' : 'Shape Match',
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
                    ? 'انقر على الشكل المطابق للمستهدف (نفس الشكل ونفس اللون).'
                    : 'Tap the cell that matches the target (same shape AND color).',
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
              if (_running)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr ? 'الهدف:' : 'Target:',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CustomPaint(
                          painter: _ShapePainter(_target.shape, _target.color),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: _running
                          ? GridView.count(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              children: [
                                for (var i = 0; i < _grid.length; i++)
                                  InkWell(
                                    onTap: () => _tap(i),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.outline,
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: CustomPaint(
                                        painter: _ShapePainter(
                                          _grid[i].shape,
                                          _grid[i].color,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_seconds <= 0 && _score > 0)
                                      Text(
                                        isAr
                                            ? 'النقاط: ${localizeDigits(_score, arabic: true)}'
                                            : 'Score: $_score',
                                        style: AppTextStyles.headingSmall
                                            .copyWith(color: AppColors.success),
                                      ),
                                    const SizedBox(height: 8),
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
                    if (_msg != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _msg!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _msg!.startsWith('✅')
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);
  final _Shape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 2;
    switch (shape) {
      case _Shape.circle:
        canvas.drawCircle(Offset(cx, cy), r, paint);
        break;
      case _Shape.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: r * 1.8,
            height: r * 1.8,
          ),
          paint,
        );
        break;
      case _Shape.triangle:
        final p = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx - r, cy + r * 0.8)
          ..lineTo(cx + r, cy + r * 0.8)
          ..close();
        canvas.drawPath(p, paint);
        break;
      case _Shape.star:
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final rad = i.isEven ? r : r * 0.45;
          final x = cx + math.cos(angle) * rad;
          final y = cy + math.sin(angle) * rad;
          if (i == 0) {
            p.moveTo(x, y);
          } else {
            p.lineTo(x, y);
          }
        }
        p.close();
        canvas.drawPath(p, paint);
        break;
      case _Shape.heart:
        final p = Path();
        p.moveTo(cx, cy + r * 0.6);
        p.cubicTo(
          cx - r * 1.2,
          cy - r * 0.2,
          cx - r * 0.6,
          cy - r * 1.0,
          cx,
          cy - r * 0.3,
        );
        p.cubicTo(
          cx + r * 0.6,
          cy - r * 1.0,
          cx + r * 1.2,
          cy - r * 0.2,
          cx,
          cy + r * 0.6,
        );
        canvas.drawPath(p, paint);
        break;
      case _Shape.diamond:
        final p = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.85, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.85, cy)
          ..close();
        canvas.drawPath(p, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
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
