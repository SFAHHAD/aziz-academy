# Media pipeline — voices, illustrations, emoji

Three knobs to make Aziz Academy feel professional and warm. Each is independent of the others. You can do them in any order.

---

## 1. Voices — upgrade to Azure Neural

### What's already there

The plumbing is done. `api/speak.js` is a Vercel serverless proxy that:
1. Takes `?text=...&lang=ar|en&gender=male|female` query params
2. Calls Azure Cognitive Services TTS using server-side keys
3. Returns the MP3 audio
4. Caches at the Vercel edge with a 30-day immutable header — popular phrases hit Azure once per cache lifetime per POP

The Flutter side `cloud_tts_service.dart` already calls this proxy. It only needs to be turned on:

```dart
// lib/core/providers/app_settings_provider.dart
this.cloudVoices = false,  // ← flip this default to true for web
```

### What you need to do (one-time, ~10 min)

1. **Get an Azure Speech key** — sign in at https://portal.azure.com → "Create a resource" → search "Speech" → free tier `F0` (500k chars/month, no card needed for sandbox)
2. **Note the Key 1 and Region** values from the resource overview
3. **Vercel project → Settings → Environment Variables**, add:
   - `AZURE_TTS_KEY` = `<the key 1 value>`
   - `AZURE_TTS_REGION` = `<region slug like "westeurope" or "eastus">`
4. **Redeploy** (any push or "Redeploy" button)
5. **Optional:** flip the `cloudVoices` default to `true` in code for web users, OR add a one-tap "Use natural voices?" prompt in onboarding so parents opt in

### Voices currently mapped in `api/speak.js`

| Lang | Gender | Voice | Notes |
|---|---|---|---|
| ar | female | `ar-SA-ZariyahNeural` | Modern Saudi, warm |
| ar | male | `ar-SA-HamedNeural` | Modern Saudi, calm |
| en | female | `en-US-JennyNeural` | Friendly, kid-appropriate |
| en | male | `en-US-GuyNeural` | Warm, narrative |

If you want different voices, edit the `VOICES` const in `api/speak.js`. The full Neural voice catalog is at https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts.

### Premium tier — ElevenLabs branded voice

If you want a signature Aziz voice that's instantly recognisable:

1. https://elevenlabs.io → Starter plan ($22/month)
2. Use Voice Lab to either:
   - Clone a recorded sample of a kid-friendly Arabic narrator (10 min of audio is enough — record yourself or commission a voice actor)
   - OR pick one of their pre-made Arabic voices
3. Plug the `ELEVENLABS_API_KEY` + voice ID into a second Vercel serverless function `api/speak_premium.js` (template below)
4. Route Plus subscribers to the premium endpoint, free users to Azure

