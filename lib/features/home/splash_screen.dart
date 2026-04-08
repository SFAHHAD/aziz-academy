import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/services/tts_service.dart';

/// Animated splash screen shown on first launch.
/// Displays the Aziz Academy logo with a gold shimmer entrance,
/// then navigates to the home screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _ringController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Ring pulse animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Sequence: logo → ring → text → show start button
    _logoController.forward().then((_) {
      _ringController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _textController.forward();
        }
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background rings
            _BackgroundRings(),

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with pulse ring
                SizedBox(
                  width: 380,
                  height: 380,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing gold ring
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _ringOpacity.value,
                            child: Transform.scale(
                              scale: _ringScale.value,
                              child: Container(
                                width: 340,
                                height: 340,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.secondary,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Logo image
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withAlpha(120),
                                blurRadius: 60,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_final.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) => const Center(
                                child: Text('🎓', style: TextStyle(fontSize: 96)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Academy title
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        context.l10n.appTitle,
                        style: TextStyle(
                          fontFamily: isArabic ? 'Cairo' : 'Nunito',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          letterSpacing: isArabic ? 0 : 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.splashTagline,
                        style: TextStyle(
                          fontFamily: isArabic ? 'Cairo' : 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight.withAlpha(180),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                // Manual Start Button (unblocks Web Audio Context!)
                if (_isReady)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: ElevatedButton(
                      onPressed: () {
                        // User gesture instantly unlocks TTS capabilities!
                        ref.read(ttsServiceProvider).speakArabic(context.l10n.appTitle);
                        context.go(AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        context.l10n.splashStartButton,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Bottom version text
            Positioned(
              bottom: 48,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => Opacity(
                  opacity: _textOpacity.value * 0.5,
                  child: child,
                ),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight.withAlpha(120),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative static background concentric rings
class _BackgroundRings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final size in [700.0, 550.0, 400.0])
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withAlpha(size == 700 ? 15 : size == 550 ? 25 : 35),
                width: 1,
              ),
            ),
          ),
      ],
    );
  }
}
