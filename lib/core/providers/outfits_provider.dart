import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cosmetic outfits the kid can buy with coins and equip on their avatar
/// emoji. Pure visual — no gameplay effect, kid-safe, on-device only.
@immutable
class OutfitDef {
  const OutfitDef({
    required this.id,
    required this.label,
    required this.labelAr,
    required this.glyph,
    required this.cost,
  });

  final String id;
  final String label;
  final String labelAr;

  /// A single emoji rendered as a small badge on the avatar pill (top-right).
  final String glyph;

  final int cost;
}

const List<OutfitDef> kOutfits = [
  OutfitDef(
    id: 'crown',
    label: 'Royal crown',
    labelAr: 'تاج ملكي',
    glyph: '👑',
    cost: 200,
  ),
  OutfitDef(
    id: 'cape',
    label: 'Hero cape',
    labelAr: 'عباءة البطل',
    glyph: '🦸',
    cost: 150,
  ),
  OutfitDef(
    id: 'wizard_hat',
    label: 'Wizard hat',
    labelAr: 'قبعة الساحر',
    glyph: '🧙',
    cost: 150,
  ),
  OutfitDef(
    id: 'glasses',
    label: 'Smart glasses',
    labelAr: 'نظارات ذكية',
    glyph: '🤓',
    cost: 80,
  ),
  OutfitDef(
    id: 'medal',
    label: 'Gold medal',
    labelAr: 'ميدالية ذهبية',
    glyph: '🥇',
    cost: 120,
  ),
  OutfitDef(
    id: 'rocket',
    label: 'Rocket pack',
    labelAr: 'حقيبة صاروخية',
    glyph: '🚀',
    cost: 250,
  ),
];

OutfitDef? outfitById(String? id) {
  if (id == null) return null;
  for (final o in kOutfits) {
    if (o.id == id) return o;
  }
  return null;
}

const String _kOwnedKey = 'outfits_owned_v1';

final ownedOutfitsProvider =
    AsyncNotifierProvider<OwnedOutfitsNotifier, Set<String>>(
      OwnedOutfitsNotifier.new,
    );

class OwnedOutfitsNotifier extends AsyncNotifier<Set<String>> {
  SharedPreferences? _prefs;

  @override
  Future<Set<String>> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    return (_prefs!.getStringList(_kOwnedKey) ?? const []).toSet();
  }

  Future<void> markOwned(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? const <String>{};
    if (cur.contains(id)) return;
    final next = {...cur, id};
    state = AsyncData(next);
    await _prefs!.setStringList(_kOwnedKey, next.toList());
  }

  Future<void> resetAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    state = const AsyncData(<String>{});
    await _prefs!.remove(_kOwnedKey);
  }
}
