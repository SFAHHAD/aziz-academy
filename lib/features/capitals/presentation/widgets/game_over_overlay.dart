import 'package:flutter/material.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';

/// Full-screen overlay shown when the player runs out of lives.
///
/// Shows:
/// - "Nice Try! 💪" heading with encouragement
/// - Score so far
/// - Animated heart-refill countdown (3 hearts fill one-by-one)
/// - "Try Again" button (always tappable; skips countdown if early)
/// - "Back to Map" button
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    super.key,
    required this.session,
    required this.onTryAgain,
    required this.onBack,
    this.learningTip,
  });

  final QuizSessionState session;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;
  /// Shown when available (e.g. fun fact for the last question).
  final String? learningTip;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  // Entry animation
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Heart-refill countdown (3 hearts × 1.5 s each = 4.5 s total)
  late final AnimationController _refillCtrl;
  static const _refillDuration = Duration(milliseconds: 4500);

  bool _refillComplete = false;

  /// How many hearts are currently "filled" during the animation.
  int get _filledHearts {
    final v = _refillCtrl.value;
    if (v >= 1.0) return 3;
    if (v >= 0.66) return 2;
    if (v >= 0.33) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();

    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _refillCtrl = AnimationController(vsync: this, duration: _refillDuration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _refillComplete = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _refillCtrl.dispose();
    super.dispose();
  }

  String get _buttonLabel =>
      _refillComplete ? 'جاهز! هيا نبدأ 🚀' : 'حاول مجدداً الآن ←';

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Stack(
      children: [
        // ── Dark frosted backdrop ─────────────────────────────────────────
        GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A0A00).withAlpha(220),
                  const Color(0xFF2D0A00).withAlpha(240),
                ],
              ),
            ),
          ),
        ),

        // ── Content card ─────────────────────────────────────────────────
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 480 : 360),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withAlpha(40),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Emoji mascot
                        const Text('😤', style: TextStyle(fontSize: 72)),
                        const SizedBox(height: 12),

                        Text(
                          'أوشكت على النجاح!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نَفِدت قلوبك.\nكل خبير كان يوماً مبتدئاً! 💪',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Score
                        _GameOverScorePill(session: widget.session),
                        if (widget.learningTip != null &&
                            widget.learningTip!.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              '📚 ${widget.learningTip!}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Heart refill section
                        _HeartRefillSection(
                          filledHearts: _filledHearts,
                          isComplete: _refillComplete,
                        ),
                        const SizedBox(height: 28),

                        // Primary: Try Again
                        _PulsingButton(
                          label: _buttonLabel,
                          isPulsing: _refillComplete,
                          onPressed: widget.onTryAgain,
                        ),
                        const SizedBox(height: 12),

                        // Secondary: Back to Map
                        TextButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.home_rounded, size: 20),
                          label: const Text('العودة للقائمة'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMedium,
                            minimumSize: const Size(double.infinity, 48),
                            textStyle: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Heart Refill Section — shows hearts filling one by one
// =============================================================================

class _HeartRefillSection extends StatelessWidget {
  const _HeartRefillSection({
    required this.filledHearts,
    required this.isComplete,
  });

  final int filledHearts;
  final bool isComplete;
  static const _maxHearts = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isComplete ? '❤️ اكتملت القلوب!' : 'جارٍ استعادة القلوب…',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isComplete ? AppColors.success : AppColors.textMedium,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: '$filledHearts من $_maxHearts قلوب ممتلئة',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_maxHearts, (i) {
              final filled = i < filledHearts;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.elasticOut,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Icon(
                    filled
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey('heart_${i}_$filled'),
                    color: filled ? AppColors.error : AppColors.disabled,
                    size: 44,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        if (!isComplete)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: filledHearts / _maxHearts.toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.error),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Score pill for game over
// =============================================================================

class _GameOverScorePill extends StatelessWidget {
  const _GameOverScorePill({required this.session});
  final QuizSessionState session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نقاط هذه الجولة', style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${session.score}',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    ' / ${session.totalQuestions}',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Text('🎯', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }
}

// =============================================================================
// Pulsing button — pulses when enabled to draw the child's attention
// =============================================================================

class _PulsingButton extends StatefulWidget {
  const _PulsingButton({
    required this.label,
    required this.isPulsing,
    required this.onPressed,
  });

  final String label;
  final bool isPulsing;
  final VoidCallback onPressed;

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_PulsingButton old) {
    super.didUpdateWidget(old);
    if (!old.isPulsing && widget.isPulsing) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isPulsing) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) => Transform.scale(
        scale: widget.isPulsing ? _pulse.value : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPulsing ? AppColors.success : AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            textStyle: AppTextStyles.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
