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

class SumHuntScreen extends ConsumerStatefulWidget {
  const SumHuntScreen({super.key});

  @override
  ConsumerState<SumHuntScreen> createState() => _SumHuntScreenState();
}

class _SumHuntScreenState extends ConsumerState<SumHuntScreen> {
  static const _duration = 60;
  static const _gridSize = 16;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  int _target = 10;
  List<int> _grid = const [];
  int? _firstSel;
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
      _running = true;
      _msg = null;
      _firstSel = null;
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

  void _newRound() {
    if (!_running) return;
    final grid = List<int>.generate(_gridSize, (_) => 1 + _rng.nextInt(9));
    int target;
    int tries = 0;
    do {
      target = 5 + _rng.nextInt(14);
      tries += 1;
      bool hasPair = false;
      for (var i = 0; i < grid.length && !hasPair; i++) {
        for (var j = i + 1; j < grid.length; j++) {
          if (grid[i] + grid[j] == target) {
            hasPair = true;
            break;
          }
        }
      }
      if (hasPair) break;
    } while (tries < 30);
    setState(() {
      _grid = grid;
      _target = target;
      _firstSel = null;
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (_firstSel == null) {
      setState(() => _firstSel = idx);
      return;
    }
    if (_firstSel == idx) {
      setState(() => _firstSel = null);
      return;
    }
    final a = _grid[_firstSel!];
    final b = _grid[idx];
    if (a + b == _target) {
      final newGrid = [..._grid];
      newGrid[_firstSel!] = 1 + _rng.nextInt(9);
      newGrid[idx] = 1 + _rng.nextInt(9);
      setState(() {
        _grid = newGrid;
        _score += 1;
        _firstSel = null;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 250), () {
        if (mounted) _newRound();
      });
    } else {
      setState(() {
        _firstSel = null;
        _msg = '❌';
      });
      Timer(const Duration(milliseconds: 300), () {
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
          isAr ? 'صيد المجموع' : 'Sum Hunt',
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
                    ? 'اختر رقمين مجموعهما يساوي الهدف.'
                    : 'Pick two cells that sum to the target.',
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
                    label: isAr ? 'الهدف' : 'Target',
                    value: _running
                        ? localizeDigits(_target, arabic: isAr)
                        : '—',
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
                      padding: const EdgeInsets.all(12),
                      child: _running
                          ? GridView.count(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              children: [
                                for (var i = 0; i < _grid.length; i++)
                                  _Cell(
                                    value: _grid[i],
                                    selected: _firstSel == i,
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
                        top: 8,
                        right: 8,
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

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.selected,
    required this.isAr,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          localizeDigits(value, arabic: isAr),
          style: AppTextStyles.headingMedium.copyWith(
            color: selected ? Colors.white : AppColors.textDark,
            fontSize: 24,
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
