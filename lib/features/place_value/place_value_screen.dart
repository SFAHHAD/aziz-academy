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
import 'package:aziz_academy/features/place_value/place_value_engine.dart';

/// Place Value — visualize tens-rods and ones-cubes for two-digit
/// numbers. Two modes:
///   • "What number?" — blocks shown, kid picks the number.
///   • "How many tens / ones?" — number shown, kid picks the digit.
/// 10 questions per round, no timer. Personal best per mode is
/// persisted on-device.
class PlaceValueScreen extends ConsumerStatefulWidget {
  const PlaceValueScreen({super.key});

  @override
  ConsumerState<PlaceValueScreen> createState() => _PlaceValueScreenState();
}

class _PlaceValueScreenState extends ConsumerState<PlaceValueScreen> {
  static const _roundLength = 10;
  final _rng = math.Random();

  PvMode? _mode;
  PvQuestion? _q;
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

  String _bestKey(PvMode m) =>
      'place_value:${m == PvMode.blocksToNumber ? 'blocks' : 'digit'}';

  String _missKey(PvMode m, int number) => '${_bestKey(m)}:$number';

  Map<int, int> _weightsFor(PvMode m, QuizMisses? misses) {
    if (misses == null) return const {};
    final prefix = _bestKey(m);
    final result = <int, int>{};
    for (final e in misses.byKey.entries) {
      if (!e.key.startsWith('$prefix:')) continue;
      final tail = e.key.substring(prefix.length + 1);
      final num = int.tryParse(tail);
      if (num != null) result[num] = e.value;
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

  void _start(PvMode m) {
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
    // Half-weighted sampling — same shape as Number Bonds, so the
    // kid practices weak spots without feeling like the app is
    // harping on one number forever.
    final misses = ref.read(quizMissesProvider).value;
    final ws = _weightsFor(_mode!, misses);
    final useWeighted = ws.isNotEmpty && _rng.nextBool();
    final q = generatePvQuestion(
      _mode!,
      rng: _rng,
      weights: useWeighted ? ws : null,
    );
    setState(() {
      _q = q;
      _options = generatePvOptions(q, rng: _rng);
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
        _hint = pvTeachingHint(_q!, arabic: isAr).forLocale(arabic: isAr);
      });
      ref
          .read(quizMissesProvider.notifier)
          .recordMiss(_missKey(_mode!, _q!.number));
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
        title: Text(isAr ? '🔢 المنازل العشرية' : '🔢 Place Value'),
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
                      changeLabelAr: 'تغيير النمط',
                      changeLabelEn: 'Change mode',
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

  final void Function(PvMode) onPick;
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bests = ref.watch(quizBestsProvider).value;
    final blocksBest = bests?.bestFor('place_value:blocks') ?? 0;
    final digitBest = bests?.bestFor('place_value:digit') ?? 0;
    String fmt(int n) => digits.localizeDigits(n, arabic: arabic);
    String bestLine(int best) => arabic
        ? 'أفضل نتيجة: ${fmt(best)} / ${fmt(10)}'
        : 'Best: ${fmt(best)} / ${fmt(10)}';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabic ? 'اختر النمط' : 'Pick a mode',
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
                emoji: '🟦',
                label: arabic ? 'ما هذا العدد؟' : 'What number?',
                subtitle:
                    arabic ? 'انظر إلى المكعبات' : 'Look at the blocks',
                color: AppColors.primary,
                bestLine: blocksBest > 0 ? bestLine(blocksBest) : null,
                onTap: () => onPick(PvMode.blocksToNumber),
              ),
              _ModeButton(
                emoji: '🔢',
                label: arabic ? 'كم آحاد وعشرات؟' : 'Tens or ones?',
                subtitle: arabic ? 'انظر إلى الرقم' : 'Look at the number',
                color: AppColors.success,
                bestLine: digitBest > 0 ? bestLine(digitBest) : null,
                onTap: () => onPick(PvMode.numberToBlocks),
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
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.bestLine,
  });

  final String emoji;
  final String label;
  final String subtitle;
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textLight,
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

  final PvQuestion q;
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
                q.mode == PvMode.blocksToNumber
                    ? (arabic ? 'ما العدد؟' : 'What number?')
                    : (q.askTens
                        ? (arabic ? 'كم عشرة؟' : 'How many tens?')
                        : (arabic ? 'كم آحاد؟' : 'How many ones?')),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: q.mode == PvMode.blocksToNumber
                ? _BlocksDisplay(tens: q.tens, ones: q.ones, arabic: arabic)
                : Text(
                    _fmt(q.number),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 88,
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

class _BlocksDisplay extends StatelessWidget {
  const _BlocksDisplay({
    required this.tens,
    required this.ones,
    required this.arabic,
  });

  final int tens;
  final int ones;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (tens > 0)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                children: List.generate(
                  tens,
                  (_) => Container(
                    width: 12,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                arabic ? 'عشرات' : 'tens',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        if (ones > 0)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(
                    ones,
                    (_) => Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: AppColors.success,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                arabic ? 'آحاد' : 'ones',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
