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

class AsteroidDodgeScreen extends ConsumerStatefulWidget {
  const AsteroidDodgeScreen({super.key});

  @override
  ConsumerState<AsteroidDodgeScreen> createState() =>
      _AsteroidDodgeScreenState();
}

class _Rock {
  _Rock({required this.x, required this.y, required this.speed});
  double x;
  double y;
  double speed;
}

class _AsteroidDodgeScreenState extends ConsumerState<AsteroidDodgeScreen> {
  static const _duration = 60;
  static const _shipSize = 32.0;
  static const _rockSize = 28.0;

  final _rng = math.Random();
  Timer? _ticker;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  double _shipX = 0.5;
  final List<_Rock> _rocks = [];
  String? _msg;
  bool _w15 = false, _w30 = false, _w50 = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _rocks.clear();
    setState(() {
      _seconds = _duration;
      _score = 0;
      _running = true;
      _shipX = 0.5;
      _msg = null;
    });
    int frames = 0;
    _ticker = Timer.periodic(const Duration(milliseconds: 32), (t) {
      if (!_running) {
        t.cancel();
        return;
      }
      frames += 1;
      // Tick seconds every ~31 frames (~1s)
      if (frames % 31 == 0) {
        setState(() {
          _seconds -= 1;
          if (_seconds <= 0) {
            _running = false;
            t.cancel();
            _award();
            return;
          }
        });
      }
      // Spawn
      final spawnRate = 0.05 + math.min(0.10, _score / 800);
      if (_rng.nextDouble() < spawnRate) {
        _rocks.add(
          _Rock(
            x: 0.05 + _rng.nextDouble() * 0.90,
            y: -0.05,
            speed: 0.012 + _rng.nextDouble() * 0.012,
          ),
        );
      }
      // Move
      for (final r in _rocks) {
        r.y += r.speed;
      }
      _rocks.removeWhere((r) {
        if (r.y > 1.05) {
          _score += 1;
          return true;
        }
        return false;
      });
      // Collision (simple AABB in normalized coords vs ship pos)
      for (final r in _rocks) {
        if ((r.y > 0.86 && r.y < 0.99) && (r.x - _shipX).abs() < 0.06) {
          // hit
          HapticFeedback.heavyImpact();
          setState(() {
            _running = false;
            _msg = '💥';
          });
          _ticker?.cancel();
          _award();
          return;
        }
      }
      setState(() {});
    });
  }

  void _move(double normalizedX, double width) {
    if (!_running) return;
    setState(() {
      _shipX = (normalizedX / width).clamp(0.05, 0.95);
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 15 && !_w15) {
      _w15 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 30 && !_w30) {
      _w30 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 50 && !_w50) {
      _w50 = true;
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
          isAr ? 'تجنّب الكويكبات' : 'Asteroid Dodge',
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
                    ? 'حرّك السفينة بإصبعك لتفادي الكويكبات.'
                    : 'Drag your finger to dodge falling asteroids.',
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return GestureDetector(
                      onPanUpdate: (d) => _move(d.localPosition.dx, c.maxWidth),
                      onPanStart: (d) => _move(d.localPosition.dx, c.maxWidth),
                      onTapDown: (d) => _move(d.localPosition.dx, c.maxWidth),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1B33),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Stars
                            for (var i = 0; i < 30; i++)
                              Positioned(
                                left: ((i * 37) % 100) / 100 * c.maxWidth,
                                top: ((i * 53) % 100) / 100 * c.maxHeight,
                                child: const Text(
                                  '·',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            // Asteroids
                            for (final r in _rocks)
                              Positioned(
                                left: r.x * c.maxWidth - _rockSize / 2,
                                top: r.y * c.maxHeight - _rockSize / 2,
                                child: const Text(
                                  '☄️',
                                  style: TextStyle(fontSize: 26),
                                ),
                              ),
                            // Ship
                            if (_running || _msg == '💥')
                              Positioned(
                                left: _shipX * c.maxWidth - _shipSize / 2,
                                top: c.maxHeight - _shipSize - 8,
                                child: const Text(
                                  '🚀',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                            if (!_running)
                              Center(
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
                                      if (_msg == '💥')
                                        Text(
                                          isAr ? 'اصطدمت!' : 'Crashed!',
                                          style: AppTextStyles.headingSmall
                                              .copyWith(color: AppColors.error),
                                        ),
                                      if (_score > 0)
                                        Text(
                                          isAr
                                              ? 'النقاط: ${localizeDigits(_score, arabic: true)}'
                                              : 'Score: $_score',
                                          style: AppTextStyles.headingSmall
                                              .copyWith(
                                                color: AppColors.success,
                                              ),
                                        ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _start,
                                        icon: Icon(
                                          _seconds <= 0 || _msg == '💥'
                                              ? Icons.replay
                                              : Icons.play_arrow,
                                        ),
                                        label: Text(
                                          (_seconds <= 0 || _msg == '💥')
                                              ? (isAr
                                                    ? 'مرة أخرى'
                                                    : 'Play again')
                                              : (isAr ? 'ابدأ' : 'Start'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
