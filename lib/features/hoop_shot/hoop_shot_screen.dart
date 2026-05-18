import 'dart:async';

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

class HoopShotScreen extends ConsumerStatefulWidget {
  const HoopShotScreen({super.key});

  @override
  ConsumerState<HoopShotScreen> createState() => _HoopShotScreenState();
}

class _HoopShotScreenState extends ConsumerState<HoopShotScreen> {
  static const _maxShots = 10;
  static const _greenZone = 0.42;
  static const _greenWidth = 0.16;

  Timer? _meter;
  double _power = 0.0;
  double _dir = 1.0;
  bool _running = false;
  bool _gameOver = false;
  int _shots = 0;
  int _makes = 0;
  String? _msg;
  bool _ballAnim = false;
  double _ballT = 0;
  bool _lastMake = false;
  bool _awarded = false;

  @override
  void dispose() {
    _meter?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _shots = 0;
      _makes = 0;
      _running = true;
      _gameOver = false;
      _msg = null;
      _awarded = false;
      _power = 0;
      _dir = 1.0;
    });
    _startMeter();
  }

  void _startMeter() {
    _meter?.cancel();
    _meter = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_running || _ballAnim) return;
      setState(() {
        _power += _dir * 0.018;
        if (_power >= 1.0) {
          _power = 1.0;
          _dir = -1.0;
        } else if (_power <= 0) {
          _power = 0;
          _dir = 1.0;
        }
      });
    });
  }

  Future<void> _shoot() async {
    if (!_running || _ballAnim) return;
    HapticFeedback.lightImpact();
    final lockedPower = _power;
    final make =
        lockedPower >= _greenZone && lockedPower <= _greenZone + _greenWidth;
    setState(() {
      _ballAnim = true;
      _ballT = 0;
      _lastMake = make;
      _msg = null;
    });
    // Animate ball
    for (var i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 22));
      if (!mounted) return;
      setState(() => _ballT = (i + 1) / 30);
    }
    if (!mounted) return;
    setState(() {
      _shots += 1;
      if (make) {
        _makes += 1;
        _msg = '🏀 Score!';
      } else {
        _msg = lockedPower < _greenZone ? '↓ Short' : '↑ Long';
      }
      _ballAnim = false;
      _ballT = 0;
      _power = 0;
      _dir = 1.0;
      if (_shots >= _maxShots) {
        _running = false;
        _gameOver = true;
        _award();
      }
    });
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    int reward;
    if (_makes >= 8) {
      reward = 10;
    } else if (_makes >= 5) {
      reward = 5;
    } else if (_makes >= 3) {
      reward = 2;
    } else {
      reward = 0;
    }
    if (reward > 0) {
      ref.read(coinProvider.notifier).award(reward);
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
          isAr ? 'الرمية الحرة' : 'Hoop Shot',
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
                    ? 'شريط القوة يتحرك. اضغط عندما يصل للمنطقة الخضراء لتسجل!'
                    : 'Power bar oscillates. Tap when in the green zone to score!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'الرميات' : 'Shots',
                    value:
                        '${localizeDigits(_shots, arabic: isAr)}/${localizeDigits(_maxShots, arabic: isAr)}',
                    color: AppColors.textDark,
                  ),
                  _Pill(
                    label: isAr ? 'تسجيلات' : 'Makes',
                    value: localizeDigits(_makes, arabic: isAr),
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final hoopY = c.maxHeight * 0.18;
                    final shooterY = c.maxHeight * 0.78;
                    final ballX = c.maxWidth * 0.5;
                    final ballY = _ballAnim
                        ? shooterY + (hoopY - shooterY) * _ballT
                        : shooterY - 18;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Hoop (rim)
                          Positioned(
                            left: c.maxWidth * 0.5 - 32,
                            top: hoopY,
                            child: Container(
                              width: 64,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Backboard
                          Positioned(
                            left: c.maxWidth * 0.5 - 50,
                            top: hoopY - 50,
                            child: Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                border: Border.all(
                                  color: AppColors.outline,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Net (lines)
                          Positioned(
                            left: c.maxWidth * 0.5 - 24,
                            top: hoopY + 8,
                            child: const Text(
                              '|||||',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 20,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          // Ball
                          Positioned(
                            left: ballX - 18,
                            top: ballY,
                            child: const Text(
                              '🏀',
                              style: TextStyle(fontSize: 36),
                            ),
                          ),
                          // Shooter
                          Positioned(
                            left: c.maxWidth * 0.5 - 18,
                            top: shooterY + 20,
                            child: const Text(
                              '🧍',
                              style: TextStyle(fontSize: 36),
                            ),
                          ),
                          if (_msg != null)
                            Positioned(
                              top: c.maxHeight * 0.45,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  _msg!,
                                  style: AppTextStyles.headingMedium.copyWith(
                                    color: _lastMake
                                        ? AppColors.success
                                        : AppColors.error,
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
                                      ? 'النتيجة: ${localizeDigits(_makes, arabic: true)}/${localizeDigits(_maxShots, arabic: true)}'
                                      : 'Final: $_makes/$_maxShots',
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
              if (_running)
                _PowerMeter(
                  power: _power,
                  greenZone: _greenZone,
                  greenWidth: _greenWidth,
                )
              else
                const SizedBox(height: 32),
              const SizedBox(height: 12),
              if (_running)
                ElevatedButton.icon(
                  onPressed: _ballAnim ? null : _shoot,
                  icon: const Icon(Icons.sports_basketball),
                  label: Text(isAr ? 'سدد!' : 'Shoot!'),
                )
              else
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

class _PowerMeter extends StatelessWidget {
  const _PowerMeter({
    required this.power,
    required this.greenZone,
    required this.greenWidth,
  });
  final double power;
  final double greenZone;
  final double greenWidth;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          child: Stack(
            children: [
              // Green zone
              Positioned(
                left: greenZone * c.maxWidth,
                top: 4,
                bottom: 4,
                child: Container(
                  width: greenWidth * c.maxWidth,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Indicator
              Positioned(
                left: power * c.maxWidth - 4,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
