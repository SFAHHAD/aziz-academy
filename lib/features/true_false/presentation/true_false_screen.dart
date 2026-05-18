import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/general_quiz_pool_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/sciences_pool_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// True/False mode (Research.txt). Pairs each question's correct answer with
/// a random distractor, with 50% chance the prompt actually presents the
/// correct one. Kid taps True / False.
class TrueFalseScreen extends ConsumerStatefulWidget {
  const TrueFalseScreen({super.key});

  @override
  ConsumerState<TrueFalseScreen> createState() => _TrueFalseScreenState();
}

class _TrueFalseScreenState extends ConsumerState<TrueFalseScreen> {
  static const int _kTotal = 10;
  List<_TFItem> _items = const [];
  int _idx = 0;
  int _score = 0;
  bool _loading = true;
  bool? _lastWasRight;
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final pool = <QuizQuestion>[];
    try {
      final s = await ref.read(sciencesPoolProvider.future);
      pool.addAll(s.map((e) => e.toQuizQuestion(arabic: isArabic)));
    } catch (_) {}
    try {
      final g = await ref.read(generalQuizPoolProvider.future);
      pool.addAll(g.map((e) => e.toQuizQuestion(arabic: isArabic)));
    } catch (_) {}
    final r = math.Random();
    pool.shuffle(r);
    final items = <_TFItem>[];
    for (final q in pool) {
      if (items.length >= _kTotal) break;
      if (q.options.length < 2) continue;
      final showCorrect = r.nextBool();
      final wrong = q.options.firstWhere(
        (o) => o.trim() != q.correctAnswer.trim(),
        orElse: () => q.options.first,
      );
      items.add(
        _TFItem(
          question: q.question,
          proposed: showCorrect ? q.correctAnswer : wrong,
          truth: showCorrect,
          questionId: q.id,
          category: q.category,
        ),
      );
    }
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionStarted,
          module: 'true_false',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _answer(bool tapped) {
    if (_idx >= _items.length) return;
    final cur = _items[_idx];
    final correct = tapped == cur.truth;
    if (correct) _score += 1;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'true_false',
        timestamp: DateTime.now(),
        questionId: cur.questionId,
        category: cur.category,
        correct: correct,
      ),
    );
    final audio = ref.read(audioServiceProvider);
    if (correct) {
      HapticFeedback.lightImpact();
      audio.playCorrectSound();
    } else {
      HapticFeedback.heavyImpact();
      audio.playWrongSound();
    }
    setState(() => _lastWasRight = correct);
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _idx += 1;
        _lastWasRight = null;
      });
      if (_idx >= _items.length) {
        EventBus.instance.emit(
          LearningEvent(
            type: LearningEventType.sessionEnded,
            module: 'true_false',
            timestamp: DateTime.now(),
            score: _score,
          ),
        );
        // Award 2 coins per correct.
        ref.read(coinProvider.notifier).award(_score * 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_idx >= _items.length) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 96)),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'انتهت الجولة!' : 'Round complete!',
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${localizeDigitsCtx(_score, context)} / ${localizeDigitsCtx(_items.length, context)}',
                    style: AppTextStyles.displayLargeGold,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _idx = 0;
                        _score = 0;
                        _loading = true;
                      });
                      _load();
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(isArabic ? 'العب مرة أخرى' : 'Play again'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(context.l10n.homeButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final cur = _items[_idx];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '${localizeDigitsCtx(_idx + 1, context)} / ${localizeDigitsCtx(_items.length, context)}',
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cur.question,
                          style: AppTextStyles.headingMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isArabic ? 'الإجابة:' : 'Answer:',
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cur.proposed,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BigButton(
                        label: isArabic ? 'صح ✓' : 'True ✓',
                        color: const Color(0xFF6BBF59),
                        onTap: _lastWasRight == null
                            ? () => _answer(true)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigButton(
                        label: isArabic ? 'خطأ ✗' : 'False ✗',
                        color: AppColors.error,
                        onTap: _lastWasRight == null
                            ? () => _answer(false)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TFItem {
  const _TFItem({
    required this.question,
    required this.proposed,
    required this.truth,
    required this.questionId,
    required this.category,
  });
  final String question;
  final String proposed;
  final bool truth;
  final String questionId;
  final String category;
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
