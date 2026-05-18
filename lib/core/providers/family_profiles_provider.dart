import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/profile_provider.dart';

/// Family profiles — up to 4 kid name+age slots stored on this device.
///
/// Note: this is a "display profile" switcher. The active slot's name+age
/// drives the visible profile label (Stats screen, Edit Profile, certificate).
/// Achievements, coins, and skill data are SHARED across the device so all
/// kids' progress contributes to the same trophy room. This matches kid-safe
/// app conventions where one device serves one family without account
/// separation. The switcher is communicated as such in the UI copy.

class ProfileSlot {
  const ProfileSlot({
    required this.id,
    required this.name,
    required this.ageBand,
    required this.avatarEmoji,
    this.gender = Gender.unset,
    this.outfitId,
  });

  final int id;
  final String name;
  final String ageBand;
  final String avatarEmoji;

  /// Gender.boy | Gender.girl | Gender.unset. Drives gendered Arabic
  /// address forms (see `gendered_ar.dart`); unset → neutral forms.
  final String gender;

  /// Cosmetic accessory id (null = no outfit). Resolved against the outfit
  /// catalog at render time; missing/unknown ids degrade to no outfit.
  final String? outfitId;

  ProfileSlot copyWith({
    String? name,
    String? ageBand,
    String? avatarEmoji,
    String? gender,
    String? outfitId,
    bool clearOutfit = false,
  }) => ProfileSlot(
    id: id,
    name: name ?? this.name,
    ageBand: ageBand ?? this.ageBand,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    gender: gender ?? this.gender,
    outfitId: clearOutfit ? null : (outfitId ?? this.outfitId),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    'a': ageBand,
    'e': avatarEmoji,
    if (gender != Gender.unset) 'g': gender,
    if (outfitId != null) 'o': outfitId,
  };

  static ProfileSlot fromJson(Map<String, dynamic> m) => ProfileSlot(
    id: (m['id'] as num).toInt(),
    name: (m['n'] as String?) ?? '',
    ageBand: (m['a'] as String?) ?? '8-10',
    avatarEmoji: (m['e'] as String?) ?? '🦉',
    gender: Gender.normalize(m['g'] as String?),
    outfitId: m['o'] as String?,
  );
}

class FamilyProfilesState {
  const FamilyProfilesState({
    this.slots = const [
      ProfileSlot(id: 0, name: '', ageBand: '8-10', avatarEmoji: '🦉'),
    ],
    this.activeSlotId = 0,
  });

  final List<ProfileSlot> slots;
  final int activeSlotId;

  ProfileSlot get active =>
      slots.firstWhere((s) => s.id == activeSlotId, orElse: () => slots.first);

  FamilyProfilesState copyWith({List<ProfileSlot>? slots, int? activeSlotId}) =>
      FamilyProfilesState(
        slots: slots ?? this.slots,
        activeSlotId: activeSlotId ?? this.activeSlotId,
      );
}

const _kKey = 'family_profiles_v1';
const int _kMaxSlots = 4;

final familyProfilesProvider =
    AsyncNotifierProvider<FamilyProfilesNotifier, FamilyProfilesState>(
      FamilyProfilesNotifier.new,
      name: 'familyProfilesProvider',
    );

class FamilyProfilesNotifier extends AsyncNotifier<FamilyProfilesState> {
  SharedPreferences? _prefs;

  @override
  Future<FamilyProfilesState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) {
      // Bootstrap from existing single-profile state if available, so users
      // upgrading don't lose their name/age.
      final existing = ref.read(profileProvider).value;
      final slot = ProfileSlot(
        id: 0,
        name: existing?.displayName ?? '',
        ageBand: existing?.ageBand ?? '8-10',
        avatarEmoji: '🦉',
      );
      return FamilyProfilesState(slots: [slot], activeSlotId: 0);
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final list = (m['slots'] as List?) ?? const [];
      final slots = list
          .whereType<Map<String, dynamic>>()
          .map(ProfileSlot.fromJson)
          .toList();
      return FamilyProfilesState(
        slots: slots.isEmpty
            ? const [
                ProfileSlot(
                  id: 0,
                  name: '',
                  ageBand: '8-10',
                  avatarEmoji: '🦉',
                ),
              ]
            : slots,
        activeSlotId: (m['active'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const FamilyProfilesState();
    }
  }

  Future<void> _persist(FamilyProfilesState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(
      _kKey,
      jsonEncode({
        'slots': s.slots.map((e) => e.toJson()).toList(),
        'active': s.activeSlotId,
      }),
    );
    // Mirror active slot to the legacy single-profile provider so other
    // screens that read it keep working.
    final active = s.active;
    final notifier = ref.read(profileProvider.notifier);
    await notifier.setDisplayName(active.name);
    await notifier.setAgeBand(active.ageBand);
    await notifier.setGender(active.gender);
  }

  Future<void> addSlot({
    required String name,
    String ageBand = '8-10',
    String avatarEmoji = '🦊',
    String gender = Gender.unset,
  }) async {
    final cur = state.value ?? const FamilyProfilesState();
    if (cur.slots.length >= _kMaxSlots) return;
    final nextId =
        (cur.slots.map((s) => s.id).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    final newSlot = ProfileSlot(
      id: nextId,
      name: name.trim(),
      ageBand: ageBand,
      avatarEmoji: avatarEmoji,
      gender: Gender.normalize(gender),
    );
    await _persist(
      cur.copyWith(slots: [...cur.slots, newSlot], activeSlotId: nextId),
    );
  }

  Future<void> switchTo(int slotId) async {
    final cur = state.value ?? const FamilyProfilesState();
    if (!cur.slots.any((s) => s.id == slotId)) return;
    await _persist(cur.copyWith(activeSlotId: slotId));
  }

  Future<void> removeSlot(int slotId) async {
    final cur = state.value ?? const FamilyProfilesState();
    if (cur.slots.length <= 1) return;
    final remaining = cur.slots.where((s) => s.id != slotId).toList();
    final nextActive = cur.activeSlotId == slotId
        ? remaining.first.id
        : cur.activeSlotId;
    await _persist(
      FamilyProfilesState(slots: remaining, activeSlotId: nextActive),
    );
  }

  Future<void> updateSlot(
    int slotId, {
    String? name,
    String? ageBand,
    String? avatarEmoji,
    String? gender,
  }) async {
    final cur = state.value ?? const FamilyProfilesState();
    final updated = cur.slots
        .map(
          (s) => s.id == slotId
              ? s.copyWith(
                  name: name?.trim(),
                  ageBand: ageBand,
                  avatarEmoji: avatarEmoji,
                  gender: gender == null ? null : Gender.normalize(gender),
                )
              : s,
        )
        .toList();
    await _persist(cur.copyWith(slots: updated));
  }

  Future<void> replaceSlots(
    List<ProfileSlot> slots, {
    int? activeSlotId,
  }) async {
    final cur = state.value ?? const FamilyProfilesState();
    await _persist(
      FamilyProfilesState(
        slots: slots,
        activeSlotId: activeSlotId ?? cur.activeSlotId,
      ),
    );
  }
}
