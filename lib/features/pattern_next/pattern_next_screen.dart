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

class PatternNextScreen extends ConsumerStatefulWidget {
  const PatternNextScreen({super.key});

  @override
  ConsumerState<PatternNextScreen> createState() => _PatternNextScreenState();
}

class _PatternNextScreenState extends ConsumerState<PatternNextScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  List<int> _seq = const [];
  int _answer = 0;
  List<int> _options = const [];
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

  ({List<int> seq, int next}) _generate() {
    final kind = _rng.nextInt(6);
    switch (kind) {
      case 0:
        // arithmetic
        final start = 1 + _rng.nextInt(8);
        final d = 1 + _rng.nextInt(6);
        final s = List.generate(4, (i) => start + d * i);
        return (seq: s, next: start + d * 4);
      case 1:
        // geometric ×2
        final start = 1 + _rng.nextInt(4);
        final s = List.generate(4, (i) => start * math.pow(2, i).toInt());
        return (seq: s, next: start * math.pow(2, 4).toInt());
      case 2:
        // squares
        final start = 1 + _rng.nextInt(4);
        final s = List.generate(4, (i) => (start + i) * (start + i));
        return (seq: s, next: (start + 4) * (start + 4));
      case 3:
        // fibonacci-like
        final a = 1 + _rng.nextInt(3);
        final b = 1 + _rng.nextInt(4);
        final s = <int>[a, b];
        for (var i = 0; i < 2; i++) {
          s.add(s[s.length - 1] + s[s.length - 2]);
        }
        final next = s[3] + s[2];
        return (seq: s, next: next);
      case 4:
        // doubling
        final start = 1 + _rng.nextInt(5);
        final s = List.generate(4, (i) => start * math.pow(3, i).toInt());
        return (seq: s, next: start * math.pow(3, 4).toInt());
      default:
        // descending arithmetic
        final start = 30 + _rng.nextInt(20);
        final d = 1 + _rng.nextInt(5);
        final s = List.generate(4, (i) => start - d * i);
        return (seq: s, next: start - d * 4);
    }
  }

  void _newRound() {
    if (!_running) return;
    final r = _generate();
    final correct = r.next;
    final opts = <int>{correct};
    while (opts.length < 4) {
      final delta = (1 + _rng.nextInt(7)) * (_rng.nextBool() ? 1 : -1);
      final cand = correct + delta;
      if (cand > 0) opts.add(cand);
    }
    final shuffled = opts.toList()..shuffle(_rng);
    setState(() {
      _seq = r.seq;
      _answer = correct;
      _options = shuffled;
      _msg = null;
    });
  }

  void _tap(int v) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (v == _answer) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 350), () {
        if (mounted && _running) _newRound();
      });
    } else {
      setState(() => _msg = '❌ $_answer');
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
          isAr ? 'الرقم التالي' : 'Pattern Next',
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
                    ? 'ما الرقم التالي في النمط؟'
                    : 'What number comes next in the pattern?',
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
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                for (final n in _seq)
                                  Text(
                                    localizeDigits(n, arabic: isAr),
                                    style: AppTextStyles.headingLarge.copyWith(
                                      color: AppColors.textDark,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                Text(
                                  isAr ? '؟' : '?',
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final n in _options)
                      ElevatedButton(
                        onPressed: () => _tap(n),
                        child: Text(
                          localizeDigits(n, arabic: isAr),
                          style: const TextStyle(fontSize: 18),
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
