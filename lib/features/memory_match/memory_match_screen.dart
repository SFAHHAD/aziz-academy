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

/// Memory Match — flip pairs of emoji cards to find matches. 12 cards (6
/// pairs) on a 3×4 grid. Tracks moves; +١🪙 per match, +٥🪙 perfect run.
class MemoryMatchScreen extends ConsumerStatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  ConsumerState<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends ConsumerState<MemoryMatchScreen> {
  static const _allEmojis = [
    '🐶',
    '🐱',
    '🦁',
    '🐯',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐸',
    '🐵',
    '🦉',
    '🦒',
    '🐬',
    '🐳',
    '🦋',
    '🌳',
    '🌸',
    '🍎',
  ];

  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  int _firstIdx = -1;
  int _moves = 0;
  int _matches = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final rng = math.Random();
    final pool = List.of(_allEmojis)..shuffle(rng);
    final picks = pool.take(6).toList();
    final cards = [...picks, ...picks]..shuffle(rng);
    setState(() {
      _cards = cards;
      _flipped = List.filled(12, false);
      _matched = List.filled(12, false);
      _firstIdx = -1;
      _moves = 0;
      _matches = 0;
      _busy = false;
    });
  }

  void _tap(int i) {
    if (_busy) return;
    if (_flipped[i] || _matched[i]) return;

    setState(() => _flipped[i] = true);

    if (_firstIdx == -1) {
      _firstIdx = i;
      return;
    }
    setState(() => _moves += 1);
    if (_cards[_firstIdx] == _cards[i]) {
      setState(() {
        _matched[_firstIdx] = true;
        _matched[i] = true;
        _matches += 1;
        _firstIdx = -1;
      });
      ref.read(coinProvider.notifier).award(1);
      if (_matches == 6) {
        ref.read(coinProvider.notifier).award(5);
      }
    } else {
      _busy = true;
      Timer(const Duration(milliseconds: 700), () {
        setState(() {
          _flipped[_firstIdx] = false;
          _flipped[i] = false;
          _firstIdx = -1;
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final won = _matches == 6;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'مطابقة الذاكرة' : 'Memory Match'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isAr ? 'لعبة جديدة' : 'New game',
            onPressed: _newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAr
                            ? 'حركات: ${localizeDigits(_moves, arabic: true)}'
                            : 'Moves: $_moves',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      isAr
                          ? 'مطابقات: ${localizeDigits(_matches, arabic: true)}/${localizeDigits(6, arabic: true)}'
                          : 'Matches: $_matches/6',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (ctx, i) {
                    final shown = _flipped[i] || _matched[i];
                    return InkWell(
                      onTap: () => _tap(i),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _matched[i]
                              ? AppColors.success.withAlpha(60)
                              : shown
                              ? AppColors.accent.withAlpha(36)
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _matched[i]
                                ? AppColors.success
                                : shown
                                ? AppColors.accent
                                : AppColors.outline.withAlpha(80),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          shown ? _cards[i] : '?',
                          style: TextStyle(
                            fontSize: shown ? 36 : 24,
                            color: shown
                                ? AppColors.textDark
                                : AppColors.textDark.withAlpha(140),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (won) ...[
                const SizedBox(height: 12),
                Text(
                  isAr ? '🎉 وجدت كل المطابقات +٥🪙' : '🎉 All matched +5🪙',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(isAr ? 'لعبة جديدة' : 'Play again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
