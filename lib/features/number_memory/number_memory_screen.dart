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

class NumberMemoryScreen extends ConsumerStatefulWidget {
  const NumberMemoryScreen({super.key});

  @override
  ConsumerState<NumberMemoryScreen> createState() => _NumberMemoryScreenState();
}

enum _Phase { idle, show, recall, result }

class _NumberMemoryScreenState extends ConsumerState<NumberMemoryScreen> {
  static const _duration = 60;

  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  int _len = 3;
  bool _running = false;
  _Phase _phase = _Phase.idle;
  List<int> _target = const [];
  List<int> _input = const [];
  String? _msg;
  bool _w5 = false, _w10 = false, _w18 = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _seconds = _duration;
      _score = 0;
      _len = 3;
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
    final seq = List<int>.generate(_len, (_) => rng.nextInt(10));
    final ms = 1500 + _len * 350;
    setState(() {
      _target = seq;
      _input = const [];
      _phase = _Phase.show;
      _msg = null;
    });
    Timer(Duration(milliseconds: ms), () {
      if (!mounted || !_running) return;
      setState(() => _phase = _Phase.recall);
    });
  }

  void _tap(int n) {
    if (!_running || _phase != _Phase.recall) return;
    HapticFeedback.lightImpact();
    final newIn = [..._input, n];
    final wrong = newIn[newIn.length - 1] != _target[newIn.length - 1];
    if (wrong) {
      setState(() {
        _phase = _Phase.result;
        _len = math.max(3, _len - 1);
        _msg = '❌ ${_target.join(' ')}';
      });
      Timer(const Duration(milliseconds: 900), () {
        if (mounted && _running) _newRound();
      });
      return;
    }
    if (newIn.length == _target.length) {
      setState(() {
        _phase = _Phase.result;
        _score += 1;
        _len = math.min(9, _len + 1);
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 600), () {
        if (mounted && _running) _newRound();
      });
      return;
    }
    setState(() => _input = newIn);
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 5 && !_w5) {
      _w5 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 10 && !_w10) {
      _w10 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 18 && !_w18) {
      _w18 = true;
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
          isAr ? 'ذاكرة الأرقام' : 'Number Memory',
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
                    ? 'تظهر الأرقام للحظة، أعدها بالترتيب.'
                    : 'Numbers flash briefly. Repeat them in order.',
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
                    label: isAr ? 'الطول' : 'Length',
                    value: localizeDigits(_len, arabic: isAr),
                    color: AppColors.primary,
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
                  child: _buildBoard(isAr),
                ),
              ),
              const SizedBox(height: 12),
              if (_phase == _Phase.recall)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int n = 0; n <= 9; n++)
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

  Widget _buildBoard(bool isAr) {
    if (_phase == _Phase.show) {
      return Text(
        _target.map((d) => localizeDigits(d, arabic: isAr)).join('  '),
        style: AppTextStyles.headingLarge.copyWith(
          color: AppColors.textDark,
          fontSize: 44,
          letterSpacing: 4,
        ),
      );
    }
    if (_phase == _Phase.recall) {
      final shown = _input
          .map((d) => localizeDigits(d, arabic: isAr))
          .join('  ');
      final dots = List.filled(_target.length - _input.length, '•').join(' ');
      return Text(
        shown.isEmpty ? dots : '$shown  $dots',
        style: AppTextStyles.headingLarge.copyWith(
          color: AppColors.textDark,
          fontSize: 36,
          letterSpacing: 4,
        ),
      );
    }
    if (_msg != null) {
      return Text(
        _msg!,
        style: AppTextStyles.headingMedium.copyWith(
          color: _msg!.startsWith('✅') ? AppColors.success : AppColors.error,
        ),
      );
    }
    return Container(
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
            icon: Icon(_seconds <= 0 ? Icons.replay : Icons.play_arrow),
            label: Text(
              _seconds <= 0
                  ? (isAr ? 'مرة أخرى' : 'Play again')
                  : (isAr ? 'ابدأ' : 'Start'),
            ),
          ),
        ],
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
