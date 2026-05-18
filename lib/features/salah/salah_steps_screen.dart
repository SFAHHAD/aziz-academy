import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/widgets/step_guide_screen.dart';

/// "How to pray" — 10-step interactive Salah guide for kids. Thin wrapper
/// over [StepGuideScreen] supplying the Salah JSON pack and theme.
class SalahStepsScreen extends StatelessWidget {
  const SalahStepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StepGuideScreen(
      assetPath: 'assets/data/salah_steps.json',
      titleEn: 'How to Pray',
      titleAr: 'كيف نصلي',
      accent: AppColors.accent,
      emptyIcon: Icons.mosque_outlined,
      fallbackIcon: '🕌',
    );
  }
}
