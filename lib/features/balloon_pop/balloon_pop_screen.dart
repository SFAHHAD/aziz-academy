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

class BalloonPopScreen extends ConsumerStatefulWidget {
  const BalloonPopScreen({super.key});

  @override
  ConsumerState<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _Balloon {
  _Balloon({
    required this.x,
    required this.y,
    required this.kind,
    required this.speed,
  });
  final double x;
  double y;
  final int kind; // 0..3 = colored balloons, 4 = bomb
  final double speed;
}

class _BalloonPopScreenState extends ConsumerState<BalloonPopScreen> {
  static const _emoji = ['🎈', '🎈', '🎈', '🎈', '💣'];
  static const _colors = [
    Colors.transparent,
    Colors.transparent,
    Colors.transparent,
    Colors.transparent,
    Color(0xFFE53935),
  ];

  Timer? _ticker;
  Timer? _spawner;
  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = 3;
  double _baseSpeed = 0.006;
  final List<_Balloon> _balloons = [];
  bool _w15 = false, _w35 = false, _w70 = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _spawner?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _balloons.clear();
      _running = true;
      _gameOver = false;
      _score = 0;
      _lives = 3;
      _baseSpeed = 0.006;
      _w15 = _w35 = _w70 = false;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _spawner = Timer.periodic(
      const Duration(milliseconds: 750),
      (_) => _spawn(),
    );
  }

  void _stop() {
    _running = false;
    _gameOver = true;
    _ticker?.cancel();
    _spawner?.cancel();
    _award();
  }

  void _spawn() {
    if (!_running) return;
    final rng = math.Random();
    final isBomb = rng.nextDouble() < 0.18;
    setState(() {
      _balloons.add(
        _Balloon(
          x: 0.06 + rng.nextDouble() * 0.88,
          y: 1.05,
          kind: isBomb ? 4 : rng.nextInt(4),
          speed: _baseSpeed + rng.nextDouble() * 0.003,
        ),
      );
    });
    _baseSpeed = math.min(_baseSpeed + 0.00007, 0.018);
  }

  void _tick() {
    if (!_running) return;
    setState(() {
      for (final b in _balloons) {
        b.y -= b.speed;
      }
      _balloons.removeWhere((b) {
        if (b.y < -0.05) {
          // Missed: lose life if it was a normal balloon (didn't pop in time)
          if (b.kind != 4) {
            _lives -= 1;
            HapticFeedback.heavyImpact();
          }
          return true;
        }
        return false;
      });
      if (_lives <= 0) _stop();
    });
  }

  void _tap(_Balloon b) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    setState(() {
      _balloons.remove(b);
      if (b.kind == 4) {
        _lives -= 1;
        if (_lives <= 0) {
          _stop();
        }
      } else {
        _score += 1;
      }
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 15 && !_w15) {
      _w15 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 35 && !_w35) {
      _w35 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 70 && !_w70) {
      _w70 = true;
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
          isAr ? 'فقاعات البالونات' : 'Balloon Pop',
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
                    ? 'اضغط البالونات لتفجيرها وتجنّب القنابل!'
                    : 'Pop the balloons and avoid the bombs!',
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
                    label: isAr ? 'القلوب' : 'Lives',
                    value: '❤️' * _lives,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (final b in _balloons)
                            Positioned(
                              left: b.x * c.maxWidth - 22,
                              top: b.y * c.maxHeight - 22,
                              child: GestureDetector(
                                onTap: () => _tap(b),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _colors[b.kind].withValues(
                                      alpha: 0.4,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _emoji[b.kind],
                                    style: const TextStyle(fontSize: 32),
                                  ),
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
                                      ? '💥 انتهت!\nالنقاط: ${localizeDigits(_score, arabic: true)}'
                                      : '💥 Done!\nScore: $_score',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.success,
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
