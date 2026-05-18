import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/quiz_bests_provider.dart';
import 'package:aziz_academy/core/providers/quiz_misses_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart' as digits;
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/widgets/quiz_option_tile.dart';
import 'package:aziz_academy/core/widgets/round_progress_bar.dart';
import 'package:aziz_academy/core/widgets/round_result_panel.dart';
import 'package:aziz_academy/core/widgets/teaching_hint_banner.dart';
import 'package:aziz_academy/features/number_bonds/number_bonds_engine.dart';

/// Number Bonds — mental-math foundation for ages 6-8. Pick a target
/// (10 or 20), then answer 10 "shown + ? = target" questions by
/// tapping one of four options. Correct picks flash green + briefly
/// pause before advancing; wrong picks shake red so the kid can
/// retry. Personal best per target is persisted on-device.
class NumberBondsScreen extends ConsumerStatefulWidget {
  const NumberBondsScreen({super.key});

  @override
  ConsumerState<NumberBondsScreen> createState() => _NumberBondsScreenState();
}

class _NumberBondsScreenState extends ConsumerState<NumberBondsScreen> {
  static const _roundLength = 10;
  final _rng = math.Random();

  BondTarget? _target;
  BondQuestion? _q;
  List<int> _options = const [];
  int _index = 0;
  int _correct = 0;
  int? _lastWrong;
  int? _lastCorrect;
  String? _hint;
  bool _done = false;
  bool _isNewBest = false;
  int _previousBest = 0;
  Timer? _advanceTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  String _bestKey(BondTarget t) =>
      'number_bonds:${t == BondTarget.ten ? 'ten' : 'twenty'}';

  String _missKey(BondTarget t, int shown) =>
      '${_bestKey(t)}:$shown';

  Map<int, int> _weightsFor(BondTarget t, QuizMisses? misses) {
    if (misses == null) return const {};
    final prefix = _bestKey(t);
    final result = <int, int>{};
    for (final e in misses.byKey.entries) {
      if (!e.key.startsWith('$prefix:')) continue;
      final tail = e.key.substring(prefix.length + 1);
      final shown = int.tryParse(tail);
      if (shown != null) result[shown] = e.value;
    }
    return result;
  }

  bool get _adaptiveActive {
    if (_target == null) return false;
    final misses = ref.read(quizMissesProvider).value;
    final ws = _weightsFor(_target!, misses);
    final total = ws.values.fold<int>(0, (a, b) => a + b);
    return total >= 3;
  }

  void _start(BondTarget t) {
    _advanceTimer?.cancel();
    setState(() {
      _target = t;
      _index = 0;
      _correct = 0;
      _done = false;
      _isNewBest = false;
      _previousBest = 0;
      _next();
    });
  }

  void _next() {
    // Weighted sampling kicks in only when the kid has accumulated
    // some misses. We flip a coin so half the questions are still
    // uniformly random — keeps the practice from feeling like the
    // app is harping on one weak spot forever.
    final misses = ref.read(quizMissesProvider).value;
    final ws = _weightsFor(_target!, misses);
    final useWeighted = ws.isNotEmpty && _rng.nextBool();
    final q = generateBondQuestion(
      _target!,
      rng: _rng,
      weights: useWeighted ? ws : null,
    );
    setState(() {
      _q = q;
      _options = generateBondOptions(q, rng: _rng);
      _lastWrong = null;
      _lastCorrect = null;
      _hint = null;
    });
  }

  Future<void> _finish() async {
    final res = await ref
        .read(quizBestsProvider.notifier)
        .recordScore(_bestKey(_target!), _correct);
    if (!mounted) return;
    setState(() {
      _done = true;
      _isNewBest = res.isNewBest;
      _previousBest = res.previousBest;
    });
  }

  void _pick(int v) {
    if (_done || _q == null || _lastCorrect != null) return;
    if (v == _q!.answer) {
      setState(() {
        _correct += 1;
        _lastCorrect = v;
        _hint = null;
      });
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      final delay = reduceMotion ? Duration.zero
          : const Duration(milliseconds: 320);
      _advanceTimer?.cancel();
      _advanceTimer = Timer(delay, () {
        if (!mounted) return;
        if (_index + 1 >= _roundLength) {
          _finish();
        } else {
          setState(() => _index += 1);
          _next();
        }
      });
    } else {
      final isAr = Directionality.of(context) == TextDirection.rtl;
      setState(() {
        _lastWrong = v;
        _hint = bondTeachingHint(_q!, arabic: isAr).forLocale(arabic: isAr);
      });
      // Fire-and-forget miss tracking. The kid stays in the round.
      ref
          .read(quizMissesProvider.notifier)
          .recordMiss(_missKey(_target!, _q!.shown));
    }
  }

