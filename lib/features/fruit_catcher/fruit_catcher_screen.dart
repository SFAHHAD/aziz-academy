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

class FruitCatcherScreen extends ConsumerStatefulWidget {
  const FruitCatcherScreen({super.key});

  @override
  ConsumerState<FruitCatcherScreen> createState() => _FruitCatcherScreenState();
}

class _FallingItem {
  _FallingItem({
    required this.x,
    required this.y,
    required this.emoji,
    required this.bad,
    required this.speed,
  });
  double x;
  double y;
  final String emoji;
  final bool bad;
  final double speed;
}

class _FruitCatcherScreenState extends ConsumerState<FruitCatcherScreen> {
  static const _fruits = ['🍎', '🍌', '🍇', '🍊', '🍉', '🍓', '🍑', '🥝'];
  static const _bads = ['💣', '🧅', '🌶️'];

  Timer? _ticker;
  Timer? _spawner;
  double _basketX = 0.5;
  int _score = 0;
  int _lives = 3;
  bool _running = false;
  final List<_FallingItem> _items = [];
  bool _w20 = false, _w50 = false, _w100 = false;
  double _baseSpeed = 0.005;

  @override
  void dispose() {
    _ticker?.cancel();
    _spawner?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _items.clear();
      _basketX = 0.5;
      _score = 0;
      _lives = 3;
      _running = true;
      _w20 = _w50 = _w100 = false;
      _baseSpeed = 0.005;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
    _spawner = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => _spawn(),
    );
  }

  void _stop() {
    _ticker?.cancel();
    _spawner?.cancel();
    setState(() => _running = false);
    _award();
  }

  void _spawn() {
    if (!_running) return;
    final rng = math.Random();
    final bad = rng.nextDouble() < 0.18;
    setState(() {
      _items.add(
        _FallingItem(
          x: 0.05 + rng.nextDouble() * 0.9,
          y: -0.05,
          emoji: bad
              ? _bads[rng.nextInt(_bads.length)]
              : _fruits[rng.nextInt(_fruits.length)],
          bad: bad,
          speed: _baseSpeed + rng.nextDouble() * 0.003,
        ),
      );
    });
    _baseSpeed = math.min(_baseSpeed + 0.00006, 0.018);
  }

  void _tick() {
    if (!_running) return;
    setState(() {
      for (final it in _items) {
        it.y += it.speed;
      }
      final caught = <_FallingItem>[];
      for (final it in _items) {
        if (it.y >= 0.85 && it.y <= 0.95) {
          if ((it.x - _basketX).abs() < 0.10) {
            caught.add(it);
            if (it.bad) {
              HapticFeedback.heavyImpact();
              _lives -= 1;
            } else {
              HapticFeedback.lightImpact();
              _score += 1;
            }
          }
        }
      }
      _items.removeWhere((it) => caught.contains(it) || it.y > 1.05);
      if (_lives <= 0) _stop();
    });
  }

  void _move(double dx) {
    if (!_running) return;
    setState(() {
      _basketX = (_basketX + dx).clamp(0.05, 0.95);
    });
  }

  void _onTap(double xRatio) {
    if (!_running) return;
    _move(xRatio < 0.5 ? -0.10 : 0.10);
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 20 && !_w20) {
      _w20 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 50 && !_w50) {
      _w50 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 100 && !_w100) {
      _w100 = true;
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
          isAr ? 'صياد الفاكهة' : 'Fruit Catcher',
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
                    ? 'اضغط يمين/يسار لتحريك السلة. أمسك الفاكهة وتجنّب القنابل.'
                    : 'Tap left/right to move. Catch fruit, dodge bombs.',
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
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _onTap(d.localPosition.dx / c.maxWidth),
                      onPanUpdate: (d) {
                        if (!_running) return;
                        setState(() {
                          _basketX = (_basketX + d.delta.dx / c.maxWidth).clamp(
                            0.05,
                            0.95,
                          );
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            for (final it in _items)
                              Positioned(
                                left: it.x * c.maxWidth - 16,
                                top: it.y * c.maxHeight - 16,
                                child: Text(
                                  it.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            Positioned(
                              left: _basketX * c.maxWidth - 28,
                              top: c.maxHeight * 0.88 - 24,
                              child: const Text(
                                '🧺',
                                style: TextStyle(fontSize: 44),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (!_running)
                Column(
                  children: [
                    if (_score > 0)
                      Text(
                        isAr
                            ? 'النقاط النهائية: ${localizeDigits(_score, arabic: true)}'
                            : 'Final score: $_score',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _start,
                      icon: Icon(_score > 0 ? Icons.replay : Icons.play_arrow),
                      label: Text(
                        _score > 0
                            ? (isAr ? 'مرة أخرى' : 'Play again')
                            : (isAr ? 'ابدأ' : 'Start'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filled(
                      onPressed: () => _move(-0.08),
                      icon: const Icon(Icons.arrow_left, size: 32),
                    ),
                    IconButton.filled(
                      onPressed: () => _move(0.08),
                      icon: const Icon(Icons.arrow_right, size: 32),
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
