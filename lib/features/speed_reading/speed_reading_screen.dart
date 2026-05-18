import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Speed-reading drill — flashes a short passage one word at a time at a
/// user-selected WPM (60 / 120 / 180 / 240), then asks one comprehension
/// question. Pure on-device, no network. +1🪙 per correct answer.
class SpeedReadingScreen extends ConsumerStatefulWidget {
  const SpeedReadingScreen({super.key});

  @override
  ConsumerState<SpeedReadingScreen> createState() => _SpeedReadingScreenState();
}

class _SpeedReadingScreenState extends ConsumerState<SpeedReadingScreen> {
  int _wpm = 180;
  int _idx = 0;
  int _wordIdx = 0;
  bool _flashing = false;
  bool _done = false;
  Timer? _timer;
  String? _picked;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final passage = _passages[_idx];
    final words = passage.words(_isAr());
    setState(() {
      _flashing = true;
      _done = false;
      _wordIdx = 0;
      _picked = null;
    });
    final intervalMs = (60000 / _wpm).round();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (_wordIdx >= words.length - 1) {
        t.cancel();
        setState(() {
          _flashing = false;
          _done = true;
        });
      } else {
        setState(() => _wordIdx += 1);
      }
    });
  }

  bool _isAr() => Directionality.of(context) == TextDirection.rtl;

  void _pick(String opt) {
    if (_picked != null) return;
    final isAr = _isAr();
    final correct = isAr ? _passages[_idx].correctAr : _passages[_idx].correct;
    setState(() => _picked = opt);
    if (opt == correct) {
      ref.read(coinProvider.notifier).award(1);
    }
  }

  void _next() {
    setState(() {
      _idx = (_idx + 1) % _passages.length;
      _flashing = false;
      _done = false;
      _wordIdx = 0;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr();
    final p = _passages[_idx];
    final words = p.words(isAr);
    final question = isAr ? p.questionAr : p.question;
    final options = isAr ? p.optionsAr : p.options;
    final correct = isAr ? p.correctAr : p.correct;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'القراءة السريعة' : 'Speed Reading'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            _timer?.cancel();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_flashing && !_done) ...[
                Text(
                  isAr ? 'اختر السرعة' : 'Pick a speed',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final v in [60, 120, 180, 240])
                      ChoiceChip(
                        label: Text(
                          '${localizeDigits(v, arabic: isAr)} ${isAr ? "كلمة/د" : "wpm"}',
                        ),
                        selected: _wpm == v,
                        onSelected: (_) => setState(() => _wpm = v),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(isAr ? 'ابدأ' : 'Start'),
                ),
              ] else if (_flashing) ...[
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(120),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        words[math.min(_wordIdx, words.length - 1)],
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.textDark,
                          fontSize: 36,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                LinearProgressIndicator(
                  value: words.isEmpty ? 0 : (_wordIdx + 1) / words.length,
                  color: AppColors.accent,
                  backgroundColor: AppColors.outline.withAlpha(60),
                ),
              ] else ...[
                Text(
                  question,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                for (final opt in options) ...[
                  _OptionTile(
                    label: opt,
                    onTap: () => _pick(opt),
                    state: _picked == null
                        ? _OptionState.idle
                        : opt == correct
                        ? _OptionState.correct
                        : opt == _picked
                        ? _OptionState.wrong
                        : _OptionState.idle,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                if (_picked != null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(isAr ? 'إعادة' : 'Replay'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _next,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(isAr ? 'التالي' : 'Next'),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.onTap,
    required this.state,
  });
  final String label;
  final VoidCallback onTap;
  final _OptionState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptionState.correct => AppColors.success,
      _OptionState.wrong => AppColors.error,
      _OptionState.idle => AppColors.outline,
    };
    return InkWell(
      onTap: state == _OptionState.idle ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(state == _OptionState.idle ? 18 : 36),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(140), width: 1.4),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDark),
        ),
      ),
    );
  }
}

