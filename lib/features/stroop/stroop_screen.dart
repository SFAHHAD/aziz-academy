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

class StroopScreen extends ConsumerStatefulWidget {
  const StroopScreen({super.key});

  @override
  ConsumerState<StroopScreen> createState() => _StroopScreenState();
}

class _Color {
  const _Color(this.label, this.labelAr, this.color);
  final String label;
  final String labelAr;
  final Color color;
}

const _colors = <_Color>[
  _Color('RED', 'أحمر', Color(0xFFE53935)),
  _Color('BLUE', 'أزرق', Color(0xFF1E88E5)),
  _Color('GREEN', 'أخضر', Color(0xFF43A047)),
  _Color('YELLOW', 'أصفر', Color(0xFFFDD835)),
  _Color('PURPLE', 'بنفسجي', Color(0xFF8E24AA)),
];

class _StroopScreenState extends ConsumerState<StroopScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  int _wordIdx = 0;
  int _inkIdx = 1;
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
    _newPrompt();
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

  void _newPrompt() {
    if (!_running) return;
    final w = _rng.nextInt(_colors.length);
    int ink;
    do {
      ink = _rng.nextInt(_colors.length);
    } while (ink == w);
    setState(() {
      _wordIdx = w;
      _inkIdx = ink;
      _msg = null;
    });
  }

  void _tap(int i) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (i == _inkIdx) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && _running) _newPrompt();
      });
    } else {
      setState(() => _msg = '❌');
      Timer(const Duration(milliseconds: 250), () {
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
          isAr ? 'لون الحبر' : 'Ink Color',
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
                    ? 'انقر على لون الحبر، ليس معنى الكلمة!'
                    : "Tap the INK color, not the word's meaning!",
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
                  child: _running
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              isAr
                                  ? _colors[_wordIdx].labelAr
                                  : _colors[_wordIdx].label,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: _colors[_inkIdx].color,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (_msg != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.85,
                                    ),
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
                    for (var i = 0; i < _colors.length; i++)
                      ElevatedButton(
                        onPressed: () => _tap(i),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colors[i].color,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isAr ? _colors[i].labelAr : _colors[i].label,
                          style: const TextStyle(
                            fontSize: 16,
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
