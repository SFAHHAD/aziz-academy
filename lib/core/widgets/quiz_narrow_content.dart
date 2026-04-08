import 'package:flutter/material.dart';

/// Centers quiz body on wide screens (web / tablet) for a consistent max width.
class QuizNarrowContent extends StatelessWidget {
  const QuizNarrowContent({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
