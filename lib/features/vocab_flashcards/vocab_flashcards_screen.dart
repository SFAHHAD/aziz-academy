import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Flashcard study mode for the vocabulary pack — one card at a time, tap
/// to flip from question → answer + fun fact, then "got it" / "review again".
/// Pure on-device, no scoring, no streaks, just self-paced practice.
class VocabFlashcardsScreen extends ConsumerStatefulWidget {
  const VocabFlashcardsScreen({super.key});

  @override
  ConsumerState<VocabFlashcardsScreen> createState() =>
      _VocabFlashcardsScreenState();
}

class _VocabFlashcardsScreenState extends ConsumerState<VocabFlashcardsScreen> {
  List<_Card> _all = const [];
  List<_Card> _queue = const [];
  bool _flipped = false;
  int _gotIt = 0;
  int _review = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.loadString('assets/data/vocabulary.json');
      final list = (json.decode(data) as List).cast<Map<String, dynamic>>();
      final cards = list.map(_Card.fromJson).toList()..shuffle(math.Random());
      setState(() {
        _all = cards;
        _queue = cards;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _next({required bool gotIt}) {
    setState(() {
      if (gotIt) {
        _gotIt += 1;
      } else {
        _review += 1;
        _queue = [..._queue.skip(1), _queue.first];
        _flipped = false;
        return;
      }
      _queue = _queue.skip(1).toList();
      _flipped = false;
    });
  }

  void _restart() {
    setState(() {
      _queue = List.of(_all)..shuffle(math.Random());
      _gotIt = 0;
      _review = 0;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'بطاقات المفردات' : 'Vocab Flashcards'),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
          ? _Done(
              gotIt: _gotIt,
              review: _review,
              total: _all.length,
              isAr: isAr,
              onRestart: _restart,
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _Progress(
                      done: _all.length - _queue.length + _review,
                      total: _all.length,
                      gotIt: _gotIt,
                      review: _review,
                      isAr: isAr,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _flipped = !_flipped),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _CardFace(
                            key: ValueKey('${_queue.first.id}-$_flipped'),
                            card: _queue.first,
                            flipped: _flipped,
                            isAr: isAr,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_flipped)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _next(gotIt: false),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(isAr ? 'راجع' : 'Review again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _next(gotIt: true),
                              icon: const Icon(Icons.check_rounded),
                              label: Text(isAr ? 'فهمتها' : 'Got it'),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          isAr
                              ? 'انقر البطاقة لرؤية الإجابة'
                              : 'Tap card to flip',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Card {
  const _Card({
    required this.id,
    required this.question,
    required this.questionAr,
    required this.answer,
    required this.answerAr,
    required this.category,
    required this.categoryAr,
    required this.funFact,
    required this.funFactAr,
  });

  final String id;
  final String question;
  final String questionAr;
  final String answer;
  final String answerAr;
  final String category;
  final String categoryAr;
  final String funFact;
  final String funFactAr;

  static _Card fromJson(Map<String, dynamic> j) => _Card(
    id: j['id'] as String,
    question: j['question'] as String,
    questionAr: (j['question_ar'] as String?) ?? j['question'] as String,
    answer: j['correct_answer'] as String,
    answerAr:
        (j['correct_answer_ar'] as String?) ?? j['correct_answer'] as String,
    category: j['category'] as String,
    categoryAr: (j['category_ar'] as String?) ?? j['category'] as String,
    funFact: (j['fun_fact'] as String?) ?? '',
    funFactAr:
        (j['fun_fact_ar'] as String?) ?? (j['fun_fact'] as String?) ?? '',
  );
}

class _CardFace extends ConsumerWidget {
  const _CardFace({
    super.key,
    required this.card,
    required this.flipped,
    required this.isAr,
  });
  final _Card card;
  final bool flipped;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = isAr ? card.categoryAr : card.category;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: flipped
            ? AppColors.success.withAlpha(36)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flipped
              ? AppColors.success.withAlpha(160)
              : AppColors.outline.withAlpha(120),
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(36),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              cat,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
          const Spacer(),
          if (flipped) ...[
            Text(
              isAr ? card.answerAr : card.answer,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 12),
            if ((isAr ? card.funFactAr : card.funFact).isNotEmpty)
              Text(
                isAr ? card.funFactAr : card.funFact,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
          ] else ...[
            Text(
              isAr ? card.questionAr : card.question,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
                fontSize: 22,
              ),
            ),
          ],
          const Spacer(),
          if (flipped)
            TtsSpeakerIcon(
              text: isAr ? card.answerAr : card.answer,
              arabic: isAr,
              filledTonal: true,
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.done,
    required this.total,
    required this.gotIt,
    required this.review,
    required this.isAr,
  });
  final int done;
  final int total;
  final int gotIt;
  final int review;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(36),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '✓ ${localizeDigits(gotIt, arabic: isAr)}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(36),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '↻ ${localizeDigits(review, arabic: isAr)}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (done / total).clamp(0, 1).toDouble(),
              minHeight: 8,
              color: AppColors.accent,
              backgroundColor: AppColors.outline.withAlpha(60),
            ),
          ),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.gotIt,
    required this.review,
    required this.total,
    required this.isAr,
    required this.onRestart,
  });
  final int gotIt;
  final int review;
  final int total;
  final bool isAr;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              isAr ? 'انتهت الجلسة' : 'Session done',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'فهمت ${localizeDigits(gotIt, arabic: true)} من ${localizeDigits(total, arabic: true)}، وتحتاج للمراجعة ${localizeDigits(review, arabic: true)}'
                  : 'Got ${localizeDigits(gotIt, arabic: false)} of ${localizeDigits(total, arabic: false)}, reviewed $review',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: Text(isAr ? 'جلسة جديدة' : 'New session'),
            ),
          ],
        ),
      ),
    );
  }
}
