import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';

// =============================================================================
// Today's mission — the single hero CTA at the top of the home screen.
//
// Deep violet→blue "magic" gradient so it reads as the special, premium card
// (distinct from the cool navy bg and the coloured tile grid below). Floats on
// a soft glow, has a frosted icon tile and a clean circular play button.
// =============================================================================

class TodaysMissionCard extends StatelessWidget {
  const TodaysMissionCard({
    super.key,
    required this.titleEn,
    required this.titleAr,
    required this.subtitle,
    required this.emoji,
    required this.onStart,
    this.bonusLabel,
  });

  final String titleEn;
  final String titleAr;
  final String subtitle;
  final String emoji;
  final VoidCallback onStart;
  final String? bonusLabel;

  // Hero gradient stops + glow colour.
  static const Color _g1 = Color(0xFF7C4DFF); // violet
  static const Color _g2 = Color(0xFF4364F7); // royal blue

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_g1, _g2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: _g1.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAr ? 'مهمة اليوم' : "TODAY'S MISSION",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        if (bonusLabel != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bonusLabel!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3A2A00),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAr ? titleAr : titleEn,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    size: 30, color: _g2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
