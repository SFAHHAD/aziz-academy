import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';

/// A 🔊 button that speaks the given Arabic text through the TTS
/// service — and hides itself entirely when the kid is in
/// "real audio only" mode (the default since v1.1.96). Replaces the
/// inline `IconButton(... speakArabic ...)` pattern that lived in
/// every Islamic content screen.
///
/// When `ttsEnabled` is false (the default), this returns
/// [SizedBox.shrink], so visually there is no button at all — no
/// dangling tap-target that does nothing. When a parent re-enables AI
/// voices, the button reappears and works as before.
///
/// Quran recitation (real audio via EveryAyah CDN) is unaffected — that
/// path is its own service and does not go through this widget.
class TtsSpeakerIcon extends ConsumerWidget {
  const TtsSpeakerIcon({
    super.key,
    required this.text,
    this.arabic = true,
    this.size,
    this.color,
    this.tooltip,
    this.filledTonal = false,
  });

  /// The text to speak. If empty the button hides.
  final String text;

  /// Speak in Arabic (default) or English.
  final bool arabic;

  /// Optional icon size override.
  final double? size;

  /// Optional foreground color override.
  final Color? color;

  /// Optional tooltip (recommended for screen readers).
  final String? tooltip;

  /// Use `IconButton.filledTonal` styling — matches the hadith card.
  final bool filledTonal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsOn =
        ref.watch(appSettingsProvider).value?.ttsEnabled ?? false;
    if (!ttsOn || text.isEmpty) return const SizedBox.shrink();

    final icon = Icon(
      Icons.volume_up_rounded,
      size: size,
      color: color,
    );
    void onPressed() {
      final tts = ref.read(ttsServiceProvider);
      if (arabic) {
        tts.speakArabic(text);
      } else {
        tts.speakEnglish(text);
      }
    }
    if (filledTonal) {
      return IconButton.filledTonal(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
      );
    }
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      color: color ?? AppColors.textDark,
      tooltip: tooltip,
    );
  }
}
