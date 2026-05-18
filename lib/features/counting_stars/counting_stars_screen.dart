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

class CountingStarsScreen extends ConsumerStatefulWidget {
  const CountingStarsScreen({super.key});

  @override
  ConsumerState<CountingStarsScreen> createState() =>
      _CountingStarsScreenState();
}

enum _Phase { idle, flash, choose, result }

class _CountingStarsScreenState extends ConsumerState<CountingStarsScreen> {
  static const _duration = 60;

  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  int _streak = 0;
  bool _running = false;
  _Phase _phase = _Phase.idle;
  int _correct = 1;
  List<Offset> _positions = const [];
  String? _msg;
  bool _w8 = false, _w16 = false, _w30 = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _seconds = _duration;
      _score = 0;
      _streak = 0;
      _running = true;
      _msg = null;
    });
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
    _newRound();
  }

  void _newRound() {
    if (!_running) return;
    final rng = math.Random();
    // Difficulty grows with streak (1..9)
    final maxN = math.min(9, 3 + _streak);
    final n = 1 + rng.nextInt(maxN);
    final positions = <Offset>[];
    for (var i = 0; i < n; i++) {
      positions.add(
        Offset(0.10 + rng.nextDouble() * 0.80, 0.10 + rng.nextDouble() * 0.80),
      );
    }
    final ms = math.max(450, 950 - _streak * 50);
    setState(() {
      _correct = n;
      _positions = positions;
      _phase = _Phase.flash;
      _msg = null;
    });
    Timer(Duration(milliseconds: ms), () {
      if (!mounted || !_running) return;
      setState(() => _phase = _Phase.choose);
    });
  }

  void _guess(int n) {
    if (!_running || _phase != _Phase.choose) return;
    HapticFeedback.lightImpact();
    final correct = n == _correct;
    setState(() {
      _phase = _Phase.result;
      if (correct) {
        _score += 1;
        _streak += 1;
        _msg = '✅ +1';
      } else {
        _streak = 0;
        _msg = '❌ Was $_correct';
      }
    });
    Timer(const Duration(milliseconds: 700), () {
      if (mounted && _running) _newRound();
    });
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
          isAr ? 'عدّ النجوم' : 'Counting Stars',
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
                    ? 'تومض النجوم لجزء من الثانية. كم رأيت؟'
                    : 'Stars flash for a moment. How many did you see?',
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
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          if (_phase == _Phase.flash)
                            for (final p in _positions)
                              Positioned(
                                left: p.dx * c.maxWidth - 16,
                                top: p.dy * c.maxHeight - 16,
                                child: const Text(
                                  '⭐',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                          if (_msg != null)
                            Center(
                              child: Text(
                                _msg!,
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: _msg!.startsWith('✅')
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          if (!_running && _phase != _Phase.flash)
                            Center(
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
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_phase == _Phase.choose)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int n = 1; n <= 9; n++)
                      ElevatedButton(
                        onPressed: () => _guess(n),
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
