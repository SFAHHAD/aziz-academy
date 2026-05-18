import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/l10n/gendered_ar.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';

void main() {
  const boy = GenderedAr(Gender.boy);
  const girl = GenderedAr(Gender.girl);
  const unset = GenderedAr(Gender.unset);

  test('boy gets masculine forms', () {
    expect(boy.isBoy, isTrue);
    expect(boy.explorer, 'مُكتشِف');
    expect(boy.champion, 'بطل');
    expect(boy.smart, 'ذكي');
    expect(boy.wellDone, 'أحسنتَ');
    expect(boy.keepGoing, 'واصِل');
    expect(boy.genderEmoji, '👦');
  });

  test('girl gets feminine forms', () {
    expect(girl.isGirl, isTrue);
    expect(girl.explorer, 'مُكتشِفة');
    expect(girl.champion, 'بطلة');
    expect(girl.smart, 'ذكية');
    expect(girl.wellDone, 'أحسنتِ');
    expect(girl.keepGoing, 'واصِلي');
    expect(girl.genderEmoji, '👧');
  });

  test('unset uses neutral / default forms', () {
    expect(unset.isSet, isFalse);
    // Verb with no diacritic — acceptable to a reader of either gender.
    expect(unset.wellDone, 'أحسنت');
    // Nouns default to the generic masculine.
    expect(unset.champion, 'بطل');
    expect(unset.genderEmoji, '🧒');
  });

  test('boy and girl forms are always distinct for gendered words', () {
    expect(boy.explorer, isNot(girl.explorer));
    expect(boy.champion, isNot(girl.champion));
    expect(boy.wellDone, isNot(girl.wellDone));
    expect(boy.youAreAStar, isNot(girl.youAreAStar));
    expect(boy.ready, isNot(girl.ready));
  });

  test('GenderedAr.of reads a ProfileState', () {
    expect(
      GenderedAr.of(const ProfileState(gender: Gender.girl)).champion,
      'بطلة',
    );
    expect(GenderedAr.of(null).gender, Gender.unset);
  });

  test('genderLabelEn', () {
    expect(genderLabelEn(Gender.boy), 'Boy');
    expect(genderLabelEn(Gender.girl), 'Girl');
    expect(genderLabelEn(Gender.unset), 'Not set');
    expect(genderLabelEn('garbage'), 'Not set');
  });
}
