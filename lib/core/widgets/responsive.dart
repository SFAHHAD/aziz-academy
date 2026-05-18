import 'package:flutter/material.dart';

/// Phone < 600 < Tablet < 900 < Large.
class Breakpoints {
  static const double phoneMax = 600;
  static const double tabletMax = 900;
  static const double bodyMax = 720; // single-column max for readability
  static const double bodyMaxWide =
      1100; // for screens that benefit from a wider grid
}

/// Returns the screen class for the current context.
enum Device { phone, tablet, large }

Device deviceOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < Breakpoints.phoneMax) return Device.phone;
  if (w < Breakpoints.tabletMax) return Device.tablet;
  return Device.large;
}

bool isPhone(BuildContext c) => deviceOf(c) == Device.phone;
bool isTablet(BuildContext c) => deviceOf(c) == Device.tablet;
bool isLarge(BuildContext c) => deviceOf(c) == Device.large;

/// Wraps a screen body so it never gets uncomfortably wide on tablet/desktop.
/// Pass `wide: true` for grid-heavy screens (home, leaderboard, shop).
class CenteredBody extends StatelessWidget {
  const CenteredBody({
    super.key,
    required this.child,
    this.wide = false,
    this.padding,
  });

  final Widget child;
  final bool wide;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final maxW = wide ? Breakpoints.bodyMaxWide : Breakpoints.bodyMax;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// Adaptive horizontal padding — phones get tighter padding, tablets get more.
EdgeInsets adaptivePadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return const EdgeInsets.symmetric(horizontal: 16);
  if (w < 900) return const EdgeInsets.symmetric(horizontal: 24);
  return const EdgeInsets.symmetric(horizontal: 32);
}
