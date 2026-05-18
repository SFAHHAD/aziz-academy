# Aziz Academy — Privacy & Data Protection

_Last reviewed: 2026-05-02_

Aziz Academy is built for children aged 6–12. We follow the strictest
applicable child-data regimes wherever the app is offered:

- **COPPA** (U.S., under-13)
- **GDPR-K** (EU, under-16, age varies by member state)
- **PDPL** (Saudi Personal Data Protection Law)
- **Kuwait DPPR** + GCC equivalents

When regimes conflict, we apply the strictest.

## What we collect

### On-device only (default)

These never leave the device:

| Category               | What                                                | Where stored                       |
|------------------------|-----------------------------------------------------|------------------------------------|
| Quiz progress          | Score per session, stars per module                 | `SharedPreferences` (`achievement_*`) |
| XP / coins / streak    | Level, total XP, daily streak count                 | `SharedPreferences` (`xp_*`, `coin_*`) |
| Learner profile        | Skill estimates per topic, recent miss log (≤50)    | `SharedPreferences` (`learner_state_v1`) |
| Settings               | Sound, motion, font, language, accessibility flags  | `SharedPreferences` (`app_settings_v1`) |
| Interests              | Optional onboarding picks (animals/space/...)        | inside `learner_state_v1`          |

No PII is collected. No name, email, school, address, phone number, or device
identifiers leave the device. There are no third-party tracking SDKs.

### Network calls

The web build is a static asset bundle hosted on Vercel's CDN. The app does
not call out to any backend at runtime. Web Vitals / hosting logs are limited
to anonymous request metadata (IP truncation, no cookies set by us).

There is **no advertising SDK, no analytics SDK, no crash reporter**.

## Data retention & erasure

- All on-device data persists until the user clears app storage or taps
  **Settings → Reset profile** (planned UI).
- Backup-export is opt-in (`Settings → Export progress`); the export file is
  shared via the OS share-sheet under user control.
- Backup-import accepts a previously-exported JSON.

## Parental controls

- The **Parent Dashboard** (`/parent`) is gated by a simple math problem to
  keep kids out of the analytics view. It is _not_ a security boundary.
- All accessibility & gameplay toggles live in `Settings`.
- Sound, motion, and read-aloud are independently toggleable.

## Child-safety guarantees

- No chat. No multiplayer. No user-generated content.
- No external links from inside gameplay screens.
- Privacy policy + About are reachable from the home top bar.

## In-app AI agents — data dossier

Each agent declares: input, decision boundary, output, retention.

| Agent                 | Inputs                                            | Decision   | Retention                       |
|-----------------------|---------------------------------------------------|------------|---------------------------------|
| A1 Adaptive Difficulty| skill[module] + question difficulty               | local      | derived; no log                 |
| A2 Tutor Companion    | wrong streak, idle time, current question         | local      | none                            |
| A3 Mistake-Pattern    | last 50 errors (module, category)                 | local      | rolling 50, ~30 days            |
| C1 Reward & Quest     | weakest module, frustration                       | local      | derived                         |
| C2 Encouragement      | frustration EMA (rapid-retries / accuracy drop)   | local      | rolling                         |
| B1 Learning Path      | skill table + days-since-played per module        | local      | derived                         |
| C4 Celebration        | per-session counters                              | local      | session-only                    |
| E1 Parent Dashboard   | aggregates of all the above                       | local      | reads on demand                 |
| G1 Reading-Support    | text-question latency averages                    | local      | sticky flag, override available |
| G2 Attention-Aware    | session-duration distribution                     | local      | sticky flag, override available |

No agent calls out to any LLM or remote API today. If a future feature
introduces remote inference, it will:

1. Be opt-in by parents in the Parent Dashboard.
2. Redact any PII before any cloud call.
3. Be auditable in this same dossier.

## Reporting

Privacy questions, breach reports, or data subject requests:
**privacy@aziz-academy.app** (placeholder — wire to a real address before
public launch).
