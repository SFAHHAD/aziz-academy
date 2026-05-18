import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Pass-and-Play — local 2-player versus mode. Players alternate turns on
/// the same device. 5 questions each. No network, no PII. Tracks score for
/// both. Pure offline.
class PassPlayScreen extends ConsumerStatefulWidget {
  const PassPlayScreen({super.key});

  @override
  ConsumerState<PassPlayScreen> createState() => _PassPlayScreenState();
}

enum _Phase { setup, handOver, ask, summary }

class _PassPlayScreenState extends ConsumerState<PassPlayScreen> {
  static const _qsPerPlayer = 5;

  final _p1 = TextEditingController(text: 'P1');
  final _p2 = TextEditingController(text: 'P2');
  _Phase _phase = _Phase.setup;
  List<QuizQuestion> _pool = const [];
  int _turn = 0; // 0..(2*_qsPerPlayer)-1
  int _s1 = 0;
  int _s2 = 0;
  bool _answered = false;
  String? _picked;
  bool _loading = false;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final caps = await ref
        .read(capitalsRepositoryProvider)
        .loadQuestions(arabic: isArabic);
    final sci = await ref
        .read(sciencesRepositoryProvider)
        .loadQuestions(arabic: isArabic);
    final mixed = [...caps, ...sci]..shuffle();
    if (mounted) {
      setState(() {
        _pool = mixed.take(_qsPerPlayer * 2).toList();
        _phase = _Phase.handOver;
        _loading = false;
      });
    }
  }

  bool get _isP1Turn => _turn.isEven;
  QuizQuestion? get _curQ => _pool.length > _turn ? _pool[_turn] : null;
  String get _curName => _isP1Turn ? _p1.text : _p2.text;

  void _onAnswer(String pick) {
    final q = _curQ;
    if (q == null || _answered) return;
    setState(() {
      _picked = pick;
      _answered = true;
      if (pick == q.correctAnswer) {
        if (_isP1Turn) {
          _s1++;
        } else {
          _s2++;
        }
      }
    });
  }

  void _advance() {
    if (_turn + 1 >= _pool.length) {
      // Match end — record win for active family slot if either won.
      final family = ref.read(familyProfilesProvider).value;
      final activeSlotId = family?.activeSlotId ?? 0;
      // P1 sits at slot 0 by convention; P2 is "guest" — only count badge
      // for active slot wins.
      final activeWon = activeSlotId == 0 ? _s1 > _s2 : _s2 > _s1;
      ref.read(achievementProvider.notifier).recordPassPlay(won: activeWon);
      setState(() => _phase = _Phase.summary);
    } else {
      setState(() {
        _turn++;
        _answered = false;
        _picked = null;
        _phase = _Phase.handOver;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _body(isArabic),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool isArabic) {
    if (_loading) {
      return const Center(
        key: ValueKey('load'),
        child: CircularProgressIndicator(),
      );
    }
    switch (_phase) {
      case _Phase.setup:
        return _setupBody(isArabic);
      case _Phase.handOver:
        return _handOverBody(isArabic);
      case _Phase.ask:
        return _askBody(isArabic);
      case _Phase.summary:
        return _summaryBody(isArabic);
    }
  }

  Widget _setupBody(bool isArabic) {
    return SingleChildScrollView(
      key: const ValueKey('setup'),
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
              const Text('🤝', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'وضع لاعبَين' : 'Pass & Play (2 players)',
                  style: AppTextStyles.headingMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic
                  ? 'يلعب لاعبان على نفس الجهاز. ٥ أسئلة لكل لاعب — مرّر الجهاز عند الانتهاء من دورك.'
                  : 'Two players share this device. 5 questions each — pass the device when your turn ends.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _p1,
            decoration: InputDecoration(
              labelText: isArabic ? 'اسم اللاعب 1' : 'Player 1 name',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLength: 16,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _p2,
            decoration: InputDecoration(
              labelText: isArabic ? 'اسم اللاعب 2' : 'Player 2 name',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLength: 16,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(isArabic ? 'ابدأ' : 'Start'),
          ),
        ],
      ),
    );
  }

  Widget _handOverBody(bool isArabic) {
    return Column(
      key: const ValueKey('hand'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📱', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text(
          isArabic ? 'دور $_curName' : "$_curName's turn",
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          isArabic
              ? 'مرّر الجهاز إلى $_curName ثم اضغط استعداد.'
              : 'Pass the device to $_curName, then tap ready.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => setState(() => _phase = _Phase.ask),
          icon: const Icon(Icons.check_rounded),
          label: Text(isArabic ? 'استعداد' : "I'm ready"),
        ),
        const SizedBox(height: 16),
        Text(
          isArabic
              ? 'النتيجة: ${_p1.text} $_s1  •  ${_p2.text} $_s2'
              : 'Score: ${_p1.text} $_s1  •  ${_p2.text} $_s2',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _askBody(bool isArabic) {
    final q = _curQ!;
    return SingleChildScrollView(
      key: ValueKey('ask-$_turn'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isArabic ? 'دور $_curName' : "$_curName's turn",
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(q.question, style: AppTextStyles.headingSmall),
          ),
          const SizedBox(height: 12),
          for (final opt in q.options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                onPressed: _answered ? null : () => _onAnswer(opt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _answered
                      ? (opt == q.correctAnswer
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
            if (q.funFact.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('💡 ${q.funFact}', style: AppTextStyles.bodyMedium),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _advance,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                isArabic
                    ? (_turn + 1 >= _pool.length ? 'النتيجة' : 'تالٍ')
                    : (_turn + 1 >= _pool.length ? 'See result' : 'Next'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryBody(bool isArabic) {
    final winner = _s1 == _s2 ? null : (_s1 > _s2 ? _p1.text : _p2.text);
    return Column(
      key: const ValueKey('sum'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 96)),
        const SizedBox(height: 12),
        Text(
          winner == null
              ? (isArabic ? 'تعادل!' : "It's a tie!")
              : (isArabic ? 'الفائز: $winner' : 'Winner: $winner'),
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${_p1.text}: $_s1   ${_p2.text}: $_s2',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _phase = _Phase.setup;
                  _turn = 0;
                  _s1 = 0;
                  _s2 = 0;
                  _pool = const [];
                  _answered = false;
                  _picked = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isArabic ? 'لعب مرة أخرى' : 'Play again'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.home_rounded),
              label: Text(isArabic ? 'الرئيسية' : 'Home'),
            ),
          ],
        ),
      ],
    );
  }
}
