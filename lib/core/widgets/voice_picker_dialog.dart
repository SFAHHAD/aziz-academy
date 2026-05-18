import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/tts_service.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// A bottom sheet listing every TTS voice installed on the device for a given
/// language family, with a "preview" button so the parent can audition each
/// voice and pick the one they prefer. Persists the choice to AppSettings —
/// `null` means "use auto-pick".
///
/// Honest disclosure: on Flutter web we are bound to the Web Speech API,
/// which on most browsers exposes only the OS's installed voices. Quality
/// varies wildly. This picker lets the user pick the best of what's there;
/// it can't synthesize a new voice.
class VoicePickerSheet extends ConsumerStatefulWidget {
  const VoicePickerSheet({super.key, required this.arabic});
  final bool arabic;

  @override
  ConsumerState<VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends ConsumerState<VoicePickerSheet> {
  List<Map<String, String>> _voices = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tts = ref.read(ttsServiceProvider);
    final all = await tts.availableVoices();
    final prefix = widget.arabic ? 'ar' : 'en';
    final filtered = all
        .where(
          (v) => (v['locale'] ?? '').toLowerCase().startsWith(prefix),
        )
        .toList();
    if (mounted) {
      setState(() {
        _voices = filtered;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final settings = ref.watch(appSettingsProvider).value;
    final notifier = ref.read(appSettingsProvider.notifier);
    final selected =
        widget.arabic ? settings?.preferredArVoice : settings?.preferredEnVoice;

    final headingText = widget.arabic
        ? (isAr ? 'صوت اللغة العربية' : 'Arabic voice')
        : (isAr ? 'صوت اللغة الإنجليزية' : 'English voice');

    final previewText = widget.arabic
        ? 'بسم الله الرحمن الرحيم'
        : 'Hello, this is your selected voice.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.outline.withAlpha(160),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              headingText,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAr
                  ? 'اختر الصوت الذي تفضله. اضغط ▶︎ للاستماع قبل الحفظ.'
                  : 'Pick the voice you prefer. Tap ▶︎ to preview before saving.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark.withAlpha(180),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            // Most users don't realise the OS itself ships better voices
            // that the Web Speech API can use — surface the tip so they
            // can upgrade once instead of being stuck with the legacy SAPI
            // / eSpeak voices forever.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withAlpha(80)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'تلميح: لتحسين الأصوات بشكل كبير، ثبّت الأصوات الطبيعية من نظامك:\n'
                              '• ويندوز ١١: الإعدادات > الوقت واللغة > الكلام > أضف الصوت العربي (Salma / Hamed / Naayf).\n'
                              '• ماك: الإعدادات > إمكانية الوصول > النطق > الصوت > "Majed (Enhanced)".\n'
                              '• أندرويد: الإعدادات > التطبيقات > Google > تنزيل صوت Arabic Natural.\n'
                              '• آيفون: الإعدادات > إمكانية الوصول > المحتوى المنطوق > الأصوات > Maged (Enhanced).'
                          : 'Tip — your OS likely has much better voices you can install:\n'
                              '• Windows 11: Settings > Time & language > Speech > Add Arabic voices (Salma / Hamed / Naayf).\n'
                              '• Mac: Settings > Accessibility > Spoken Content > System Voice > pick "Enhanced".\n'
                              '• Android: Settings > Apps > Google > Download Arabic Natural voice.\n'
                              '• iOS: Settings > Accessibility > Spoken Content > Voices > Maged (Enhanced).',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_voices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  isAr
                      ? 'لا تتوفر أصوات لهذه اللغة على هذا الجهاز.'
                      : 'No voices for this language are installed on this device.',
                  style: AppTextStyles.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _voices.length + 1,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      final isAuto = selected == null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isAuto
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isAuto
                              ? AppColors.accent
                              : AppColors.textDark.withAlpha(140),
                        ),
                        title: Text(
                          isAr
                              ? 'تلقائي (الأفضل المتاح)'
                              : 'Auto (best available)',
                        ),
                        onTap: () async {
                          if (widget.arabic) {
                            await notifier.setPreferredArVoice(null);
                          } else {
                            await notifier.setPreferredEnVoice(null);
                          }
                        },
                      );
                    }
                    final v = _voices[i - 1];
                    final name = v['name'] ?? '';
                    final locale = v['locale'] ?? '';
                    final isSelected = selected == name;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textDark.withAlpha(140),
                      ),
                      onTap: () async {
                        if (widget.arabic) {
                          await notifier.setPreferredArVoice(name);
                        } else {
                          await notifier.setPreferredEnVoice(name);
                        }
                      },
                      title: Text(
                        name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        locale,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textDark.withAlpha(150),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: isAr ? 'استمع' : 'Preview',
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        onPressed: () async {
                          // Temporarily swap to this voice, speak, then
                          // restore. try/finally guards against a leaked
                          // override if speak throws or the sheet is
                          // closed mid-preview.
                          final tts = ref.read(ttsServiceProvider);
                          final saved = ref.read(appSettingsProvider).value;
                          final savedAr = saved?.preferredArVoice;
                          final savedEn = saved?.preferredEnVoice;
                          try {
                            if (widget.arabic) {
                              tts.setPreferredVoices(
                                arabicVoiceName: name,
                                englishVoiceName: savedEn,
                              );
                              await tts.previewVoice(previewText, arabic: true);
                            } else {
                              tts.setPreferredVoices(
                                arabicVoiceName: savedAr,
                                englishVoiceName: name,
                              );
                              await tts.previewVoice(previewText, arabic: false);
                            }
                          } finally {
                            tts.setPreferredVoices(
                              arabicVoiceName: savedAr,
                              englishVoiceName: savedEn,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAr ? 'تم' : 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showVoicePickerSheet(BuildContext context,
    {required bool arabic}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.7,
      child: VoicePickerSheet(arabic: arabic),
    ),
  );
}
