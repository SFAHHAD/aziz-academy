import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/favorites_provider.dart';
import 'package:aziz_academy/core/providers/general_quiz_pool_provider.dart';
import 'package:aziz_academy/core/providers/iq_pool_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/sciences_pool_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// Random Quiz mode — random pick from across all modules. Different from
/// Survival in that it has lives + a fixed length, and from Self-Challenge in
/// that the kid doesn't pick anything.
class RandomQuizScreen extends ConsumerStatefulWidget {
  const RandomQuizScreen({super.key});

  @override
  ConsumerState<RandomQuizScreen> createState() => _RandomQuizScreenState();
}

class _RandomQuizScreenState extends ConsumerState<RandomQuizScreen> {
  static const int _kTotal = 10;
  List<QuizQuestion> _items = const [];
  int _idx = 0;
  int _score = 0;
  bool _loading = true;
  String? _selected;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _next?.cancel();
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
    try {
      final iq = await ref.read(iqPoolProvider.future);
      pool.addAll(iq.map((e) => e.toQuizQuestion(arabic: isArabic)));
    } catch (_) {}
    pool.shuffle(math.Random());
    final picked = pool.take(_kTotal).toList();
    if (mounted) {
      setState(() {
        _items = picked;
        _loading = false;
      });
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionStarted,
          module: 'random',
          timestamp: DateTime.now(),
        ),
      );
      _maybeReadAloud();
    }
  }

  void _maybeReadAloud() {
    final audioOn = ref.read(appSettingsProvider).value?.audioQuiz ?? false;
    if (audioOn && _idx < _items.length) {
      final txt = _items[_idx].question;
      ref.read(ttsServiceProvider).speakLocale(txt, txt);
    }
  }

  void _answer(String opt) {
    if (_selected != null) return;
    final cur = _items[_idx];
    final correct = opt.trim() == cur.correctAnswer.trim();
    if (correct) _score += 1;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'random',
        timestamp: DateTime.now(),
        questionId: cur.id,
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
    setState(() => _selected = opt);
    _next?.cancel();
    _next = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        _idx += 1;
        _selected = null;
      });
      if (_idx >= _items.length) {
        EventBus.instance.emit(
          LearningEvent(
            type: LearningEventType.sessionEnded,
            module: 'random',
            timestamp: DateTime.now(),
            score: _score,
          ),
        );
        ref.read(coinProvider.notifier).award(_score * 2);
      } else {
        _maybeReadAloud();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
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
                  const Text('🎲', style: TextStyle(fontSize: 96)),
                  const SizedBox(height: 16),
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
                    icon: const Icon(Icons.shuffle_rounded),
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
    final q = _items[_idx];
    final favs = ref.watch(favoritesProvider).value ?? const <String>{};
    final isFav = favs.contains(q.id);
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
                    IconButton(
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(q.id),
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.error : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          q.category,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(q.question, style: AppTextStyles.headingMedium),
                        const SizedBox(height: 24),
                        ...q.options.map((opt) {
                          Color? bg;
                          if (_selected != null) {
                            if (opt == q.correctAnswer) {
                              bg = const Color(0xFF6BBF59);
                            } else if (opt == _selected) {
                              bg = AppColors.error;
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      bg ?? AppColors.surfaceContainerHigh,
                                  foregroundColor: bg == null
                                      ? AppColors.textDark
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  alignment: AlignmentDirectional.centerStart,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _selected == null
                                    ? () => _answer(opt)
                                    : null,
                                child: Text(
                                  opt,
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