  void _reset() {
    _advanceTimer?.cancel();
    setState(() {
      _target = null;
      _q = null;
      _options = const [];
      _index = 0;
      _correct = 0;
      _done = false;
      _lastWrong = null;
      _lastCorrect = null;
      _hint = null;
      _isNewBest = false;
      _previousBest = 0;
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
        title: Text(isAr ? '🧮 روابط الأعداد' : '🧮 Number Bonds'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (_target != null && !_done) {
              _reset();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _target == null
              ? _TargetPicker(onPick: _start, arabic: isAr)
              : _done
                  ? RoundResultPanel(
                      correct: _correct,
                      total: _roundLength,
                      arabic: isAr,
                      isNewBest: _isNewBest,
                      previousBest: _previousBest,
                      changeLabelAr: 'تغيير الهدف',
                      changeLabelEn: 'Change target',
                      onAgain: () => _start(_target!),
                      onChange: _reset,
                    )
                  : _Round(
                      q: _q!,
                      options: _options,
                      index: _index,
                      total: _roundLength,
                      lastWrong: _lastWrong,
                      lastCorrect: _lastCorrect,
                      hint: _hint,
                      adaptive: _adaptiveActive,
                      onPick: _pick,
                      arabic: isAr,
                    ),
        ),
      ),
    );
  }
}

class _TargetPicker extends ConsumerWidget {
  const _TargetPicker({required this.onPick, required this.arabic});

  final void Function(BondTarget) onPick;
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bests = ref.watch(quizBestsProvider).value;
    final tenBest = bests?.bestFor('number_bonds:ten') ?? 0;
    final twentyBest = bests?.bestFor('number_bonds:twenty') ?? 0;
    String fmt(int n) => digits.localizeDigits(n, arabic: arabic);
    String bestLine(int best) => arabic
        ? 'أفضل نتيجة: ${fmt(best)} / ${fmt(10)}'
        : 'Best: ${fmt(best)} / ${fmt(10)}';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabic ? 'اختر الهدف' : 'Pick a target',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            arabic
                ? 'كم نحتاج لنُكمل المجموع؟'
                : 'How much do we need to complete the total?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _TargetButton(
                label: arabic ? 'روابط الـ ١٠' : 'Bonds to 10',
                emoji: '🔟',
                color: AppColors.success,
                bestLine: tenBest > 0 ? bestLine(tenBest) : null,
                onTap: () => onPick(BondTarget.ten),
              ),
              _TargetButton(
                label: arabic ? 'روابط الـ ٢٠' : 'Bonds to 20',
                emoji: '🎯',
                color: AppColors.primary,
                bestLine: twentyBest > 0 ? bestLine(twentyBest) : null,
                onTap: () => onPick(BondTarget.twenty),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetButton extends StatelessWidget {
  const _TargetButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
    this.bestLine,
  });

  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  final String? bestLine;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: bestLine == null ? label : '$label · $bestLine',
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (bestLine != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    bestLine!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.q,
    required this.options,
    required this.index,
    required this.total,
    required this.lastWrong,
    required this.lastCorrect,
    required this.hint,
    required this.adaptive,
    required this.onPick,
    required this.arabic,
  });

  final BondQuestion q;
  final List<int> options;
  final int index;
  final int total;
  final int? lastWrong;
  final int? lastCorrect;
  final String? hint;
  final bool adaptive;
  final void Function(int) onPick;
  final bool arabic;

  String _fmt(int n) => digits.localizeDigits(n, arabic: arabic);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              arabic
                  ? 'سؤال ${_fmt(index + 1)} / ${_fmt(total)}'
                  : 'Q ${_fmt(index + 1)} / ${_fmt(total)}',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textLight,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                arabic ? 'الهدف ${_fmt(q.target)}' : 'Target ${_fmt(q.target)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (adaptive) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Text(
                arabic
                    ? '💪 تدريب على الأرقام التي أخطأت فيها'
                    : '💪 Practicing the bonds you find tricky',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        RoundProgressBar(progress: (index + (lastCorrect != null ? 1 : 0)) / total),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Bubble(text: _fmt(q.shown), color: AppColors.primary),
                  const _Op(symbol: '+'),
                  _Bubble(text: '?', color: AppColors.warning, dashed: true),
                  const _Op(symbol: '='),
                  _Bubble(text: _fmt(q.target), color: AppColors.success),
                ],
              ),
            ),
          ),
        ),
        TeachingHintBanner(text: hint, arabic: arabic),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: options.length,
          itemBuilder: (context, i) {
            final v = options[i];
            final state = v == lastCorrect
                ? QuizTileState.correct
                : v == lastWrong
                    ? QuizTileState.wrong
                    : QuizTileState.neutral;
            return QuizOptionTile(
              text: _fmt(v),
              state: state,
              semanticLabel: arabic
                  ? 'الإجابة ${_fmt(v)}'
                  : 'Answer ${_fmt(v)}',
              onTap: () => onPick(v),
            );
          },
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.color,
    this.dashed = false,
  });

  final String text;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
          width: dashed ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.displayMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Op extends StatelessWidget {
  const _Op({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Text(
      symbol,
      style: AppTextStyles.displayMedium.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
