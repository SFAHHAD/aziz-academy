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

/// Color Match — Stroop-inspired focus game. The word names a color but
/// is rendered in a different ink color. Tap the option whose label
/// matches the INK color, not the word. ٢٠ rounds, ٣s timer per round.
/// +٢🪙 finish, +٥🪙 score ≥ ١٧/٢٠.
class ColorMatchScreen extends ConsumerStatefulWidget {
  const ColorMatchScreen({super.key});

  @override
  ConsumerState<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _Pair {
  const _Pair(this.label, this.labelAr, this.color);
  final String label;
  final String labelAr;
  final Color color;
}

class _ColorMatchScreenState extends ConsumerState<ColorMatchScreen> {
  static const int _rounds = 20;
  static const _palette = [
    _Pair('Red', 'أحمر', Color(0xFFE53935)),
    _Pair('Blue', 'أزرق', Color(0xFF1E88E5)),
    _Pair('Green', 'أخضر', Color(0xFF43A047)),
    _Pair('Yellow', 'أصفر', Color(0xFFFFC107)),
    _Pair('Purple', 'بنفسجي', Color(0xFF8E24AA)),
    _Pair('Orange', 'برتقالي', Color(0xFFFB8C00)),
  ];

  late _Pair _word; // text label
  late _Pair _ink; // rendered color (the correct answer)
  late List<_Pair> _options;
  int _round = 0;
  int _score = 0;
  int _msLeft = 3000;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    if (_round >= _rounds) {
      _finish();
      return;
    }
    final rng = math.Random();
    _word = _palette[rng.nextInt(_palette.length)];
    do {
      _ink = _palette[rng.nextInt(_palette.length)];
    } while (_ink == _word);
    final wrongPool = _palette.where((p) => p != _ink).toList()..shuffle(rng);
    _options = [_ink, ...wrongPool.take(3)]..shuffle(rng);
    _msLeft = 3000;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _msLeft -= 100;
      if (_msLeft <= 0) {
        t.cancel();
        _round += 1;
        setState(() {});
        Future.delayed(const Duration(milliseconds: 200), _next);
      } else {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _pick(_Pair option) {
    if (_done) return;
    HapticFeedback.lightImpact();
    if (option == _ink) _score += 1;
    _round += 1;
    _timer?.cancel();
    if (_round >= _rounds) {
      _finish();
    } else {
      _next();
    }
  }

  void _finish() {
    _timer?.cancel();
    _done = true;
    ref.read(coinProvider.notifier).award(2);
    if (_score >= 17) {
      ref.read(coinProvider.notifier).award(5);
    }
    setState(() {});
  }

  void _reset() {
    setState(() {
      _round = 0;
      _score = 0;
      _done = false;
    });
    _next();
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
          isAr ? 'لون الكلمة' : 'Color Match',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _done ? _buildDone(isAr) : _buildPlay(isAr),
        ),
      ),
    );
  }

  Widget _buildPlay(bool isAr) {
    return Column(
      children: [
        Text(
          isAr
              ? 'تجاهل الكلمة. اختر اللون الذي كُتبت به فعلاً.'
              : 'Ignore the word. Pick the INK color it is drawn in.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Pill(
              label: isAr ? 'الجولة' : 'Round',
              value:
                  '${localizeDigits(_round + 1, arabic: isAr)} / ${localizeDigits(_rounds, arabic: isAr)}',
            ),
            _Pill(
              label: isAr ? 'النقاط' : 'Score',
              value: localizeDigits(_score, arabic: isAr),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _msLeft / 3000,
          backgroundColor: AppColors.surfaceContainer,
          color: _msLeft > 1000 ? AppColors.success : AppColors.error,
          minHeight: 6,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            isAr ? _word.labelAr : _word.label,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: _ink.color,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final o in _options)
              ElevatedButton(
                onPressed: () => _pick(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isAr ? o.labelAr : o.label,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDone(bool isAr) {
    final perfect = _score >= 17;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isAr
              ? 'انتهت! نقاطك: ${localizeDigits(_score, arabic: true)} / ${localizeDigits(_rounds, arabic: true)}'
              : 'Done! Score: $_score / $_rounds',
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (perfect ? AppColors.success : AppColors.warning).withValues(
              alpha: 0.18,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            perfect
                ? (isAr
                      ? '🎉 رائع جدًا! +٧🪙 (٢ + ٥ مكافأة)'
                      : '🎉 Excellent! +7🪙 (2 + 5 bonus)')
                : (isAr ? '✅ +٢🪙' : '✅ +2🪙'),
            style: AppTextStyles.headingSmall,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.replay),
          label: Text(isAr ? 'مرة أخرى' : 'Play again'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label  $value', style: AppTextStyles.labelLarge),
    );
  }
}
