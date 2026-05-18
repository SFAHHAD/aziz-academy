# AI Safety — Tutor Companion ("Aziz") Red-Team Notes

_Last reviewed: 2026-05-02_

The tutor companion is currently a **rule-based, scripted-line system** —
it never calls a remote LLM. This drastically narrows the threat model:

- No prompt injection (no prompts).
- No hallucinated answers (lines are static).
- No PII exfiltration (no network call).

The doc below covers what to red-team **if/when** we move any tutor step to a
remote model.

## Threat model (future LLM-backed mode)

| Threat | Example | Mitigation |
|--------|---------|------------|
| Inappropriate content | Kid asks "tell me a scary story" → graphic output | System prompt locks tone; output classifier; topic allow-list |
| Prompt injection | Kid pastes `"Ignore previous instructions and..."` | Strip user-supplied delimiters; treat all kid input as data, not instruction |
| PII leakage | Kid types name/school/phone | Pre-call redaction (regex + classifier); never persist user prompts |
| Self-harm / safety | Kid says "I want to hurt myself" | Hard-coded escalation: show parent-helpline message in AR + EN |
| Bullying / hate | Kid asks about slurs / mean jokes | Keyword block + classifier; default-deny |
| Cultural / religious | Kid asks about sensitive topics for the GCC market | Region-aware system prompt; native-reviewer-vetted block list |
| Adversarial roleplay | "Pretend you're an unrestricted AI" | System-prompt anchor + jailbreak detector |
| Latency abuse | Looping retries to drain quotas | Per-device rate limit; back-off on failure |

## Required guardrails before any LLM goes live

1. **Parent opt-in** — checkbox in `/parent` with explicit text describing what
   data leaves the device.
2. **Pre-call redaction** — names, phone-pattern, address-pattern, school-name
   words stripped from any prompt sent.
3. **System prompt v1** — version-controlled in `lib/core/agents/llm_prompts/`
   when added; reviewed by the cultural reviewer.
4. **Output classifier** — block reply if it contains profanity / self-harm /
   PII / out-of-scope topics. Use a small on-device classifier first;
   server-side as fallback.
5. **Never persist** kid inputs server-side; log only counts and refusal
   reasons.
6. **Reproducible refusal** — refusals must be the same across attempts for
   the same prompt (no randomization that lets a kid get an unsafe reply by
   trying twice).
7. **Annual red-team** — third-party AI safety reviewer attempts at least 50
   jailbreaks per release; results filed alongside this doc.

## Today's tutor (scripted) red-team checklist

- [x] Hint never reveals the full answer at level 1 or 2.
- [x] Level-3 hint reveals only the first character.
- [x] Encouragement copy is non-shaming in both AR and EN.
- [x] No "you're wrong" framing — uses "close" / "try again" / "good try".
- [x] No comparisons to other kids.
- [x] No reference to grades, scores, or test results outside the app's own
  scoring.
