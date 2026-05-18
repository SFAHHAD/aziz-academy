import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// Learning Zone (Research.txt) — kid reads a short passage, then answers
/// comprehension questions. Loaded from assets/data/learning_zone.json.
class LearningZoneScreen extends ConsumerStatefulWidget {
  const LearningZoneScreen({super.key});

  @override
  ConsumerState<LearningZoneScreen> createState() => _LearningZoneScreenState();
}

class _LearningZoneScreenState extends ConsumerState<LearningZoneScreen> {
  List<_LZ> _list = const [];
  int _idx = 0;
  bool _readingDone = false;
  int _qIdx = 0;
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
    final base = await _loadPack('assets/data/learning_zone.json');
    final extra = await _loadPack('assets/data/learning_zone_extra.json');
    final extra2 = await _loadPack('assets/data/learning_zone_extra2.json');
    final extra3 = await _loadPack('assets/data/learning_zone_extra3.json');
    final seen = <String>{};
    final merged = <_LZ>[];
    for (final item in [...base, ...extra, ...extra2, ...extra3]) {
      if (seen.add(item.id)) merged.add(item);
    }
    setState(() {
      _list = merged;
      _loading = false;
    });
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'learning_zone',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<List<_LZ>> _loadPack(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final str = utf8.decode(byteData.buffer.asUint8List());
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => _LZ.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const <_LZ>[];
    }
  }

  void _answer(String opt) {
    if (_selected != null) return;
    final cur = _list[_idx];
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final correctAnswer = isArabic
        ? cur.questions[_qIdx].correctAr
        : cur.questions[_qIdx].correct;
    final correct = opt == correctAnswer;
    if (correct) _score += 1;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'learning_zone',
        timestamp: DateTime.now(),
        questionId: '${cur.id}_$_qIdx',
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
    _next = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final qLen = cur.questions.length;
      setState(() {
        _selected = null;
        if (_qIdx + 1 < qLen) {
          _qIdx += 1;
        } else if (_idx + 1 < _list.length) {
          _idx += 1;
          _qIdx = 0;
          _readingDone = false;
        } else {
          // All passages done.
          EventBus.instance.emit(
            LearningEvent(
              type: LearningEventType.sessionEnded,
              module: 'learning_zone',
              timestamp: DateTime.now(),
              score: _score,
            ),
          );
          ref.read(coinProvider.notifier).award(_score * 3);
          _idx = _list.length;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    if (_idx >= _list.length) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📖', style: TextStyle(fontSize: 96)),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'انتهيت من القراءة!' : 'Reading complete!',
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${localizeDigitsCtx(_score, context)} ${isArabic ? 'إجابات صحيحة' : 'correct answers'}',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 24),
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
    final cur = _list[_idx];
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
                        '${localizeDigitsCtx(_idx + 1, context)} / ${localizeDigitsCtx(_list.length, context)}',
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_readingDone)
                  _ReadingView(
                    title: isArabic ? cur.titleAr : cur.titleEn,
                    passage: isArabic ? cur.passageAr : cur.passageEn,
                    onContinue: () => setState(() => _readingDone = true),
                    onRead: () {
                      final txt = isArabic ? cur.passageAr : cur.passageEn;
                      ref.read(ttsServiceProvider).speakLocale(txt, txt);
                    },
                    isArabic: isArabic,
                  )
                else
                  Expanded(
                    child: _QuestionView(
                      question: isArabic
                          ? cur.questions[_qIdx].qAr
                          : cur.questions[_qIdx].qEn,
                      options: isArabic
                          ? cur.questions[_qIdx].optionsAr
                          : cur.questions[_qIdx].optionsEn,
                      correct: isArabic
                          ? cur.questions[_qIdx].correctAr
                          : cur.questions[_qIdx].correct,
                      selected: _selected,
                      onAnswer: _answer,
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

class _ReadingView extends StatelessWidget {
  const _ReadingView({
    required this.title,
    required this.passage,
    required this.onContinue,
    required this.onRead,
    required this.isArabic,
  });

  final String title;
  final String passage;
  final VoidCallback onContinue;
  final VoidCallback onRead;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.displayMedium),
            const SizedBox(height: 12),
            Text(
              passage,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.6,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Read-aloud button hides when AI voices are off
                // (real-audio-only policy from v1.1.96).
                Consumer(builder: (ctx, r, _) {
                  final ttsOn =
                      r.watch(appSettingsProvider).value?.ttsEnabled ?? false;
                  if (!ttsOn) return const SizedBox.shrink();
                  return ElevatedButton.icon(
                    onPressed: onRead,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(isArabic ? 'استمع' : 'Read aloud'),
                  );
                }),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(isArabic ? 'الأسئلة' : 'Questions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.question,
    required this.options,
    required this.correct,
    required this.selected,
    required this.onAnswer,
  });

  final String question;
  final List<String> options;
  final String correct;
  final String? selected;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question, style: AppTextStyles.headingMedium),
            const SizedBox(height: 20),
            ...options.map((opt) {
              Color? bg;
              if (selected != null) {
                if (opt == correct) {
                  bg = const Color(0xFF6BBF59);
                } else if (opt == selected) {
                  bg = AppColors.error;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bg ?? AppColors.surfaceContainerHigh,
                      foregroundColor: bg == null
                          ? AppColors.textDark
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: selected == null ? () => onAnswer(opt) : null,
                    child: Text(opt, style: AppTextStyles.bodyLarge),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LZ {
  const _LZ({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.passageEn,
    required this.passageAr,
    required this.category,
    required this.questions,
  });
  final String id;
  final String titleEn;
  final String titleAr;
  final String passageEn;
  final String passageAr;
  final String category;
  final List<_LZQ> questions;

  static _LZ fromJson(Map<String, dynamic> m) {
    return _LZ(
      id: m['id'] as String,
      titleEn: m['title'] as String,
      titleAr: (m['title_ar'] as String?) ?? m['title'] as String,
      passageEn: m['passage'] as String,
      passageAr: (m['passage_ar'] as String?) ?? m['passage'] as String,
      category: m['category'] as String? ?? 'Sciences',
      questions: ((m['questions'] as List?) ?? const [])
          .map((e) => _LZQ.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _LZQ {
  const _LZQ({
    required this.qEn,
    required this.qAr,
    required this.optionsEn,
    required this.optionsAr,
    required this.correct,
    required this.correctAr,
  });
  final String qEn;
  final String qAr;
  final List<String> optionsEn;
  final List<String> optionsAr;
  final String correct;
  final String correctAr;

  static _LZQ fromJson(Map<String, dynamic> m) {
    return _LZQ(
      qEn: m['q'] as String,
      qAr: (m['q_ar'] as String?) ?? m['q'] as String,
      optionsEn: List<String>.from(m['options'] as List),
      optionsAr: m['options_ar'] != null
          ? List<String>.from(m['options_ar'] as List)
          : List<String>.from(m['options'] as List),
      correct: m['correct'] as String,
      correctAr: (m['correct_ar'] as String?) ?? m['correct'] as String,
    );
  }
}
