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

class StickHeroScreen extends ConsumerStatefulWidget {
  const StickHeroScreen({super.key});

  @override
  ConsumerState<StickHeroScreen> createState() => _StickHeroScreenState();
}

enum _Phase { idle, growing, falling, walking, dead }

class _StickHeroScreenState extends ConsumerState<StickHeroScreen> {
  static const double _platformY = 0.7;

  // All distances/widths are fractions of canvas width.
  double _myLeft = 0.05;
  double _myWidth = 0.18;
  double _nextLeft = 0.45;
  double _nextWidth = 0.18;

  double _stickLength = 0.0;
  double _stickAngle = 0.0; // 0 = vertical (growing); pi/2 = horizontal
  double _heroX = 0.0;

  Timer? _ticker;
  _Phase _phase = _Phase.idle;
  int _score = 0;
  int _high = 0;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _myLeft = 0.05;
      _myWidth = 0.18;
      _stickLength = 0.0;
      _stickAngle = 0.0;
      _phase = _Phase.idle;
      _score = 0;
      _running = true;
      _setupNext();
      _heroX = _myLeft + _myWidth - 0.04;
    });
  }

  void _setupNext() {
    final rng = math.Random();
    final gapMin = 0.10;
    final gapMax = 0.35;
    final gap = gapMin + rng.nextDouble() * (gapMax - gapMin);
    _nextWidth = 0.08 + rng.nextDouble() * 0.13;
    _nextLeft = _myLeft + _myWidth + gap;
    if (_nextLeft + _nextWidth > 0.98) {
      _nextLeft = 0.98 - _nextWidth;
    }
  }

  void _startGrow(_) {
    if (!_running || _phase != _Phase.idle) return;
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _Phase.growing;
      _stickLength = 0.005;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_phase != _Phase.growing) return;
      setState(() {
        _stickLength = (_stickLength + 0.012).clamp(0.0, 0.85);
      });
    });
  }

  Future<void> _release([Object? _]) async {
    if (!_running || _phase != _Phase.growing) return;
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    final lockedLength = _stickLength;
    setState(() => _phase = _Phase.falling);
    // Animate stick falling
    for (var i = 1; i <= 14; i++) {
      await Future.delayed(const Duration(milliseconds: 22));
      if (!mounted) return;
      setState(() => _stickAngle = math.pi / 2 * (i / 14));
    }
    // Determine outcome
    final tipX = _myLeft + _myWidth - 0.005 + lockedLength;
    final reachedNext = tipX >= _nextLeft && tipX <= _nextLeft + _nextWidth;
    if (reachedNext) {
      // Walk to next platform
      setState(() => _phase = _Phase.walking);
      final target = _nextLeft + _nextWidth - 0.04;
      while (_heroX < target) {
        await Future.delayed(const Duration(milliseconds: 18));
        if (!mounted) return;
        setState(() {
          _heroX = math.min(_heroX + 0.012, target);
        });
      }
      // Score and shift to make next pillar appear from right
      setState(() {
        _score += 1;
        if (_score > _high) _high = _score;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      // Shift left (new "current" platform becomes the next; spawn new next)
      setState(() {
        _myLeft = _nextLeft;
        _myWidth = _nextWidth;
        _stickLength = 0;
        _stickAngle = 0;
        _phase = _Phase.idle;
        _heroX = _myLeft + _myWidth - 0.04;
        _setupNext();
      });
    } else {
      // Hero falls
      setState(() => _phase = _Phase.dead);
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      _award();
      setState(() {
        _running = false;
      });
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    int reward;
    if (_score >= 15) {
      reward = 10;
    } else if (_score >= 8) {
      reward = 5;
    } else if (_score >= 3) {
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
          isAr ? 'بطل العصا' : 'Stick Hero',
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
                    ? 'اضغط مطولًا لتمديد العصا. اتركها لتسقط على المنصة التالية.'
                    : 'Press and hold to extend the stick. Release to drop it onto the next platform.',
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
                  onTapDown: _startGrow,
                  onTapUp: _release,
                  onTapCancel: () => _release(),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final h = c.maxHeight;
                      final platTop = h * _platformY;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Current platform
                            Positioned(
                              left: _myLeft * w,
                              top: platTop,
                              width: _myWidth * w,
                              height: h * 0.30,
                              child: Container(color: AppColors.primary),
                            ),
                            // Next platform
                            Positioned(
                              left: _nextLeft * w,
                              top: platTop,
                              width: _nextWidth * w,
                              height: h * 0.30,
                              child: Container(color: AppColors.success),
                            ),
                            // Stick
                            Positioned(
                              left: (_myLeft + _myWidth - 0.005) * w,
                              top: platTop,
                              child: Transform(
                                alignment: Alignment.topLeft,
                                transform: Matrix4.identity()
                                  ..rotateZ(_stickAngle),
                                child: Container(
                                  width: 4,
                                  height: -_stickLength * w,
                                  color: AppColors.textDark,
                                  transform: Matrix4.translationValues(
                                    0,
                                    _stickLength * w,
                                    0,
                                  ),
                                ),
                              ),
                            ),
                            // Hero
                            Positioned(
                              left: _heroX * w,
                              top: platTop - 30,
                              child: AnimatedRotation(
                                turns: _phase == _Phase.dead ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: const Text(
                                  '🤺',
                                  style: TextStyle(fontSize: 30),
                                ),
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
                                      if (_score > 0)
                                        Text(
                                          isAr
                                              ? '😢 سقطت!\nالنقاط: ${localizeDigits(_score, arabic: true)}'
                                              : '😢 You fell!\nScore: $_score',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.headingSmall
                                              .copyWith(color: AppColors.error),
                                        ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _newGame,
                                        icon: Icon(
                                          _score > 0
                                              ? Icons.replay
                                              : Icons.play_arrow,
                                        ),
                                        label: Text(
                                          _score > 0
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
                      );
                    },
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
