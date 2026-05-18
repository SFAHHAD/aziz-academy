import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Brick Breaker — drag the paddle to bounce the ball and clear all bricks.
/// ٣ lives. Earn coins by bricks broken: +٢🪙 first board cleared,
/// +٥🪙 cleared without losing a life, +١٠🪙 finish in <٦٠ seconds.
class BrickBreakerScreen extends ConsumerStatefulWidget {
  const BrickBreakerScreen({super.key});

  @override
  ConsumerState<BrickBreakerScreen> createState() => _BrickBreakerScreenState();
}

class _Brick {
  _Brick(this.col, this.row, this.color);
  final int col;
  final int row;
  final Color color;
  bool alive = true;
}

class _BrickBreakerScreenState extends ConsumerState<BrickBreakerScreen>
    with SingleTickerProviderStateMixin {
  static const _cols = 7;
  static const _rows = 5;
  static const _paddleW = 90.0;
  static const _paddleH = 12.0;
  static const _ballSize = 12.0;
  static const _maxLives = 3;

  Ticker? _ticker;
  Duration _last = Duration.zero;

  Size _playSize = Size.zero;
  double _ballX = 0.5, _ballY = 0.7;
  double _vx = 0.4, _vy = -0.7;
  double _paddleX = 0.5;
  int _lives = _maxLives;
  bool _running = false;
  bool _won = false;
  bool _lost = false;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  final List<_Brick> _bricks = [];
  bool _firstClear = false, _noLossClear = false, _fastClear = false;

  static const _palette = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _newGame();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _newGame() {
    _bricks
      ..clear()
      ..addAll([
        for (var r = 0; r < _rows; r++)
          for (var c = 0; c < _cols; c++) _Brick(c, r, _palette[r]),
      ]);
    setState(() {
      _ballX = 0.5;
      _ballY = 0.7;
      final rng = math.Random();
      final speed = 0.7;
      _vx = (rng.nextDouble() * 0.8 - 0.4) * speed;
      _vy = -0.8 * speed;
      _lives = _maxLives;
      _running = false;
      _won = false;
      _lost = false;
      _elapsed = Duration.zero;
      _startedAt = null;
    });
  }

  void _start() {
    setState(() {
      _running = true;
      _startedAt = DateTime.now();
    });
    _ticker?.start();
  }

  void _resetBall() {
    final rng = math.Random();
    _ballX = 0.5;
    _ballY = 0.7;
    final speed = 0.7;
    _vx = (rng.nextDouble() * 0.8 - 0.4) * speed;
    _vy = -0.8 * speed;
  }

  void _tick(Duration elapsed) {
    if (_playSize.isEmpty || !_running) return;
    final dt = (_last == Duration.zero)
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    setState(() {
      if (_startedAt != null) {
        _elapsed = DateTime.now().difference(_startedAt!);
      }
      _ballX += _vx * dt;
      _ballY += _vy * dt;

      final ballRx = (_ballSize / 2) / _playSize.width;
      final ballRy = (_ballSize / 2) / _playSize.height;

      // Walls
      if (_ballX < ballRx) {
        _ballX = ballRx;
        _vx = _vx.abs();
      } else if (_ballX > 1 - ballRx) {
        _ballX = 1 - ballRx;
        _vx = -_vx.abs();
      }
      if (_ballY < ballRy) {
        _ballY = ballRy;
        _vy = _vy.abs();
      }

      // Paddle
      final paddleHalf = (_paddleW / 2) / _playSize.width;
      if (_ballY > 0.94 - ballRy && _vy > 0) {
        if ((_ballX - _paddleX).abs() < paddleHalf + ballRx) {
          _vy = -_vy.abs();
          final off = (_ballX - _paddleX) / paddleHalf;
          _vx = (_vx + off * 0.35).clamp(-1.0, 1.0);
          HapticFeedback.lightImpact();
        }
      }

      // Bricks: each brick takes (1/_cols x 0.06) of play area at top-third.
      final brickW = 1.0 / _cols;
      const brickHRel = 0.05;
      const topPad = 0.05;
      for (final b in _bricks) {
        if (!b.alive) continue;
        final left = b.col * brickW;
        final top = topPad + b.row * brickHRel;
        if (_ballX > left - ballRx &&
            _ballX < left + brickW + ballRx &&
            _ballY > top - ballRy &&
            _ballY < top + brickHRel + ballRy) {
          b.alive = false;
          // Reflect: simple Y-flip is fine for kid game
          _vy = -_vy;
          _vx = (_vx * 1.02).clamp(-1.1, 1.1);
          _vy = (_vy * 1.02).clamp(-1.1, 1.1);
          HapticFeedback.selectionClick();
          break;
        }
      }

      // Bottom: lose life
      if (_ballY > 1.05) {
        _lives -= 1;
        if (_lives <= 0) {
          _running = false;
          _lost = true;
          _ticker?.stop();
        } else {
          _resetBall();
          HapticFeedback.heavyImpact();
        }
      }

      if (_bricks.every((b) => !b.alive)) {
        _running = false;
        _won = true;
        _ticker?.stop();
        _award();
      }
    });
  }

  void _award() {
    if (!_firstClear) {
      _firstClear = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (!_noLossClear && _lives == _maxLives) {
      _noLossClear = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (!_fastClear && _elapsed.inSeconds < 60) {
      _fastClear = true;
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
          isAr ? 'كاسر القرميد' : 'Brick Breaker',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isAr ? 'لعبة جديدة' : 'New game',
            onPressed: () {
              _ticker?.stop();
              _newGame();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(label: isAr ? 'الأرواح' : 'Lives', value: '❤' * _lives),
                  _Pill(
                    label: isAr ? 'الوقت' : 'Time',
                    value: localizeDigits(_elapsed.inSeconds, arabic: isAr),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    _playSize = Size(c.maxWidth, c.maxHeight);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) {
                        if (!_running) return;
                        setState(() {
                          _paddleX += d.delta.dx / c.maxWidth;
                          _paddleX = _paddleX.clamp(0.05, 0.95);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Stack(
                          children: [
                            // Bricks
                            for (final b in _bricks)
                              if (b.alive)
                                Positioned(
                                  left: b.col * (c.maxWidth / _cols) + 2,
                                  top:
                                      0.05 * c.maxHeight +
                                      b.row * (0.05 * c.maxHeight),
                                  width: c.maxWidth / _cols - 4,
                                  height: 0.05 * c.maxHeight - 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: b.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            // Paddle
                            Positioned(
                              left: _paddleX * c.maxWidth - _paddleW / 2,
                              top: 0.94 * c.maxHeight - _paddleH / 2,
                              child: Container(
                                width: _paddleW,
                                height: _paddleH,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            // Ball
                            Positioned(
                              left: _ballX * c.maxWidth - _ballSize / 2,
                              top: _ballY * c.maxHeight - _ballSize / 2,
                              child: Container(
                                width: _ballSize,
                                height: _ballSize,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            if (!_running)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _won
                                        ? (isAr ? 'انتصرت! 🎉' : 'Cleared! 🎉')
                                        : _lost
                                        ? (isAr
                                              ? 'انتهت الأرواح'
                                              : 'Out of lives')
                                        : (isAr ? 'اضغط ابدأ' : 'Tap Start'),
                                    style: AppTextStyles.headingSmall,
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
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  if (_won || _lost) {
                    _newGame();
                    _start();
                  } else if (!_running) {
                    _start();
                  }
                },
                icon: Icon(_won || _lost ? Icons.replay : Icons.play_arrow),
                label: Text(
                  _won || _lost
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
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}
