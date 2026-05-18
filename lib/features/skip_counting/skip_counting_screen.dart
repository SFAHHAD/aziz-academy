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
import 'package:aziz_academy/features/skip_counting/skip_counting_engine.dart';

/// Skip Counting — count by 2s, 5s, or 10s. The kid sees six numbers
/// in a row with one blank, taps the missing number from four options.
/// 10 rounds per mode. Personal best per step is persisted on-device.
class SkipCountingScreen extends ConsumerStatefulWidget {
  const SkipCountingScreen({super.key});

  @override
  ConsumerState<SkipCountingScreen> createState() =>
      _SkipCountingScreenState();
}

class _SkipCountingScreenState extends ConsumerState<SkipCountingScreen> {
  static const _roundLength = 10;
  final _rng = math.Random();

  SkipMode? _mode;
  SkipQuestion? _q;
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

  String _bestKey(SkipMode m) => 'skip_counting:${m.name}';

  String _missKey(SkipMode m, int answer) => '${_bestKey(m)}:$answer';

  Map<int, int> _weightsFor(SkipMode m, QuizMisses? misses) {
    if (misses == null) return const {};
    final prefix = _bestKey(m);
    final result = <int, int>{};
    for (final e in misses.byKey.entries) {
      if (!e.key.startsWith('$prefix:')) continue;
      final tail = e.key.substring(prefix.length + 1);
      final ans = int.tryParse(tail);
      if (ans != null) result[ans] = e.value;
    }
    return result;
  }

  bool get _adaptiveActive {
    if (_mode == null) return false;
    final misses = ref.read(quizMissesProvider).value;
    final ws = _weightsFor(_mode!, misses);
    final total = ws.values.fold<int>(0, (a, b) => a + b);
    return total >= 3;
  }

  void _start(SkipMode m) {
    _advanceTimer?.cancel();
    setState(() {
      _mode = m;
      _index = 0;
      _correct = 0;
      _done = false;
      _isNewBest = false;
      _previousBest = 0;
      _next();
    });
  }

  void _next() {
    final misses = ref.read(quizMissesProvider).value;
    final ws = _weightsFor(_mode!, misses);
    final useWeighted = ws.isNotEmpty && _rng.nextBool();
    final q = generateSkipQuestion(
      _mode!,
      rng: _rng,
      weights: useWeighted ? ws : null,
    );
    setState(() {
      _q = q;
      _options = generateSkipOptions(q, rng: _rng);
      _lastWrong = null;
      _lastCorrect = null;
      _hint = null;
    });
  }

  Future<void> _finish() async {
    final res = await ref
        .read(quizBestsProvider.notifier)
        .recordScore(_bestKey(_mode!), _correct);
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
        _hint = skipTeachingHint(_q!, arabic: isAr).forLocale(arabic: isAr);
      });
      ref
          .read(quizMissesProvider.notifier)
          .recordMiss(_missKey(_mode!, _q!.answer));
    }
  }

  void _reset() {
    _advanceTimer?.cancel();
    setState(() {
      _mode = null;
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
        title: Text(isAr ? '⏭️ العد بالقفز' : '⏭️ Skip Counting'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (_mode != null && !_done) {
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
          child: _mode == null
              ? _ModePicker(onPick: _start, arabic: isAr)
              : _done
                  ? RoundResultPanel(
                      correct: _correct,
                      total: _roundLength,
                      arabic: isAr,
                      isNewBest: _isNewBest,
                      previousBest: _previousBest,
                      changeLabelAr: 'تغيير الخطوة',
                      changeLabelEn: 'Change step',
                      onAgain: () => _start(_mode!),
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

class _ModePicker extends ConsumerWidget {
  const _ModePicker({required this.onPick, required this.arabic});

  final void Function(SkipMode) onPick;
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bests = ref.watch(quizBestsProvider).value;
    String fmt(int n) => digits.localizeDigits(n, arabic: arabic);
    String? bestLine(SkipMode m) {
      final b = bests?.bestFor('skip_counting:${m.name}') ?? 0;
      if (b <= 0) return null;
      return arabic
          ? 'أفضل: ${fmt(b)} / ${fmt(10)}'
          : 'Best: ${fmt(b)} / ${fmt(10)}';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabic ? 'اختر الخطوة' : 'Pick a step',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _ModeButton(
                stepLabel: '2',
                arabicStepLabel: '٢',
                label: arabic ? 'بـ ٢' : 'By 2s',
                color: AppColors.primary,
                arabic: arabic,
                bestLine: bestLine(SkipMode.twos),
                onTap: () => onPick(SkipMode.twos),
              ),
              _ModeButton(
                stepLabel: '5',
                arabicStepLabel: '٥',
                label: arabic ? 'بـ ٥' : 'By 5s',
                color: AppColors.warning,
                arabic: arabic,
                bestLine: bestLine(SkipMode.fives),
                onTap: () => onPick(SkipMode.fives),
              ),
              _ModeButton(
                stepLabel: '10',
                arabicStepLabel: '١٠',
                label: arabic ? 'بـ ١٠' : 'By 10s',
                color: AppColors.success,
                arabic: arabic,
                bestLine: bestLine(SkipMode.tens),
                onTap: () => onPick(SkipMode.tens),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.stepLabel,
    required this.arabicStepLabel,
    required this.label,
    required this.color,
    required this.arabic,
    required this.onTap,
    this.bestLine,
  });

  final String stepLabel;
  final String arabicStepLabel;
  final String label;
  final Color color;
  final bool arabic;
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
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  arabic ? arabicStepLabel : stepLabel,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 56,
                  ),
                ),
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

  final SkipQuestion q;
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
                arabic
                    ? 'الخطوة ${_fmt(stepFor(q.mode))}'
                    : 'Step ${_fmt(stepFor(q.mode))}',
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
                    : '💪 Practicing numbers you find tricky',
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
          padding:
              const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < q.sequence.length; i++) ...[
                  _Cell(
                    text: i == q.blankIndex ? '?' : _fmt(q.sequence[i]),
                    isBlank: i == q.blankIndex,
                  ),
                  if (i < q.sequence.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ',',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                ],
              ],
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

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.isBlank});

  final String text;
  final bool isBlank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isBlank
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlank
              ? AppColors.warning
              : AppColors.surfaceContainerHigh,
          width: isBlank ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.displayMedium.copyWith(
            color: isBlank ? AppColors.warning : AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
