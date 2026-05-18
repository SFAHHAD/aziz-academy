import 'package:aziz_academy/core/providers/profile_provider.dart';

/// Gendered Arabic address forms.
///
/// Arabic second-person address inflects with the addressee's gender —
/// verbs, adjectives and nouns all change. Greeting a girl with masculine
/// forms ("يا بطل", "أحسنتَ") reads as a plain mistake to an Arabic-speaking
/// child, and vice-versa. These helpers resolve the right form from the
/// kid's profile gender.
///
/// When [gender] is [Gender.unset] the forms fall back to the conventional
/// Arabic default: the masculine for gendered *nouns* (which is also the
/// generic form), and the diacritic-free spelling for *verbs* (e.g.
/// `أحسنت` with no fatha/kasra, which a reader of either gender accepts).
///
/// English is not gendered in second person, so callers only need this on
/// the Arabic path.
class GenderedAr {
  const GenderedAr(this.gender);

  /// Convenience constructor from a [ProfileState].
  GenderedAr.of(ProfileState? profile)
    : gender = Gender.normalize(profile?.gender);

  final String gender;

  bool get isBoy => gender == Gender.boy;
  bool get isGirl => gender == Gender.girl;
  bool get isSet => gender != Gender.unset;

  /// "explorer" — the friendly pet name used before the kid enters a name.
  String get explorer => isGirl ? 'مُكتشِفة' : 'مُكتشِف';

  /// "champion / hero" — the headline title on the profile card.
  String get champion => isGirl ? 'بطلة' : 'بطل';

  /// "little learner" — softer title for younger kids.
  String get learner => isGirl ? 'متعلِّمة' : 'متعلِّم';

  /// "smart / clever".
  String get smart => isGirl ? 'ذكية' : 'ذكي';

  /// "wonderful / great".
  String get wonderful => isGirl ? 'رائعة' : 'رائع';

  /// "ready".
  String get ready => isGirl ? 'مُستعِدة' : 'مُستعِد';

  /// "active / hard-working".
  String get active => isGirl ? 'نشيطة' : 'نشيط';

  /// "proud" — as in "we are proud of you".
  String get proud => isGirl ? 'فخورون بكِ' : 'فخورون بكَ';

  /// "you did well" — second-person praise verb.
  String get wellDone => isBoy
      ? 'أحسنتَ'
      : isGirl
      ? 'أحسنتِ'
      : 'أحسنت';

  /// "keep going" — second-person imperative.
  String get keepGoing => isGirl ? 'واصِلي' : 'واصِل';

  /// "you can do it" — encouragement sentence.
  String get youCanDoIt => isGirl ? 'تستطيعينَ ذلك!' : 'تستطيعُ ذلك!';

  /// "you are a star".
  String get youAreAStar => isGirl ? 'أنتِ نجمة' : 'أنتَ نجم';

  /// Greeting verb "welcome" + correct pronoun ("welcome to you").
  String get welcomeYou => isGirl ? 'أهلاً بكِ' : 'أهلاً بكَ';

  /// A gendered display label for the gender itself — "Boy" / "Girl".
  String get genderLabel => isBoy
      ? 'ولد'
      : isGirl
      ? 'بنت'
      : 'غير محدّد';

  /// Emoji that matches the gender; neutral star when unset.
  String get genderEmoji => isBoy
      ? '👦'
      : isGirl
      ? '👧'
      : '🧒';
}

/// English label for a gender string — used on the (non-gendered) English
/// UI path so the profile card still shows the chosen value.
String genderLabelEn(String gender) {
  switch (Gender.normalize(gender)) {
    case Gender.boy:
      return 'Boy';
    case Gender.girl:
      return 'Girl';
    default:
      return 'Not set';
  }
}
