auditors/reviewers
**Senior engineers — build team**

- *Senior mobile engineer (iOS + Android)* — ideally Flutter or React Native for a single codebase, since you'll ship to both stores. Native (Swift/Kotlin) only if you need heavy game performance.
- *Senior game/Unity engineer* — if your gamification is rich (animations, physics, 2D/3D scenes), you'll likely build the game layer in Unity and embed it. If it's lightweight (badges, points, simple interactions), the mobile engineer can handle it.
- *Senior backend engineer* — APIs, user accounts, progress tracking, subscriptions, content delivery. Node.js, Go, or Python typically.
- *Senior AI/ML engineer* — owns the in-app agents (adaptive difficulty, tutor companion, mistake-pattern detection). Needs experience with LLMs *and* with on-device or low-latency inference, since kids won't tolerate lag.
- *Senior data engineer* — sets up event tracking, analytics pipelines, and the data layer your AI agents depend on. Easy to skip early; painful to retrofit.
- *Senior UX/UI designer (kids specialty)* — designing for ages 6–16 is its own discipline. Big tap targets, minimal text, clear visual hierarchy, age-appropriate aesthetics. Don't hire a generic SaaS designer here.
- *DevOps / cloud engineer* — CI/CD, scaling, cost control. Often part-time or a senior backend engineer wearing two hats early on.

**Auditors & specialized reviewers**

This is where kids' apps differ from normal apps. You need outside eyes on:

- *Child safety & privacy auditor (COPPA / GDPR-K / Kuwait & GCC data laws)* — critical. If you collect any data from under-13s, this is non-negotiable. They review what you collect, how you store it, parental consent flows, and third-party SDKs.
- *Security auditor / penetration tester* — independent firm runs a pentest before launch and annually. Especially important if you handle payments or store student data.
- *Educational content auditor* — a curriculum specialist (ideally aligned with Kuwait MOE or your target market's standards) who validates that the learning content actually teaches what it claims. Parents and schools will ask.
- *Accessibility auditor* — WCAG compliance, screen reader support, color contrast, dyslexia-friendly fonts. Required in some markets, good practice everywhere.
- *Localization & cultural reviewer* — for Arabic content specifically: native reviewer who checks tone, dialect choices (MSA vs. Khaleeji), cultural appropriateness, and right-to-left UI behavior.
- *App Store compliance reviewer* — Apple and Google have strict rules for kids' apps (Apple's "Kids Category," Google's "Designed for Families"). Someone who's shipped kids' apps before can save you weeks of rejections.
- *AI safety reviewer* — since you're using AI agents talking to children, someone needs to red-team the tutor companion: can a kid get inappropriate responses? Can prompts be jailbroken? This is newer territory but increasingly expected.

**Realistic early-stage version**

You don't need all of this on day one. A lean MVP team is usually:

1. One senior full-stack mobile engineer (handles mobile + lightweight backend)
2. One senior AI engineer (for the agents)
3. One kids-specialized UX designer (contract is fine)
4. A child privacy/COPPA consultant (a few hours, not full-time)
5. App Store compliance advisor (one-time engagement before launch)
