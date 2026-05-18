import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/coin_countup_chip.dart';
import 'package:aziz_academy/core/widgets/sparkline.dart';

/// Catalogue of in-app widgets rendered in isolation. Useful for visual
/// regressions and quick design tweaks without booting a full quiz flow.
/// Reachable at `/dev/gallery` only — not surfaced in production navigation.
class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: const Text('Widget gallery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Group(
            title: 'CoinCountUpChip',
            children: [
              CoinCountUpChip(coinsEarned: 25),
              SizedBox(height: 12),
              CoinCountUpChip(coinsEarned: 120),
              SizedBox(height: 12),
              CoinCountUpChip(coinsEarned: 0),
            ],
          ),
          _Group(
            title: 'Sparkline',
            children: [
              SizedBox(
                width: 220,
                child: Sparkline(
                  values: [
                    0.1,
                    0.3,
                    0.4,
                    0.35,
                    0.5,
                    0.55,
                    0.6,
                    0.62,
                    0.7,
                    0.74,
                    0.8,
                    0.78,
                    0.82,
                    0.9,
                  ],
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: 220,
                child: Sparkline(
                  values: [0.5, 0.5, 0.5, 0.5, 0.5],
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          _Group(
            title: 'Color tokens',
            children: [
              _Swatch(label: 'primary', color: AppColors.primary),
              _Swatch(label: 'secondary', color: AppColors.secondary),
              _Swatch(label: 'accent', color: AppColors.accent),
              _Swatch(label: 'success', color: AppColors.success),
              _Swatch(label: 'warning', color: AppColors.warning),
              _Swatch(label: 'error', color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.divider),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
