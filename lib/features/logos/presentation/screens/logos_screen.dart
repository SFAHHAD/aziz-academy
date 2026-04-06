import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/features/logos/providers/logos_provider.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/victory_overlay.dart';
import 'package:aziz_academy/features/capitals/presentation/widgets/game_over_overlay.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/services/audio_service.dart';

import 'package:aziz_academy/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helper: looks up a brand key (e.g. 'youtube') and returns fact/desc strings.
// Falls back gracefully if the brand is unknown.
// ---------------------------------------------------------------------------
extension _BrandL10n on AppLocalizations {
  String brandDesc(String id) {
    switch (id) {
      case 'youtube':   return brand_youtube_desc;
      case 'apple':     return brand_apple_desc;
      case 'lego':      return brand_lego_desc;
      case 'nasa':      return brand_nasa_desc;
      case 'nike':      return brand_nike_desc;
      case 'mcdonalds': return brand_mcdonalds_desc;
      case 'google':    return brand_google_desc;
      case 'amazon':    return brand_amazon_desc;
      case 'twitter':   return brand_twitter_desc;
      case 'facebook':  return brand_facebook_desc;
      case 'instagram': return brand_instagram_desc;
      case 'netflix':   return brand_netflix_desc;
      default:          return id;
    }
  }

  String brandFact(String id) {
    switch (id) {
      case 'youtube':   return brand_youtube_fact;
      case 'apple':     return brand_apple_fact;
      case 'lego':      return brand_lego_fact;
      case 'nasa':      return brand_nasa_fact;
      case 'nike':      return brand_nike_fact;
      case 'mcdonalds': return brand_mcdonalds_fact;
      case 'google':    return brand_google_fact;
      case 'amazon':    return brand_amazon_fact;
      case 'twitter':   return brand_twitter_fact;
      case 'facebook':  return brand_facebook_fact;
      case 'instagram': return brand_instagram_fact;
      case 'netflix':   return brand_netflix_fact;
      default:          return '';
    }
  }
}

// =============================================================================
// LogosScreen
// =============================================================================

class LogosScreen extends ConsumerWidget {
  const LogosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(logosQuizProvider);
    final l10n = AppLocalizations.of(context)!;

    // Fire achievement recording and SFX exactly once when quiz completes.
    ref.listen<AsyncValue<QuizSessionState>>(
      logosQuizProvider,
      (prev, next) {
        if (next.value?.isComplete == true &&
            prev?.value?.isComplete != true) {
          final session = next.value!;
          ref.read(achievementProvider.notifier).recordLogosSession(
            score: session.score,
            livesRemaining: session.livesRemaining,
          );
          ref.read(audioServiceProvider).playVictorySound();
        } else if (next.value?.isGameOver == true &&
                   prev?.value?.isGameOver != true) {
          ref.read(audioServiceProvider).playWrongSound(); // Buzzer for game over
        }
      },
    );

    return sessionAsync.when(
      loading: () => const _LoadingView(),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (session) {
        if (session.isGameOver) {
          return Scaffold(
            body: GameOverOverlay(
              session: session,
              onTryAgain: () => ref.read(logosQuizProvider.notifier).restart(),
              onBack: () => context.go(AppRoutes.home),
            ),
          );
        }
        if (session.isComplete) {
          return Scaffold(
            body: VictoryOverlay(
              session: session,
              onPlayAgain: () =>
                  ref.read(logosQuizProvider.notifier).restart(),
              onBack: () => context.go(AppRoutes.home),
            ),
          );
        }
        return _QuizView(session: session, l10n: l10n);
      },
    );
  }
}

// =============================================================================
// Active quiz view
// =============================================================================

class _QuizView extends ConsumerStatefulWidget {
  const _QuizView({required this.session, required this.l10n});
  final QuizSessionState session;
  final AppLocalizations l10n;

  @override
  ConsumerState<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends ConsumerState<_QuizView>
    with TickerProviderStateMixin {
  late AnimationController _revealCtrl;
  bool _answered = false;
  bool? _lastCorrect;

  static const _revealDuration = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(vsync: this, duration: _revealDuration);
    _revealCtrl.addStatusListener(_onRevealStatus);
    _revealCtrl.forward();
  }

  @override
  void didUpdateWidget(_QuizView old) {
    super.didUpdateWidget(old);
    // New question arrived → reset animation.
    if (old.session.currentIndex != widget.session.currentIndex) {
      _answered = false;
      _lastCorrect = null;
      _startReveal();
    }
  }

  void _startReveal() {
    if (!mounted) return;
    _revealCtrl
      ..removeStatusListener(_onRevealStatus)
      ..reset()
      ..addStatusListener(_onRevealStatus)
      ..forward();
  }

  void _onRevealStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_answered && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  void _handleAnswer(String answer) {
    if (_answered) return;
    final isCorrect =
        ref.read(logosQuizProvider.notifier).submitAnswer(answer);
        
    if (isCorrect) {
      ref.read(audioServiceProvider).playCorrectSound();
    } else {
      ref.read(audioServiceProvider).playWrongSound();
    }

    _revealCtrl.stop();
    setState(() {
      _answered = true;
      _lastCorrect = isCorrect;
    });
  }

