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

class SpeedMathScreen extends ConsumerStatefulWidget {
  const SpeedMathScreen({super.key});

  @override
  ConsumerState<SpeedMathScreen> createState() => _SpeedMathScreenState();
}

enum _Op { add, sub, mul, div }

class _SpeedMathScreenState extends ConsumerState<SpeedMathScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  String _expr = '';
  int _answer = 0;
  List<int> _options = const [];
  String? _msg;
  bool _w10 = false, _w20 = false, _w32 = false;

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

  _Op _pickOp() {
    if (_score < 4) {
      return _rng.nextBool() ? _Op.add : _Op.sub;
    }
    if (_score < 10) {
      final r = _rng.nextInt(3);
      return r == 0 ? _Op.add : (r == 1 ? _Op.sub : _Op.mul);
    }
    final r = _rng.nextInt(4);
    return _Op.values[r];
  }

  void _newRound() {
    if (!_running) return;
    final op = _pickOp();
    int a, b, ans;
    String sym;
    switch (op) {
      case _Op.add:
        a = _rng.nextInt(_score < 6 ? 20 : 50) + 1;
        b = _rng.nextInt(_score < 6 ? 20 : 50) + 1;
        ans = a + b;
        sym = '+';
      case _Op.sub:
        a = _rng.nextInt(_score < 6 ? 20 : 60) + 5;
        b = _rng.nextInt(a) + 1;
        ans = a - b;
        sym = '−';
      case _Op.mul:
        a = _rng.nextInt(_score < 12 ? 9 : 12) + 2;
        b = _rng.nextInt(_score < 12 ? 9 : 12) + 2;
        ans = a * b;
        sym = '×';
      case _Op.div:
        b = _rng.nextInt(8) + 2;
        ans = _rng.nextInt(10) + 2;
        a = b * ans;
        sym = '÷';
    }
    final opts = <int>{ans};
    while (opts.length < 4) {
      final delta = _rng.nextInt(8) - 4;
      final cand = ans + delta + (delta == 0 ? (_rng.nextInt(3) + 1) : 0);
      if (cand >= 0) opts.add(cand);
    }
    final list = opts.toList()..shuffle(_rng);
    setState(() {
      _expr = '$a $sym $b = ?';
      _answer = ans;
      _options = list;
    });
  }

  void _tap(int v) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (v == _answer) {
      setState(() {
        _score += 1;
        _msg = '✅';
      });
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && _running) _newRound();
      });
    } else {
      setState(() {
        _score = math.max(0, _score - 1);
        _msg = '❌';
      });
      Timer(const Duration(milliseconds: 350), () {
        if (mounted && _running) _newRound();
      });
    }
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
    if (_score >= 32 && !_w32) {
      _w32 = true;
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
          isAr ? 'الحساب السريع' : 'Speed Math',
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
                    ? 'احسب بسرعة! اضغط الإجابة الصحيحة.'
                    : 'Solve fast! Tap the correct answer.',
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
                            Text(
                              _localizeExpr(_expr, isAr),
                              style: AppTextStyles.headingLarge.copyWith(
                                color: AppColors.textDark,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.4,
                              children: [
                                for (final v in _options)
                                  ElevatedButton(
                                    onPressed: () => _tap(v),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      localizeDigits(v, arabic: isAr),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_msg != null) ...[
                              const SizedBox(height: 12),
                              Text(_msg!, style: const TextStyle(fontSize: 22)),
                            ],
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _seconds == _duration
                                  ? (isAr ? '📐 جاهز؟' : '📐 Ready?')
                                  : (isAr
                                        ? 'انتهى! نقاطك: ${localizeDigits(_score, arabic: true)}'
                                        : 'Done! Score: ${localizeDigits(_score, arabic: false)}'),
                              style: AppTextStyles.headingMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _start,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                isAr ? 'ابدأ' : 'Start',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizeExpr(String expr, bool isAr) {
    if (!isAr) return expr;
    const map = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    final buf = StringBuffer();
    for (final ch in expr.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
