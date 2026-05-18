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

class CrossyLaneScreen extends ConsumerStatefulWidget {
  const CrossyLaneScreen({super.key});

  @override
  ConsumerState<CrossyLaneScreen> createState() => _CrossyLaneScreenState();
}

class _Lane {
  _Lane({required this.dir, required this.speed, required this.cars});
  final int dir; // -1 left, +1 right
  final double speed;
  final List<double> cars; // x positions [0..1]
}

class _CrossyLaneScreenState extends ConsumerState<CrossyLaneScreen> {
  static const _rows = 9; // 0=top safe, 8=bottom safe; 1..7 lanes
  static const _cols = 7;

  Timer? _ticker;
  int _px = 3;
  int _py = 8;
  int _score = 0;
  int _high = 0;
  bool _running = false;
  bool _gameOver = false;
  List<_Lane?> _lanes = const [];
  bool _w5 = false, _w12 = false, _w25 = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    final rng = math.Random();
    setState(() {
      _px = 3;
      _py = 8;
      _score = 0;
      _running = true;
      _gameOver = false;
      _w5 = _w12 = _w25 = false;
      _lanes = List.generate(_rows, (r) {
        if (r == 0 || r == 8 || r == 4) return null;
        final cars = <double>[];
        var x = rng.nextDouble();
        for (var i = 0; i < 2; i++) {
          cars.add(x);
          x = (x + 0.4 + rng.nextDouble() * 0.2) % 1.0;
        }
        return _Lane(
          dir: rng.nextBool() ? 1 : -1,
          speed: 0.0035 + rng.nextDouble() * 0.0035,
          cars: cars,
        );
      });
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 32), (_) => _tick());
  }

  void _tick() {
    if (!_running) return;
    setState(() {
      for (final lane in _lanes) {
        if (lane == null) continue;
        for (var i = 0; i < lane.cars.length; i++) {
          var x = lane.cars[i] + lane.dir * lane.speed;
          if (x > 1.05) x -= 1.10;
          if (x < -0.05) x += 1.10;
          lane.cars[i] = x;
        }
      }
      // Collision
      final lane = _lanes[_py];
      if (lane != null) {
        final px = (_px + 0.5) / _cols;
        for (final cx in lane.cars) {
          final carCenter = cx + 0.10;
          if ((carCenter - px).abs() < 0.10) {
            _stop();
            return;
          }
        }
      }
    });
  }

  void _stop() {
    _running = false;
    _gameOver = true;
    _ticker?.cancel();
    if (_score > _high) _high = _score;
    _award();
  }

  void _move(int dx, int dy) {
    if (!_running || _gameOver) return;
    HapticFeedback.lightImpact();
    setState(() {
      final nx = (_px + dx).clamp(0, _cols - 1);
      final ny = (_py + dy).clamp(0, _rows - 1);
      _px = nx;
      _py = ny;
      if (_py == 0) {
        _score += 1;
        _py = 8;
        _px = 3;
      }
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 5 && !_w5) {
      _w5 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 12 && !_w12) {
      _w12 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 25 && !_w25) {
      _w25 = true;
      ref.read(coinProvider.notifier).award(10);
    }
  }

  Color _rowColor(int r) {
    if (r == 0) return AppColors.success.withValues(alpha: 0.4);
    if (r == 8) return AppColors.success.withValues(alpha: 0.25);
    if (r == 4) return AppColors.warning.withValues(alpha: 0.25);
    return AppColors.surfaceContainer;
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
          isAr ? 'عبور المسار' : 'Crossy Lane',
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
                    ? 'اعبر المسار وتجنّب السيارات. المنطقة الخضراء آمنة.'
                    : 'Cross the road dodging cars. Green rows are safe.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'النقاط' : 'Score',
                    value: localizeDigits(_score, arabic: isAr),
                    color: AppColors.success,
                  ),
                  _Pill(
                    label: isAr ? 'الأفضل' : 'High',
                    value: localizeDigits(_high, arabic: isAr),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: _cols / _rows,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cellW = c.maxWidth / _cols;
                      final cellH = c.maxHeight / _rows;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.outline,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Row background
                            Column(
                              children: [
                                for (int r = 0; r < _rows; r++)
                                  Expanded(
                                    child: Container(color: _rowColor(r)),
                                  ),
                              ],
                            ),
                            // Cars
                            for (int r = 0; r < _rows; r++)
                              if (_lanes.length > r && _lanes[r] != null)
                                for (final cx in _lanes[r]!.cars)
                                  Positioned(
                                    left: cx * c.maxWidth,
                                    top: r * cellH + cellH * 0.1,
                                    width: cellW * 1.4,
                                    height: cellH * 0.8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '🚗',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                            // Player
                            Positioned(
                              left: _px * cellW,
                              top: _py * cellH,
                              width: cellW,
                              height: cellH,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                alignment: Alignment.center,
                                child: const Text(
                                  '🐔',
                                  style: TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            if (_gameOver)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isAr
                                        ? '💥 صدمت!\nالنقاط: ${localizeDigits(_score, arabic: true)}'
                                        : '💥 Squashed!\nScore: $_score',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_running)
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: Icon(_gameOver ? Icons.replay : Icons.play_arrow),
                  label: Text(
                    _gameOver
                        ? (isAr ? 'مرة أخرى' : 'Play again')
                        : (isAr ? 'ابدأ' : 'Start'),
                  ),
                )
              else
                Column(
                  children: [
                    IconButton.filled(
                      onPressed: () => _move(0, -1),
                      icon: const Icon(Icons.arrow_upward, size: 28),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: () => _move(-1, 0),
                          icon: const Icon(Icons.arrow_back, size: 28),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () => _move(0, 1),
                          icon: const Icon(Icons.arrow_downward, size: 28),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () => _move(1, 0),
                          icon: const Icon(Icons.arrow_forward, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
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
