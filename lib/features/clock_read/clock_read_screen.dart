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

class ClockReadScreen extends ConsumerStatefulWidget {
  const ClockReadScreen({super.key});

  @override
  ConsumerState<ClockReadScreen> createState() => _ClockReadScreenState();
}

class _ClockReadScreenState extends ConsumerState<ClockReadScreen> {
  static const _duration = 60;

  final _rng = math.Random();
  Timer? _countdown;
  int _seconds = _duration;
  int _score = 0;
  bool _running = false;
  int _hour = 3;
  int _minute = 0;
  List<_Time> _options = const [];
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
    final hour = _rng.nextInt(12) + 1; // 1..12
    final minute = (_rng.nextInt(12)) * 5; // 0,5,10,...,55
    final correct = _Time(hour, minute);
    final opts = <_Time>{correct};
    while (opts.length < 4) {
      var h = hour + _rng.nextInt(5) - 2;
      if (h < 1) h += 12;
      if (h > 12) h -= 12;
      final m = (_rng.nextInt(12)) * 5;
      opts.add(_Time(h, m));
    }
    final list = opts.toList()..shuffle(_rng);
    setState(() {
      _hour = hour;
      _minute = minute;
      _options = list;
    });
  }

  void _tap(_Time t) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    if (t.hour == _hour && t.minute == _minute) {
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
          isAr ? 'اقرأ الساعة' : 'Tell the Time',
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
                    ? 'اقرأ الساعة التماثلية واختر الإجابة الصحيحة.'
                    : 'Read the analog clock and pick the right time.',
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
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(painter: _ClockPainter(_hour, _minute)),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: [
            for (final t in _options)
              ElevatedButton(
                onPressed: () => _tap(t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _format(t, isAr),
                  style: const TextStyle(
                    fontSize: 22,
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
              ? (isAr ? '🕒 جاهز؟' : '🕒 Ready?')
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

  String _format(_Time t, bool isAr) {
    final h = localizeDigits(t.hour, arabic: isAr);
    final m = t.minute.toString().padLeft(2, '0');
    final mLoc = isAr
        ? m.split('').map((c) {
            const map = {
              '0': '٠',
              '1': '١',
              '2': '٢',
              '3': '٣',
              '4': '٤',
              '5': '٥',
              '6': '٦',
              '7': '٧',
              '8': '٨',
              '9': '٩',
            };
            return map[c] ?? c;
          }).join()
        : m;
    return '$h:$mLoc';
  }
}

class _Time {
  const _Time(this.hour, this.minute);
  final int hour;
  final int minute;
  @override
  bool operator ==(Object other) =>
      other is _Time && other.hour == hour && other.minute == minute;
  @override
  int get hashCode => Object.hash(hour, minute);
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.hour, this.minute);
  final int hour;
  final int minute;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final face = Paint()..color = const Color(0xFFFFF8E7);
    final ring = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, face);
    canvas.drawCircle(center, radius, ring);

    final tick = Paint()
      ..color = AppColors.textMedium
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final ang = (i * 30 - 90) * math.pi / 180;
      final p1 = Offset(
        center.dx + math.cos(ang) * (radius - 10),
        center.dy + math.sin(ang) * (radius - 10),
      );
      final p2 = Offset(
        center.dx + math.cos(ang) * (radius - 2),
        center.dy + math.sin(ang) * (radius - 2),
      );
      canvas.drawLine(p1, p2, tick);
    }

    // Hour hand: each hour = 30 deg, plus minute fraction = 0.5 deg/min
    final hourAng = ((hour % 12) * 30 + minute * 0.5 - 90) * math.pi / 180;
    final hourLen = radius * 0.55;
    final hourPaint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(hourAng) * hourLen,
        center.dy + math.sin(hourAng) * hourLen,
      ),
      hourPaint,
    );

    // Minute hand: each min = 6 deg
    final minAng = (minute * 6 - 90) * math.pi / 180;
    final minLen = radius * 0.8;
    final minPaint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(minAng) * minLen,
        center.dy + math.sin(minAng) * minLen,
      ),
      minPaint,
    );

    final cap = Paint()..color = AppColors.textDark;
    canvas.drawCircle(center, 5, cap);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute;
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
