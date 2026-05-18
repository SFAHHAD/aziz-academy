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

class HangmanScreen extends ConsumerStatefulWidget {
  const HangmanScreen({super.key});

  @override
  ConsumerState<HangmanScreen> createState() => _HangmanScreenState();
}

const _enWords = <String>[
  'APPLE',
  'BREAD',
  'OCEAN',
  'TIGER',
  'EAGLE',
  'PLANT',
  'MUSIC',
  'HEART',
  'BRAIN',
  'EARTH',
  'PLANET',
  'CASTLE',
  'GARDEN',
  'WINTER',
  'SPRING',
  'SUMMER',
  'AUTUMN',
  'PUZZLE',
  'KNIGHT',
  'DRAGON',
  'ROCKET',
  'CAMERA',
  'FOREST',
  'RIVER',
  'STORM',
  'CHEESE',
  'COFFEE',
  'PALACE',
  'ISLAND',
  'MARKET',
  'SCHOOL',
  'FAMILY',
  'FRIEND',
  'NUMBER',
  'LETTER',
  'SCIENCE',
  'HISTORY',
  'COURAGE',
  'JOURNEY',
  'MYSTERY',
  'CULTURE',
  'WONDER',
  'FREEDOM',
  'WISDOM',
  'TREASURE',
  'KINGDOM',
  'HARVEST',
  'COMPASS',
  'TELESCOPE',
  'PYRAMID',
  'VOLCANO',
  'GLACIER',
];

const _arWords = <String>[
  'تفاحة',
  'خبز',
  'بحر',
  'نمر',
  'نسر',
  'نبات',
  'موسيقى',
  'قلب',
  'دماغ',
  'أرض',
  'كوكب',
  'قلعة',
  'حديقة',
  'شتاء',
  'ربيع',
  'صيف',
  'خريف',
  'لغز',
  'فارس',
  'تنين',
  'صاروخ',
  'كاميرا',
  'غابة',
  'نهر',
  'عاصفة',
  'جبنة',
  'قهوة',
  'قصر',
  'جزيرة',
  'سوق',
  'مدرسة',
  'عائلة',
  'صديق',
  'رقم',
  'حرف',
  'علم',
  'تاريخ',
  'شجاعة',
  'رحلة',
  'لغز',
  'ثقافة',
  'عجيبة',
  'حرية',
  'حكمة',
  'كنز',
  'مملكة',
  'حصاد',
  'بوصلة',
  'مرصد',
  'هرم',
  'بركان',
  'جليد',
];

const _enLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _arLetters = [
  'ا',
  'ب',
  'ت',
  'ث',
  'ج',
  'ح',
  'خ',
  'د',
  'ذ',
  'ر',
  'ز',
  'س',
  'ش',
  'ص',
  'ض',
  'ط',
  'ظ',
  'ع',
  'غ',
  'ف',
  'ق',
  'ك',
  'ل',
  'م',
  'ن',
  'ه',
  'و',
  'ي',
  'ء',
  'ة',
  'ى',
  'أ',
  'إ',
  'آ',
  'ؤ',
  'ئ',
];

class _HangmanScreenState extends ConsumerState<HangmanScreen> {
  static const _duration = 75;
  static const _maxMisses = 6;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  String _word = '';
  Set<String> _guessed = {};
  int _misses = 0;
  String? _msg;
  bool _w3 = false, _w6 = false, _w10 = false;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _seconds = _duration;
      _score = 0;
      _running = true;
      _msg = null;
    });
    _newWord();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
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

  void _newWord() {
    if (!_running) return;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final words = isAr ? _arWords : _enWords;
    setState(() {
      _word = words[_rng.nextInt(words.length)];
      _guessed = {};
      _misses = 0;
      _msg = null;
    });
  }

  bool _isComplete() {
    for (final c in _word.split('')) {
      if (!_guessed.contains(c)) return false;
    }
    return true;
  }

  void _guessLetter(String letter) {
    if (!_running) return;
    if (_guessed.contains(letter)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _guessed = {..._guessed, letter};
      if (!_word.contains(letter)) {
        _misses += 1;
      }
    });
    if (_isComplete()) {
      setState(() {
        _score += 1;
        _msg = '✅ +1';
      });
      Timer(const Duration(milliseconds: 600), () {
        if (mounted && _running) _newWord();
      });
    } else if (_misses >= _maxMisses) {
      setState(() => _msg = '❌ $_word');
      Timer(const Duration(milliseconds: 900), () {
        if (mounted && _running) _newWord();
      });
    }
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 3 && !_w3) {
      _w3 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 6 && !_w6) {
      _w6 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 10 && !_w10) {
      _w10 = true;
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
          isAr ? 'لعبة الكلمة المفقودة' : 'Hangman',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'خمّن الحروف لكشف الكلمة. ٦ أخطاء فقط لكل كلمة!'
                    : 'Guess letters to reveal the word. Only 6 misses per word!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
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
                    label: isAr ? 'أخطاء' : 'Miss',
                    value:
                        '${localizeDigits(_misses, arabic: isAr)}/${localizeDigits(_maxMisses, arabic: isAr)}',
                    color: _misses >= _maxMisses - 1
                        ? AppColors.error
                        : AppColors.textDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: _running ? _buildPlay(isAr) : _buildIdle(isAr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlay(bool isAr) {
    final letters = isAr ? _arLetters : _enLetters.split('');
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _word
                .split('')
                .map((c) => _guessed.contains(c) ? c : '_')
                .join(' '),
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final l in letters)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _guessed.contains(l)
                        ? null
                        : () => _guessLetter(l),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: _guessed.contains(l)
                          ? (_word.contains(l)
                                ? AppColors.success.withAlpha(80)
                                : AppColors.error.withAlpha(80))
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Text(_msg!, style: const TextStyle(fontSize: 22)),
          ],
        ],
      ),
    );
  }

  Widget _buildIdle(bool isAr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _seconds == _duration
              ? (isAr ? '🪢 جاهز؟' : '🪢 Ready?')
              : (isAr
                    ? 'انتهى! نقاطك: ${localizeDigits(_score, arabic: true)}'
                    : 'Done! Score: ${localizeDigits(_score, arabic: false)}'),
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            isAr ? 'ابدأ' : 'Start',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
