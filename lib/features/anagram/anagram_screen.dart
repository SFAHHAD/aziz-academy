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

class AnagramScreen extends ConsumerStatefulWidget {
  const AnagramScreen({super.key});

  @override
  ConsumerState<AnagramScreen> createState() => _AnagramScreenState();
}

const _enWords = <String>[
  'BIRD',
  'FISH',
  'BOOK',
  'TREE',
  'STAR',
  'KING',
  'LOVE',
  'TIME',
  'GOLD',
  'MOON',
  'BLUE',
  'PINK',
  'SAND',
  'CAVE',
  'ROCK',
  'SNOW',
  'RAIN',
  'WIND',
  'FIRE',
  'LION',
  'WOLF',
  'BEAR',
  'DEER',
  'FROG',
  'DUCK',
  'GOAT',
  'CROW',
  'OWL',
  'ANT',
  'BEE',
  'HORSE',
  'MOUSE',
  'EAGLE',
  'TIGER',
  'ZEBRA',
  'PANDA',
  'SNAKE',
  'WHALE',
  'SHEEP',
  'CAMEL',
  'STORK',
  'CRANE',
  'APPLE',
  'GRAPE',
  'LEMON',
  'MANGO',
  'PEACH',
  'BERRY',
  'BREAD',
  'WATER',
  'JUICE',
  'MILK',
  'HONEY',
  'SUGAR',
  'HOUSE',
  'TABLE',
  'CHAIR',
  'CLOCK',
  'PHONE',
  'PIANO',
  'EARTH',
  'CLOUD',
  'OCEAN',
  'RIVER',
  'STONE',
  'PLANT',
  'LEAF',
  'SEED',
  'ROOT',
  'GRASS',
  'NIGHT',
  'LIGHT',
  'BRIGHT',
  'SMILE',
  'HEART',
  'BRAIN',
  'HAND',
  'FOOT',
  'PLAY',
  'GAME',
  'SONG',
  'DANCE',
];

const _arWords = <String>[
  'كتاب',
  'قلم',
  'باب',
  'بيت',
  'ماء',
  'نار',
  'شمس',
  'قمر',
  'نجم',
  'ورد',
  'زهر',
  'سحب',
  'مطر',
  'ثلج',
  'رمل',
  'حجر',
  'جبل',
  'بحر',
  'نهر',
  'غاب',
  'شجرة',
  'فأر',
  'أسد',
  'نمر',
  'ذئب',
  'ثعلب',
  'حصان',
  'بقرة',
  'دجاج',
  'ديك',
  'بطة',
  'حمل',
  'تفاح',
  'ليمون',
  'موز',
  'عنب',
  'بطيخ',
  'تمر',
  'خبز',
  'حليب',
  'عسل',
  'سكر',
  'ملح',
  'كرسي',
  'طاولة',
  'سرير',
  'باب',
  'نافذة',
  'ساعة',
  'هاتف',
  'يوم',
  'ليل',
  'صباح',
  'مساء',
  'قلب',
  'يد',
  'رأس',
  'عين',
  'أذن',
  'لعب',
  'فرح',
  'حب',
  'سلام',
  'حياة',
  'علم',
  'فن',
  'قراءة',
  'كتابة',
];

class _AnagramScreenState extends ConsumerState<AnagramScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  String _target = '';
  List<String> _scrambled = const [];
  List<int> _used = const [];
  String _input = '';
  String? _msg;
  bool _w8 = false, _w16 = false, _w26 = false;

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
    _newRound();
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

  void _newRound() {
    if (!_running) return;
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final words = isAr ? _arWords : _enWords;
    final word = words[_rng.nextInt(words.length)];
    final letters = word.split('');
    var scrambled = [...letters];
    do {
      scrambled.shuffle(_rng);
    } while (scrambled.join() == word && letters.length > 1);
    setState(() {
      _target = word;
      _scrambled = scrambled;
      _used = [];
      _input = '';
      _msg = null;
    });
  }

  void _tap(int idx) {
    if (!_running) return;
    if (_used.contains(idx)) return;
    HapticFeedback.lightImpact();
    final newUsed = [..._used, idx];
    final newInput = _input + _scrambled[idx];
    if (newInput.length == _target.length) {
      if (newInput == _target) {
        setState(() {
          _used = newUsed;
          _input = newInput;
          _score += 1;
          _msg = '✅ +1';
        });
        Timer(const Duration(milliseconds: 350), () {
          if (mounted && _running) _newRound();
        });
      } else {
        setState(() => _msg = '❌ $_target');
        Timer(const Duration(milliseconds: 600), () {
          if (mounted && _running) _newRound();
        });
      }
    } else {
      setState(() {
        _used = newUsed;
        _input = newInput;
      });
    }
  }

  void _clear() {
    if (!_running) return;
    HapticFeedback.lightImpact();
    setState(() {
      _used = [];
      _input = '';
      _msg = null;
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 8 && !_w8) {
      _w8 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 16 && !_w16) {
      _w16 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 26 && !_w26) {
      _w26 = true;
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
          isAr ? 'حل الأناجرام' : 'Anagram Solver',
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
                    ? 'انقر الحروف بالترتيب الصحيح لتكوين كلمة.'
                    : 'Tap letters in the correct order to spell a word.',
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
                  padding: const EdgeInsets.all(16),
                  child: _running
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _input.isEmpty
                                  ? List.filled(_target.length, '_').join(' ')
                                  : _input.split('').join(' '),
                              style: AppTextStyles.headingLarge.copyWith(
                                color: AppColors.textDark,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (var i = 0; i < _scrambled.length; i++)
                                  ElevatedButton(
                                    onPressed: _used.contains(i)
                                        ? null
                                        : () => _tap(i),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(56, 56),
                                      backgroundColor: _used.contains(i)
                                          ? AppColors.surfaceContainer
                                          : AppColors.primary,
                                      foregroundColor: _used.contains(i)
                                          ? AppColors.textMedium
                                          : Colors.white,
                                    ),
                                    child: Text(
                                      _scrambled[i],
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_msg != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _msg!,
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: _msg!.startsWith('✅')
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_seconds <= 0 && _score > 0)
                                Text(
                                  isAr
                                      ? 'النقاط: ${localizeDigits(_score, arabic: true)}'
                                      : 'Score: $_score',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _start,
                                icon: Icon(
                                  _seconds <= 0
                                      ? Icons.replay
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  _seconds <= 0
                                      ? (isAr ? 'مرة أخرى' : 'Play again')
                                      : (isAr ? 'ابدأ' : 'Start'),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (_running)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.backspace),
                      label: Text(isAr ? 'مسح' : 'Clear'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _newRound,
                      icon: const Icon(Icons.skip_next),
                      label: Text(isAr ? 'تخطّي' : 'Skip'),
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
