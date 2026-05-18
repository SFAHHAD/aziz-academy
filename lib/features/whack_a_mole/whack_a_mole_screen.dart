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

/// Whack-a-Mole — 3×3 grid. Moles pop up in random holes; tap before
/// they disappear. ٤٥ second round, increasing pace. Tap a bomb 💣 and
/// you lose 5 points. +٢🪙 finish, +٥🪙 score ≥ ٢٥.
class WhackAMoleScreen extends ConsumerStatefulWidget {
  const WhackAMoleScreen({super.key});

  @override
  ConsumerState<WhackAMoleScreen> createState() => _WhackAMoleScreenState();
}

enum _Cell { empty, mole, bomb }

class _WhackAMoleScreenState extends ConsumerState<WhackAMoleScreen> {
  static const int _n = 9;
  static const int _gameSeconds = 45;

  late List<_Cell> _cells;
  int _score = 0;
  int _msLeft = _gameSeconds * 1000;
  bool _running = false;
  bool _done = false;
  Timer? _spawn;
  Timer? _tick;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _cells = List.filled(_n, _Cell.empty);
  }

  @override
  void dispose() {
    _spawn?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _cells = List.filled(_n, _Cell.empty);
      _score = 0;
      _msLeft = _gameSeconds * 1000;
      _running = true;
      _done = false;
      _rewarded = false;
    });
    _scheduleSpawn();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _msLeft -= 100;
      if (_msLeft <= 0) {
        t.cancel();
        _spawn?.cancel();
        _running = false;
        _done = true;
        ref.read(coinProvider.notifier).award(2);
        if (_score >= 25 && !_rewarded) {
          ref.read(coinProvider.notifier).award(5);
          _rewarded = true;
        }
      }
      if (mounted) setState(() {});
    });
  }

  void _scheduleSpawn() {
    if (!_running) return;
    final pace = _msLeft > 30000 ? 800 : (_msLeft > 15000 ? 600 : 450);
    _spawn?.cancel();
    _spawn = Timer(Duration(milliseconds: pace), () {
      _spawnOne();
      _scheduleSpawn();
    });
  }

  void _spawnOne() {
    final rng = math.Random();
    final empties = <int>[];
    for (var i = 0; i < _n; i++) {
      if (_cells[i] == _Cell.empty) empties.add(i);
    }
    if (empties.isEmpty) return;
    final idx = empties[rng.nextInt(empties.length)];
    final isBomb = rng.nextDouble() < 0.15;
    setState(() {
      _cells[idx] = isBomb ? _Cell.bomb : _Cell.mole;
    });
    final life = isBomb ? 1500 : 1100;
    Timer(Duration(milliseconds: life), () {
      if (!mounted) return;
      if (_cells[idx] != _Cell.empty) {
        setState(() => _cells[idx] = _Cell.empty);
      }
    });
  }

  void _whack(int i) {
    if (!_running) return;
    HapticFeedback.lightImpact();
    final cell = _cells[i];
    if (cell == _Cell.mole) {
      _score += 1;
    } else if (cell == _Cell.bomb) {
      _score = math.max(0, _score - 5);
    }
    setState(() => _cells[i] = _Cell.empty);
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
          isAr ? 'اضرب الخلد' : 'Whack-a-Mole',
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
                    ? 'انقر الخلد 🦫 — لكن تجنّب القنبلة 💣!'
                    : 'Tap the mole 🦫 — but avoid the bomb 💣!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pill(
                    label: isAr ? 'النقاط' : 'Score',
                    value: localizeDigits(_score, arabic: isAr),
                  ),
                  _Pill(
                    label: isAr ? 'الزمن' : 'Time',
                    value: localizeDigits(
                      (_msLeft / 1000).ceil(),
                      arabic: isAr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, i) {
                    final c = _cells[i];
                    return GestureDetector(
                      onTap: () => _whack(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.textDark.withValues(alpha: 0.15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c == _Cell.mole
                              ? '🦫'
                              : c == _Cell.bomb
                              ? '💣'
                              : '',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (!_running && !_done)
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(isAr ? 'ابدأ' : 'Start'),
                ),
              if (_done) ...[
                Text(
                  isAr
                      ? 'انتهى! النقاط: ${localizeDigits(_score, arabic: true)}'
                      : 'Done! Score: $_score',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.replay),
                  label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label  $value', style: AppTextStyles.labelLarge),
    );
  }
}