class _Passage {
  const _Passage({
    required this.en,
    required this.ar,
    required this.question,
    required this.questionAr,
    required this.options,
    required this.optionsAr,
    required this.correct,
    required this.correctAr,
  });
  final String en;
  final String ar;
  final String question;
  final String questionAr;
  final List<String> options;
  final List<String> optionsAr;
  final String correct;
  final String correctAr;

  List<String> words(bool arabic) => (arabic ? ar : en)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
}

const _passages = <_Passage>[
  _Passage(
    en: 'Long ago a small village near the Nile lost its only well. The children walked far each morning to bring water back. One clever girl noticed clouds gathering above the cliffs. She built a wide cloth funnel between two trees to catch the rain, and within a week the village had water again.',
    ar: 'منذ زمن طويل، فقدت قرية صغيرة قرب النيل بئرها الوحيد. كان الأطفال يمشون مسافة طويلة كل صباح لجلب الماء. لاحظت بنت ذكية الغيوم تتجمع فوق الجرف. صنعت قمعاً واسعاً من القماش بين شجرتين ليلتقط المطر، فعاد الماء إلى القرية في أسبوع.',
    question: 'How did the girl get water?',
    questionAr: 'كيف حصلت البنت على الماء؟',
    options: [
      'She caught rain with a cloth funnel',
      'She dug a deeper well',
      'She walked to the Nile',
      'She bought it from a market',
    ],
    optionsAr: [
      'التقطت المطر بقمع من القماش',
      'حفرت بئراً أعمق',
      'مشت إلى النيل',
      'اشترته من السوق',
    ],
    correct: 'She caught rain with a cloth funnel',
    correctAr: 'التقطت المطر بقمع من القماش',
  ),
  _Passage(
    en: 'A young apprentice in Damascus learned to bind books from his grandfather. The grandfather taught him that good glue must come from boiled fish bones, and that thread must always go from inside to outside, never the reverse. After three winters, the boy bound his first book alone — a small atlas of stars.',
    ar: 'تعلّم صبي في دمشق فن تجليد الكتب من جدّه. علّمه جدّه أن الصمغ الجيد يأتي من عظام السمك المسلوقة، وأن الخيط يمر من الداخل إلى الخارج لا العكس. بعد ثلاثة شتاءات، جلّد الصبي أول كتاب له وحده، أطلساً صغيراً للنجوم.',
    question: 'What did the apprentice bind first on his own?',
    questionAr: 'ما هو الكتاب الأول الذي جلده الصبي وحده؟',
    options: [
      'A small atlas of stars',
      'A poetry book',
      'A medical encyclopedia',
      'A cookbook',
    ],
    optionsAr: ['أطلس صغير للنجوم', 'ديوان شعر', 'موسوعة طبية', 'كتاب طبخ'],
    correct: 'A small atlas of stars',
    correctAr: 'أطلس صغير للنجوم',
  ),
  _Passage(
    en: 'The honey badger is one of the bravest animals in Africa. It does not fear cobras, scorpions, or even lions. Its thick rubbery skin can resist bites and stings. Scientists have watched a single honey badger chase three young lions away from its den. It is small but full of courage and clever tricks.',
    ar: 'حيوان غُرير العسل من أشجع الحيوانات في إفريقيا. لا يخاف من الكوبرا ولا العقارب ولا حتى الأسود. جلده السميك المطّاطي يقاوم اللدغات والعض. شاهد العلماء غُريراً واحداً يطارد ثلاثة أشبال من الأسود بعيداً عن جحره. صغير لكنه مليء بالشجاعة والحيل الذكية.',
    question: 'Why is the honey badger so brave?',
    questionAr: 'لماذا غُرير العسل شجاع جداً؟',
    options: [
      'Its skin resists bites and stings',
      'It is bigger than a lion',
      'It can fly away from danger',
      'It is too fast to be caught',
    ],
    optionsAr: [
      'جلده يقاوم اللدغات والعض',
      'لأنه أكبر من الأسد',
      'لأنه يطير هرباً',
      'لأنه سريع جداً لا يُمسك',
    ],
    correct: 'Its skin resists bites and stings',
    correctAr: 'جلده يقاوم اللدغات والعض',
  ),
];
