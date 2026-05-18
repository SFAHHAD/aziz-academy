import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Times-tables drill — 20-question speed run on a chosen multiplication
/// table (1..12). Awards 1 coin per correct answer + 5 if all 20 correct.
/// No lives, no game-over; just keep going so the kid builds fluency.
class TimesTablesScreen extends ConsumerStatefulWidget {
  const TimesTablesScreen({super.key});

  @override
  ConsumerState<TimesTablesScreen> createState() => _TimesTablesScreenState();
}

class _TimesTablesScreenState extends ConsumerState<TimesTablesScreen> {
  static const int _drillLength = 20;
  final _rng = math.Random();
  int _table = 5;
  bool _drillStarted = false;
  int _idx = 0;
  int _correct = 0;
  late List<int> _factors;
  late List<List<int>> _options;
  int? _selected;

  void _start() {
    _factors = List.generate(_drillLength, (_) => _rng.nextInt(12) + 1);
    _options = _factors.map((f) {
      final answer = f * _table;
      final set = <int>{answer};
      while (set.length < 4) {
        final delta = _rng.nextInt(7) - 3;
        final wrong = answer + delta == answer ? answer + 1 : answer + delta;
        if (wrong > 0) set.add(wrong);
      }
      final list = set.toList()..shuffle(_rng);
      return list;
    }).toList();
    setState(() {
      _drillStarted = true;
      _idx = 0;
      _correct = 0;
      _selected = null;
    });
  }

  void _answer(int v) {
    if (_selected != null) return;
    final correct = _factors[_idx] * _table;
    final wasCorrect = v == correct;
    setState(() {
      _selected = v;
      if (wasCorrect) _correct += 1;
    });
    if (wasCorrect) {
      ref.read(audioServiceProvider).playCorrectSound();
      ref.read(coinProvider.notifier).award(1);
    } else {
      HapticFeedback.lightImpact();
    }
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_idx + 1 >= _drillLength) {
        if (_correct == _drillLength) {
          ref.read(coinProvider.notifier).award(5);
        }
        setState(() {
          _idx = _drillLength;
          _selected = null;
        });
      } else {
        setState(() {
          _idx += 1;
          _selected = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? '✖️ جدول الضرب' : '✖️ Times Tables'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: !_drillStarted
          ? _picker(isAr)
          : _idx >= _drillLength
          ? _summary(isAr)
          : _drill(isAr),
    );
  }

  Widget _picker(bool isAr) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'اختر الجدول' : 'Pick a table',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var t = 1; t <= 12; t++)
                  ChoiceChip(
                    label: Text(
                      '× ${localizeDigits(t, arabic: isAr)}',
                      style: AppTextStyles.headingMedium,
                    ),
                    selected: _table == t,
                    onSelected: (_) => setState(() => _table = t),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isAr
                      ? 'ابدأ التدريب (٢٠ سؤال)'
                      : 'Start drill (20 questions)',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drill(bool isAr) {
    final f = _factors[_idx];
    final correct = f * _table;
    final opts = _options[_idx];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localizeDigits(_idx + 1, arabic: isAr)} / ${localizeDigits(_drillLength, arabic: isAr)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                Text(
                  '🪙 ${localizeDigits(_correct, arabic: isAr)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${localizeDigits(_table, arabic: isAr)} × ${localizeDigits(f, arabic: isAr)} = ?',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            for (final o in opts) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? () => _answer(o) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected == null
                        ? AppColors.surfaceContainer
                        : (o == correct
                              ? AppColors.success
                              : (o == _selected
                                    ? AppColors.error
                                    : AppColors.surfaceContainer)),
                    foregroundColor: _selected != null && o == correct
                        ? Colors.white
                        : AppColors.textDark,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    localizeDigits(o, arabic: isAr),
                    style: AppTextStyles.headingMedium.copyWith(
                      color: _selected != null && o == correct
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(bool isAr) {
    final perfect = _correct == _drillLength;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(perfect ? '🏆' : '👏', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'انتهيت! ${localizeDigits(_correct, arabic: isAr)} من ${localizeDigits(_drillLength, arabic: isAr)}'
                  : 'Finished! $_correct / $_drillLength',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              perfect
                  ? (isAr ? '🪙 مكافأة الإتقان: +٥' : '🪙 Mastery bonus: +5')
                  : (isAr
                        ? '🪙 +${localizeDigits(_correct, arabic: isAr)}'
                        : '🪙 +$_correct'),
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.accent,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(isAr ? 'تدريب جديد' : 'New drill'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _drillStarted = false),
                child: Text(isAr ? 'تغيير الجدول' : 'Change table'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
