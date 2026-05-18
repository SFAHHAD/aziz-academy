import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/mental_math_bests_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/features/mental_math/mental_math_engine.dart';

/// "Mental Math Sprint" — answer as many as you can in 60 seconds.
/// Three bands tune difficulty. Personal best per band persists.
/// Tap-to-answer (4 options) — no keyboard, so this works for kids
/// who can't type fast yet.
class MentalMathSprintScreen extends ConsumerStatefulWidget {
  const MentalMathSprintScreen({super.key});

  @override
  ConsumerState<MentalMathSprintScreen> createState() =>
      _MentalMathSprintScreenState();
}

class _MentalMathSprintScreenState
    extends ConsumerState<MentalMathSprintScreen> {
  static const _sprintSeconds = 60;
  final _rng = math.Random();

  MentalMathBand? _band; // null = on the band-picker screen
  MentalQuestion? _q;
  List<int> _options = const [];
  int _score = 0;
  int _secondsLeft = _sprintSeconds;
  Timer? _ticker;
  bool _finished = false;
  bool _wasPB = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startSprint(MentalMathBand band) {
    setState(() {
      _band = band;
      _score = 0;
      _secondsLeft = _sprintSeconds;
      _finished = false;
      _wasPB = false;
      _next();
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        _ticker?.cancel();
        final isPB = await ref
            .read(mentalMathBestsProvider.notifier)
            .recordScore(band, _score);
        if (!mounted) return;
        setState(() {
          _finished = true;
          _wasPB = isPB;
        });
      }
    });
  }

  void _next() {
    final q = generateMentalQuestion(_band!, rng: _rng);
    setState(() {
      _q = q;
      _options = generateMentalOptions(q, rng: _rng);
    });
  }

  void _pick(int value) {
    if (_finished || _q == null) return;
    if (value == _q!.answer) {
      setState(() => _score += 1);
    }
    // No penalty for wrong — speed is the only resource.
    _next();
  }

  void _exitToPicker() {
    _ticker?.cancel();
    setState(() {
      _band = null;
      _finished = false;
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
        title: Text(isAr ? 'الحساب الذهني' : 'Mental Math Sprint'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (_band != null) {
              _exitToPicker();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: _band == null
          ? _pickerView(isAr)
          : _finished
              ? _resultView(isAr)
              : _sprintView(isAr),
    );
  }

  Widget _pickerView(bool isAr) {
    final bests = ref.watch(mentalMathBestsProvider).value ??
        MentalMathBests.empty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          isAr ? 'اختر المستوى' : 'Pick difficulty',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAr
              ? 'لديك ${localizeDigits(_sprintSeconds, arabic: true)} ثانية. كم سؤالًا تستطيع حل؟'
              : 'You have $_sprintSeconds seconds. How many can you answer?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark.withAlpha(170),
          ),
        ),
        const SizedBox(height: 16),
        _BandTile(
          band: MentalMathBand.easy,
          isAr: isAr,
          labelEn: 'Easy',
          labelAr: 'سهل',
          hintEn: '+ and − up to 20',
          hintAr: 'جمع وطرح حتى ٢٠',
          emoji: '🌱',
          accent: AppColors.success,
          best: bests.bestFor(MentalMathBand.easy),
          onTap: () => _startSprint(MentalMathBand.easy),
        ),
        const SizedBox(height: 10),
        _BandTile(
          band: MentalMathBand.medium,
          isAr: isAr,
          labelEn: 'Medium',
          labelAr: 'متوسط',
          hintEn: '+ − × up to 100',
          hintAr: 'جمع وطرح وضرب حتى ١٠٠',
          emoji: '⚡',
          accent: AppColors.secondary,
          best: bests.bestFor(MentalMathBand.medium),
          onTap: () => _startSprint(MentalMathBand.medium),
        ),
        const SizedBox(height: 10),
        _BandTile(
          band: MentalMathBand.hard,
          isAr: isAr,
          labelEn: 'Hard',
          labelAr: 'صعب',
          hintEn: '+ − × ÷ larger numbers',
          hintAr: 'جميع العمليات وأعداد أكبر',
          emoji: '🔥',
          accent: AppColors.error,
          best: bests.bestFor(MentalMathBand.hard),
          onTap: () => _startSprint(MentalMathBand.hard),
        ),
      ],
    );
  }

  Widget _sprintView(bool isAr) {
    final q = _q!;
    final timeRatio = _secondsLeft / _sprintSeconds;
    return Column(
      children: [
        LinearProgressIndicator(
          value: timeRatio,
          minHeight: 6,
          color: timeRatio < 0.2 ? AppColors.error : AppColors.secondary,
          backgroundColor: AppColors.outline.withAlpha(60),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: AppColors.outline.withAlpha(80),
                  ),
                ),
                child: Text(
                  isAr
                      ? '${localizeDigits(_secondsLeft, arabic: true)}ث'
                      : '${_secondsLeft}s',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(40),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isAr
                      ? 'صحيح: ${localizeDigits(_score, arabic: true)}'
                      : 'Score: $_score',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withAlpha(48),
                AppColors.accent.withAlpha(28),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withAlpha(140)),
          ),
          child: Center(
            child: Text(
              isAr
                  ? '${_localizeOperand(q.a, true)} ${_opSymbol(q.op)} ${_localizeOperand(q.b, true)} = ؟'
                  : '${q.a} ${_opSymbol(q.op)} ${q.b} = ?',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              for (final v in _options)
                _SprintAnswer(
                  text: localizeDigits(v, arabic: isAr),
                  onTap: () => _pick(v),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultView(bool isAr) {
    final band = _band!;
    final bests = ref.watch(mentalMathBestsProvider).value ??
        MentalMathBests.empty;
    final best = bests.bestFor(band);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _wasPB ? '🏆' : '⏱️',
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? '${localizeDigits(_score, arabic: true)} ${_score == 1 ? 'إجابة' : 'إجابات'}'
                  : '$_score correct',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 44,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_wasPB)
              Text(
                isAr ? 'رقم قياسي جديد!' : 'New personal best!',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.success,
                ),
              )
            else
              Text(
                isAr
                    ? 'الأفضل: ${localizeDigits(best, arabic: true)}'
                    : 'Best: $best',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _exitToPicker,
                  icon: Icon(
                    isAr
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                  ),
                  label: Text(isAr ? 'المستويات' : 'Levels'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _startSprint(band),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(isAr ? 'إعادة' : 'Play again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _opSymbol(MentalOp op) => switch (op) {
        MentalOp.add => '+',
        MentalOp.sub => '−',
        MentalOp.mul => '×',
        MentalOp.div => '÷',
      };

  String _localizeOperand(int n, bool arabic) =>
      localizeDigits(n, arabic: arabic);
}

class _BandTile extends StatelessWidget {
  const _BandTile({
    required this.band,
    required this.isAr,
    required this.labelEn,
    required this.labelAr,
    required this.hintEn,
    required this.hintAr,
    required this.emoji,
    required this.accent,
    required this.best,
    required this.onTap,
  });

  final MentalMathBand band;
  final bool isAr;
  final String labelEn;
  final String labelAr;
  final String hintEn;
  final String hintAr;
  final String emoji;
  final Color accent;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withAlpha(120), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withAlpha(140)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? labelAr : labelEn,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textDark,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    isAr ? hintAr : hintEn,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isAr ? 'الأفضل' : 'Best',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textDark.withAlpha(170),
                    fontSize: 11,
                  ),
                ),
                Text(
                  localizeDigits(best, arabic: isAr),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SprintAnswer extends StatelessWidget {
  const _SprintAnswer({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline.withAlpha(80), width: 1.4),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
            fontSize: 26,
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
