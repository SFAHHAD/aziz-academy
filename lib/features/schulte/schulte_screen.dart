import 'dart:async';

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

class SchulteScreen extends ConsumerStatefulWidget {
  const SchulteScreen({super.key});

  @override
  ConsumerState<SchulteScreen> createState() => _SchulteScreenState();
}

class _SchulteScreenState extends ConsumerState<SchulteScreen> {
  static const _duration = 60;

  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  int _next = 1;
  int _grid = 3;
  bool _running = false;
  List<int> _cells = const [];
  String? _msg;
  bool _w3 = false, _w6 = false, _w10 = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _seconds = _duration;
      _score = 0;
      _grid = 3;
      _running = true;
      _msg = null;
    });
    _newGrid();
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

  void _newGrid() {
    if (!_running) return;
    final n = _grid * _grid;
    final cells = List<int>.generate(n, (i) => i + 1)..shuffle();
    setState(() {
      _cells = cells;
      _next = 1;
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (_cells[idx] == _next) {
      if (_next == _cells.length) {
        setState(() {
          _score += 1;
          _grid = _grid < 5 ? _grid + 1 : 5;
          _msg = '✅ +1';
        });
        Timer(const Duration(milliseconds: 400), () {
          if (mounted && _running) _newGrid();
        });
      } else {
        setState(() => _next += 1);
      }
    } else {
      setState(() => _msg = '❌');
      Timer(const Duration(milliseconds: 250), () {
        if (mounted && _running) setState(() => _msg = null);
      });
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 3 && !_w3) {
      _w3 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 6 && !_w6) {
      _w6 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 10 && !_w10) {
      _w10 = true;
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
          isAr ? 'جدول شولته' : 'Schulte Table',
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
                    ? 'انقر الأرقام بالترتيب من ١ حتى النهاية.'
                    : 'Tap the numbers in order from 1 to the end.',
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
                    label: isAr ? 'التالي' : 'Next',
                    value: _running ? localizeDigits(_next, arabic: isAr) : '—',
                    color: AppColors.primary,
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
                      padding: const EdgeInsets.all(8),
                      child: _running
                          ? GridView.count(
                              crossAxisCount: _grid,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              children: [
                                for (var i = 0; i < _cells.length; i++)
                                  _Tile(
                                    value: _cells[i],
                                    isNext: _cells[i] == _next,
                                    isPast: _cells[i] < _next,
                                    isAr: isAr,
                                    onTap: () => _tap(i),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.isNext,
    required this.isPast,
    required this.isAr,
    required this.onTap,
  });

  final int value;
  final bool isNext;
  final bool isPast;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isPast
        ? AppColors.surfaceContainer
        : (isNext
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.background);
    final fg = isPast
        ? AppColors.textMedium
        : (isNext ? AppColors.primary : AppColors.textDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNext ? AppColors.primary : AppColors.outline,
            width: isNext ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          localizeDigits(value, arabic: isAr),
          style: AppTextStyles.headingSmall.copyWith(color: fg, fontSize: 22),
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
