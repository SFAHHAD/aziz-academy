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

class BowlingScreen extends ConsumerStatefulWidget {
  const BowlingScreen({super.key});

  @override
  ConsumerState<BowlingScreen> createState() => _BowlingScreenState();
}

class _BowlingScreenState extends ConsumerState<BowlingScreen> {
  static const _frames = 10;

  final _rng = math.Random();
  Timer? _aimTimer;
  int _score = 0;
  int _frame = 0; // 0..9
  bool _running = false;
  bool _firstRoll = true;
  int _firstRollPins = 0;
  double _aim = 0; // -1..1, 0 = center
  bool _aimDir = true; // true = increasing, false = decreasing
  List<int> _frameScores = const [];
  String? _msg;
  bool _w60 = false, _w100 = false, _w150 = false;

  @override
  void dispose() {
    _aimTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _score = 0;
      _frame = 0;
      _running = true;
      _firstRoll = true;
      _firstRollPins = 0;
      _aim = 0;
      _aimDir = true;
      _frameScores = List.filled(_frames, 0);
      _msg = null;
    });
    _startAim();
  }

  void _startAim() {
    _aimTimer?.cancel();
    _aimTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!_running || _frame >= _frames) {
        t.cancel();
        return;
      }
      setState(() {
        _aim += _aimDir ? 0.05 : -0.05;
        if (_aim >= 1) {
          _aim = 1;
          _aimDir = false;
        } else if (_aim <= -1) {
          _aim = -1;
          _aimDir = true;
        }
      });
    });
  }

  void _roll() {
    if (!_running) return;
    HapticFeedback.lightImpact();
    // Knock down pins based on aim accuracy. |aim| close to 0 = better.
    final accuracy = 1 - _aim.abs(); // 0..1
    final pinsAvailable = _firstRoll ? 10 : (10 - _firstRollPins);
    var pinsKnocked = (pinsAvailable * accuracy + _rng.nextDouble() * 0.3)
        .round();
    if (pinsKnocked > pinsAvailable) pinsKnocked = pinsAvailable;
    if (pinsKnocked < 0) pinsKnocked = 0;

    setState(() {
      if (_firstRoll) {
        _firstRollPins = pinsKnocked;
        if (pinsKnocked == 10) {
          _frameScores = [..._frameScores]..[_frame] = 10;
          _msg = '🎯 STRIKE!';
          _frame += 1;
          _firstRoll = true;
          _firstRollPins = 0;
        } else {
          _msg = localizeDigits(pinsKnocked, arabic: false);
          _firstRoll = false;
        }
      } else {
        final total = _firstRollPins + pinsKnocked;
        _frameScores = [..._frameScores]..[_frame] = total;
        if (total == 10) {
          _msg = '✨ SPARE!';
        } else {
          _msg = localizeDigits(total, arabic: false);
        }
        _frame += 1;
        _firstRoll = true;
        _firstRollPins = 0;
      }
      _score = _frameScores.fold(0, (a, b) => a + b);
    });

    if (_frame >= _frames) {
      _running = false;
      _aimTimer?.cancel();
      _award();
    }

    Timer(const Duration(milliseconds: 800), () {
      if (mounted && _running) setState(() => _msg = null);
    });
  }

  void _award() {
    HapticFeedback.heavyImpact();
    if (_score >= 60 && !_w60) {
      _w60 = true;
      ref.read(coinProvider.notifier).award(2);
    }
    if (_score >= 100 && !_w100) {
      _w100 = true;
      ref.read(coinProvider.notifier).award(5);
    }
    if (_score >= 150 && !_w150) {
      _w150 = true;
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
          isAr ? 'البولينغ' : 'Bowling',
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
                    ? 'وقّت رميتك! اضغط عندما يكون السهم في المنتصف.'
                    : 'Time your roll! Tap when the arrow is centered.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'الدور' : 'Frame',
                    value:
                        '${localizeDigits(math.min(_frame + 1, _frames), arabic: isAr)}/${localizeDigits(_frames, arabic: isAr)}',
                    color: AppColors.textDark,
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
          width: 240,
          height: 200,
          child: CustomPaint(
            painter: _LanePainter(_aim, _firstRoll, _firstRollPins),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _firstRoll
              ? (isAr ? 'الرمية الأولى' : 'First roll')
              : (isAr
                    ? 'الرمية الثانية (${localizeDigits(10 - _firstRollPins, arabic: true)} متبقية)'
                    : 'Second roll (${localizeDigits(10 - _firstRollPins, arabic: false)} pins left)'),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _roll,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            isAr ? 'ارم!' : 'Roll!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        if (_msg != null) ...[
          const SizedBox(height: 12),
          Text(
            _msg!,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIdle(bool isAr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _frame == 0
              ? (isAr ? '🎳 جاهز؟' : '🎳 Ready?')
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

class _LanePainter extends CustomPainter {
  _LanePainter(this.aim, this.firstRoll, this.firstRollPins);
  final double aim;
  final bool firstRoll;
  final int firstRollPins;

  @override
  void paint(Canvas canvas, Size size) {
    final lane = Paint()..color = const Color(0xFFD7AB7A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 0, size.width - 40, size.height),
        const Radius.circular(12),
      ),
      lane,
    );

    // Pins (10-pin triangle at top)
    final pinsRemaining = firstRoll ? 10 : (10 - firstRollPins);
    final pinPaint = Paint()..color = Colors.white;
    final pinPositions = <Offset>[
      // Row 1 (back): 4 pins
      Offset(size.width / 2 - 36, 20),
      Offset(size.width / 2 - 12, 20),
      Offset(size.width / 2 + 12, 20),
      Offset(size.width / 2 + 36, 20),
      // Row 2: 3 pins
      Offset(size.width / 2 - 24, 40),
      Offset(size.width / 2, 40),
      Offset(size.width / 2 + 24, 40),
      // Row 3: 2 pins
      Offset(size.width / 2 - 12, 60),
      Offset(size.width / 2 + 12, 60),
      // Row 4 (front): 1 pin
      Offset(size.width / 2, 80),
    ];
    for (var i = 0; i < pinsRemaining; i++) {
      canvas.drawCircle(pinPositions[i], 6, pinPaint);
    }

    // Aim arrow at bottom
    final arrowX = size.width / 2 + aim * (size.width / 2 - 30);
    final arrow = Paint()..color = AppColors.error;
    final path = Path()
      ..moveTo(arrowX, size.height - 30)
      ..lineTo(arrowX - 10, size.height - 10)
      ..lineTo(arrowX + 10, size.height - 10)
      ..close();
    canvas.drawPath(path, arrow);

    // Center guide line
    final guide = Paint()
      ..color = Colors.white.withAlpha(80)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 100),
      Offset(size.width / 2, size.height - 30),
      guide,
    );
  }

  @override
  bool shouldRepaint(_LanePainter old) =>
      old.aim != aim ||
      old.firstRoll != firstRoll ||
      old.firstRollPins != firstRollPins;
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
