import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';

/// Type-the-answer mode (Research.txt). Generates simple math facts the kid
/// types into a number field. Number-only — no free-text typing yet.
class TypeAnswerScreen extends ConsumerStatefulWidget {
  const TypeAnswerScreen({super.key});

  @override
  ConsumerState<TypeAnswerScreen> createState() => _TypeAnswerScreenState();
}

class _TypeAnswerScreenState extends ConsumerState<TypeAnswerScreen> {
  static const int _kTotal = 10;
  late final List<_TypeQ> _items;
  int _idx = 0;
  int _score = 0;
  final _ctrl = TextEditingController();
  bool? _wasRight;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _items = _generate();
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'type_answer',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _next?.cancel();
    super.dispose();
  }

  List<_TypeQ> _generate() {
    final r = math.Random();
    final out = <_TypeQ>[];
    for (var i = 0; i < _kTotal; i++) {
      final op = r.nextInt(4);
      switch (op) {
        case 0:
          final a = r.nextInt(50) + 5;
          final b = r.nextInt(50) + 5;
          out.add(_TypeQ('$a + $b = ?', a + b));
          break;
        case 1:
          final a = r.nextInt(50) + 20;
          final b = r.nextInt(a - 1) + 1;
          out.add(_TypeQ('$a − $b = ?', a - b));
          break;
        case 2:
          final a = r.nextInt(11) + 2;
          final b = r.nextInt(11) + 2;
          out.add(_TypeQ('$a × $b = ?', a * b));
          break;
        default:
          final b = r.nextInt(11) + 2;
          final ans = r.nextInt(11) + 2;
          out.add(_TypeQ('${b * ans} ÷ $b = ?', ans));
      }
    }
    return out;
  }

  void _submit() {
    if (_wasRight != null) return;
    final v = int.tryParse(_ctrl.text.trim());
    if (v == null) return;
    final cur = _items[_idx];
    final correct = v == cur.answer;
    if (correct) _score += 1;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'type_answer',
        timestamp: DateTime.now(),
        questionId: 'math_$_idx',
        category: 'arithmetic',
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
    setState(() => _wasRight = correct);
    _next?.cancel();
    _next = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _idx += 1;
        _wasRight = null;
        _ctrl.clear();
      });
      if (_idx >= _items.length) {
        EventBus.instance.emit(
          LearningEvent(
            type: LearningEventType.sessionEnded,
            module: 'type_answer',
            timestamp: DateTime.now(),
            score: _score,
          ),
        );
        ref.read(coinProvider.notifier).award(_score * 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('⌨️', style: TextStyle(fontSize: 96)),
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
                      });
                      _items
                        ..clear()
                        ..addAll(_generate());
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
                const SizedBox(height: 36),
                Text(
                  cur.prompt,
                  style: AppTextStyles.displayLargeGold.copyWith(fontSize: 56),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: TextField(
                    controller: _ctrl,
                    enabled: _wasRight == null,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _wasRight == null
                          ? AppColors.surfaceContainerLow
                          : (_wasRight!
                                ? const Color(0xFF6BBF59).withAlpha(80)
                                : AppColors.error.withAlpha(80)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _wasRight == null ? _submit : null,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(isArabic ? 'تحقق' : 'Check'),
                    ),
                  ),
                ),
                if (_wasRight == false) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${isArabic ? 'الإجابة:' : 'Answer:'} ${cur.answer}',
                    style: AppTextStyles.headingSmall,
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

class _TypeQ {
  const _TypeQ(this.prompt, this.answer);
  final String prompt;
  final int answer;
}
