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

class GreaterThanScreen extends ConsumerStatefulWidget {
  const GreaterThanScreen({super.key});

  @override
  ConsumerState<GreaterThanScreen> createState() => _GreaterThanScreenState();
}

enum _Op { lt, eq, gt }

class _Side {
  const _Side(this.text, this.value);
  final String text;
  final int value;
}

class _GreaterThanScreenState extends ConsumerState<GreaterThanScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  _Side _left = const _Side('0', 0);
  _Side _right = const _Side('0', 0);
  _Op _answer = _Op.eq;
  String? _msg;
  bool _w8 = false, _w16 = false, _w28 = false;

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

  _Side _makeSide(bool isAr) {
    final mode = _rng.nextInt(4);
    switch (mode) {
      case 0:
        final n = _rng.nextInt(50);
        return _Side(localizeDigits(n, arabic: isAr), n);
      case 1:
        final a = _rng.nextInt(20);
        final b = _rng.nextInt(15);
        return _Side(
          '${localizeDigits(a, arabic: isAr)}+${localizeDigits(b, arabic: isAr)}',
          a + b,
        );
      case 2:
        final a = 10 + _rng.nextInt(40);
        final b = _rng.nextInt(a + 1);
        return _Side(
          '${localizeDigits(a, arabic: isAr)}-${localizeDigits(b, arabic: isAr)}',
          a - b,
        );
      default:
        final a = 1 + _rng.nextInt(9);
        final b = 1 + _rng.nextInt(9);
        return _Side(
          '${localizeDigits(a, arabic: isAr)}×${localizeDigits(b, arabic: isAr)}',
          a * b,
        );
    }
  }

  void _newRound() {
    if (!_running) return;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    var l = _makeSide(isAr);
    var r = _makeSide(isAr);
    if (_rng.nextInt(5) == 0) {
      r = _Side(l.text, l.value);
    }
    final ans = l.value < r.value
        ? _Op.lt
        : l.value > r.value
        ? _Op.gt
        : _Op.eq;
    setState(() {
      _left = l;
      _right = r;
      _answer = ans;
      _msg = null;
    });
  }

  void _tap(_Op op) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (op == _answer) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && _running) _newRound();
      });
    } else {
      setState(() => _msg = '❌');
      Timer(const Duration(milliseconds: 350), () {
        if (mounted && _running) setState(() => _msg = null);
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
    if (_score >= 28 && !_w28) {
      _w28 = true;
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
          isAr ? 'أكبر أم أصغر؟' : 'Greater or Less?',
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
                    ? 'قارن الجانبين واختر العلامة الصحيحة.'
                    : 'Compare the two sides and pick the correct sign.',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  _left.text,
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '?',
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 36,
                                  ),
                                ),
                                Text(
                                  _right.text,
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final e in const [
                      (_Op.lt, '<'),
                      (_Op.eq, '='),
                      (_Op.gt, '>'),
                    ])
                      ElevatedButton(
                        onPressed: () => _tap(e.$1),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(72, 48),
                        ),
                        child: Text(
                          e.$2,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
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
