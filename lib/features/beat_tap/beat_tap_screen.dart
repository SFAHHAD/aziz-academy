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

class BeatTapScreen extends ConsumerStatefulWidget {
  const BeatTapScreen({super.key});

  @override
  ConsumerState<BeatTapScreen> createState() => _BeatTapScreenState();
}

class _Note {
  _Note({required this.lane, required this.y});
  final int lane;
  double y;
}

class _BeatTapScreenState extends ConsumerState<BeatTapScreen> {
  static const _lanes = 4;
  static const _laneColors = [
    Color(0xFFE53935),
    Color(0xFFFFC107),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
  ];
  static const _duration = 60;
  static const _hitZone = 0.85;
  static const _hitWindow = 0.10;

  Timer? _ticker;
  Timer? _spawner;
  Timer? _countdown;
  final List<_Note> _notes = [];
  int _seconds = _duration;
  int _score = 0;
  int _streak = 0;
  bool _running = false;
  bool _gameOver = false;
  double _fallSpeed = 0.012;
  bool _w20 = false, _w50 = false, _w100 = false;
  String? _flash;

  @override
  void dispose() {
    _ticker?.cancel();
    _spawner?.cancel();
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _notes.clear();
      _seconds = _duration;
      _score = 0;
      _streak = 0;
      _running = true;
      _gameOver = false;
      _fallSpeed = 0.012;
      _w20 = _w50 = _w100 = false;
      _flash = null;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _spawner = Timer.periodic(
      const Duration(milliseconds: 600),
      (_) => _spawn(),
    );
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds -= 1;
        if (_seconds <= 0) {
          t.cancel();
          _stop();
        }
      });
    });
  }

  void _stop() {
    _running = false;
    _gameOver = true;
    _ticker?.cancel();
    _spawner?.cancel();
    _countdown?.cancel();
    _award();
  }

  void _spawn() {
    if (!_running) return;
    final rng = math.Random();
    setState(() {
      _notes.add(_Note(lane: rng.nextInt(_lanes), y: 0.0));
    });
    _fallSpeed = (_fallSpeed + 0.000045).clamp(0.012, 0.022);
  }

  void _tick() {
    if (!_running) return;
    setState(() {
      for (final n in _notes) {
        n.y += _fallSpeed;
      }
      _notes.removeWhere((n) {
        if (n.y > 1.0) {
          _streak = 0;
          return true;
        }
        return false;
      });
    });
  }

  void _laneTap(int lane) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    _Note? best;
    double bestDist = double.infinity;
    for (final n in _notes) {
      if (n.lane != lane) continue;
      final dist = (n.y - _hitZone).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = n;
      }
    }
    if (best != null && bestDist < _hitWindow) {
      setState(() {
        _notes.remove(best);
        final perfect = bestDist < 0.04;
        _score += perfect ? 3 : 1;
        _streak += 1;
        _flash = perfect ? '✨ Perfect!' : 'Good';
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _flash = null);
      });
    } else {
      setState(() {
        _streak = 0;
        _flash = 'Miss';
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _flash = null);
      });
    }
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
          isAr ? 'إيقاع' : 'Beat Tap',
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
                    ? 'اضغط الزر تحت كل نغمة عند وصولها لخط النقر.'
                    : 'Tap each lane button when its note hits the line.',
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
                  _Pill(
                    label: isAr ? 'متتالية' : 'Streak',
                    value: localizeDigits(_streak, arabic: isAr),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final laneW = c.maxWidth / _lanes;
                    final hitY = c.maxHeight * _hitZone;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Hit line
                          Positioned(
                            top: hitY,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              color: AppColors.outline,
                            ),
                          ),
                          // Lane dividers
                          for (int i = 1; i < _lanes; i++)
                            Positioned(
                              left: i * laneW - 0.5,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 1,
                                color: AppColors.outline.withValues(alpha: 0.3),
                              ),
                            ),
                          // Notes
                          for (final n in _notes)
                            Positioned(
                              left: n.lane * laneW + laneW * 0.15,
                              top: n.y * c.maxHeight,
                              width: laneW * 0.7,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _laneColors[n.lane],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          if (_flash != null)
                            Center(
                              child: Text(
                                _flash!,
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: _flash == 'Miss'
                                      ? AppColors.error
                                      : AppColors.success,
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
                                      ? '🎵 انتهت!\nالنقاط: ${localizeDigits(_score, arabic: true)}'
                                      : '🎵 Done!\nScore: $_score',
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
              const SizedBox(height: 8),
              if (_running)
                Row(
                  children: [
                    for (int i = 0; i < _lanes; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTapDown: (_) => _laneTap(i),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: _laneColors[i].withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
