import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/iq/data/iq_repository.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_champion_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

const int _kChampionCoinReward = 50;
const int _kChampionPerfectBonus = 50;

class BrainBoostChampionScreen extends ConsumerStatefulWidget {
  const BrainBoostChampionScreen({super.key});

  @override
  ConsumerState<BrainBoostChampionScreen> createState() =>
      _BrainBoostChampionScreenState();
}

class _BrainBoostChampionScreenState
    extends ConsumerState<BrainBoostChampionScreen> {
  int _idx = 0;
  int _correct = 0;
  String? _picked;
  late List<IqEntry> _items;
  bool _bound = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final itemsAsync = ref.watch(brainBoostChampionItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  isArabic
                      ? 'تعذّر تحميل وضع البطل.'
                      : "Couldn't load Champion mode.",
                ),
              ),
              data: (items) {
                if (!_bound) {
                  _items = items;
                  _bound = true;
                }
                if (_items.isEmpty) {
                  return Center(
                    child: Text(
                      isArabic
                          ? 'لا توجد أسئلة كافية.'
                          : 'Not enough questions yet.',
                    ),
                  );
                }
                if (_idx >= _items.length) {
                  return _ChampionDoneView(
                    correct: _correct,
                    total: _items.length,
                    arabic: isArabic,
                    onBack: () => context.go(AppRoutes.iq),
                  );
                }
                return _ChampionPlayingView(
                  item: _items[_idx],
                  index: _idx,
                  total: _items.length,
                  picked: _picked,
                  arabic: isArabic,
                  onPick: _onPick,
                  onNext: _onNext,
                  onBack: () => context.go(AppRoutes.iq),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onPick(String picked) {
    if (_picked != null) return;
    final cur = _items[_idx];
    final isCorrect =
        picked == cur.correctAnswer || picked == cur.correctAnswerAr;
    HapticFeedback.lightImpact();
    final audio = ref.read(audioServiceProvider);
    if (isCorrect) {
      audio.playCorrectSound();
    } else {
      audio.playWrongSound();
    }
    setState(() {
      _picked = picked;
      if (isCorrect) _correct++;
    });
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'iq',
        timestamp: DateTime.now(),
        questionId: cur.id,
        category: cur.category,
        correct: isCorrect,
        latencyMs: 0,
      ),
    );
  }

  Future<void> _onNext() async {
    final wasLast = _idx + 1 >= _items.length;
    setState(() {
      _idx++;
      _picked = null;
    });
    if (wasLast) {
      final perfect = _correct == _items.length;
      final reward =
          _kChampionCoinReward + (perfect ? _kChampionPerfectBonus : 0);
      await ref.read(coinProvider.notifier).award(reward);
      await ref
          .read(achievementProvider.notifier)
          .recordBrainBoostChampion(perfect: perfect);
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'iq',
          timestamp: DateTime.now(),
          score: _correct,
        ),
      );
    }
  }
}

class _ChampionPlayingView extends StatelessWidget {
  const _ChampionPlayingView({
    required this.item,
    required this.index,
    required this.total,
    required this.picked,
    required this.arabic,
    required this.onPick,
    required this.onNext,
    required this.onBack,
  });

  final IqEntry item;
  final int index;
  final int total;
  final String? picked;
  final bool arabic;
  final ValueChanged<String> onPick;
  final VoidCallback onNext;
  final VoidCallback onBack;

  String _diffLabel(int d) {
    switch (d) {
      case 1:
        return arabic ? 'سهل' : 'Easy';
      case 2:
        return arabic ? 'متوسط' : 'Medium';
      default:
        return arabic ? 'صعب' : 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = arabic ? item.questionAr : item.question;
    final options = arabic ? item.optionsAr : item.options;
    final correct = arabic ? item.correctAnswerAr : item.correctAnswer;
    final cat = arabic ? item.categoryAr : item.category;
    final fact = arabic ? (item.funFactAr ?? '') : (item.funFact ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: context.l10n.commonBack,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                arabic ? 'وضع البطل' : 'Champion Mode',
                style: AppTextStyles.headingMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${localizeDigitsCtx(index + 1, context)} / ${localizeDigitsCtx(total, context)}',
                style: AppTextStyles.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (index + (picked == null ? 0 : 1)) / total,
            minHeight: 6,
            backgroundColor: AppColors.surfaceContainer,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(40),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                cat,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                _diffLabel(item.difficulty),
                style: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question,
          style: AppTextStyles.headingSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _OptTile(
              label: opt,
              picked: picked,
              correct: correct,
              onTap: picked == null ? () => onPick(opt) : null,
            ),
          ),
        const SizedBox(height: 14),
        if (picked != null) ...[
          if (fact.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('💡 $fact', style: AppTextStyles.bodyMedium),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                index + 1 >= total
                    ? (arabic ? 'إنهاء' : 'Finish')
                    : (arabic ? 'التالي' : 'Next'),
                style: AppTextStyles.labelLarge,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptTile extends StatelessWidget {
  const _OptTile({
    required this.label,
    required this.picked,
    required this.correct,
    required this.onTap,
  });
  final String label;
  final String? picked;
  final String correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceContainerLow;
    Color border = AppColors.glassBorder;
    if (picked != null) {
      if (label == correct) {
        bg = AppColors.success.withAlpha(60);
        border = AppColors.success;
      } else if (label == picked) {
        bg = AppColors.error.withAlpha(60);
        border = AppColors.error;
      }
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Text(label, style: AppTextStyles.bodyLarge),
      ),
    );
  }
}

class _ChampionDoneView extends StatelessWidget {
  const _ChampionDoneView({
    required this.correct,
    required this.total,
    required this.arabic,
    required this.onBack,
  });
  final int correct;
  final int total;
  final bool arabic;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final perfect = correct == total;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              perfect ? '🏆' : '👑',
              style: const TextStyle(fontSize: 64),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              perfect
                  ? (arabic ? 'بطل بدرجة ممتاز!' : 'Perfect Champion!')
                  : (arabic ? 'أكملت وضع البطل!' : 'Champion Mode complete!'),
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${localizeDigitsCtx(correct, context)} / ${localizeDigitsCtx(total, context)}',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        '+${localizeDigitsCtx(_kChampionCoinReward + (perfect ? _kChampionPerfectBonus : 0), context)}',
                        style: AppTextStyles.headingSmall,
                      ),
                    ],
                  ),
                  if (perfect) ...[
                    const SizedBox(height: 6),
                    Text(
                      arabic
                          ? 'مكافأة الكمال إضافية!'
                          : 'Perfect-run bonus included!',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.home_rounded),
              label: Text(
                arabic ? 'العودة' : 'Back',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
