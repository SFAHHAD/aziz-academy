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

/// Odd One Out — grid of identical-looking tiles with one tile a slightly
/// different shade. Tap the odd one. Each correct find = +١ point and
/// the next round gets harder (smaller color difference, more tiles).
/// ٤٥-second game. +٢🪙 first ٥, +٥🪙 ١٥+, +١٠🪙 ٣٠+.
class OddOneOutScreen extends ConsumerStatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  ConsumerState<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends ConsumerState<OddOneOutScreen> {
  static const _duration = 45;
  Timer? _timer;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  late Color _baseColor;
  late Color _oddColor;
  late int _oddIdx;
  int _gridSize = 3;
  bool _w5 = false, _w15 = false, _w30 = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _randomBase() {
    final rng = math.Random();
    return HSLColor.fromAHSL(1.0, rng.nextDouble() * 360, 0.6, 0.55).toColor();
  }

  void _newRound() {
    final rng = math.Random();
    _baseColor = _randomBase();
    // Difficulty: harder = smaller delta. Score 0 → big delta; score 30 → small.
    final delta = (28 - _score.clamp(0, 26)).clamp(2, 28);
    final base = HSLColor.fromColor(_baseColor);
    _oddColor = base
        .withLightness((base.lightness + delta / 100).clamp(0.0, 1.0))
        .toColor();
    _gridSize = _score < 5
        ? 3
        : _score < 15
        ? 4
        : _score < 25
        ? 5
        : 6;
    _oddIdx = rng.nextInt(_gridSize * _gridSize);
  }

  void _start() {
    setState(() {
      _running = true;
      _seconds = _duration;
      _score = 0;
    });
    _newRound();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds -= 1;
        if (_seconds <= 0) {
          _running = false;
          t.cancel();
          _award();
        }
      });
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    if (idx == _oddIdx) {
      HapticFeedback.lightImpact();
      setState(() {
        _score += 1;
        _newRound();
      });
    } else {
      HapticFeedback.heavyImpact();
      // Penalty: reduce score by 1 (min 0)
      setState(() {
        if (_score > 0) _score -= 1;
      });
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 5 && !_w5) {
      _w5 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 15 && !_w15) {
      _w15 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 30 && !_w30) {
      _w30 = true;
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
          isAr ? 'الشاذ' : 'Odd One Out',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'اضغط على المربع المختلف بين الباقي.'
                    : 'Tap the tile that looks different from the rest.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _running
                      ? GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _gridSize,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                          itemCount: _gridSize * _gridSize,
                          itemBuilder: (context, i) {
                            return GestureDetector(
                              onTap: () => _tap(i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i == _oddIdx ? _oddColor : _baseColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_seconds <= 0)
                                Text(
                                  isAr
                                      ? 'النقاط النهائية: ${localizeDigits(_score, arabic: true)}'
                                      : 'Final score: $_score',
                                  style: AppTextStyles.headingMedium.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _start,
                                icon: Icon(
                                  _seconds <= 0
                                      ? Icons.replay
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  _seconds <= 0
                                      ? (isAr ? 'مرة أخرى' : 'Play again')
                                      : (isAr ? 'ابدأ' : 'Start'),
                                ),
                              ),
                            ],
                          ),
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
