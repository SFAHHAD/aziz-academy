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

class WordScrambleScreen extends ConsumerStatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  ConsumerState<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends ConsumerState<WordScrambleScreen> {
  static const _duration = 75;

  static const List<({String en, String ar})> _words = [
    (en: 'APPLE', ar: 'تفاحة'),
    (en: 'BANANA', ar: 'موز'),
    (en: 'ORANGE', ar: 'برتقال'),
    (en: 'TIGER', ar: 'نمر'),
    (en: 'ELEPHANT', ar: 'فيل'),
    (en: 'GIRAFFE', ar: 'زرافة'),
    (en: 'MOUNTAIN', ar: 'جبل'),
    (en: 'RIVER', ar: 'نهر'),
    (en: 'OCEAN', ar: 'محيط'),
    (en: 'FOREST', ar: 'غابة'),
    (en: 'GARDEN', ar: 'حديقة'),
    (en: 'SCHOOL', ar: 'مدرسة'),
    (en: 'PENCIL', ar: 'قلم'),
    (en: 'BOOK', ar: 'كتاب'),
    (en: 'TEACHER', ar: 'معلم'),
    (en: 'STUDENT', ar: 'طالب'),
    (en: 'FAMILY', ar: 'عائلة'),
    (en: 'FRIEND', ar: 'صديق'),
    (en: 'MOTHER', ar: 'أم'),
    (en: 'FATHER', ar: 'أب'),
    (en: 'KITCHEN', ar: 'مطبخ'),
    (en: 'WINDOW', ar: 'نافذة'),
    (en: 'COMPUTER', ar: 'حاسوب'),
    (en: 'PLANET', ar: 'كوكب'),
    (en: 'SCIENCE', ar: 'علوم'),
    (en: 'HISTORY', ar: 'تاريخ'),
    (en: 'NUMBER', ar: 'رقم'),
    (en: 'LETTER', ar: 'حرف'),
    (en: 'CIRCLE', ar: 'دائرة'),
    (en: 'SQUARE', ar: 'مربع'),
    (en: 'YELLOW', ar: 'أصفر'),
    (en: 'PURPLE', ar: 'بنفسجي'),
    (en: 'WINTER', ar: 'شتاء'),
    (en: 'SUMMER', ar: 'صيف'),
    (en: 'CLOUD', ar: 'سحابة'),
    (en: 'DESERT', ar: 'صحراء'),
    (en: 'ISLAND', ar: 'جزيرة'),
    (en: 'BRIDGE', ar: 'جسر'),
    (en: 'CASTLE', ar: 'قلعة'),
    (en: 'ROCKET', ar: 'صاروخ'),
  ];

  Timer? _timer;
  int _seconds = _duration;
  int _score = 0;
  int _streak = 0;
  bool _running = false;
  String _target = '';
  late List<String> _scrambled;
  late List<int> _picked;
  String? _flash;
  bool _w5 = false, _w12 = false, _w20 = false;

  @override
  void initState() {
    super.initState();
    _newWord();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _activeWord {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return isAr ? _wordPair.ar : _wordPair.en;
  }

  late ({String en, String ar}) _wordPair;

  void _newWord() {
    final rng = math.Random();
    _wordPair = _words[rng.nextInt(_words.length)];
    _target = _wordPair.en;
    final letters = _target.split('');
    letters.shuffle(rng);
    if (letters.join() == _target && _target.length > 1) {
      final i = rng.nextInt(_target.length - 1);
      final tmp = letters[i];
      letters[i] = letters[i + 1];
      letters[i + 1] = tmp;
    }
    _scrambled = letters;
    _picked = [];
  }

  void _start() {
    setState(() {
      _running = true;
      _seconds = _duration;
      _score = 0;
      _streak = 0;
      _flash = null;
    });
    _newWord();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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

  void _tapLetter(int idx) {
    if (!_running) return;
    if (_picked.contains(idx)) return;
    setState(() {
      _picked.add(idx);
      final built = _picked.map((i) => _scrambled[i]).join();
      if (built == _target) {
        HapticFeedback.lightImpact();
        _score += 1;
        _streak += 1;
        _seconds = math.min(_seconds + 3, _duration);
        _flash = 'good';
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _newWord();
              _flash = null;
            });
          }
        });
      } else if (built.length == _target.length) {
        HapticFeedback.heavyImpact();
        _streak = 0;
        _flash = 'bad';
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _picked = [];
              _flash = null;
            });
          }
        });
      }
    });
  }

  void _undo() {
    if (!_running || _picked.isEmpty) return;
    setState(() {
      _picked.removeLast();
    });
  }

  void _skip() {
    if (!_running) return;
    setState(() {
      _streak = 0;
      _seconds = math.max(_seconds - 5, 0);
      _newWord();
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 5 && !_w5) {
      _w5 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 12 && !_w12) {
      _w12 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 20 && !_w20) {
      _w20 = true;
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
          isAr ? 'ترتيب الكلمات' : 'Word Scramble',
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
                    ? 'رتّب الحروف لتكوين الكلمة الإنجليزية المطلوبة.'
                    : 'Arrange the letters to spell the word.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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
                  _Pill(
                    label: isAr ? 'متتالية' : 'Streak',
                    value: localizeDigits(_streak, arabic: isAr),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_running) ...[
                Text(
                  isAr ? 'المعنى: ${_wordPair.ar}' : 'Hint: $_activeWord',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _flash == 'good'
                        ? AppColors.success.withValues(alpha: 0.2)
                        : _flash == 'bad'
                        ? AppColors.error.withValues(alpha: 0.2)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _picked.map((i) => _scrambled[i]).join(' '),
                    style: AppTextStyles.headingMedium.copyWith(
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < _scrambled.length; i++)
                      _LetterTile(
                        letter: _scrambled[i],
                        used: _picked.contains(i),
                        onTap: () => _tapLetter(i),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _undo,
                      icon: const Icon(Icons.undo),
                      label: Text(isAr ? 'تراجع' : 'Undo'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _skip,
                      icon: const Icon(Icons.skip_next),
                      label: Text(isAr ? 'تخطي (-٥)' : 'Skip (-5s)'),
                    ),
                  ],
                ),
              ] else ...[
                const Spacer(),
                if (_seconds <= 0)
                  Text(
                    isAr
                        ? 'النقاط النهائية: ${localizeDigits(_score, arabic: true)}'
                        : 'Final score: $_score',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: Icon(_seconds <= 0 ? Icons.replay : Icons.play_arrow),
                  label: Text(
                    _seconds <= 0
                        ? (isAr ? 'مرة أخرى' : 'Play again')
                        : (isAr ? 'ابدأ' : 'Start'),
                  ),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.used,
    required this.onTap,
  });
  final String letter;
  final bool used;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: used ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: used ? AppColors.surfaceContainer : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: AppTextStyles.headingMedium.copyWith(
            color: used ? AppColors.textMedium : Colors.white,
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
