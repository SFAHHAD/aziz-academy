import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// Gentle screen-time reminder.
///
/// Tracks how long the app has been open in this session (in-memory; resets
/// on reload). After [threshold] of continuous open time, shows a polite
/// banner that a kid can dismiss to snooze for [snooze]. We don't track
/// across reloads or per-day — the goal is "long single sitting" detection,
/// not per-day enforcement, which would need a Parent Area control surface.
class BreakReminderHost extends StatefulWidget {
  const BreakReminderHost({
    super.key,
    required this.child,
    this.threshold = const Duration(minutes: 30),
    this.snooze = const Duration(minutes: 10),
  });

  final Widget child;
  final Duration threshold;
  final Duration snooze;

  @override
  State<BreakReminderHost> createState() => _BreakReminderHostState();
}

class _BreakReminderHostState extends State<BreakReminderHost> {
  late final DateTime _sessionStart;
  DateTime? _suppressedUntil;
  Timer? _ticker;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final shouldShow =
          now.difference(_sessionStart) >= widget.threshold &&
          (_suppressedUntil == null || now.isAfter(_suppressedUntil!));
      if (shouldShow != _showing) {
        setState(() => _showing = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _snooze() {
    setState(() {
      _suppressedUntil = DateTime.now().add(widget.snooze);
      _showing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showing) return widget.child;
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 88,
          left: 12,
          right: 12,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withAlpha(80)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(70),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('☕', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'وقت الاستراحة!' : 'Break time!',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr
                                ? 'لقد لعبت ٣٠ دقيقة. خذ استراحة قصيرة لراحة عينيك.'
                                : "You've been playing for 30 minutes. Rest your eyes for a bit.",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              height: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _snooze,
                      child: Text(
                        isAr ? 'لاحقًا' : 'Later',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
