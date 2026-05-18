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

class TapJumpScreen extends ConsumerStatefulWidget {
  const TapJumpScreen({super.key});

  @override
  ConsumerState<TapJumpScreen> createState() => _TapJumpScreenState();
}

class _Obstacle {
  _Obstacle({required this.x, required this.kind});
  double x;
  final int kind;
}

class _TapJumpScreenState extends ConsumerState<TapJumpScreen> {
  static const _kinds = ['🌵', '🪨', '🌵', '🪨', '🐍'];

  Timer? _ticker;
  double _y = 0; // 0 = ground; positive = jumping up
  double _vy = 0;
  bool _jumping = false;
  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  int _high = 0;
  double _speed = 0.012;
  final List<_Obstacle> _obs = [];
  bool _w15 = false, _w35 = false, _w70 = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _y = 0;
      _vy = 0;
      _jumping = false;
      _running = true;
      _gameOver = false;
      _score = 0;
      _speed = 0.012;
      _obs.clear();
      _obs.add(_Obstacle(x: 1.4, kind: 0));
      _w15 = _w35 = _w70 = false;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _stop() {
    _running = false;
    _gameOver = true;
    _ticker?.cancel();
    if (_score > _high) _high = _score;
    _award();
  }

  void _tick() {
    if (!_running) return;
    setState(() {
      // Gravity
      if (_jumping) {
        _vy -= 0.0035;
        _y += _vy;
        if (_y <= 0) {
          _y = 0;
          _vy = 0;
          _jumping = false;
        }
      }
      // Obstacles move
      for (final o in _obs) {
        o.x -= _speed;
      }
      _obs.removeWhere((o) {
        if (o.x < -0.1) {
          _score += 1;
          return true;
        }
        return false;
      });
      // Spawn new
      final rng = math.Random();
      if (_obs.isEmpty || _obs.last.x < 0.6 - rng.nextDouble() * 0.2) {
        _obs.add(_Obstacle(x: 1.1, kind: rng.nextInt(_kinds.length)));
      }
      // Ramp speed
      _speed = (_speed + 0.000007).clamp(0.012, 0.030);
      // Collision
      for (final o in _obs) {
        if (o.x < 0.18 && o.x > 0.04 && _y < 0.07) {
          _stop();
          break;
        }
      }
    });
  }

  void _jump() {
    if (!_running || _jumping) return;
    HapticFeedback.lightImpact();
    setState(() {
      _jumping = true;
      _vy = 0.05;
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
          isAr ? 'القفز السريع' : 'Tap Jump',
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
                    ? 'اضغط في أي مكان لتقفز فوق العقبات.'
                    : 'Tap anywhere to jump over obstacles.',
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _jump,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const groundFrac = 0.78;
                      final groundY = c.maxHeight * groundFrac;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Ground line
                            Positioned(
                              top: groundY + 30,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: AppColors.outline,
                              ),
                            ),
                            // Player (sticky figure as emoji)
                            Positioned(
                              left: c.maxWidth * 0.08,
                              top: groundY - _y * c.maxHeight * 1.5,
                              child: const Text(
                                '🦘',
                                style: TextStyle(fontSize: 36),
                              ),
                            ),
                            // Obstacles
                            for (final o in _obs)
                              Positioned(
                                left: o.x * c.maxWidth,
                                top: groundY,
                                child: Text(
                                  _kinds[o.kind],
                                  style: const TextStyle(fontSize: 32),
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
                                        ? '💥 انتهت اللعبة!\nالنقاط: ${localizeDigits(_score, arabic: true)}'
                                        : '💥 Game over!\nScore: $_score',
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
