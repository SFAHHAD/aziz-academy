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

/// Tower of Hanoi — move all disks from peg A to peg C. Larger disks
/// can never sit on smaller ones. Optimal moves = ٢^n - ١.
/// Reward by disk count: 3 disks → +٢🪙, 4 → +٥🪙, 5 → +١٠🪙 (first solve).
class HanoiScreen extends ConsumerStatefulWidget {
  const HanoiScreen({super.key});

  @override
  ConsumerState<HanoiScreen> createState() => _HanoiScreenState();
}

class _HanoiScreenState extends ConsumerState<HanoiScreen> {
  int _n = 3;
  late List<List<int>> _pegs;
  int _moves = 0;
  int? _selected;
  bool _solved3 = false, _solved4 = false, _solved5 = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _pegs = [List<int>.generate(_n, (i) => _n - i), <int>[], <int>[]];
      _moves = 0;
      _selected = null;
    });
  }

  bool get _isWon => _pegs[2].length == _n;

  int _optimal(int n) => (1 << n) - 1;

  void _onPegTap(int idx) {
    if (_isWon) return;
    HapticFeedback.selectionClick();
    if (_selected == null) {
      if (_pegs[idx].isEmpty) return;
      setState(() => _selected = idx);
      return;
    }
    if (_selected == idx) {
      setState(() => _selected = null);
      return;
    }
    final from = _pegs[_selected!];
    final to = _pegs[idx];
    final disk = from.last;
    if (to.isNotEmpty && to.last < disk) {
      HapticFeedback.heavyImpact();
      setState(() => _selected = null);
      return;
    }
    setState(() {
      from.removeLast();
      to.add(disk);
      _moves += 1;
      _selected = null;
    });
    if (_isWon) {
      _award();
    }
  }

  void _award() {
    HapticFeedback.mediumImpact();
    if (_n == 3 && !_solved3) {
      _solved3 = true;
      ref.read(coinProvider.notifier).award(2);
    } else if (_n == 4 && !_solved4) {
      _solved4 = true;
      ref.read(coinProvider.notifier).award(5);
    } else if (_n == 5 && !_solved5) {
      _solved5 = true;
      ref.read(coinProvider.notifier).award(10);
    }
  }

  Widget _buildPeg(int idx, double maxWidth) {
    final disks = _pegs[idx];
    final isSel = _selected == idx;
    return GestureDetector(
      onTap: () => _onPegTap(idx),
      child: Container(
        decoration: BoxDecoration(
          color: isSel
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.outline,
            width: isSel ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final d in disks.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Container(
                  height: 18,
                  width: maxWidth * (0.4 + 0.5 * d / _n),
                  decoration: BoxDecoration(
                    color: _diskColor(d),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$d',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Container(height: 6, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  Color _diskColor(int d) {
    const palette = [
      Color(0xFFE53935),
      Color(0xFFFB8C00),
      Color(0xFFFDD835),
      Color(0xFF43A047),
      Color(0xFF1E88E5),
      Color(0xFF8E24AA),
      Color(0xFF00897B),
    ];
    return palette[(d - 1) % palette.length];
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
          isAr ? 'برج هانوي' : 'Tower of Hanoi',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: isAr ? 'إعادة' : 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                isAr
                    ? 'انقل كل الأقراص إلى العمود الأيسر. لا يمكن أن يجلس قرص أكبر فوق قرص أصغر.'
                    : 'Move all disks to the rightmost peg. A larger disk can never sit on a smaller one.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(
                    label: isAr ? 'الحركات' : 'Moves',
                    value: localizeDigits(_moves, arabic: isAr),
                  ),
                  _StatPill(
                    label: isAr ? 'الأمثل' : 'Optimal',
                    value: localizeDigits(_optimal(_n), arabic: isAr),
                  ),
                  _StatPill(
                    label: isAr ? 'الأقراص' : 'Disks',
                    value: localizeDigits(_n, arabic: isAr),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final pegW = (c.maxWidth - 24) / 3;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildPeg(0, pegW)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPeg(1, pegW)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPeg(2, pegW)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final n in [3, 4, 5, 6])
                    ChoiceChip(
                      label: Text(localizeDigits(n, arabic: isAr)),
                      selected: _n == n,
                      onSelected: (_) {
                        setState(() => _n = n);
                        _reset();
                      },
                    ),
                ],
              ),
              if (_isWon) ...[
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'ممتاز! حُلّت في ${localizeDigits(_moves, arabic: true)} حركة'
                      : 'Solved in $_moves moves!',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
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
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}
