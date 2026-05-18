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

class FindTwinScreen extends ConsumerStatefulWidget {
  const FindTwinScreen({super.key});

  @override
  ConsumerState<FindTwinScreen> createState() => _FindTwinScreenState();
}

const _emojis = <String>[
  '🐶',
  '🐱',
  '🐭',
  '🐹',
  '🐰',
  '🦊',
  '🐻',
  '🐼',
  '🐨',
  '🐯',
  '🦁',
  '🐮',
  '🐷',
  '🐸',
  '🐵',
  '🐔',
  '🐧',
  '🐦',
  '🐤',
  '🦉',
  '🐺',
  '🦄',
  '🐝',
  '🦋',
  '🐢',
  '🐍',
  '🦖',
  '🐙',
  '🦀',
  '🐠',
  '🍎',
  '🍌',
  '🍇',
  '🍉',
  '🍊',
  '🍋',
  '🍓',
  '🍒',
  '🍑',
  '🍍',
  '⚽',
  '🏀',
  '🏈',
  '⚾',
  '🎾',
  '🏐',
  '🎱',
];

class _FindTwinScreenState extends ConsumerState<FindTwinScreen> {
  static const _duration = 60;
  static const _gridSize = 16;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  List<String> _grid = const [];
  Set<int> _twinIdx = const {};
  int? _firstTap;
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

  void _newRound() {
    if (!_running) return;
    final pool = [..._emojis]..shuffle(_rng);
    final picks = pool.take(_gridSize - 1).toList();
    final twin = picks[_rng.nextInt(picks.length)];
    final cells = [...picks, twin]..shuffle(_rng);
    final twinIdx = <int>{};
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == twin) twinIdx.add(i);
    }
    setState(() {
      _grid = cells;
      _twinIdx = twinIdx;
      _firstTap = null;
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (_firstTap == null) {
      if (_twinIdx.contains(idx)) {
        setState(() => _firstTap = idx);
      } else {
        setState(() => _msg = '❌');
        Timer(const Duration(milliseconds: 250), () {
          if (mounted && _running) setState(() => _msg = null);
        });
      }
      return;
    }
    if (idx == _firstTap) {
      setState(() => _firstTap = null);
      return;
    }
    if (_twinIdx.contains(idx)) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 250), () {
        if (mounted && _running) _newRound();
      });
    } else {
      setState(() {
        _firstTap = null;
        _msg = '❌';
      });
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
          isAr ? 'ابحث عن التوأم' : 'Find the Twin',
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
                    ? 'هناك صورتان متطابقتان في الشبكة. أوجدهما!'
                    : 'Two cells in the grid match. Find them!',
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
                      padding: const EdgeInsets.all(8),
                      child: _running
                          ? GridView.count(
                              crossAxisCount: 4,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              children: [
                                for (var i = 0; i < _grid.length; i++)
                                  InkWell(
                                    onTap: () => _tap(i),
                                    borderRadius: BorderRadius.circular(8),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _firstTap == i
                                            ? AppColors.primary.withValues(
                                                alpha: 0.18,
                                              )
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _firstTap == i
                                              ? AppColors.primary
                                              : AppColors.outline,
                                          width: _firstTap == i ? 2 : 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _grid[i],
                                        style: const TextStyle(fontSize: 30),
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