  void _next() {
    ref.read(logosQuizProvider.notifier).nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.session.currentQuestion;
    if (q == null) return const SizedBox.shrink();
    final l10n = widget.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            _LogosHeader(
              title: l10n.logoQuizTitle,
              session: widget.session,
              revealCtrl: _revealCtrl,
            ),

            // ── Logo puzzle card ────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _LogoPuzzleCard(
                logoAsset: q.imageUrl ?? '',
                revealCtrl: _revealCtrl,
                answered: _answered,
                brandName: q.question, // question field holds brand name
                isCorrect: _lastCorrect,
              ),
            ),

            // ── 2×2 Answer grid ─────────────────────────────────────────
            Expanded(
              flex: 4,
              child: _OptionsGrid(
                options: q.options,
                correctAnswer: q.correctAnswer,
                answered: _answered,
                onAnswer: _handleAnswer,
              ),
            ),

            // ── Knowledge card (post-answer) / Next button ───────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _answered
                  ? _KnowledgeCard(
                      key: const ValueKey('knowledge'),
                      brandId: q.funFact, // funFact holds brand id for l10n
                      l10n: l10n,
                      onNext: _next,
                      isCorrect: _lastCorrect ?? false,
                    )
                  : const SizedBox(key: ValueKey('empty'), height: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Header with progress bar + heart bar + timer arc
// =============================================================================

class _LogosHeader extends StatelessWidget {
  const _LogosHeader({
    required this.title,
    required this.session,
    required this.revealCtrl,
  });
  final String title;
  final QuizSessionState session;
  final AnimationController revealCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.go(AppRoutes.home),
              ),
              Text(
                title,
                style: AppTextStyles.headingMedium
                    .copyWith(color: Colors.white, fontSize: 18),
              ),
              const Spacer(),
              // Hearts
              Row(
                children: List.generate(3, (i) {
                  return Icon(
                    i < session.livesRemaining
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: AppColors.error,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 12),
              // Circular timer
              _TimerRing(controller: revealCtrl),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: session.progress,
              backgroundColor: Colors.white12,
              color: AppColors.capitalsColor,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends AnimatedWidget {
  const _TimerRing({required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final ctrl = listenable as AnimationController;
    final remaining = (12 * (1.0 - ctrl.value)).ceil();
    final color = ctrl.value < 0.66
        ? AppColors.capitalsColor
        : ctrl.value < 0.88
            ? Colors.orange
            : AppColors.error;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0 - ctrl.value,
            strokeWidth: 4,
            backgroundColor: Colors.white12,
            color: color,
          ),
          Text(
            '$remaining',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Logo puzzle card with blur reveal
// =============================================================================

class _LogoPuzzleCard extends StatelessWidget {
  const _LogoPuzzleCard({
    required this.logoAsset,
    required this.revealCtrl,
    required this.answered,
    required this.brandName,
    required this.isCorrect,
  });
  final String logoAsset;
  final AnimationController revealCtrl;
  final bool answered;
  final String brandName;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Logo (always present, blur sits on top)
            Padding(
              padding: const EdgeInsets.all(20),
              child: logoAsset.isNotEmpty
                  ? (logoAsset.startsWith('assets/')
                      ? Image.asset(
                          logoAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Icon(
                            Icons.broken_image_outlined, size: 60, color: Colors.grey
                          ),
                        )
                      : Image.network(
                          logoAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Icon(
                            Icons.broken_image_outlined, size: 60, color: Colors.grey
                          ),
                        ))
                  : const Icon(Icons.image_not_supported,
                      size: 80, color: Colors.grey),
            ),

            // Blur overlay (fades away as revealCtrl progresses)
            AnimatedBuilder(
              animation: revealCtrl,
              builder: (ctx, _) {
                // When answered, instantly clear the blur.
                final sigma = answered
                    ? 0.0
                    : 18.0 * (1.0 - revealCtrl.value);
                if (sigma < 0.5) return const SizedBox.shrink();
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: Container(color: Colors.white.withAlpha(30)),
                );
              },
            ),

            // Correct / wrong indicator ribbon
            if (answered && isCorrect != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isCorrect! ? AppColors.success : AppColors.error)
                        .withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect! ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        brandName,
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2×2 Answer grid
// =============================================================================

class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({
    required this.options,
    required this.correctAnswer,
    required this.answered,
    required this.onAnswer,
  });
  final List<String> options;
  final String correctAnswer;
  final bool answered;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.6,
        children: options.map((opt) {
          Color bg = AppColors.surfaceContainerHigh;
          Color border = Colors.white12;
          if (answered) {
            if (opt == correctAnswer) {
              bg = AppColors.success.withAlpha(40);
              border = AppColors.success;
            } else {
              bg = Colors.red.withAlpha(20);
              border = Colors.transparent;
            }
          }
          return GestureDetector(
            onTap: answered ? null : () => onAnswer(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                opt,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Knowledge card (post-answer fun-fact + Next button)
// =============================================================================

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({
    super.key,
    required this.brandId,
    required this.l10n,
    required this.onNext,
    required this.isCorrect,
  });
  final String brandId;
  final AppLocalizations l10n;
  final VoidCallback onNext;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isCorrect ? AppColors.success : AppColors.error)
              .withAlpha(120),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('💡', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l10n.knowledgeCard,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.capitalsColor,
                ),
              ),
              const Spacer(),
              // Brand description chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.capitalsColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.brandDesc(brandId),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.capitalsColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.brandFact(brandId),
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white70, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.capitalsColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.nextQuestion,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Loading / Error stubs
// =============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: CircularProgressIndicator(color: AppColors.capitalsColor),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Text(error, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
