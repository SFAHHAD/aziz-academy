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

/// Simon Says — watch a sequence of 4 colored buttons light up, then
/// tap them back in the same order. Sequence grows by ١ each round.
/// +٢🪙 reach round ٥, +٥🪙 reach round ٨, +١٠🪙 reach round ١٢.
class SimonSaysScreen extends ConsumerStatefulWidget {
  const SimonSaysScreen({super.key});

  @override
  ConsumerState<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

enum _Pad { red, blue, green, yellow }

class _SimonSaysScreenState extends ConsumerState<SimonSaysScreen> {
  final List<_Pad> _seq = [];
  int _userIdx = 0;
  bool _showing = false;
  _Pad? _flash;
  int _round = 0;
  bool _failed = false;
  bool _r5 = false, _r8 = false, _r12 = false;

  Future<void> _showSeq() async {
    setState(() => _showing = true);
    for (final p in _seq) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _flash = p);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _flash = null);
    }
    setState(() {
      _showing = false;
      _userIdx = 0;
    });
  }

  void _nextRound() {
    final rng = math.Random();
    _seq.add(_Pad.values[rng.nextInt(_Pad.values.length)]);
    _round = _seq.length;
    if (_round == 5 && !_r5) {
      _r5 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_round == 8 && !_r8) {
      _r8 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_round == 12 && !_r12) {
      _r12 = true;
      ref.read(coinProvider.notifier).award(10);
    }
    _showSeq();
  }

  void _tap(_Pad p) async {
    if (_showing || _failed) return;
    HapticFeedback.lightImpact();
    setState(() => _flash = p);
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _flash = null);
    if (_seq[_userIdx] != p) {
      setState(() => _failed = true);
      return;
    }
    _userIdx += 1;
    if (_userIdx >= _seq.length) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _nextRound();
    }
  }

  void _reset() {
    setState(() {
      _seq.clear();
      _userIdx = 0;
      _failed = false;
      _round = 0;
      _r5 = _r8 = _r12 = false;
    });
    _nextRound();
  }

  Color _color(_Pad p, bool isLit) {
    if (!isLit) {
      switch (p) {
        case _Pad.red:
          return const Color(0xFF8B1F1F);
        case _Pad.blue:
          return const Color(0xFF1E4882);
        case _Pad.green:
          return const Color(0xFF1F6B36);
        case _Pad.yellow:
          return const Color(0xFF8A7321);
      }
    }
    switch (p) {
      case _Pad.red:
        return const Color(0xFFE53935);
      case _Pad.blue:
        return const Color(0xFF1E88E5);
      case _Pad.green:
        return const Color(0xFF43A047);
      case _Pad.yellow:
        return const Color(0xFFFFC107);
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
          isAr ? 'تذكّر التسلسل' : 'Simon Says',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'شاهد التسلسل ثم اضغط الألوان بنفس الترتيب.'
                    : 'Watch the sequence, then tap the colors in order.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${isAr ? "الجولة" : "Round"} ${localizeDigits(_round, arabic: isAr)}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final p in _Pad.values)
                        GestureDetector(
                          onTap: () => _tap(p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: _color(p, _flash == p),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _flash == p
                                  ? [
                                      BoxShadow(
                                        color: _color(
                                          p,
                                          true,
                                        ).withValues(alpha: 0.6),
                                        blurRadius: 18,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_round == 0)
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(isAr ? 'ابدأ' : 'Start'),
                ),
              if (_failed) ...[
                Text(
                  isAr
                      ? 'انتهت! وصلت إلى الجولة ${localizeDigits(_round, arabic: true)}'
                      : 'Done! Reached round $_round',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.replay),
                  label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
