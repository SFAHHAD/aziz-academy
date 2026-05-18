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

class TapGreatestScreen extends ConsumerStatefulWidget {
  const TapGreatestScreen({super.key});

  @override
  ConsumerState<TapGreatestScreen> createState() => _TapGreatestScreenState();
}

class _Card {
  const _Card(this.label, this.value);
  final String label;
  final int value;
}

class _TapGreatestScreenState extends ConsumerState<TapGreatestScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  List<_Card> _cards = const [];
  String? _msg;
  bool _w12 = false, _w24 = false, _w40 = false;

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

  _Card _makeCard(bool isAr) {
    final mode = _rng.nextInt(4);
    switch (mode) {
      case 0:
        final n = 1 + _rng.nextInt(99);
        return _Card(localizeDigits(n, arabic: isAr), n);
      case 1:
        final a = 1 + _rng.nextInt(30);
        final b = 1 + _rng.nextInt(20);
        return _Card(
          '${localizeDigits(a, arabic: isAr)}+${localizeDigits(b, arabic: isAr)}',
          a + b,
        );
      case 2:
        final a = 1 + _rng.nextInt(9);
        final b = 1 + _rng.nextInt(9);
        return _Card(
          '${localizeDigits(a, arabic: isAr)}×${localizeDigits(b, arabic: isAr)}',
          a * b,
        );
      default:
        final a = 30 + _rng.nextInt(40);
        final b = _rng.nextInt(a);
        return _Card(
          '${localizeDigits(a, arabic: isAr)}-${localizeDigits(b, arabic: isAr)}',
          a - b,
        );
    }
  }

  void _newRound() {
    if (!_running) return;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final cards = <_Card>[];
    final values = <int>{};
    while (cards.length < 4) {
      final c = _makeCard(isAr);
      if (values.add(c.value)) cards.add(c);
    }
    setState(() {
      _cards = cards;
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    final maxValue = _cards.map((c) => c.value).reduce((a, b) => a > b ? a : b);
    if (_cards[idx].value == maxValue) {
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
    if (_score >= 12 && !_w12) {
      _w12 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 24 && !_w24) {
      _w24 = true;
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
          isAr ? 'الأكبر' : 'Tap the Greatest',
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
                    ? 'انقر على البطاقة ذات القيمة الأكبر.'
                    : 'Tap the card with the greatest value.',
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
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: _running
                          ? GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                for (var i = 0; i < _cards.length; i++)
                                  InkWell(
                                    onTap: () => _tap(i),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.outline,
                                          width: 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _cards[i].label,
                                        style: AppTextStyles.headingLarge
                                            .copyWith(
                                              color: AppColors.textDark,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(
                                    alpha: 0.85,
                                  ),
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
                                        style: AppTextStyles.headingSmall
                                            .copyWith(color: AppColors.success),
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
                    if (_msg != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _msg!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _msg!.startsWith('✅')
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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
