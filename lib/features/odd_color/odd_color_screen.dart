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

class OddColorScreen extends ConsumerStatefulWidget {
  const OddColorScreen({super.key});

  @override
  ConsumerState<OddColorScreen> createState() => _OddColorScreenState();
}

const _basePalette = <Color>[
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFF26A69A),
];

class _OddColorScreenState extends ConsumerState<OddColorScreen> {
  static const _duration = 60;
  static const _gridSize = 9;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  Color _baseColor = _basePalette.first;
  Color _oddColor = _basePalette.first;
  int _oddIdx = 0;
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

  Color _shift(Color c, double delta) {
    final hsl = HSLColor.fromColor(c);
    final newL = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(newL).toColor();
  }

  void _newRound() {
    if (!_running) return;
    final base = _basePalette[_rng.nextInt(_basePalette.length)];
    // Difficulty: smaller delta as score grows
    final delta = math.max(0.06, 0.20 - _score * 0.005);
    final dir = _rng.nextBool() ? 1.0 : -1.0;
    final odd = _shift(base, delta * dir);
    final idx = _rng.nextInt(_gridSize);
    setState(() {
      _baseColor = base;
      _oddColor = odd;
      _oddIdx = idx;
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (idx == _oddIdx) {
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
          isAr ? 'اللون المختلف' : 'Spot the Odd Color',
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
                    ? 'انقر على المربع الذي يختلف لونه عن الباقي.'
                    : 'Tap the square whose color differs from the rest.',
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
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              children: [
                                for (var i = 0; i < _gridSize; i++)
                                  InkWell(
                                    onTap: () => _tap(i),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: i == _oddIdx
                                            ? _oddColor
                                            : _baseColor,
                                        borderRadius: BorderRadius.circular(10),
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
