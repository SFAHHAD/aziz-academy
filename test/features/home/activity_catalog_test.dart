import 'package:aziz_academy/features/home/activity_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Activity catalog integrity', () {
    test('every activity has a unique id', () {
      final ids = <String>{};
      final dups = <String>[];
      for (final a in kActivities) {
        if (!ids.add(a.id)) dups.add(a.id);
      }
      expect(dups, isEmpty,
          reason: 'duplicate activity IDs would confuse personalisation');
    });

    test('every activity has a non-empty route', () {
      for (final a in kActivities) {
        expect(a.route.trim(), isNotEmpty,
            reason: 'activity ${a.id} has empty route — would silently no-op');
        expect(a.route.startsWith('/'), isTrue,
            reason: 'activity ${a.id} route should start with /');
      }
    });

    test('every category has at least 3 activities', () {
      final counts = <ActivityCategory, int>{};
      for (final a in kActivities) {
        counts[a.category] = (counts[a.category] ?? 0) + 1;
      }
      for (final entry in counts.entries) {
        expect(entry.value, greaterThanOrEqualTo(3),
            reason: 'category ${entry.key.labelEn()} has only ${entry.value} '
                'activities — feels half-built');
      }
    });

    test('every featured activity remains discoverable in its category', () {
      final featured = kActivities.where((a) => a.featured).toList();
      expect(featured.length, greaterThanOrEqualTo(6),
          reason: 'Featured rail should curate at least 6 activities so '
              'discovery rotation has room to add picks');
      for (final a in featured) {
        final inCategory =
            activitiesByCategory(a.category).any((x) => x.id == a.id);
        expect(inCategory, isTrue,
            reason: 'featured activity ${a.id} must surface in its category tab');
      }
    });

    test('activityById round-trips for every entry', () {
      for (final a in kActivities) {
        expect(activityById(a.id)?.id, a.id);
      }
      expect(activityById('definitely-not-real'), isNull);
    });

    test('activity matches() finds Arabic and English independently', () {
      final cap = kActivities.firstWhere((a) => a.id == 'capitals');
      expect(cap.matches('Capital'), isTrue);
      expect(cap.matches('العواصم'), isTrue);
      expect(cap.matches('xyz-not-real'), isFalse);
      expect(cap.matches(''), isTrue, reason: 'empty query matches everything');
    });

    test('filterActivities respects category + query together', () {
      final mathOnly = filterActivities(category: ActivityCategory.math);
      expect(mathOnly, isNotEmpty);
      for (final a in mathOnly) {
        expect(a.category, ActivityCategory.math);
      }
      final mathSearch =
          filterActivities(category: ActivityCategory.math, query: 'sprint');
      expect(mathSearch.any((a) => a.id == 'math_sprint'), isTrue);
    });

    test('Arabic strings contain no stray Latin letters', () {
      // Latin letters in Arabic UI text mean a missed translation. Arabic
      // numerals and punctuation are fine; Latin a-z / A-Z are not.
      final latin = RegExp(r'[A-Za-z]');
      final offenders = <String>[];
      for (final a in kActivities) {
        if (latin.hasMatch(a.titleAr)) {
          offenders.add('${a.id}.titleAr="${a.titleAr}"');
        }
        if (latin.hasMatch(a.subtitleAr)) {
          offenders.add('${a.id}.subtitleAr="${a.subtitleAr}"');
        }
      }
      expect(offenders, isEmpty,
          reason: 'Arabic catalog text contains Latin letters: $offenders');
    });

    test('English strings contain no stray Arabic letters', () {
      // Conversely — Arabic letters in English UI text would render in the
      // wrong font and break alignment for English-locale kids.
      final arabic = RegExp(r'[؀-ۿ]');
      final offenders = <String>[];
      for (final a in kActivities) {
        if (arabic.hasMatch(a.titleEn)) {
          offenders.add('${a.id}.titleEn="${a.titleEn}"');
        }
        if (arabic.hasMatch(a.subtitleEn)) {
          offenders.add('${a.id}.subtitleEn="${a.subtitleEn}"');
        }
      }
      expect(offenders, isEmpty,
          reason: 'English catalog text contains Arabic letters: $offenders');
    });

    test('every activity has a non-empty bilingual pair', () {
      for (final a in kActivities) {
        expect(a.titleEn.trim(), isNotEmpty,
            reason: '${a.id} missing English title');
        expect(a.titleAr.trim(), isNotEmpty,
            reason: '${a.id} missing Arabic title');
        expect(a.subtitleEn.trim(), isNotEmpty,
            reason: '${a.id} missing English subtitle');
        expect(a.subtitleAr.trim(), isNotEmpty,
            reason: '${a.id} missing Arabic subtitle');
        expect(a.emoji.trim(), isNotEmpty,
            reason: '${a.id} missing emoji');
      }
    });
  });
}
