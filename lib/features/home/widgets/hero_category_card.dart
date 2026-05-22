import 'package:flutter/material.dart';

// =============================================================================
// Hero category card — one of the 5 tiles on the v2 home grid.
//
// Each tile is a solid, vibrant gradient (lit from the top-left, deepened
// toward the bottom-right) sitting on a soft *coloured* drop shadow so it
// reads as a physical card floating above the navy background — not a flat,
// outlined box. The emoji lives in a frosted rounded chip for consistency.
// =============================================================================

class HeroCategoryCard extends StatelessWidget {
  const HeroCategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isPro = false,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isPro;

  static Color _lighten(Color c, double amount) =>
      Color.lerp(c, Colors.white, amount) ?? c;
  static Color _darken(Color c, double amount) =>
      Color.lerp(c, Colors.black, amount) ?? c;

  @override
  Widget build(BuildContext context) {
    final top = _lighten(color, 0.14);
    final bottom = _darken(color, 0.24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [top, bottom],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.42),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frosted icon chip
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _darken(color, 0.28),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
