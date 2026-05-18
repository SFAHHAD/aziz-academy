import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/gender_picker.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Family pass-and-play — kid + sibling slots on the same device. Lets the
/// active profile name + age band be switched without re-entering details.
/// Achievements, coins, and progress are SHARED across slots (one device →
/// one trophy room) — communicated transparently in the screen copy.
class FamilyProfilesScreen extends ConsumerWidget {
  const FamilyProfilesScreen({super.key});

  static const _avatarOptions = ['🦉', '🦊', '🐼', '🐲', '🤖', '🦄'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final familyAsync = ref.watch(familyProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: familyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  isArabic
                      ? 'تعذّر تحميل البطاقات.'
                      : 'Could not load profiles.',
                ),
              ),
              data: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: context.l10n.commonBack,
                          onPressed: () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '👨‍👩‍👧‍👦',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic ? 'وضع العائلة' : 'Family Profiles',
                            style: AppTextStyles.headingMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isArabic
                            ? 'بدّل بين بطاقات إخوتك. الإنجازات والعملات والشارات مشتركة بين الجميع على هذا الجهاز.'
                            : 'Switch between sibling profiles. Achievements, coins, and badges are shared across everyone on this device.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final slot in state.slots)
                      _SlotCard(
                        slot: slot,
                        active: slot.id == state.activeSlotId,
                        canRemove: state.slots.length > 1,
                        arabic: isArabic,
                        onTap: () => ref
                            .read(familyProfilesProvider.notifier)
                            .switchTo(slot.id),
                        onEdit: () =>
                            _showEditSheet(context, ref, slot, isArabic),
                        onRemove: () => ref
                            .read(familyProfilesProvider.notifier)
                            .removeSlot(slot.id),
                      ),
                    if (state.slots.length < 4) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showAddSheet(context, ref, isArabic),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          isArabic ? 'إضافة بطاقة جديدة' : 'Add new profile',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    bool arabic,
  ) async {
    String name = '';
    String age = '8-10';
    String emoji = '🦊';
    String gender = Gender.unset;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      arabic ? 'بطاقة جديدة' : 'New profile',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: arabic ? 'الاسم' : 'Name',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => name = v,
                      maxLength: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      arabic ? 'الفئة العمرية' : 'Age band',
                      style: AppTextStyles.labelMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      children: ['6-8', '8-10', '10-12'].map((b) {
                        return ChoiceChip(
                          label: Text(b),
                          selected: age == b,
                          onSelected: (_) => setSt(() => age = b),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      arabic ? 'الأفاتار' : 'Avatar',
                      style: AppTextStyles.labelMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      children: _avatarOptions.map((e) {
                        final sel = e == emoji;
                        return GestureDetector(
                          onTap: () => setSt(() => emoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.secondary.withAlpha(60)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: sel
                                    ? AppColors.secondary
                                    : AppColors.glassBorder,
                              ),
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      arabic ? 'ولد أم بنت' : 'Boy or girl',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    GenderPicker(
                      value: gender,
                      arabic: arabic,
                      compact: true,
                      onChanged: (g) => setSt(() => gender = g),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (name.trim().isEmpty) return;
                        await ref
                            .read(familyProfilesProvider.notifier)
                            .addSlot(
                              name: name,
                              ageBand: age,
                              avatarEmoji: emoji,
                              gender: gender,
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text(arabic ? 'إضافة' : 'Add'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    ProfileSlot slot,
    bool arabic,
  ) async {
    final controller = TextEditingController(text: slot.name);
    String age = slot.ageBand;
    String emoji = slot.avatarEmoji;
    String gender = slot.gender;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      arabic ? 'تعديل البطاقة' : 'Edit profile',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: arabic ? 'الاسم' : 'Name',
                        border: const OutlineInputBorder(),
                      ),
                      maxLength: 20,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['6-8', '8-10', '10-12'].map((b) {
                        return ChoiceChip(
                          label: Text(b),
                          selected: age == b,
                          onSelected: (_) => setSt(() => age = b),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _avatarOptions.map((e) {
                        final sel = e == emoji;
                        return GestureDetector(
                          onTap: () => setSt(() => emoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.secondary.withAlpha(60)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: sel
                                    ? AppColors.secondary
                                    : AppColors.glassBorder,
                              ),
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      arabic ? 'ولد أم بنت' : 'Boy or girl',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    GenderPicker(
                      value: gender,
                      arabic: arabic,
                      compact: true,
                      onChanged: (g) => setSt(() => gender = g),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(familyProfilesProvider.notifier)
                            .updateSlot(
                              slot.id,
                              name: controller.text,
                              ageBand: age,
                              avatarEmoji: emoji,
                              gender: gender,
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text(arabic ? 'حفظ' : 'Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }
}

String _genderEmoji(String g) => g == Gender.boy
    ? '👦'
    : g == Gender.girl
    ? '👧'
    : '';

String _genderText(String g, bool arabic) => g == Gender.boy
    ? (arabic ? 'ولد' : 'Boy')
    : g == Gender.girl
    ? (arabic ? 'بنت' : 'Girl')
    : '';

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.active,
    required this.canRemove,
    required this.arabic,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
  });

  final ProfileSlot slot;
  final bool active;
  final bool canRemove;
  final bool arabic;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: active
            ? AppColors.secondary.withAlpha(50)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AppColors.secondary : AppColors.glassBorder,
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Text(slot.avatarEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.name.isEmpty
                        ? (arabic ? 'بدون اسم' : 'Unnamed')
                        : slot.name,
                    style: AppTextStyles.headingSmall,
                  ),
                  Text(
                    slot.gender == Gender.unset
                        ? slot.ageBand
                        : '${slot.ageBand}  ·  '
                              '${_genderEmoji(slot.gender)} '
                              '${_genderText(slot.gender, arabic)}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '✓',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: arabic ? 'تعديل' : 'Edit',
              onPressed: onEdit,
            ),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                tooltip: arabic ? 'حذف' : 'Remove',
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
