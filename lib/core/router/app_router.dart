import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/features/home/splash_screen.dart';
import 'package:aziz_academy/features/home/home_screen.dart';
import 'package:aziz_academy/features/achievements/presentation/screens/trophy_room_screen.dart';
import 'package:aziz_academy/features/maps/presentation/screens/maps_screen.dart';
import 'package:aziz_academy/features/capitals/presentation/screens/capitals_screen.dart';
import 'package:aziz_academy/features/capitals/presentation/screens/capitals_quiz_screen.dart';
import 'package:aziz_academy/features/logos/presentation/screens/logos_screen.dart';
import 'package:aziz_academy/features/sciences/presentation/screens/sciences_screen.dart';
import 'package:aziz_academy/features/sciences/presentation/screens/sciences_quiz_screen.dart';

import 'package:aziz_academy/features/flags/presentation/screens/flags_screen.dart';
import 'package:aziz_academy/features/flags/presentation/screens/flags_quiz_screen.dart';

import 'package:aziz_academy/features/math/presentation/screens/math_screen.dart';
import 'package:aziz_academy/features/math/presentation/screens/math_quiz_screen.dart';
import 'package:aziz_academy/features/legal/privacy_policy_screen.dart';
import 'package:aziz_academy/features/legal/about_screen.dart';

abstract final class AppRoutes {
  static const splash        = '/';
  static const home          = '/home';
  static const maps          = '/maps';
  static const capitals      = '/capitals';
  static const capitalsQuiz  = '/capitals/quiz';
  static const flags         = '/flags';
  static const flagsQuiz     = '/flags/quiz';
  static const math          = '/math';
  static const mathQuiz      = '/math/quiz';
  static const logos         = '/logos';
  static const sciences      = '/sciences';
  static const sciencesQuiz  = '/sciences/quiz';
  static const trophy        = '/trophy';
  static const privacy       = '/privacy';
  static const about         = '/about';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.errorPageTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.errorPageHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.maps,
      builder: (context, state) => MapsScreen(
        skipIntro: state.uri.queryParameters['recap'] == '1',
      ),
    ),
    GoRoute(
      path: AppRoutes.capitals,
      builder: (context, state) => const CapitalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.capitalsQuiz,
      builder: (context, state) => const CapitalsQuizScreen(),
    ),
    GoRoute(
      path: AppRoutes.flags,
      builder: (context, state) => const FlagsScreen(),
    ),
    GoRoute(
      path: AppRoutes.flagsQuiz,
      builder: (context, state) => const FlagsQuizScreen(),
    ),
    GoRoute(
      path: AppRoutes.math,
      builder: (context, state) => const MathScreen(),
    ),
    GoRoute(
      path: AppRoutes.mathQuiz,
      builder: (context, state) => const MathQuizScreen(),
    ),
    GoRoute(
      path: AppRoutes.logos,
      builder: (context, state) => const LogosScreen(),
    ),
    GoRoute(
      path: AppRoutes.trophy,
      builder: (context, state) => const TrophyRoomScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.sciences,
      builder: (context, state) => const SciencesScreen(),
    ),
    GoRoute(
      path: AppRoutes.sciencesQuiz,
      builder: (context, state) => const SciencesQuizScreen(),
    ),
  ],
);

