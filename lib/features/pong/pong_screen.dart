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

/// Pong vs CPU — drag the bottom paddle. First to ٧ points wins.
/// Reaction-based: ball speeds up after each rally hit.
/// +٢🪙 first win, +٥🪙 win without losing a point, +١٠🪙 win ١٠-٠.
class PongScreen extends ConsumerStatefulWidget {
  const PongScreen({super.key});

  @override
  ConsumerState<PongScreen> createState() => _PongScreenState();
}

class _PongScreenState extends ConsumerState<PongScreen>
    with SingleTickerProviderStateMixin {
  static const _paddleW = 80.0;
  static const _paddleH = 12.0;
  static const _ballSize = 14.0;
  static const _maxScore = 7;

  Ticker? _ticker;
  Duration _last = Duration.zero;

  // Normalized 0..1 coords inside the play area.
  double _ballX = 0.5;
  double _ballY = 0.5;
  double _vx = 0.5; // per-second velocity (units of play area)
  double _vy = 0.5;
  double _playerPaddleX = 0.5;
  double _cpuPaddleX = 0.5;

  int _playerScore = 0;
  int _cpuScore = 0;
  bool _running = false;
  bool _gameOver = false;
  bool _firstWinAwarded = false;

  Size _playSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _resetBall(serveDown: true);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _gameOver = false;
      _playerScore = 0;
      _cpuScore = 0;
    });
    _resetBall(serveDown: true);
    _ticker?.start();
  }

  void _resetBall({required bool serveDown}) {
    final rng = math.Random();
    _ballX = 0.5;
    _ballY = 0.5;
    final dirY = serveDown ? 1 : -1;
    final speed = 0.55;
    final angleX = (rng.nextDouble() * 0.8) - 0.4; // [-0.4, 0.4]
    _vx = angleX * speed;
    _vy = dirY * speed;
  }

  void _onTick(Duration elapsed) {
    if (_playSize.isEmpty) return;
    final dt = (_last == Duration.zero)
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!_running) return;

    setState(() {
      _ballX += _vx * dt;
      _ballY += _vy * dt;

      // CPU follows ball with a soft cap on speed (gives player a chance).
      final delta = (_ballX - _cpuPaddleX);
      final cpuSpeed = 0.65; // per-second
      _cpuPaddleX += delta.sign * math.min(cpuSpeed * dt, delta.abs());

      // Wall bounce L/R
      final ballR = (_ballSize / 2) / _playSize.width;
      if (_ballX < ballR) {
        _ballX = ballR;
        _vx = _vx.abs();
      } else if (_ballX > 1 - ballR) {
        _ballX = 1 - ballR;
        _vx = -_vx.abs();
      }

      // Top paddle (CPU) at y=0.06, bottom (Player) at y=0.94
      final ballRy = (_ballSize / 2) / _playSize.height;
      final paddleHalf = (_paddleW / 2) / _playSize.width;

      // Top hit
      if (_ballY < 0.06 + ballRy && _vy < 0) {
        if ((_ballX - _cpuPaddleX).abs() < paddleHalf + ballR) {
          _vy = _vy.abs();
          // Spin: shift vx based on hit position
          final off = (_ballX - _cpuPaddleX) / paddleHalf;
          _vx = (_vx + off * 0.25).clamp(-0.9, 0.9);
          _speedUp();
          HapticFeedback.lightImpact();
        }
      }
      // Bottom hit
      if (_ballY > 0.94 - ballRy && _vy > 0) {
        if ((_ballX - _playerPaddleX).abs() < paddleHalf + ballR) {
          _vy = -_vy.abs();
          final off = (_ballX - _playerPaddleX) / paddleHalf;
          _vx = (_vx + off * 0.25).clamp(-0.9, 0.9);
          _speedUp();
          HapticFeedback.lightImpact();
        }
      }

      // Scoring
      if (_ballY < -0.04) {
        _playerScore += 1;
        HapticFeedback.mediumImpact();
        _checkEnd();
        if (!_gameOver) _resetBall(serveDown: true);
      } else if (_ballY > 1.04) {
        _cpuScore += 1;
        HapticFeedback.mediumImpact();
        _checkEnd();
        if (!_gameOver) _resetBall(serveDown: false);
      }
    });
  }

  void _speedUp() {
    final factor = 1.04;
    _vx = (_vx * factor).clamp(-1.5, 1.5);
    _vy = (_vy * factor).clamp(-1.5, 1.5);
  }

  void _checkEnd() {
    if (_playerScore >= _maxScore || _cpuScore >= _maxScore) {
      _running = false;
      _gameOver = true;
      _ticker?.stop();
      if (_playerScore > _cpuScore) _award();
    }
  }

  void _award() {
    if (!_firstWinAwarded) {
      _firstWinAwarded = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_cpuScore == 0) {
      ref.read(coinProvider.notifier).award(5);
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
        title: Text(isAr ? 'بونغ' : 'Pong', style: AppTextStyles.headingSmall),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScorePill(
                    label: isAr ? 'الحاسب' : 'CPU',
                    value: localizeDigits(_cpuScore, arabic: isAr),
                  ),
                  _ScorePill(
                    label: isAr ? 'أنت' : 'You',
                    value: localizeDigits(_playerScore, arabic: isAr),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    _playSize = Size(c.maxWidth, c.maxHeight);
                    return GestureDetector(
                      onPanUpdate: (d) {
                        if (!_running) return;
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        setState(() {
                          _playerPaddleX += d.delta.dx / c.maxWidth;
                          _playerPaddleX = _playerPaddleX.clamp(0.05, 0.95);
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
                            // Center dashed line
                            Center(
                              child: Container(
                                height: 1,
                                color: AppColors.outline.withValues(alpha: 0.4),
                              ),
                            ),
                            // CPU paddle
                            Positioned(
                              left: _cpuPaddleX * c.maxWidth - _paddleW / 2,
                              top: 0.06 * c.maxHeight - _paddleH / 2,
                              child: _Paddle(color: AppColors.error),
                            ),
                            // Player paddle
                            Positioned(
                              left: _playerPaddleX * c.maxWidth - _paddleW / 2,
                              top: 0.94 * c.maxHeight - _paddleH / 2,
                              child: _Paddle(color: AppColors.primary),
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
                                    _gameOver
                                        ? (_playerScore > _cpuScore
                                              ? (isAr
                                                    ? 'فزت! 🎉'
                                                    : 'You won! 🎉')
                                              : (isAr
                                                    ? 'فاز الحاسب'
                                                    : 'CPU won'))
                                        : (isAr
                                              ? 'اضغط ابدأ للعب'
                                              : 'Tap Start to play'),
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
              const SizedBox(height: 12),
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

class _Paddle extends StatelessWidget {
  const _Paddle({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PongScreenState._paddleW,
      height: _PongScreenState._paddleH,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          Text(value, style: AppTextStyles.headingSmall),
        ],
      ),
    );
  }
}
