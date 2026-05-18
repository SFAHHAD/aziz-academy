// Pure search-logic for the Islamic content search screen. Indexes
// four content packs (Hadith, 99 Names, Prophets, Duas) into a flat
// list of [SearchHit]s, then does bilingual case-insensitive substring
// match. Kept out of the widget so the matching rules are unit-testable.

enum SearchSection { hadith, asma, prophet, dua }

class SearchHit {
  const SearchHit({
    required this.section,
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.snippetEn,
    required this.snippetAr,
    required this.searchableText,
  });

  final SearchSection section;
  final String id;
  final String titleEn;
  final String titleAr;
  final String snippetEn;
  final String snippetAr;

  /// Concatenation of every text field we want the query to match
  /// against. Pre-lowercased.
  final String searchableText;
}

/// Build an index entry for one hadith record.
SearchHit indexHadith(Map<String, dynamic> j) {
  final ar = (j['ar'] as String?) ?? '';
  final translation = (j['translation'] as String?) ?? '';
  final title = (j['title'] as String?) ?? '';
  final titleAr = (j['title_ar'] as String?) ?? '';
  final translationAr = (j['translation_ar'] as String?) ?? '';
  final lesson = (j['lesson'] as String?) ?? '';
  final lessonAr = (j['lesson_ar'] as String?) ?? '';
  return SearchHit(
    section: SearchSection.hadith,
    id: (j['id'] as String?) ?? '',
    titleEn: title,
    titleAr: titleAr,
    snippetEn: translation,
    snippetAr: translationAr,
    searchableText: [
      title,
      titleAr,
      ar,
      translation,
      translationAr,
      lesson,
      lessonAr,
    ].join(' ').toLowerCase(),
  );
}

SearchHit indexAsmaName(Map<String, dynamic> j) {
  final nameAr = (j['name_ar'] as String?) ?? '';
  final name = (j['name'] as String?) ?? '';
  final en = (j['en'] as String?) ?? '';
  final enAr = (j['en_ar'] as String?) ?? '';
  return SearchHit(
    section: SearchSection.asma,
    id: (j['n']?.toString()) ?? '',
    titleEn: name,
    titleAr: nameAr,
    snippetEn: en,
    snippetAr: enAr,
    searchableText: [name, nameAr, en, enAr].join(' ').toLowerCase(),
  );
}

SearchHit indexProphet(Map<String, dynamic> j) {
  final name = (j['name'] as String?) ?? '';
  final nameAr = (j['name_ar'] as String?) ?? '';
  final story = (j['story'] as String?) ?? '';
  final storyAr = (j['story_ar'] as String?) ?? '';
  final lesson = (j['lesson'] as String?) ?? '';
  final lessonAr = (j['lesson_ar'] as String?) ?? '';
  final title = (j['title'] as String?) ?? '';
  final titleAr = (j['title_ar'] as String?) ?? '';
  return SearchHit(
    section: SearchSection.prophet,
    id: (j['id'] as String?) ?? '',
    titleEn: name,
    titleAr: nameAr,
    snippetEn: lesson.isNotEmpty ? lesson : title,
    snippetAr: lessonAr.isNotEmpty ? lessonAr : titleAr,
    searchableText: [
      name,
      nameAr,
      title,
      titleAr,
      story,
      storyAr,
      lesson,
      lessonAr,
    ].join(' ').toLowerCase(),
  );
}

SearchHit indexDua(Map<String, dynamic> j) {
  final title = (j['title'] as String?) ?? '';
  final titleAr = (j['title_ar'] as String?) ?? '';
  final ar = (j['ar'] as String?) ?? '';
  final translation = (j['translation'] as String?) ?? '';
  final translationAr = (j['translation_ar'] as String?) ?? '';
  final occasion = (j['occasion'] as String?) ?? '';
  final occasionAr = (j['occasion_ar'] as String?) ?? '';
  return SearchHit(
    section: SearchSection.dua,
    id: (j['id'] as String?) ?? '',
    titleEn: title,
    titleAr: titleAr,
    snippetEn: translation.isNotEmpty ? translation : occasion,
    snippetAr: translationAr.isNotEmpty ? translationAr : occasionAr,
    searchableText: [
      title,
      titleAr,
      ar,
      translation,
      translationAr,
      occasion,
      occasionAr,
    ].join(' ').toLowerCase(),
  );
}

/// Match every hit whose [searchableText] contains the lowercased query.
/// Returns the original order; the caller decides on display grouping.
/// Returns an empty list (not the full index) for empty/whitespace queries.
List<SearchHit> runSearch(List<SearchHit> index, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final hit in index)
      if (hit.searchableText.contains(q)) hit,
  ];
}

/// Group hits by section, preserving original order within each group.
Map<SearchSection, List<SearchHit>> groupBySection(List<SearchHit> hits) {
  final out = <SearchSection, List<SearchHit>>{};
  for (final hit in hits) {
    out.putIfAbsent(hit.section, () => <SearchHit>[]).add(hit);
  }
  return out;
}
