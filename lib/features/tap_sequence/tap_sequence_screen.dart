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

/// Tap Sequence — numbers ١..N appear scattered on a grid; tap them in
/// order. Time is the score. ٢٥ numbers default. Wrong tap = +٢s
/// penalty. +٢🪙 finish, +٥🪙 ≤ ٢٠s, +١٠🪙 ≤ ١٢s.
class TapSequenceScreen extends ConsumerStatefulWidget {
  const TapSequenceScreen({super.key});

  @override
  ConsumerState<TapSequenceScreen> createState() => _TapSequenceScreenState();
}

class _TapSequenceScreenState extends ConsumerState<TapSequenceScreen> {
  static const _n = 25;
  late List<int> _slots; // grid-position -> number (1..n) or 0 for empty
  int _next = 1;
  Stopwatch _sw = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _finished = false;
  bool _firstWin = false, _under20 = false, _under12 = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _newGame() {
    final rng = math.Random();
    final positions = List<int>.generate(36, (i) => i)..shuffle(rng);
    _slots = List<int>.filled(36, 0);
    for (var i = 0; i < _n; i++) {
      _slots[positions[i]] = i + 1;
    }
    setState(() {
      _next = 1;
      _finished = false;
      _elapsed = Duration.zero;
      _sw.reset();
      _sw.start();
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_sw.isRunning) {
        setState(() {
          _elapsed = _sw.elapsed;
        });
      }
    });
  }

  void _tap(int idx) {
    if (_finished) return;
    final v = _slots[idx];
    if (v == 0) return;
    if (v == _next) {
      HapticFeedback.lightImpact();
      setState(() {
        _slots[idx] = 0;
        _next += 1;
        if (_next > _n) {
          _finished = true;
          _sw.stop();
          _award();
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      // Penalty: add 2 seconds (a hidden offset on stopwatch)
      _sw.stop();
      final penalised = _sw.elapsed + const Duration(seconds: 2);
      _sw = Stopwatch()..start();
      // hack: store baseline by re-elapsing
      Future<void>(() async {
        await Future<void>.delayed(penalised);
      });
      // Simpler approach: just compute display elapsed = stopwatch.elapsed + penalty
      // Use the baseline trick: keep a static accumulator.
      _penaltyMs += 2000;
      _sw.start();
    }
  }

  int _penaltyMs = 0;

  Duration get _displayElapsed => _elapsed + Duration(milliseconds: _penaltyMs);

  void _award() {
    HapticFeedback.heavyImpact();
    final s = _displayElapsed.inSeconds;
    if (!_firstWin) {
      _firstWin = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (!_under20 && s <= 20) {
      _under20 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (!_under12 && s <= 12) {
      _under12 = true;
      ref.read(coinProvider.notifier).award(10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final secs = _displayElapsed.inMilliseconds / 1000.0;
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
          isAr ? 'تسلسل الأرقام' : 'Tap Sequence',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isAr ? 'لعبة جديدة' : 'New game',
            onPressed: () {
              _penaltyMs = 0;
              _newGame();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'اضغط الأرقام بالترتيب من ١ إلى ٢٥. الخطأ = +٢ ثانية.'
                    : 'Tap numbers in order from 1 to 25. Mistake = +2s penalty.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'التالي' : 'Next',
                    value: localizeDigits(
                      _finished ? _n : _next.clamp(1, _n),
                      arabic: isAr,
                    ),
                  ),
                  _Pill(
                    label: isAr ? 'الوقت' : 'Time',
                    value: '${secs.toStringAsFixed(1)}s',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: 36,
                    itemBuilder: (context, i) {
                      final v = _slots[i];
                      return GestureDetector(
                        onTap: () => _tap(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: v == 0
                                ? AppColors.surfaceContainerLow
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: v == 0
                                ? null
                                : Text(
                                    localizeDigits(v, arabic: isAr),
                                    style: AppTextStyles.headingSmall,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_finished) ...[
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'انتهيت في ${secs.toStringAsFixed(1)} ثانية! 🎉'
                      : 'Finished in ${secs.toStringAsFixed(1)}s! 🎉',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
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
          Text(value, style: AppTextStyles.headingSmall),
        ],
      ),
    );
  }
}
