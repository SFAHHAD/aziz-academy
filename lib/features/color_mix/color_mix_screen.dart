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

class ColorMixScreen extends ConsumerStatefulWidget {
  const ColorMixScreen({super.key});

  @override
  ConsumerState<ColorMixScreen> createState() => _ColorMixScreenState();
}

class _ColorPair {
  const _ColorPair(
    this.aColor,
    this.aLabel,
    this.aLabelAr,
    this.bColor,
    this.bLabel,
    this.bLabelAr,
    this.resultColor,
    this.resultLabel,
    this.resultLabelAr,
  );
  final Color aColor;
  final String aLabel;
  final String aLabelAr;
  final Color bColor;
  final String bLabel;
  final String bLabelAr;
  final Color resultColor;
  final String resultLabel;
  final String resultLabelAr;
}

const _red = Color(0xFFE53935);
const _yellow = Color(0xFFFDD835);
const _blue = Color(0xFF1E88E5);
const _white = Color(0xFFFAFAFA);
const _black = Color(0xFF212121);
const _orange = Color(0xFFFB8C00);
const _green = Color(0xFF43A047);
const _purple = Color(0xFF8E24AA);
const _pink = Color(0xFFEC407A);
const _gray = Color(0xFF757575);
const _maroon = Color(0xFF8B1E1E);
const _lightBlue = Color(0xFF81D4FA);
const _cream = Color(0xFFFFF3CD);
const _brown = Color(0xFF6D4C41);
const _olive = Color(0xFF7B8A3A);
const _teal = Color(0xFF00897B);

const _pairs = <_ColorPair>[
  _ColorPair(
    _red,
    'Red',
    'أحمر',
    _yellow,
    'Yellow',
    'أصفر',
    _orange,
    'Orange',
    'برتقالي',
  ),
  _ColorPair(
    _blue,
    'Blue',
    'أزرق',
    _yellow,
    'Yellow',
    'أصفر',
    _green,
    'Green',
    'أخضر',
  ),
  _ColorPair(
    _red,
    'Red',
    'أحمر',
    _blue,
    'Blue',
    'أزرق',
    _purple,
    'Purple',
    'بنفسجي',
  ),
  _ColorPair(
    _white,
    'White',
    'أبيض',
    _black,
    'Black',
    'أسود',
    _gray,
    'Gray',
    'رمادي',
  ),
  _ColorPair(
    _red,
    'Red',
    'أحمر',
    _white,
    'White',
    'أبيض',
    _pink,
    'Pink',
    'وردي',
  ),
  _ColorPair(
    _red,
    'Red',
    'أحمر',
    _black,
    'Black',
    'أسود',
    _maroon,
    'Maroon',
    'كستنائي',
  ),
  _ColorPair(
    _blue,
    'Blue',
    'أزرق',
    _white,
    'White',
    'أبيض',
    _lightBlue,
    'Light Blue',
    'أزرق فاتح',
  ),
  _ColorPair(
    _yellow,
    'Yellow',
    'أصفر',
    _white,
    'White',
    'أبيض',
    _cream,
    'Cream',
    'كريمي',
  ),
  _ColorPair(
    _red,
    'Red',
    'أحمر',
    _green,
    'Green',
    'أخضر',
    _brown,
    'Brown',
    'بني',
  ),
  _ColorPair(
    _yellow,
    'Yellow',
    'أصفر',
    _green,
    'Green',
    'أخضر',
    _olive,
    'Olive',
    'زيتوني',
  ),
  _ColorPair(
    _blue,
    'Blue',
    'أزرق',
    _green,
    'Green',
    'أخضر',
    _teal,
    'Teal',
    'أزرق مخضر',
  ),
];

class _ColorMixScreenState extends ConsumerState<ColorMixScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  _ColorPair _current = _pairs.first;
  List<_ColorPair> _options = const [];
  String? _msg;
  bool _w8 = false, _w16 = false, _w24 = false;

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
    final correct = _pairs[_rng.nextInt(_pairs.length)];
    final opts = <_ColorPair>{correct};
    while (opts.length < 4) {
      opts.add(_pairs[_rng.nextInt(_pairs.length)]);
    }
    final list = opts.toList()..shuffle(_rng);
    setState(() {
      _current = correct;
      _options = list;
    });
  }

  void _tap(_ColorPair p) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (p.resultColor == _current.resultColor) {
      setState(() {
        _score += 1;
        _msg = '✅';
      });
      Timer(const Duration(milliseconds: 250), () {
        if (mounted && _running) _newRound();
      });
    } else {
      setState(() {
        _score = math.max(0, _score - 1);
        _msg = '❌';
      });
      Timer(const Duration(milliseconds: 350), () {
        if (mounted && _running) _newRound();
      });
    }
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
    if (_score >= 24 && !_w24) {
      _w24 = true;
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
          isAr ? 'مزج الألوان' : 'Color Mix',
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
                    ? 'ما اللون الناتج عن خلط هذين اللونين؟'
                    : 'What color do these two make when mixed?',
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circle(_current.aColor),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '+',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
              ),
            ),
            _circle(_current.bColor),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '=',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
              ),
            ),
            _circle(Colors.transparent, border: true),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            for (final p in _options)
              ElevatedButton(
                onPressed: () => _tap(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.resultColor,
                  foregroundColor: _onColor(p.resultColor),
                ),
                child: Text(
                  isAr ? p.resultLabelAr : p.resultLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        if (_msg != null) ...[
          const SizedBox(height: 12),
          Text(_msg!, style: const TextStyle(fontSize: 24)),
        ],
      ],
    );
  }

  Widget _buildIdle(bool isAr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _seconds == _duration
              ? (isAr ? '🎀 جاهز؟' : '🎀 Ready?')
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

  Widget _circle(Color c, {bool border = false}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: border ? Border.all(color: AppColors.outline, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: border ? const Text('?', style: TextStyle(fontSize: 28)) : null,
    );
  }

  Color _onColor(Color bg) {
    final l = (0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b);
    return l > 0.6 ? AppColors.textDark : Colors.white;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
