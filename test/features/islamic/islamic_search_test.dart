import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/islamic_search/islamic_search.dart';

void main() {
  group('indexers extract searchable text', () {
    test('hadith indexer concatenates fields and lowercases', () {
      final hit = indexHadith({
        'id': 'hdt_001',
        'title': 'Smile is charity',
        'title_ar': 'التبسم صدقة',
        'ar': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
        'translation': 'Your smile to your brother is charity for you.',
        'translation_ar': 'تبسّمك في وجه أخيك صدقة لك.',
        'lesson': 'Kindness counts as worship.',
        'lesson_ar': 'اللطف عبادة.',
        'category': 'Manners',
      });
      expect(hit.section, SearchSection.hadith);
      expect(hit.id, 'hdt_001');
      expect(hit.titleEn, 'Smile is charity');
      expect(hit.searchableText, contains('smile'));
      expect(hit.searchableText, contains('kindness'));
      expect(hit.searchableText, contains('صدقة')); // arabic word preserved
    });

    test('asma indexer keys on n', () {
      final hit = indexAsmaName({
        'n': 1,
        'name_ar': 'الرحمن',
        'name': 'Ar-Rahman',
        'en': 'The Most Merciful',
        'en_ar': 'الرحمن',
      });
      expect(hit.section, SearchSection.asma);
      expect(hit.id, '1');
      expect(hit.searchableText, contains('rahman'));
      expect(hit.searchableText, contains('merciful'));
    });

    test('prophet indexer prefers lesson as snippet', () {
      final hit = indexProphet({
        'id': 'p01',
        'name': 'Adam',
        'name_ar': 'آدم',
        'story': 'Adam was the first human.',
        'story_ar': 'كان آدم أول إنسان.',
        'lesson': 'Ask for forgiveness right away.',
        'lesson_ar': 'استغفر فورًا.',
      });
      expect(hit.snippetEn, 'Ask for forgiveness right away.');
      expect(hit.searchableText, contains('adam'));
      expect(hit.searchableText, contains('forgiveness'));
    });

    test('dua indexer falls back to occasion if translation missing', () {
      final hit = indexDua({
        'id': 'dua_x',
        'title': 'Before Sleep',
        'title_ar': 'قبل النوم',
        'ar': 'باسمك اللهم أموت وأحيا',
        'translation': '',
        'occasion': 'Said when going to bed',
        'occasion_ar': 'تقال عند النوم',
      });
      expect(hit.snippetEn, 'Said when going to bed');
    });

    test('tolerates missing fields with sensible defaults', () {
      final hit = indexHadith({'id': 'x'});
      expect(hit.titleEn, '');
      // searchableText is the space-joined concatenation of empty fields,
      // so it's a string of spaces — trim before asserting emptiness.
      expect(hit.searchableText.trim(), '');
    });
  });

  group('runSearch', () {
    final index = [
      indexHadith({
        'id': 'hdt_001',
        'title': 'Smile is charity',
        'translation': 'Your smile is charity for you.',
        'category': 'Manners',
      }),
      indexAsmaName({
        'n': 1,
        'name': 'Ar-Rahman',
        'en': 'The Most Merciful',
      }),
      indexProphet({
        'id': 'p01',
        'name': 'Adam',
        'lesson': 'Always ask forgiveness when you make a mistake.',
      }),
      indexDua({
        'id': 'dua_eat_before',
        'title': 'Before Eating',
        'translation': 'In the name of Allah.',
      }),
    ];

    test('empty query returns no hits (not full index)', () {
      expect(runSearch(index, ''), isEmpty);
      expect(runSearch(index, '   '), isEmpty);
    });

    test('matches case-insensitively', () {
      final hits = runSearch(index, 'SMILE');
      expect(hits.length, 1);
      expect(hits.first.id, 'hdt_001');
    });

    test('substring matches snippet text', () {
      final hits = runSearch(index, 'forgiveness');
      expect(hits.length, 1);
      expect(hits.first.section, SearchSection.prophet);
    });

    test('matches across sections', () {
      // "the" matches Ar-Rahman ("The Most Merciful"), the dua
      // ("In the name of Allah"), and the hadith ("charity for")
      final hits = runSearch(index, 'the');
      final sections = hits.map((h) => h.section).toSet();
      expect(sections.length, greaterThanOrEqualTo(2));
    });

    test('no-match query returns empty', () {
      expect(runSearch(index, 'zzzzz_no_such_word'), isEmpty);
    });
  });

  group('groupBySection', () {
    test('preserves order within each group', () {
      final hits = [
        indexHadith({'id': 'h1', 'title': 'A', 'translation': 'A'}),
        indexAsmaName({'n': 1, 'name': 'B', 'en': 'B'}),
        indexHadith({'id': 'h2', 'title': 'A', 'translation': 'A'}),
      ];
      final grouped = groupBySection(hits);
      expect(grouped[SearchSection.hadith]!.map((h) => h.id).toList(),
          ['h1', 'h2']);
      expect(grouped[SearchSection.asma]!.length, 1);
    });
  });
}
