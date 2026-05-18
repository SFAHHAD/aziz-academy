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

class StackBuilderScreen extends ConsumerStatefulWidget {
  const StackBuilderScreen({super.key});

  @override
  ConsumerState<StackBuilderScreen> createState() => _StackBuilderScreenState();
}

class _StackBlock {
  _StackBlock({required this.left, required this.width, required this.color});
  final double left;
  final double width;
  final Color color;
}

class _StackBuilderScreenState extends ConsumerState<StackBuilderScreen> {
  static const _palette = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFFC107),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF00BCD4),
  ];

  Timer? _ticker;
  final List<_StackBlock> _stack = [];
  double _movingLeft = 0.0;
  double _movingWidth = 0.5;
  double _dir = 1.0;
  double _speed = 0.012;
  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  bool _w10 = false, _w20 = false, _w40 = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _stack.clear();
      _stack.add(_StackBlock(left: 0.25, width: 0.5, color: _palette[0]));
      _movingLeft = 0.0;
      _movingWidth = 0.5;
      _dir = 1.0;
      _speed = 0.012;
      _running = true;
      _gameOver = false;
      _score = 0;
      _w10 = _w20 = _w40 = false;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    if (!_running) return;
    setState(() {
      _movingLeft += _dir * _speed;
      if (_movingLeft + _movingWidth >= 1.0) {
        _movingLeft = 1.0 - _movingWidth;
        _dir = -1.0;
      } else if (_movingLeft <= 0) {
        _movingLeft = 0;
        _dir = 1.0;
      }
    });
  }

  void _drop() {
    if (!_running || _gameOver) return;
    HapticFeedback.lightImpact();
    final top = _stack.last;
    final overlapLeft = _movingLeft > top.left ? _movingLeft : top.left;
    final overlapRight = (_movingLeft + _movingWidth) < (top.left + top.width)
        ? (_movingLeft + _movingWidth)
        : (top.left + top.width);
    final overlap = overlapRight - overlapLeft;
    if (overlap <= 0.005) {
      _running = false;
      _gameOver = true;
      _ticker?.cancel();
      _award();
      setState(() {});
      return;
    }
    setState(() {
      _stack.add(
        _StackBlock(
          left: overlapLeft,
          width: overlap,
          color: _palette[(_score + 1) % _palette.length],
        ),
      );
      _score += 1;
      _movingWidth = overlap;
      _movingLeft = overlapLeft > 0.5 ? 0.0 : 1.0 - overlap;
      _dir = overlapLeft > 0.5 ? 1.0 : -1.0;
      _speed = (_speed + 0.0008).clamp(0.012, 0.030);
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 10 && !_w10) {
      _w10 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 20 && !_w20) {
      _w20 = true;
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
          isAr ? 'بناء الكتل' : 'Stack Builder',
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
                    ? 'اضغط في الوقت المناسب لإسقاط الكتلة فوق سابقتها بدقة.'
                    : 'Tap to drop each block; align it with the one below.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _Pill(
                label: isAr ? 'الطوابق' : 'Stacked',
                value: localizeDigits(_score, arabic: isAr),
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _drop,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const blockH = 22.0;
                      const movingTop = 30.0;
                      final stackBaseTop = c.maxHeight - 60;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Stack (fixed at bottom, growing upward).
                            for (int i = 0; i < _stack.length; i++)
                              Positioned(
                                left: _stack[i].left * c.maxWidth,
                                top: stackBaseTop - i * blockH,
                                width: _stack[i].width * c.maxWidth,
                                height: blockH,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _stack[i].color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            // Moving block at top.
                            if (_running && !_gameOver)
                              Positioned(
                                left: _movingLeft * c.maxWidth,
                                top: movingTop,
                                width: _movingWidth * c.maxWidth,
                                height: blockH,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _palette[(_score + 1) %
                                            _palette.length],
                                    borderRadius: BorderRadius.circular(3),
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
                                        ? '😢 سقط البرج!\nالطوابق: ${localizeDigits(_score, arabic: true)}'
                                        : '😢 Tower fell!\nStacked: $_score',
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
