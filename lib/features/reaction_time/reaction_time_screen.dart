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

/// Reaction Time — wait for the panel to turn green, then tap as fast as
/// you can. 5 rounds; lower average wins. False starts (tapping while
/// red) reset the round. +٢🪙 finish, +٥🪙 average ≤ 350ms.
class ReactionTimeScreen extends ConsumerStatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  ConsumerState<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

enum _Phase { idle, waiting, ready, tooSoon, captured }

class _ReactionTimeScreenState extends ConsumerState<ReactionTimeScreen> {
  static const int _rounds = 5;
  _Phase _phase = _Phase.idle;
  Timer? _t;
  DateTime? _readyAt;
  final List<int> _times = [];
  int? _lastMs;
  bool _rewarded = false;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _begin() {
    if (_times.length >= _rounds) {
      _times.clear();
      _rewarded = false;
    }
    _start();
  }

  void _start() {
    setState(() {
      _phase = _Phase.waiting;
      _lastMs = null;
    });
    final delay = 1500 + math.Random().nextInt(2500); // 1.5–4s
    _t?.cancel();
    _t = Timer(Duration(milliseconds: delay), () {
      _readyAt = DateTime.now();
      setState(() => _phase = _Phase.ready);
    });
  }

  void _tap() {
    HapticFeedback.lightImpact();
    if (_phase == _Phase.idle || _phase == _Phase.captured) {
      _begin();
      return;
    }
    if (_phase == _Phase.tooSoon) {
      _start();
      return;
    }
    if (_phase == _Phase.waiting) {
      _t?.cancel();
      setState(() => _phase = _Phase.tooSoon);
      return;
    }
    if (_phase == _Phase.ready && _readyAt != null) {
      final ms = DateTime.now().difference(_readyAt!).inMilliseconds;
      _times.add(ms);
      _lastMs = ms;
      setState(() => _phase = _Phase.captured);
      if (_times.length == _rounds) {
        final avg = _times.reduce((a, b) => a + b) ~/ _times.length;
        ref.read(coinProvider.notifier).award(2);
        if (avg <= 350 && !_rewarded) {
          ref.read(coinProvider.notifier).award(5);
          _rewarded = true;
        }
      }
    }
  }

  Color _bg() {
    switch (_phase) {
      case _Phase.idle:
        return AppColors.surfaceContainer;
      case _Phase.waiting:
        return AppColors.error;
      case _Phase.tooSoon:
        return Colors.orange;
      case _Phase.ready:
        return AppColors.success;
      case _Phase.captured:
        return AppColors.surfaceContainerHigh;
    }
  }

  String _text(bool isAr) {
    switch (_phase) {
      case _Phase.idle:
        return isAr ? 'انقر لتبدأ' : 'Tap to start';
      case _Phase.waiting:
        return isAr ? 'انتظر الأخضر…' : 'Wait for green…';
      case _Phase.tooSoon:
        return isAr ? 'بدر جدًا! انقر للإعادة' : 'Too soon! Tap to retry';
      case _Phase.ready:
        return isAr ? 'انقر الآن!' : 'Tap NOW!';
      case _Phase.captured:
        if (_times.length >= _rounds) {
          final avg = _times.reduce((a, b) => a + b) ~/ _times.length;
          return isAr
              ? 'المعدل: ${localizeDigits(avg, arabic: true)}ms — انقر مرة جديدة'
              : 'Average: ${avg}ms — tap for new round';
        }
        return isAr
            ? '${localizeDigits(_lastMs ?? 0, arabic: true)}ms ✓ — انقر للجولة التالية'
            : '${_lastMs}ms ✓ — tap for next round';
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
          isAr ? 'سرعة الاستجابة' : 'Reaction Time',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'انتظر حتى يصبح اللون أخضر، ثم انقر بأسرع ما يمكن. ٥ جولات — كلما قلّ المعدل أفضل.'
                    : 'Wait until green, then tap as fast as you can. 5 rounds — lower average is better.',
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
                  '${isAr ? "الجولة" : "Round"} ${localizeDigits(_times.length.clamp(0, _rounds), arabic: isAr)} / ${localizeDigits(_rounds, arabic: isAr)}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _tap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _bg(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _text(isAr),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_times.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in _times)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${localizeDigits(t, arabic: isAr)}ms',
                          style: AppTextStyles.labelMedium,
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
