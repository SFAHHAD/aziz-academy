# Accessibility Audit (WCAG 2.2 AA)

_Last reviewed: 2026-05-02_

| Guideline | Status | Notes |
|-----------|--------|-------|
| 1.1.1 Non-text content | ⚠️ partial | All Material icons have implicit semantics; emoji-only buttons lack labels — to add `Semantics(label:)` wrappers in v2. |
| 1.3.1 Info & relationships | ✅ | Headings use `AppTextStyles.headingMedium`; lists use `ListView.builder`. |
| 1.4.3 Contrast (minimum) | ✅ | Dark theme: gold-on-navy ≥ 7:1; light theme: navy-on-cream ≥ 4.5:1. |
| 1.4.4 Resize text | ✅ | App respects `MediaQuery.textScaler` × in-app `largerText` (+18%) toggle. |
| 1.4.10 Reflow | ✅ | Layouts use `SliverGridDelegateWithMaxCrossAxisExtent` and `Wrap` — no horizontal scroll at 320×256 zoom. |
| 1.4.12 Text spacing | ✅ | Cairo + OpenDyslexic fallback; line-height 1.5–1.6 in passage view. |
| 2.1.1 Keyboard | ✅ | All `ElevatedButton`/`InkWell`/`TextButton` accept focus. Web build supports tab/enter. |
| 2.4.7 Focus visible | ✅ | Default Flutter focus rings shown. |
| 2.5.5 Target size (level AAA) | ✅ | Quiz option buttons 56–72 dp; pills 48 dp; letter tiles 40–44 dp. |
| 3.1.1 Language of page | ✅ | `MaterialApp.locale` set; RTL flips correctly for Arabic. |
| 3.1.2 Language of parts | ✅ | Locale switch is one-tap; auto-RTL on `ar`. |
| 3.3.1 Error identification | ✅ | Type-the-answer shows the correct answer when wrong. |
| 4.1.2 Name, role, value | ⚠️ partial | Switches/sliders inherit Material semantics. Custom `_GlassPill` still needs `Semantics(button: true, label:)` — tracked as follow-up. |
| 4.1.3 Status messages | ✅ | `ScaffoldMessenger` snack-bars used for shop/reset confirmations. |

## Open follow-ups

1. Wrap every emoji-only `_GlassPill` in `Semantics(button: true, label: 'Sound', enabled: ...)`.
2. Audit color-coded charts in the Parent Dashboard with the color-blind simulation tool (deuteranopia/protanopia).
3. Add an "extra-high-contrast" theme variant that meets AAA (7:1) for low-vision users.
4. Run the iOS Accessibility Inspector + Android TalkBack pass before App Store submission.

## Toggles already in the app

| Toggle | Purpose |
|--------|---------|
| Sound | Mute all SFX/BGM |
| Reduced motion | Disables tweens (respects OS-level "reduce motion") |
| Larger text | +18% scale on top of OS scaling |
| Dyslexia-friendly font | Switches font family at the root |
| Light theme | High-contrast bright variant |
| Read questions aloud | TTS narrates each question |
| Shorter rounds | Defaults rounds to 3 questions |
