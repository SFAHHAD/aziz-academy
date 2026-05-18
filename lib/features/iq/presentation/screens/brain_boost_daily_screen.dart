import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/cosmetics_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/iq/data/iq_repository.dart';
import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

const int _kDailyCoinReward = 15;

class BrainBoostDailyScreen extends ConsumerStatefulWidget {
  const BrainBoostDailyScreen({super.key});

  @override
  ConsumerState<BrainBoostDailyScreen> createState() =>
      _BrainBoostDailyScreenState();
}

class _BrainBoostDailyScreenState extends ConsumerState<BrainBoostDailyScreen> {
  int _idx = 0;
  int _correct = 0;
  String? _picked;
  bool get _answered => _picked != null;
  late List<IqEntry> _items;
  bool _itemsBound = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final dailyAsync = ref.watch(brainBoostDailyProvider);
    final itemsAsync = ref.watch(brainBoostDailyItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  isArabic
                      ? 'تعذّر تحميل تحدي اليوم.'
                      : "Couldn't load today's challenge.",
                ),
              ),
              data: (items) {
                if (!_itemsBound) {
                  _items = items;
                  _itemsBound = true;
                }
                if (_items.isEmpty) {
                  return Center(
                    child: Text(
                      isArabic
                          ? 'لا توجد أسئلة متاحة بعد.'
                          : 'No questions available yet.',
                    ),
                  );
                }
                final completed = _idx >= _items.length;
                if (completed) {
                  return _DoneView(
                    correct: _correct,
                    total: _items.length,
                    streak: dailyAsync.value?.streak ?? 0,
                    arabic: isArabic,
                    onBack: () => context.go(AppRoutes.iq),
                    onPlayMore: () => context.go(AppRoutes.iq),
                  );
                }
                return _PlayingView(
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
    if (_answered) return;
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
      // Award streak + coins. Avoid double-award via markCompleted's same-day
      // guard. If a streak milestone was reached, grant the matching cosmetic
      // and surface a celebration dialog.
      final daily = ref.read(brainBoostDailyProvider).value;
      if (daily != null && !daily.todayCompleted) {
        final milestoneCosmeticId = await ref
            .read(brainBoostDailyProvider.notifier)
            .markCompleted();
        await ref.read(coinProvider.notifier).award(_kDailyCoinReward);
        final newStreak = ref.read(brainBoostDailyProvider).value?.streak ?? 0;
        await ref
            .read(achievementProvider.notifier)
            .recordBrainBoostDaily(streak: newStreak);
        if (milestoneCosmeticId != null) {
          await ref.read(cosmeticsProvider.notifier).grant(milestoneCosmeticId);
          if (mounted) {
            await _showMilestoneCelebration(milestoneCosmeticId);
          }
        }
      }
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

  Future<void> _showMilestoneCelebration(String cosmeticId) async {
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final newStreak = ref.read(brainBoostDailyProvider).value?.streak ?? 0;
    final emoji = _emojiForCosmetic(cosmeticId);
    final cosmeticLabel = _labelForCosmetic(cosmeticId, isArabic);
    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔥',
                style: const TextStyle(fontSize: 56),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'سلسلة $newStreak أيام!' : '$newStreak-day streak!',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withAlpha(80),
                      AppColors.primary.withAlpha(60),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      isArabic ? 'مفاجأة جديدة!' : 'New unlock!',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    Text(cosmeticLabel, style: AppTextStyles.headingSmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    isArabic ? 'رائع!' : 'Awesome!',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _emojiForCosmetic(String id) {
    const map = {
      'frame_blue': '🟦',
      'frame_gold': '🟡',
      'frame_purple': '🟪',
      'frame_rainbow': '🌈',
      'av_dragon': '🐲',
      'av_unicorn': '🦄',
      'av_wizard': '🧙',
    };
    return map[id] ?? '✨';
  }

  static String _labelForCosmetic(String id, bool arabic) {
    const en = {
      'frame_blue': 'Blue Frame',
      'frame_gold': 'Gold Frame',
      'frame_purple': 'Purple Frame',
      'frame_rainbow': 'Rainbow Frame',
      'av_dragon': 'Dragon Avatar',
      'av_unicorn': 'Unicorn Avatar',
      'av_wizard': 'Wizard Avatar',
    };
    const ar = {
      'frame_blue': 'الإطار الأزرق',
      'frame_gold': 'الإطار الذهبي',
      'frame_purple': 'الإطار البنفسجي',
      'frame_rainbow': 'إطار قوس قزح',
      'av_dragon': 'أفاتار التنين',
      'av_unicorn': 'أفاتار وحيد القرن',
      'av_wizard': 'أفاتار الساحر',
    };
    return arabic ? (ar[id] ?? id) : (en[id] ?? id);
  }
}

class _PlayingView extends StatelessWidget {
  const _PlayingView({
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
            Text('⭐', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                arabic ? 'تحدي اليوم' : "Today's Challenge",
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
            textAlign: TextAlign.center,
          ),
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
            child: _OptionTile(
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.correct,
    required this.total,
    required this.streak,
    required this.arabic,
    required this.onBack,
    required this.onPlayMore,
  });
  final int correct;
  final int total;
  final int streak;
  final bool arabic;
  final VoidCallback onBack;
  final VoidCallback onPlayMore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text(
              '🎉',
              style: TextStyle(fontSize: 64),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              arabic ? 'أنهيت تحدي اليوم!' : "Today's challenge complete!",
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
                    arabic ? 'النتيجة' : 'Score',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  Text(
                    '${localizeDigitsCtx(correct, context)} / ${localizeDigitsCtx(total, context)}',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    arabic ? 'سلسلة الأيام 🔥' : 'Streak 🔥',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  Text(
                    arabic
                        ? '${localizeDigitsCtx(streak, context)} ${streak == 1 ? "يوم" : "أيام"}'
                        : '$streak ${streak == 1 ? "day" : "days"}',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '+${localizeDigitsCtx(_kDailyCoinReward, context)}',
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onPlayMore,
              icon: const Icon(Icons.psychology_rounded),
              label: Text(
                arabic ? 'تدرّب أكثر' : 'Train more',
                style: AppTextStyles.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: Text(
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
