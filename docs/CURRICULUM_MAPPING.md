# Curriculum Mapping (Educational Content Audit)

_Last reviewed: 2026-05-13_

Aziz Academy targets ages 6–12 in the GCC. The content needs to roughly
align with the Kuwait MOE primary-stage curriculum (similar enough to KSA's
Tawakkul/Madares for cross-GCC use). This doc maps each module to the
relevant curriculum strand and flags gaps for a curriculum specialist to
review.

## Modules vs. primary-stage strands

| Module | Strand (Kuwait MOE primary) | Coverage |
|--------|------------------------------|----------|
| Sciences | العلوم — كائنات حية، طاقة، فضاء | 60+ questions; difficulty 1–3 ✅ |
| Maps | الجغرافيا — قارات، دول | World maps + interactive ✅ |
| Capitals | الجغرافيا — عواصم العالم | All UN states + bilingual ✅ |
| Flags | الجغرافيا — علم الدول | All UN states ✅ |
| Math | الرياضيات — حساب، أنماط | Arithmetic + word problems + Type-Answer mode ✅ |
| Number Bonds | الرياضيات — جمع وطرح (KG–G2) | Make 10 / Make 20, 130 questions per round ✅ |
| Place Value | الرياضيات — منازل عشرية (G1–G3) | Tens-rods + ones-cubes with 2 modes ✅ |
| Skip Counting | الرياضيات — العد بالقفز (G1–G3) | By 2s, 5s, 10s — pre-multiplication ✅ |
| Shapes Basics | الرياضيات — الهندسة (KG–G2) | 12 fundamental shapes with examples ✅ |
| Arabic Alphabet | لغة عربية — الحروف (KG–G2) | 28 letters + isolated/medial/final forms ✅ |
| English Alphabet | English — letters (KG–G2) | 26 letters A–Z with example words ✅ |
| IQ | غير منهجي — تنمية تفكير | Logic, sequences, analogies ✅ |
| General | معلومات عامة، تربية وطنية، إسلامية | Includes AR-only categories: تربية إسلامية, لغة عربية ✅ |
| Madrasati | مواد مدرستي — ابتدائي/متوسط/ثانوي | Saudi-curriculum subset ✅ |
| Reading Zone | لغة عربية / English — قراءة فهم | 39 bilingual passages with comprehension Qs across Stories, Sciences, Geography, Values ✅ |
| Spelling | لغة عربية / English — إملاء | Letter-tile spelling, generated from existing answers ✅ |

## Items flagged for curriculum specialist review

1. **Reading Zone** — 39 bilingual passages across Stories, Sciences,
   Geography, and Values categories (as of v1.1.101). Future work:
   formal grade-banding so the screen serves age-appropriate text by
   default; a passage-fluency timer for older kids.
2. **Math word problems** — current pool leans abstract. Curriculum wants
   word problems set in Kuwaiti / GCC context (souq, dates, school).
3. **Sciences difficulty=3** — verify against grade-6 standards; some
   biology questions may be grade-7+.
4. **General Knowledge "تربية إسلامية"** — verify factual accuracy and tone
   with a religious-education specialist.
5. **History coverage** — currently absent. MOE primary stage includes basic
   GCC history (founding of Kuwait, GCC formation). Consider adding a
   History module or merging into General.
6. **Civics / National Education** — currently bundled in General; consider
   surfacing as its own module ("تربية وطنية").

## Grade-band mapping (recommendation)

| Age | Grade | Difficulty band | Modules to surface |
|-----|-------|-----------------|--------------------|
| 6–8 | 1–2 | mostly difficulty 1 | Capitals, Flags, Spelling, Reading Zone (short passages), Math (+/-), Number Bonds, Place Value, Skip Counting, Shapes Basics, Arabic & English Alphabets |
| 8–10 | 3–4 | difficulty 1–2 | + Sciences, IQ basics, Math (× ÷), General Knowledge, Logos |
| 10–12 | 5–6 | difficulty 2–3 | + Boss, Survival, Maps quiz, Self-Challenge, Reading Zone (longer) |

The Adaptive Difficulty agent already biases sampling per kid skill, so
age-banding is a hint, not a hard cap.

## Open task for content team

- Hire / contract a Kuwait MOE-aligned curriculum specialist to:
  1. Audit difficulty=3 sciences questions against grade-6 standards.
  2. Draft 20+ reading-zone passages per locale, grade-banded.
  3. Validate the Madrasati subject splits match official MOE textbooks.
  4. Sign off on the History/Civics gap above.
