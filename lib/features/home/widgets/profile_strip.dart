import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';

// =============================================================================
// Profile strip — the new top of the home screen.
//
// One row: avatar, display name, level, XP bar, streak. Tap avatar → profile.
// Tap gear → settings. Designed to fit one row at 360 px width.
// =============================================================================

class ProfileStrip extends ConsumerWidget {
  const ProfileStrip({
    super.key,
    required this.displayName,
    required this.level,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.streak,
    this.avatarUrl,
  });

  final String displayName;
  final int level;
  final int xpInLevel;
  final int xpToNextLevel;
  final int streak;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = xpToNextLevel == 0
        ? 0.0
        : (xpInLevel / xpToNextLevel).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.push(AppRoutes.profileCard),
            child: _Avatar(name: displayName, url: avatarUrl, size: 52),
          ),
          const SizedBox(width: 12),
          // Name + level + XP bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv $level',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$xpInLevel / $xpToNextLevel XP',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Streak chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.deepOrange.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.size,
    this.url,
  });
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final palette = [
      const Color(0xFF7C4DFF), const Color(0xFF26C6DA),
      const Color(0xFFFFB300), const Color(0xFFFF6E40),
      const Color(0xFF66BB6A), const Color(0xFFEC407A),
    ];
    final color = palette[initial.codeUnitAt(0) % palette.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
      ),
      alignment: Alignment.center,
      child: url != null && url!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    _initialLabel(initial, size, Colors.white),
              ),
            )
          : _initialLabel(initial, size, Colors.white),
    );
  }

  Widget _initialLabel(String initial, double size, Color color) => Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      );
}
