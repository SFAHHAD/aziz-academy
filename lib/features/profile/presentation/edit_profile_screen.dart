import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/cosmetics_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/widgets/gender_picker.dart';
import 'package:aziz_academy/core/widgets/responsive.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  String _band = '8-10';
  String _gender = Gender.unset;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).value;
    if (p != null) {
      _name.text = p.displayName;
      _band = p.ageBand;
      _gender = p.gender;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).setDisplayName(_name.text);
    await ref.read(profileProvider.notifier).setAgeBand(_band);
    await ref.read(profileProvider.notifier).setGender(_gender);
    // Keep the active family slot in sync so the profile card and the
    // family switcher show the same name / age / gender.
    final active = ref.read(familyProfilesProvider).value?.activeSlotId;
    if (active != null) {
      await ref
          .read(familyProfilesProvider.notifier)
          .updateSlot(
            active,
            name: _name.text,
            ageBand: _band,
            gender: _gender,
          );
    }
    if (mounted) context.go(AppRoutes.profileCard);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final cos = ref.watch(cosmeticsProvider).value;
    final equippedAvatar = _avatarEmojiFor(cos?.equippedAvatar ?? 'av_owl');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CenteredBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
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
                    Expanded(
                      child: Text(
                        isArabic ? 'تعديل الملف' : 'Edit profile',
                        style: AppTextStyles.headingMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerLow,
                      border: Border.all(color: AppColors.secondary, width: 3),
                    ),
                    child: Text(
                      equippedAvatar,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push(AppRoutes.shop),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(isArabic ? 'غيّر الأفاتار' : 'Change avatar'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'الاسم' : 'Name',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'اسمك مثل: عزيز'
                        : 'Your name (e.g. Aziz)',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLength: 20,
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'الفئة العمرية' : 'Age band',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const ['6-8', '8-10', '10-12'].map((b) {
                    final sel = b == _band;
                    return GestureDetector(
                      onTap: () => setState(() => _band = b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.secondary
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          b,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: sel
                                ? AppColors.background
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'ولد أم بنت؟' : 'Boy or girl?',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                GenderPicker(
                  value: _gender,
                  arabic: isArabic,
                  onChanged: (g) => setState(() => _gender = g),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'نستخدمها لمخاطبتك بالشكل الصحيح بالعربية.'
                      : 'Used so Arabic greetings address you correctly.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isArabic
                        ? 'الاسم يُحفظ على هذا الجهاز فقط ولا يُرسل لأي مكان.'
                        : 'Your name stays on this device only — never uploaded.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(isArabic ? 'حفظ' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _avatarEmojiFor(String id) {
    switch (id) {
      case 'av_fox':
        return '🦊';
      case 'av_panda':
        return '🐼';
      case 'av_dragon':
        return '🐲';
      case 'av_robot':
        return '🤖';
      case 'av_unicorn':
        return '🦄';
      case 'av_astronaut':
        return '👨‍🚀';
      case 'av_wizard':
        return '🧙';
      default:
        return '🦉';
    }
  }
}
