import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';

/// Brief outline animation used when a screen receives a `?focusId=` deep
/// link and needs to draw the kid's eye to a specific card. The wrapper
/// adds an animated border only when [focused] is true — there's no
/// state inside; the parent flips [focused] on then off after ~1500ms.
class FocusHighlight extends StatelessWidget {
  const FocusHighlight({
    super.key,
    required this.focused,
    required this.child,
    this.borderRadius = 12,
  });

  final bool focused;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + 2),
        border: Border.all(
          color: focused
              ? AppColors.secondary
              : AppColors.secondary.withAlpha(0),
          width: focused ? 2.4 : 0,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.secondary.withAlpha(80),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(focused ? 2 : 0),
      child: child,
    );
  }
}
