import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
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
import 'package:aziz_academy/features/spelling/data/spelling_repository.dart';

/// Word / Letter quiz (Research.txt). Mines short single-word answers from
/// existing pools and asks the kid to spell them via tappable letter tiles.
class SpellingScreen extends ConsumerStatefulWidget {
  const SpellingScreen({super.key});

  @override
  ConsumerState<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends ConsumerState<SpellingScreen> {
  static const int _kTotal = 8;
  List<_SpellWord> _items = const [];
  int _idx = 0;
  int _score = 0;
  bool _loading = true;
  List<String> _slots = const [];
  List<String?> _placed = const [];
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
    final words = <_SpellWord>[];
    // Primary source: curated spelling word pack (assets/data/spelling*.json).
    // Curated entries skip _isGoodWord() because they are pre-validated.
    try {
      final pack = await const SpellingRepository().loadEntries();
      for (final e in pack) {
        final answer = e.answerFor(arabic: isArabic);
        if (answer.trim().isEmpty || answer.contains(' ')) continue;
        words.add(
          _SpellWord(
            id: e.id,
            prompt: e.promptFor(arabic: isArabic),
            answer: answer,
            category: e.categoryFor(arabic: isArabic),
          ),
        );
      }
    } catch (_) {}
    // Fallback / supplemental: mine words from sciences and general-quiz pools
    // (only when the curated pack is missing or sparse).
    if (words.length < _kTotal) {
      try {
        final s = await ref.read(sciencesPoolProvider.future);
        for (final e in s) {
          final answer = isArabic ? (e.correctAnswerAr ?? '') : e.correctAnswer;
          if (_isGoodWord(answer)) {
            final q = e.toQuizQuestion(arabic: isArabic);
            words.add(
              _SpellWord(
                id: e.id,
                prompt: q.question,
                answer: answer,
                category: e.category,
              ),
            );
          }
        }
      } catch (_) {}
      try {
        final g = await ref.read(generalQuizPoolProvider.future);
        for (final e in g) {
          final answer = isArabic ? e.correctAnswerAr : e.correctAnswer;
          if (_isGoodWord(answer)) {
            final q = e.toQuizQuestion(arabic: isArabic);
            words.add(
              _SpellWord(
                id: e.id,
                prompt: q.question,
                answer: answer,
                category: e.category,
              ),
            );
          }
        }
      } catch (_) {}
    }
    words.shuffle(math.Random());
    final picked = words.take(_kTotal).toList();
    if (mounted) {
      setState(() {
        _items = picked;
        _loading = false;
      });
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionStarted,
          module: 'spelling',
          timestamp: DateTime.now(),
        ),
      );
      _seed();
    }
  }

  bool _isGoodWord(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains(' ')) return false;
    return t.length >= 3 && t.length <= 10;
  }

  void _seed() {
    if (_idx >= _items.length) return;
    final answer = _items[_idx].answer;
    final letters = answer.split('');
    final pool = List<String>.from(letters);
    final r = math.Random();
    // Add 2-3 distractor letters in the alphabet of the answer.
    while (pool.length < math.min(letters.length + 3, 12)) {
      final c = String.fromCharCode(
        answer.codeUnitAt(r.nextInt(answer.length)),
      );
      pool.add(c);
    }
    pool.shuffle(r);
    setState(() {
      _slots = pool;
      _placed = List<String?>.filled(letters.length, null);
    });
  }

  void _place(int slotIdx, String letter) {
    setState(() {
      _placed = List<String?>.from(_placed);
      _placed[slotIdx] = letter;
    });
    if (_placed.every((c) => c != null)) _check();
  }

  void _erase(int i) {
    setState(() {
      _placed = List<String?>.from(_placed)..[i] = null;
    });
  }

  void _check() {
    if (_idx >= _items.length) return;
    final guess = _placed.join();
    final cur = _items[_idx];
    final correct = guess == cur.answer;
    if (correct) _score += 1;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'spelling',
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
    _next?.cancel();
    _next = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _idx += 1);
      if (_idx >= _items.length) {
        EventBus.instance.emit(
          LearningEvent(
            type: LearningEventType.sessionEnded,
            module: 'spelling',
            timestamp: DateTime.now(),
            score: _score,
          ),
        );
        ref.read(coinProvider.notifier).award(_score * 3);
      } else {
        _seed();
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
                  const Text('🅰️', style: TextStyle(fontSize: 96)),
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
                const SizedBox(height: 16),
                Text(
                  cur.category,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(cur.prompt, style: AppTextStyles.headingMedium),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(_placed.length, (i) {
                    final c = _placed[i];
                    return GestureDetector(
                      onTap: c == null ? null : () => _erase(i),
                      child: Container(
                        width: 44,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c == null
                              ? AppColors.surfaceContainerLow
                              : AppColors.secondary.withAlpha(80),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: c == null
                                ? AppColors.divider
                                : AppColors.secondary,
                          ),
                        ),
                        child: Text(
                          c ?? '_',
                          style: AppTextStyles.headingMedium,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  isArabic ? 'اضغط الأحرف:' : 'Tap the letters:',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _slots.map((letter) {
                    return GestureDetector(
                      onTap: () {
                        final firstEmpty = _placed.indexWhere((c) => c == null);
                        if (firstEmpty != -1) _place(firstEmpty, letter);
                      },
                      child: Container(
                        width: 40,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(letter, style: AppTextStyles.headingSmall),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpellWord {
  const _SpellWord({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.category,
  });
  final String id;
  final String prompt;
  final String answer;
  final String category;
}
