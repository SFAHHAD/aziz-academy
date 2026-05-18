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

class FractionMatchScreen extends ConsumerStatefulWidget {
  const FractionMatchScreen({super.key});

  @override
  ConsumerState<FractionMatchScreen> createState() =>
      _FractionMatchScreenState();
}

class _Frac {
  const _Frac(this.num, this.den);
  final int num;
  final int den;
  String label(bool isAr) =>
      '${localizeDigits(num, arabic: isAr)}/${localizeDigits(den, arabic: isAr)}';
  double get value => num / den;
}

const _candidates = <_Frac>[
  _Frac(1, 2),
  _Frac(1, 3),
  _Frac(2, 3),
  _Frac(1, 4),
  _Frac(3, 4),
  _Frac(1, 5),
  _Frac(2, 5),
  _Frac(3, 5),
  _Frac(4, 5),
  _Frac(1, 6),
  _Frac(5, 6),
  _Frac(1, 8),
  _Frac(3, 8),
  _Frac(5, 8),
  _Frac(7, 8),
];

class _FractionMatchScreenState extends ConsumerState<FractionMatchScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  _Frac _answer = const _Frac(1, 2);
  List<_Frac> _options = const [];
  String? _msg;
  bool _w8 = false, _w16 = false, _w26 = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _seconds = _duration;
      _score = 0;
      _running = true;
      _msg = null;
    });
    _newRound();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
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

  void _newRound() {
    if (!_running) return;
    final correct = _candidates[_rng.nextInt(_candidates.length)];
    final pool = [..._candidates]..shuffle(_rng);
    final opts = <_Frac>{correct};
    for (final c in pool) {
      if (opts.length >= 4) break;
      if (c.value != correct.value) opts.add(c);
    }
    final shuffled = opts.toList()..shuffle(_rng);
    setState(() {
      _answer = correct;
      _options = shuffled;
      _msg = null;
    });
  }

  void _tap(_Frac f) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (f.value == _answer.value) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 250), () {
        if (mounted && _running) _newRound();
      });
    } else {
      final isAr = Directionality.of(context) == TextDirection.rtl;
      setState(() => _msg = '❌ ${_answer.label(isAr)}');
      Timer(const Duration(milliseconds: 600), () {
        if (mounted && _running) _newRound();
      });
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 8 && !_w8) {
      _w8 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 16 && !_w16) {
      _w16 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 26 && !_w26) {
      _w26 = true;
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
          isAr ? 'مطابقة الكسور' : 'Fraction Match',
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
                    ? 'انظر إلى الجزء المُلوّن واختر الكسر المطابق.'
                    : 'Look at the shaded portion and pick the matching fraction.',
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
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: _running
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CustomPaint(
                                painter: _PiePainter(
                                  num: _answer.num,
                                  den: _answer.den,
                                  shaded: AppColors.primary,
                                  empty: AppColors.surfaceContainer,
                                  outline: AppColors.outline,
                                ),
                              ),
                            ),
                            if (_msg != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _msg!,
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: _msg!.startsWith('✅')
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_seconds <= 0 && _score > 0)
                                Text(
                                  isAr
                                      ? 'النقاط: ${localizeDigits(_score, arabic: true)}'
                                      : 'Score: $_score',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              if (_running)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final f in _options)
                      ElevatedButton(
                        onPressed: () => _tap(f),
                        child: Text(
                          f.label(isAr),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.num,
    required this.den,
    required this.shaded,
    required this.empty,
    required this.outline,
  });

  final int num;
  final int den;
  final Color shaded;
  final Color empty;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shadePaint = Paint()..color = shaded;
    final emptyPaint = Paint()..color = empty;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Empty background
    canvas.drawCircle(center, radius, emptyPaint);

    // Slices
    final slice = 2 * math.pi / den;
    for (var i = 0; i < den; i++) {
      final start = -math.pi / 2 + i * slice;
      if (i < num) {
        canvas.drawArc(rect, start, slice, true, shadePaint);
      }
    }

    // Slice outlines
    for (var i = 0; i < den; i++) {
      final angle = -math.pi / 2 + i * slice;
      final p2 = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, p2, outlinePaint);
    }
    canvas.drawCircle(center, radius, outlinePaint);
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.num != num || old.den != den;
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
