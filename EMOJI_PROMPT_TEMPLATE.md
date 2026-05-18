# AI Emoji Asset Pipeline — Generation Guide

This is the workflow for generating the kid-emoji PNG assets that replace the inline Unicode emojis throughout Aziz Academy's UI.

## How to add a new asset

1. **Pick the emoji** to generate (find it in `EMOJI_MIGRATION_MANIFEST.csv`, sorted by usage count — start with high-frequency ones for biggest visible impact).
2. **Copy the prompt template below** into your image-gen tool (ChatGPT, Midjourney, DALL-E, Imagen, Gemini, etc.). Replace `<SUBJECT>` and `<CONTEXT>`.
3. **Generate, iterate until the style matches what's already in the directory**, save as PNG.
4. **Save the file** as `assets/images/emojis/<semantic_name>.png` (the `semantic_name` column in the manifest).
5. **That's it.** The `KidEmoji` widget auto-loads it on next build. No code changes.

If the asset is missing, the widget renders the Unicode emoji as a fallback — so things never break mid-migration.

## Prompt template

Copy-paste this into any image-gen tool. Replace `<SUBJECT>` (always required) and `<CONTEXT>` (optional one-line description for the AI).

```
A flat illustrated icon of <SUBJECT>, designed for a children's educational app.

Visual style:
- Flat illustration, soft modern look (no gradients, minimal shadows)
- Slightly chunky / friendly geometry — kid-readable at small sizes (32-64px)
- Bold, confident outlines (1-2px equivalent)
- Aimed at ages 6-12 — friendly but not babyish

Color palette (strict — do not deviate):
- Primary: midnight navy #0F2C5C (dark backgrounds, accents)
- Accent: academy gold #D4AF37 (highlights, key shapes)
- Cream: #F5E9D6 (off-white for contrast)
- Soft red #E76F51 (warning / wrong-answer accent only)
- Soft green #67B99A (correct / success accent only)

Composition:
- 1:1 square aspect ratio (256×256 minimum)
- Transparent background (PNG with alpha)
- Subject centered, ~80% of frame
- No text, no logos, no human faces

Context: <CONTEXT>

Output: high-resolution PNG, transparent background, no border, no shadow.
```

## Examples to copy verbatim

**For `coin.png`:**
```
A flat illustrated icon of a coin showing a star symbol on its face,
designed for a children's educational app.

Visual style: flat illustration, kid-readable at small sizes, friendly chunky
geometry, bold confident outlines, aimed at ages 6-12.

Color palette (strict):
- Primary: midnight navy #0F2C5C
- Accent: academy gold #D4AF37
- Cream: #F5E9D6

Composition: 1:1 square, 256×256 minimum, transparent PNG, subject centered
~80% of frame, no text, no logos, no human faces.

Context: This icon represents the in-app currency. Kids earn coins for
correct quiz answers. The coin should feel rewarding but not greedy —
think gold star coin, not Vegas chip.

Output: high-resolution PNG, transparent background, no border, no shadow.
```

**For `trophy.png`:**
```
A flat illustrated icon of a gold trophy with two handles on a small base,
designed for a children's educational app.

[same visual style + palette + composition block]

Context: This icon celebrates module completion / personal best scores.
Should feel earned and special, classic trophy silhouette.
```

**For `cross.png`:**
```
A flat illustrated icon of a soft red X mark inside a rounded square,
designed for a children's educational app.

[same visual style + palette + composition block]

Color override: use the soft red #E76F51 as primary instead of navy.

Context: This icon means "wrong answer" but should NOT feel harsh or
shaming. Aim for "try again" energy — gentle, not punishing.
```

## Style consistency checklist (look at outputs)

Reject and re-generate if:
- ❌ Background isn't transparent (you'll get checkerboard artifacts in-app)
- ❌ Color palette drifted (e.g. yellow instead of gold, pure black instead of navy)
- ❌ Text/letters got rendered into the image (AI loves to add labels)
- ❌ Subject is clipped or off-center
- ❌ Style differs visibly from the previous icon you generated

Accept if:
- ✅ Recognizable as the emoji's meaning at 32px
- ✅ Palette matches the existing icons in the directory
- ✅ Transparent PNG with clean edges
- ✅ Could sit next to the previous 5 icons and look like a set

## Migration tracking

Mark progress in `EMOJI_MIGRATION_MANIFEST.csv` by editing the `art_status` column:
- `pending` → not generated yet
- `in-review` → generated, needs visual sanity check before merging
- `approved` → live in `assets/images/emojis/`

Recommended order (highest visible impact first):
1. `coin` (118 occurrences)
2. `check` (54)
3. `party` (51)
4. `trophy` (30)
5. `cross` (28)
6. Home tile emojis (graduation, school, clock, calendar — handful each, but on the most-visited screen)
7. Quiz feedback emojis (sparkles, glowing_star, fire — celebration effects)
8. Everything else, in usage-count order

## Out of scope (do NOT replace with AI assets)

- **Flag PNGs** in `assets/images/flags/` — kids learn what real flags look like
- **Company logo PNGs** in `assets/images/logos/` — kids learn what real brand logos look like
- **`logo_final.png`** — the Aziz Academy brand mark (already finalized)
- **PWA icons** (`web/icons/Icon-*.png`) — already shipped to app stores
- **Inline emojis embedded in JSON question content** (e.g. `"text": "What is 🪙 in Spanish?"`) — these aren't bare Text() emojis, they're parts of strings. Replacing them would mean parsing every quiz question and substituting Image widgets inline; that's a separate, larger refactor. Defer until Phase 1 (UI emojis) is fully done.
