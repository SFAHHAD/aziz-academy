import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/tasbih_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Digital tasbih (dhikr counter) — tap-the-bead loop. Tracks current count,
/// rings on hitting the target (33/100/etc.), persists lifetime total. Pure
/// on-device, no notifications, no permissions.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> {
  static const _phrases = <_Phrase>[
    _Phrase(
      id: 'subhanallah',
      ar: 'سُبْحَانَ اللَّهِ',
      en: 'SubhanAllah',
      meaning: 'Glory to Allah',
      meaningAr: 'تنزيه الله عن النقص',
    ),
    _Phrase(
      id: 'alhamdulillah',
      ar: 'الْحَمْدُ لِلَّهِ',
      en: 'Alhamdulillah',
      meaning: 'Praise be to Allah',
      meaningAr: 'الحمد لله',
    ),
    _Phrase(
      id: 'allahu_akbar',
      ar: 'اللَّهُ أَكْبَرُ',
      en: 'Allahu Akbar',
      meaning: 'Allah is the Greatest',
      meaningAr: 'الله أكبر',
    ),
    _Phrase(
      id: 'la_ilaha',
      ar: 'لَا إِلَهَ إِلَّا اللَّهُ',
      en: 'La ilaha illa Allah',
      meaning: 'No deity except Allah',
      meaningAr: 'لا إله إلا الله',
    ),
    _Phrase(
      id: 'astaghfirullah',
      ar: 'أَسْتَغْفِرُ اللَّهَ',
      en: 'Astaghfirullah',
      meaning: 'I seek forgiveness from Allah',
      meaningAr: 'أستغفر الله',
    ),
  ];

  void _tap() {
    HapticFeedback.lightImpact();
    ref.read(tasbihProvider.notifier).tap();
  }

  Future<void> _editTarget() async {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final cur = ref.read(tasbihProvider).value;
    int? picked = cur?.target;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'الهدف' : 'Target'),
        content: Wrap(
          spacing: 8,
          children: [
            for (final v in [33, 99, 100, 1000])
              ChoiceChip(
                label: Text(localizeDigits(v, arabic: isAr)),
                selected: picked == v,
                onSelected: (_) => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
    if (result != null) {
      await ref.read(tasbihProvider.notifier).setTarget(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final t = ref.watch(tasbihProvider).value ?? const TasbihState();
    final phrase = _phrases.firstWhere(
      (p) => p.id == t.phrase,
      orElse: () => _phrases.first,
    );
    final progress = t.target == 0
        ? 0.0
        : (t.count / t.target).clamp(0, 1).toDouble();
    final hit = t.count >= t.target && t.target > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'تسبيح' : 'Tasbih'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_rounded),
            tooltip: isAr ? 'الهدف' : 'Target',
            onPressed: _editTarget,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isAr ? 'إعادة' : 'Reset',
            onPressed: () => ref.read(tasbihProvider.notifier).reset(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final p in _phrases)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(p.en),
                          selected: t.phrase == p.id,
                          onSelected: (_) =>
                              ref.read(tasbihProvider.notifier).setPhrase(p.id),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withAlpha(120)),
                ),
                child: Column(
                  children: [
                    Text(
                      phrase.ar,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.textDark,
                        fontSize: 28,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? phrase.meaningAr : phrase.meaning,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark.withAlpha(180),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TtsSpeakerIcon(text: phrase.ar),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _tap,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            hit
                                ? AppColors.success.withAlpha(180)
                                : AppColors.accent.withAlpha(140),
                            hit
                                ? AppColors.success.withAlpha(80)
                                : AppColors.accent.withAlpha(50),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hit ? AppColors.success : AppColors.accent,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          localizeDigits(t.count, arabic: isAr),
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.textDark,
                            fontSize: 64,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: hit ? AppColors.success : AppColors.accent,
                  backgroundColor: AppColors.outline.withAlpha(60),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'الهدف: ${localizeDigits(t.target, arabic: true)} • المجموع: ${localizeDigits(t.totalLifetime, arabic: true)}'
                    : 'Target: ${t.target} • Lifetime: ${t.totalLifetime}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark.withAlpha(180),
                ),
              ),
              const SizedBox(height: 8),
              if (hit)
                Text(
                  isAr ? '🎉 وصلتَ الهدف' : '🎉 Target reached',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Phrase {
  const _Phrase({
    required this.id,
    required this.ar,
    required this.en,
    required this.meaning,
    required this.meaningAr,
  });
  final String id;
  final String ar;
  final String en;
  final String meaning;
  final String meaningAr;
}
