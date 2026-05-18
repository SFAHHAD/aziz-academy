import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/utils/haptics.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/flags/providers/flags_quiz_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Boss Rush — 12 questions chained across 3 modules (4 each: capitals,
/// flags, sciences). Sectional headers between modules. No timer; perfect
/// run awards bonus coins.
class BossRushScreen extends ConsumerStatefulWidget {
  const BossRushScreen({super.key});

  @override
  ConsumerState<BossRushScreen> createState() => _BossRushScreenState();
}

class _BossRushScreenState extends ConsumerState<BossRushScreen> {
  static const _perModule = 4;

  List<_BossItem> _items = const [];
  int _idx = 0;
  int _correct = 0;
  bool _loading = true;
  bool _answered = false;
  String? _picked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final repos = await Future.wait([
      ref.read(capitalsRepositoryProvider).loadQuestions(arabic: isArabic),
      ref.read(flagsRepositoryProvider).loadQuestions(arabic: isArabic),
      ref.read(sciencesRepositoryProvider).loadQuestions(arabic: isArabic),
    ]);
    final modules = <(String, List<QuizQuestion>)>[
      (isArabic ? 'العواصم' : 'Capitals', repos[0]),
      (isArabic ? 'الأعلام' : 'Flags', repos[1]),
      (isArabic ? 'العلوم' : 'Sciences', repos[2]),
    ];
    final picks = <_BossItem>[];
    for (final (label, qs) in modules) {
      qs.shuffle();
      for (final q in qs.take(_perModule)) {
        picks.add(_BossItem(module: label, q: q));
      }
    }
    if (mounted) {
      setState(() {
        _items = picks;
        _loading = false;
      });
    }
  }

  void _answer(String pick) {
    if (_answered) return;
    final correct = pick == _items[_idx].q.correctAnswer;
    if (correct) {
      Haptics.light();
    } else {
      Haptics.medium();
    }
    setState(() {
      _picked = pick;
      _answered = true;
      if (correct) _correct++;
    });
  }

  Future<void> _next() async {
    if (_idx + 1 >= _items.length) {
      // Award coins on completion: +5 base, +25 perfect bonus
      final perfect = _correct == _items.length;
      final base = 5 + (perfect ? 25 : 0);
      await ref.read(coinProvider.notifier).award(base);
      await ref
          .read(achievementProvider.notifier)
          .recordBossRush(perfect: perfect);
      if (mounted) _showSummary();
    } else {
      setState(() {
        _idx++;
        _answered = false;
        _picked = null;
      });
    }
  }

  void _showSummary() {
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final perfect = _correct == _items.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          perfect
              ? (isArabic ? '🏆 أداء كامل!' : '🏆 Perfect Boss Rush!')
              : (isArabic ? 'انتهى التحدي' : 'Rush complete'),
        ),
        content: Text(
          isArabic
              ? 'حصلت على $_correct من ${_items.length}.'
              : 'You scored $_correct of ${_items.length}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: Text(isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final cur = _items[_idx];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.commonBack,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    const Text('🐉', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'سباق الزعماء' : 'Boss Rush',
                        style: AppTextStyles.headingMedium,
                      ),
                    ),
                    Text(
                      '${_idx + 1}/${_items.length}',
                      style: AppTextStyles.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_idx + 1) / _items.length,
                  backgroundColor: AppColors.surfaceContainerLow,
                  color: AppColors.secondary,
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(40),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    cur.module,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    cur.q.question,
                    style: AppTextStyles.headingSmall,
                  ),
                ),
                const SizedBox(height: 12),
                for (final opt in cur.q.options)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ElevatedButton(
                      onPressed: _answered ? null : () => _answer(opt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _answered
                            ? (opt == cur.q.correctAnswer
                                  ? AppColors.success
                                  : (opt == _picked
                                        ? AppColors.error
                                        : AppColors.surfaceContainerLow))
                            : AppColors.surfaceContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(opt, style: AppTextStyles.labelLarge),
                      ),
                    ),
                  ),
                if (_answered) ...[
                  const SizedBox(height: 12),
                  if (cur.q.funFact.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '💡 ${cur.q.funFact}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      _idx + 1 == _items.length
                          ? Icons.flag_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _idx + 1 == _items.length
                          ? (isArabic ? 'إنهاء' : 'Finish')
                          : (isArabic ? 'التالي' : 'Next'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BossItem {
  const _BossItem({required this.module, required this.q});
  final String module;
  final QuizQuestion q;
}
