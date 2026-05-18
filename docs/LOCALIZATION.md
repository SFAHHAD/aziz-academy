# Localization & Cultural Review

_Last reviewed: 2026-05-02_

## Languages today

| Locale | Coverage | Notes |
|--------|----------|-------|
| Arabic (`ar`) | Primary | Modern Standard Arabic (MSA). RTL fully supported. |
| English (`en`) | Secondary | Used for fallback strings and bilingual content. |

## Future-proofing for more languages

- `kSupportedLocales` constant in `lib/core/providers/locale_provider.dart` is
  the single source-of-truth list. Adding a 4th language = drop in
  `lib/l10n/app_xx.arb` + add a `Locale` to that list.
- Question files use a `_ar` field-suffix convention (`question_ar`,
  `correct_answer_ar`). Adding `_fr` or `_ur` follows the same pattern.

## Dialect choice — MSA vs. Khaleeji

Aziz Academy ships in **MSA** (Modern Standard Arabic) so a single content
file works across the GCC, Levant, and Egypt. Trade-offs:

- ✅ Educational content for ages 6–12 is *expected* in MSA — that's how
  schools teach.
- ✅ Single source-of-truth — no fork per dialect.
- ⚠️ Spoken UX (TTS) sounds slightly formal; some kids may find it stiff.
- ⚠️ Some idioms ("yalla", "shoof") that Khaleeji kids use daily aren't
  reflected in the encouragement copy.

If we later want a Khaleeji variant, treat it as a separate `ar-KW` locale
rather than mixing dialect tokens into MSA.

## RTL UI checklist

- [x] All `Padding` uses `EdgeInsetsDirectional` where direction matters.
- [x] All `Alignment` uses `AlignmentDirectional`.
- [x] Arrow icons flip via `Directionality.of(context) == TextDirection.rtl`
  check in card + chevron widgets.
- [x] Numbers in Arabic locale render via `localizeDigitsCtx()` to use
  Arabic-Indic digits where appropriate.
- [x] Settings sheet, modal sheets, and route transitions all RTL-tested.
- [ ] Pending: parent dashboard story-card paragraphs need explicit
  `TextDirection` when string is parent-default English embedded in Arabic UI.

## Cultural review — open items

A native cultural reviewer should scan these areas before launch in the GCC:

1. **Quiz content** — particularly history / civics questions; verify nothing
   conflicts with the Saudi or Kuwait curriculum's framing.
2. **Imagery** — flag images, female/male character emoji, food
   illustrations: confirm appropriate clothing/halal context where applicable.
3. **Geographic naming** — disputed-territory names (Palestine, Crimea,
   etc.) — review default copy.
4. **Religious sensitivity** — verify Sciences questions (e.g., evolution
   topics, Big Bang) are framed neutrally for GCC audiences.
5. **Tone of celebration copy** — "rockstar", "you crushed it" don't always
   translate well; reviewer to greenlight per-locale praise lines.

## TTS / read-aloud

- Uses `flutter_tts` with locale set from current `Locale`.
- Arabic voice quality varies by device; tablet TTS engines tend to be
  better than phones. Document as a known limitation in the parent FAQ.
