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

/// Math Sprint — solve as many +/-/× problems as you can in ٦٠ seconds.
/// Reward by total correct: +٢🪙 first ١٠ correct, +٥🪙 ٢٠+, +١٠🪙 ٣٥+.
class MathSprintScreen extends ConsumerStatefulWidget {
  const MathSprintScreen({super.key});

  @override
  ConsumerState<MathSprintScreen> createState() => _MathSprintScreenState();
}

enum _Op { add, sub, mul }

class _Question {
  _Question(this.a, this.b, this.op);
  final int a;
  final int b;
  final _Op op;
  int get answer {
    switch (op) {
      case _Op.add:
        return a + b;
      case _Op.sub:
        return a - b;
      case _Op.mul:
        return a * b;
    }
  }

  String get text {
    final sym = switch (op) {
      _Op.add => '+',
      _Op.sub => '-',
      _Op.mul => '×',
    };
    return '$a $sym $b';
  }
}

class _MathSprintScreenState extends ConsumerState<MathSprintScreen> {
  static const _duration = 60;
  Timer? _timer;
  int _seconds = _duration;
  int _correct = 0;
  int _wrong = 0;
  bool _running = false;
  late _Question _q;
  List<int> _choices = [];
  bool _w10 = false, _w20 = false, _w35 = false;

  @override
  void initState() {
    super.initState();
    _q = _gen();
    _choices = _makeChoices(_q);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _Question _gen() {
    final rng = math.Random();
    final op = _Op.values[rng.nextInt(_Op.values.length)];
    int a, b;
    switch (op) {
      case _Op.add:
        a = rng.nextInt(40) + 5;
        b = rng.nextInt(40) + 5;
        break;
      case _Op.sub:
        a = rng.nextInt(50) + 20;
        b = rng.nextInt(a - 1) + 1;
        break;
      case _Op.mul:
        a = rng.nextInt(11) + 2;
        b = rng.nextInt(11) + 2;
        break;
    }
    return _Question(a, b, op);
  }

  List<int> _makeChoices(_Question q) {
    final rng = math.Random();
    final correct = q.answer;
    final out = {correct};
    while (out.length < 4) {
      final delta = rng.nextInt(15) - 7;
      final cand = correct + (delta == 0 ? 1 : delta);
      if (cand >= 0) out.add(cand);
    }
    final list = out.toList()..shuffle(rng);
    return list;
  }

  void _start() {
    setState(() {
      _running = true;
      _seconds = _duration;
      _correct = 0;
      _wrong = 0;
      _q = _gen();
      _choices = _makeChoices(_q);
    });
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

  void _answer(int v) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (v == _q.answer) {
        _correct += 1;
      } else {
        _wrong += 1;
      }
      _q = _gen();
      _choices = _makeChoices(_q);
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_correct >= 10 && !_w10) {
      _w10 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_correct >= 20 && !_w20) {
      _w20 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_correct >= 35 && !_w35) {
      _w35 = true;
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
          isAr ? 'سباق الحساب' : 'Math Sprint',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
                    label: isAr ? 'صحيح' : 'Right',
                    value: localizeDigits(_correct, arabic: isAr),
                    color: AppColors.success,
                  ),
                  _Pill(
                    label: isAr ? 'خطأ' : 'Wrong',
                    value: localizeDigits(_wrong, arabic: isAr),
                    color: AppColors.error,
                  ),
                ],
              ),
              const Spacer(),
              if (_running) ...[
                Text(
                  _q.text,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in _choices)
                      SizedBox(
                        width: 110,
                        height: 70,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainer,
                            foregroundColor: AppColors.textDark,
                          ),
                          onPressed: () => _answer(c),
                          child: Text(
                            localizeDigits(c, arabic: isAr),
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                  ],
                ),
              ] else if (_seconds <= 0) ...[
                Text(
                  isAr
                      ? 'النتيجة: ${localizeDigits(_correct, arabic: true)} صحيح'
                      : 'Final: $_correct correct',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.replay),
                  label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                ),
              ] else ...[
                Text(
                  isAr
                      ? 'احسب أكبر عدد ممكن في ٦٠ ثانية'
                      : 'Solve as many as you can in 60 seconds',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(isAr ? 'ابدأ' : 'Start'),
                ),
              ],
              const Spacer(),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          Text(value, style: AppTextStyles.headingSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
