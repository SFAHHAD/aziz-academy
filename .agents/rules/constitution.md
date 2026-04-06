# 📜 Aziz Academy — Project Constitution

> This document is the single source of truth for all architectural, design, and content decisions in the Aziz Academy project. Every AI assistant, developer, and contributor MUST follow these rules without exception.

---

## 1. 🎯 Project Overview

**App Name:** Aziz Academy
**Target Audience:** Children aged 8–12
**Platform:** Flutter (iOS, Android, Web)
**Purpose:** An interactive educational app teaching world geography (Maps), country capitals (Capitals), and brand/flag recognition (Logos).

---

## 2. 🏗️ Architecture Rules

### 2.1 Modular Feature Structure
The app MUST follow a feature-first modular architecture. Each educational section is a **fully self-contained module**:

```
lib/
├── core/               # Shared utilities, theme, router, widgets
│   ├── theme/          # App-wide colors, text styles, spacing
│   ├── router/         # go_router configuration
│   └── widgets/        # Reusable UI components
├── features/
│   ├── home/           # Home screen & navigation hub
│   ├── maps/           # World Maps module (self-contained)
│   ├── capitals/       # Capitals quiz module (self-contained)
│   └── logos/          # Logo/flag recognition module (self-contained)
└── main.dart
```

### 2.2 Module Internal Structure
Each feature module MUST follow this internal layout:
```
features/<module>/
├── data/               # JSON loading & data models
├── presentation/
│   ├── screens/        # Full-page screens
│   └── widgets/        # Module-specific widgets
└── providers/          # Riverpod providers for this module
```

### 2.3 No Cross-Module Imports
Modules MUST NOT import from sibling modules. Only `core/` is shared across modules.

---

## 3. 🔧 Technology Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (latest stable) |
| State Management | `flutter_riverpod` — **NO other state solutions** |
| Navigation | `go_router` |
| Data | Local JSON files in `assets/data/` |
| SVG Assets | `flutter_svg` |
| Code Generation | `riverpod_annotation` + `build_runner` |

### 3.1 State Management Rules
- All state MUST be managed via `flutter_riverpod` providers.
- Use `@riverpod` annotation (code-gen style) wherever possible.
- Providers MUST live in the `providers/` folder of their respective module.
- **No `setState()` in business logic**. `setState` is only allowed for purely local UI animation states.
- **No `BuildContext` in providers**.

### 3.2 Data Loading Rules
- ALL content (questions, answers, country data, logos, map regions) MUST be loaded from local JSON files in `assets/data/`.
- No network calls for content. The app MUST work 100% offline.
- JSON files are read via `rootBundle.loadString()` and parsed via `dart:convert`.
- A `DataProvider` in each module handles loading and caching its module's JSON.

---

## 4. 🎨 UI & Design Rules

### 4.1 Kid-Friendly Design Principles
- **High Contrast:** Minimum contrast ratio of 4.5:1 for all text/background combinations.
- **Large Fonts:** Minimum body font size is **18sp**. Titles start at **28sp**.
- **Bold Labels:** All interactive elements use `FontWeight.w700` or higher.
- **No small tap targets:** All buttons and tappable elements have a minimum size of **56×56dp**.

### 4.2 Color Palette
Define all colors in `lib/core/theme/app_colors.dart`. No magic hex codes anywhere else.

```dart
// Aziz Academy Brand Colors
primary:     #FF6B35  // Energetic Orange
secondary:   #4ECDC4  // Playful Teal
accent:      #FFE66D  // Sunshine Yellow
background:  #F7F9FC  // Soft off-white
surface:     #FFFFFF
error:       #E63946
success:     #2DC653
textDark:    #1A1A2E  // Near-black for readability
textLight:   #FFFFFF
```

### 4.3 Typography
- Font family: **Nunito** (from Google Fonts) — rounded, friendly, highly legible.
- Font sizes defined as constants in `lib/core/theme/app_text_styles.dart`.
- Never hardcode `fontSize` inline in widgets. Always use the theme text styles.

### 4.4 Animations & Feedback
- Every correct answer triggers a celebratory animation (confetti, scale bounce, or color flash).
- Every wrong answer triggers a gentle shake animation — never punishing, always encouraging.
- Screen transitions use a consistent slide or fade animation defined in the router.

### 4.5 Accessibility
- All images MUST have semantic labels.
- All interactive widgets MUST have `Semantics` wrappers with descriptive labels.
- Support both light and dark mode (defined in the theme).

---

## 5. 📁 Asset Rules

```
assets/
├── data/
│   ├── maps.json         # Map regions and related quiz questions
│   ├── capitals.json     # Countries, capitals, flags, hints
│   └── logos.json        # Brand logos, names, categories
├── images/
│   └── *.png / *.webp    # Illustrations, backgrounds, character mascot
└── fonts/
    └── Nunito/           # Bundled font files
```

- All assets MUST be registered in `pubspec.yaml`.
- JSON data files use **snake_case** keys.
- Image files use **kebab-case** filenames.

---

## 6. 📐 JSON Data Schema

### `capitals.json`
```json
[
  {
    "id": "sa",
    "country": "Saudi Arabia",
    "capital": "Riyadh",
    "continent": "Asia",
    "flag_emoji": "🇸🇦",
    "hint": "Home to the Burj Khalifa... wait, wrong country! Think deserts and oil.",
    "difficulty": 1
  }
]
```

### `logos.json`
```json
[
  {
    "id": "apple",
    "brand": "Apple",
    "category": "Technology",
    "image_asset": "assets/images/logos/apple.png",
    "hint": "Think of a fruit that keeps the doctor away.",
    "difficulty": 1
  }
]
```

### `maps.json`
```json
[
  {
    "id": "middle_east",
    "region": "Middle East",
    "countries": ["Saudi Arabia", "UAE", "Kuwait", "Bahrain"],
    "quiz_questions": [
      {
        "question": "Which country has the largest land area in the Middle East?",
        "answer": "Saudi Arabia",
        "options": ["Saudi Arabia", "Iran", "Iraq", "Turkey"]
      }
    ]
  }
]
```

---

## 7. 🧪 Testing Rules

- Every provider MUST have a corresponding unit test in `test/`.
- Widget tests MUST cover all screens.
- No PR/commit that removes existing tests is acceptable.
- Test folder mirrors `lib/` folder structure.

---

## 8. 🚫 Prohibited Practices

| ❌ Prohibited | ✅ Correct Alternative |
|---|---|
| `setState()` for business logic | Riverpod providers |
| Network calls for content | Local JSON in `assets/data/` |
| Hardcoded colors in widgets | `AppColors.primary` constants |
| Hardcoded font sizes | `AppTextStyles.bodyLarge` constants |
| Cross-module feature imports | Core-only shared code |
| `print()` for logging | `debugPrint()` only |
| Magic numbers/strings | Named constants in `core/` |
| Skipping accessibility labels | Always add `Semantics` |

---

## 9. 🔖 Versioning & Git Rules

- Branch naming: `feature/<module>/<description>` (e.g., `feature/capitals/add-quiz-screen`)
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`
- Every new screen or provider must have a corresponding entry in this constitution if it changes the architecture.

---

*Last updated: April 2026 — Aziz Academy v1.0*
