import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/islamic_audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';

/// A 🔊 button for the Islamic content suite that prefers real recitation
/// MP3s over synthetic TTS. Behaviour, in order:
///
/// 1. If a real recording is bundled for `(category, id)`, tap plays the
///    MP3 via [IslamicAudioService]. Sound toggle gates this — TTS toggle
///    does not.
/// 2. If no recording is bundled, the button only renders when the parent
///    has explicitly re-enabled AI voices. Tap then speaks `arabicText`
///    via [TtsService].
/// 3. If neither condition holds, the widget renders `SizedBox.shrink()`
///    — no dead tap-target.
///
/// This is the v1.1.96 "real audio only" policy generalised: the kid only
/// hears real human voices unless a parent has opted into AI speech.
/// As recordings ship under `assets/audio/<category>/`, screens transparently
/// upgrade from "hidden by default" to "plays the real thing" without any
/// per-screen code change.
class RealAudioButton extends ConsumerWidget {
  const RealAudioButton({
    super.key,
    required this.category,
    required this.id,
    required this.arabicText,
    this.size,
    this.color,
    this.tooltip,
    this.filledTonal = false,
  });

  /// One of: `hadith`, `azkar`, `names`, `dua`, `tajweed`.
  final String category;

  /// The content id — must match the JSON `id` field (or `name_NNN` for
  /// the 99 Names, `morning_NN` / `evening_NN` for athkar).
  final String id;

  /// Fallback Arabic text spoken via TTS when no recording is bundled and
  /// the parent has re-enabled AI voices.
  final String arabicText;

  final double? size;
  final Color? color;
  final String? tooltip;
  final bool filledTonal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(islamicAudioServiceProvider);
    final hasReal = svc.hasRecording(category, id);

    final settings = ref.watch(appSettingsProvider).value;
    final soundOn = settings?.soundEnabled ?? true;
    final ttsOn = settings?.ttsEnabled ?? false;

    // Hide the button entirely when there's nothing we can play.
    if (!soundOn) return const SizedBox.shrink();
    if (!hasReal && !ttsOn) return const SizedBox.shrink();
    if (!hasReal && arabicText.isEmpty) return const SizedBox.shrink();

    void onPressed() {
      if (hasReal) {
        // Fire-and-forget; the service awaits the player internally and
        // surfaces errors via debugPrint. We deliberately don't await
        // because UI rebuilds shouldn't block.
        svc
            .play(category: category, id: id)
            .catchError((Object e, StackTrace _) {
          // Registry says we have it, but playback failed — fall back to
          // TTS only if the parent has opted into AI voices.
          if (ttsOn && arabicText.isNotEmpty) {
            ref.read(ttsServiceProvider).speakArabic(arabicText);
          }
        });
        return;
      }
      // No recording yet — speak the Arabic via TTS.
      ref.read(ttsServiceProvider).speakArabic(arabicText);
    }

    final icon = Icon(
      Icons.volume_up_rounded,
      size: size,
      color: color,
    );
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
