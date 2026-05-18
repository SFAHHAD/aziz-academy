import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/widgets/step_guide_screen.dart';

/// "How to do Wudu" — 9-step interactive ablution guide. Thin wrapper
/// over [StepGuideScreen] supplying the Wudu JSON pack and theme.
class WuduStepsScreen extends StatelessWidget {
  const WuduStepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StepGuideScreen(
      assetPath: 'assets/data/wudu_steps.json',
      titleEn: 'How to do Wudu',
      titleAr: 'الوضوء',
      accent: AppColors.secondary,
      emptyIcon: Icons.water_drop_outlined,
      fallbackIcon: '💧',
    );
  }
}