Use this for the **Daily Did-you-know fact**, **recap session intros**, and the **first Hadith of the day** — content that benefits from a distinctive voice. Keep Azure for incidental tap-to-hear buttons (it's cheaper at scale).

Template for the premium endpoint:

```js
// api/speak_premium.js
export default async function handler(req, res) {
  const { text, lang } = req.query;
  if (!text || text.length > 1500) return res.status(400).end();
  const key = process.env.ELEVENLABS_API_KEY;
  const voiceId = lang === 'ar' ? process.env.ELEVENLABS_AR_VOICE : process.env.ELEVENLABS_EN_VOICE;
  const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}/stream`, {
    method: 'POST',
    headers: { 'xi-api-key': key, 'Content-Type': 'application/json' },
    body: JSON.stringify({ text, model_id: 'eleven_multilingual_v2' }),
  });
  if (!r.ok) return res.status(r.status).end();
  res.setHeader('Content-Type', 'audio/mpeg');
  res.setHeader('Cache-Control', 'public, max-age=2592000, immutable');
  r.body.pipe(res);
}
```

---

## 2. Illustrations — Aziz character + new welcome screen art

### Current state

- The splash uses `assets/images/aziz_character.png` (the boy with neural-network background you've seen on the live site)
- `welcome_screen_v2.dart` falls back gracefully if the asset is missing
- Emojis use `KidEmoji` widget which falls back to Unicode if PNG is missing

### Generation prompts (drop into Midjourney, DALL-E, Ideogram, or Flux)

**1. Aziz character — refined hero pose for welcome screen**

> Flat illustrated portrait of a curious 10-year-old Arab boy named Aziz with short dark curly hair, big amber eyes, smiling gently. Wearing a navy hoodie with a small gold star embroidered on the chest. Background: deep navy night sky with subtle constellation lines connecting in geometric patterns, soft gold accents. Style: friendly, modern, slightly stylized — Pixar meets Studio Ghibli. Centered composition, transparent background, 1024x1024.

**2. Welcome screen banner — wide hero**

> Hero illustration for a kids' learning app. Aziz (the boy character) holding an open book that emits golden light, with floating educational icons (planet, math symbols, Arabic letters, microscope) drifting around him. Deep navy gradient background with soft gold glows. Cinematic lighting, warm and inviting. 1920x1080 horizontal.

**3. Empty state — for when a category is filtered to nothing**

> Cute illustration of a small empty bookshelf with one curious cat sitting beside it. Navy and gold palette, minimal, with negative space. Used as an "empty state" graphic in a kids' app. 600x600 transparent background.

**4. Pro tier illustration — for the upsell card**

> Aziz wearing a glowing gold crown made of stars, smiling confidently, with a sash that reads "Plus" in tasteful gold lettering. Navy background with sparkle accents. Soft, aspirational, not flashy. 800x800 transparent.

### Where to save them

```
assets/images/
├── aziz_character.png         # the existing splash boy (keep)
├── aziz_hero.png              # NEW prompt #2 — for welcome screen
├── empty_state_cat.png        # NEW prompt #3
├── pro_aziz.png               # NEW prompt #4
```

Then register the new paths in `pubspec.yaml` under `flutter.assets` (the directory wildcard `assets/images/` already covers them if you're using that — verify in pubspec).

---

## 3. Emoji — replacement set

### Current state

`KidEmoji` widget maps named PNGs at `assets/images/emojis/<name>.png` (lots already exist: trophy, coin, school, game_die, …). The widget falls back to Unicode if the PNG is missing.

The audit found these emoji asset files already there: abacus, adult, alembic, american_football, amphora, anticlockwise_downwards_and_upwards_open, artist_palette, atom_symbol, automobile, baby_chick, balloon, ballot_x, banana, bar_chart, baseball, basket, basketball_and_hoop, bear_face, beaver, billiards…

### If you want a new style

Generate one prompt per category in a consistent style and replace the PNGs in `assets/images/emojis/`. Suggested categories the app uses most:

1. **subjects** — book, microscope, globe, calculator, palette
2. **rewards** — trophy, gold-star, crown, ribbon, coin
3. **emotions** — happy, excited, thinking, surprised, proud (kid faces)
4. **actions** — play-button, gear, search, plus, sparkle

Generation prompt template (consistent style):

> Flat illustrated emoji icon: <subject>. Navy `#0F2C5C` and gold `#D4AF37` color palette only. Soft shadows, kid-friendly, age 6-12. Centered, transparent background, 256x256.

### Bulk replacement workflow

1. Generate a set in your preferred tool (Midjourney is fastest for batch).
2. Drop them in `assets/images/emojis/` with the exact filename the app expects (run `python scripts/audit_islamic_audio.py` to see the manifest; or just `grep -r "KidEmoji.named" lib/` to find call sites).
3. Run `flutter clean && flutter pub get` to refresh the asset bundle.
4. Run `python scripts/audit_font_coverage.py` to verify nothing regressed.

The widget will pick up the new files automatically. Existing Unicode fallbacks remain available as the last-resort fallback.

---

## 4. Quick wins for "feels pro"

Even without new assets, these tiny changes make the app feel premium:

- **Reduce default motion** if `reducedMotion = false` and animation looks busy: cap durations to 220 ms. Currently some are 400+ ms.
- **Use SF Pro Display / Inter weight 800** for hero headlines (Aziz Academy title on welcome screen). Cairo 800 for the Arabic equivalent — both already bundled.
- **Round corners to 16-20 px consistently** — the new widgets I added use 14-20 px; sweep the legacy widgets and bump from 8-12 to match.
- **Replace any flat solid color with a subtle gradient** for hero surfaces. The new home cards do this; the legacy home tiles don't.
- **Add a faint outer glow on focus** — `BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 18, spreadRadius: 1)` on the active tile/card. Already in some widgets, missing in others.

These are 10-line changes per widget; doing them across the legacy widgets is a 2-3 hour pass once the v2 home + welcome ship.

---

## Sequencing recommendation

1. **This week:** Get Azure TTS key on Vercel → flip `cloudVoices` default → users immediately hear better voices everywhere (no app rebuild needed for the cache fill; old browsers will use the new MP3 next time they invalidate).
2. **Next sprint:** generate the 4 new illustrations from prompts above. Ship as part of the v2 welcome screen rollout.
3. **As time allows:** regenerate the emoji set in a consistent style. Lowest user impact but biggest "polish" payoff.
4. **Long-term:** subscribe ElevenLabs and ship the premium-voice path behind the Plus tier. Tie marketing of Aziz Academy Plus to "Aziz's special voice."
