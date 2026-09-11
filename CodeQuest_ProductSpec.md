 # CodeQuest — Master Product Specification Document
### Hackathon Build Guide · Version 1.0 · Confidential

> **Purpose:** This document is the single source of truth for the CodeQuest build. Every teammate — coder or not — has a section written for them. Read yours first, then read the whole thing.

---

## Table of Contents
1. [The World of NETRUNNER — Theme & Lore Bible](#1-the-world-of-netrunner--theme--lore-bible)
2. [Flutter Design System — The HUD Spec](#2-flutter-design-system--the-hud-spec)
3. [Hybrid Architecture & Data Flow](#3-hybrid-architecture--data-flow)
4. [Team Task Distribution](#4-team-task-distribution)
5. [Critical Review & Market-Readiness Checklist](#5-critical-review--market-readiness-checklist)
6. [Build Timeline — 24-Hour Sprint](#6-build-timeline--24-hour-sprint)

---

## 1. The World of NETRUNNER — Theme & Lore Bible

### 1.1 The Premise

> *"The Citadel's AI has locked humanity's collective knowledge behind encrypted vaults. You are a NETRUNNER — a rogue coder who must breach each vault, survive the QUARANTINE PROTOCOLS, and challenge other runners in the ARENA before the Citadel shuts you down."*

This is your pitch sentence. Every UI label, every loading state, every error message must feel like it belongs in this world.

### 1.2 Module Rename Map

This is the **single most impactful change** you can make to kill the "quiz app" perception. Never use the plain English name in any user-facing string.

| Plain English Name | NETRUNNER Name | UI Label | Flavor Text |
|---|---|---|---|
| Placement Test / Calibration | **NEURAL SCAN** | `[INITIALIZING NEURAL SCAN...]` | *"Calibrating your threat profile before Citadel entry."* |
| Beginner Tier | **RECRUIT** | `RECRUIT // CLEARANCE LVL 01` | *"Citadel protocols underestimated."* |
| Intermediate Tier | **ROGUE** | `ROGUE // CLEARANCE LVL 02` | *"Half their walls are already down."* |
| Advanced Tier | **PHANTOM** | `PHANTOM // CLEARANCE LVL 03` | *"Ghost in the machine. The Citadel fears you."* |
| Theory Cards / Lesson | **DATA CACHE** | `[CACHE DECRYPTED]` | *"Intelligence extracted from Vault {N}."* |
| Quiz / Question | **BREACH ATTEMPT** | `INITIATING BREACH //` | *"Answer correctly to crack the encryption."* |
| Correct Answer | **BREACH SUCCESSFUL** | `[ACCESS GRANTED]` | *"Vulnerability exploited."* |
| Wrong Answer | **FIREWALL HIT** | `[INTRUSION DETECTED]` | *"Citadel firewall rejected your payload."* |
| Revision Module | **QUARANTINE ZONE** | `[ENTERING QUARANTINE]` | *"Your neural patterns have been flagged. Remediation protocol engaged."* |
| AI Remediation Plan | **PATCH PROTOCOL** | `PATCH PROTOCOL v{X} GENERATED` | *"Analyzing your failure vector... generating countermeasures."* |
| Competition Mode | **THE ARENA** | `[ARENA // LIVE DUEL]` | *"A rival NETRUNNER has issued a challenge."* |
| User Profile | **RUNNER PROFILE** | `RUNNER ID: {username}` | — |
| XP / Points | **SIGNAL STRENGTH** | `SIG: {points}` | — |
| Streak | **UPTIME** | `UPTIME: {N} DAYS` | — |
| Guest Mode | **GHOST MODE** | `[GHOST PROTOCOL ACTIVE]` | *"No identity. No trace. No mercy."* |
| Leaderboard | **THREAT INDEX** | `THREAT INDEX // GLOBAL` | — |
| Course Map | **BREACH MAP** | `BREACH MAP // SECTOR {N}` | — |
| Learning Node / Topic | **VAULT** | `VAULT {N}: {Topic}` | — |
| Locked Node | **ENCRYPTED VAULT** | `[ENCRYPTED // CLEAR PRIOR VAULTS]` | — |
| Completed Node | **BREACHED** | `[STATUS: BREACHED ✓]` | — |

### 1.3 Tier Progression Story

When the Neural Scan places a user, show a full-screen cinematic:

- **RECRUIT:** Dark room. A single terminal blinks. Text types out: `"Identity confirmed. Threat level: MINIMAL. Citadel has assigned you a basic sector. Don't disappoint us."`
- **ROGUE:** Matrix-style cascade. Text: `"Impressive. You've broken through the outer perimeter. The real walls start now."`
- **PHANTOM:** Static, then a glitch explosion. Text: `"...Ghost detected in the network. Citadel placing you in the restricted sector. You've been warned."`

These are 3-second animated text sequences your Visual/Story teammate writes. You plug them in as a single `AnimatedTextWidget`.

### 1.4 The Lore "Codex" (Easter Eggs)

Have your Content teammate write 20 one-liner "Citadel intercepted transmissions" that appear randomly as loading screen text. Example:
- *"CITADEL LOG 4471: Runner activity in Sector 7 increasing. Deploy countermeasures."*
- *"ENCRYPTED COMM: They're learning too fast. Slow the vaults."*

These cost zero development time and create an incredible sense of a living world. Judges will notice.

---

## 2. Flutter Design System — The HUD Spec

### 2.1 The Design Principle

Your previous app was "vibe-coded." The fix is to build **one shared `AppTheme` class** and **never hardcode a color, font size, or padding anywhere else in the codebase.** This is the #1 rule.

### 2.2 The Color Palette (NETRUNNER HUD)

```dart
// lib/theme/app_theme.dart

class NetrunnerColors {
  // Primary palette — dark terminal aesthetic
  static const Color voidBlack    = Color(0xFF0A0E1A); // Background
  static const Color deepNavy     = Color(0xFF0D1B2A); // Card backgrounds
  static const Color codeGray     = Color(0xFF1C2B3A); // Surface
  static const Color borderGlow   = Color(0xFF1E3A5F); // Default borders
  
  // Accent — pick ONE primary and stick to it
  static const Color signalGreen  = Color(0xFF00FF88); // PRIMARY ACCENT
  static const Color dangerRed    = Color(0xFFFF3B5C); // Errors, Firewalls
  static const Color warningAmber = Color(0xFFFFB800); // Warnings, timers
  static const Color phantomBlue  = Color(0xFF4D9EFF); // Info, links
  
  // Text
  static const Color textPrimary   = Color(0xFFE2E8F0); // Main text
  static const Color textSecondary = Color(0xFF64748B); // Muted
  static const Color textAccent    = Color(0xFF00FF88); // Highlighted
  
  // Semantic
  static const Color success = signalGreen;
  static const Color danger  = dangerRed;
  static const Color neutral = phantomBlue;
}
```

**Non-negotiable rule for your team:** Every color in every widget comes from `NetrunnerColors`. If you find yourself typing `0xFF` anywhere else, stop.

### 2.3 The Typography Stack

Use `google_fonts` package. The combination:

```dart
// Headlines / Module names → Rajdhani (military/tech feel)
// Body / Code snippets → JetBrains Mono (hacker terminal feel)  
// UI Labels → Barlow Condensed (HUD overlay feel)

TextTheme netrunnerTextTheme = TextTheme(
  displayLarge:  GoogleFonts.rajdhani(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: 4, color: NetrunnerColors.textAccent),
  headlineMedium: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 2, color: NetrunnerColors.textPrimary),
  titleLarge:    GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.5, color: NetrunnerColors.textSecondary),
  bodyMedium:    GoogleFonts.jetBrainsMono(fontSize: 14, color: NetrunnerColors.textPrimary, height: 1.6),
  labelSmall:    GoogleFonts.barlowCondensed(fontSize: 11, letterSpacing: 2, color: NetrunnerColors.textSecondary),
);
```

### 2.4 The HUD Widget Library (Build These First)

Build these 6 widgets on Day 1 before any screen. Everything else is assembled from these.

#### Widget 1: `HudCard`
A bordered card with an optional glowing top-edge accent line.
```dart
// Usage: HudCard(accentColor: NetrunnerColors.signalGreen, child: ...)
// Appearance: dark card, 1px border (borderGlow), optional 2px top accent line
// Border radius: 4 (sharp, military feel — NOT rounded)
```

#### Widget 2: `GlitchText`
Text that briefly "glitches" on first render — characters flicker for 300ms then resolve.
```dart
// Package: Use 'animated_text_kit' → TypewriterAnimatedText
// Add a 'scramble' phase using Timer-based character replacement
// Use for: Module names, tier reveals, error messages
```

#### Widget 3: `HudButton`
The only button style in the app. Sharp corners, signal-green border, dark fill.
```dart
// Style: OutlinedButton with custom side = BorderSide(color: signalGreen, width: 1)
// On hover/press: fill animates to signalGreen with 150ms duration
// Border radius: 2 (very sharp)
// Label: ALL_CAPS, Barlow Condensed, letterSpacing: 2
```

#### Widget 4: `ScanlineOverlay`
A subtle full-screen overlay of horizontal scan lines (3px gap, 1px line, 3% opacity). This one widget makes the entire app look like a game HUD.
```dart
// Implementation: CustomPainter that draws horizontal lines
// Wrap every screen's Scaffold body with this
// Opacity: 0.03 — barely visible but critical for the aesthetic
```

#### Widget 5: `ProgressBar` (SIGNAL_STRENGTH)
Replaced by a segmented HUD-style indicator.
```dart
// Appearance: Row of small rectangles (e.g., 20 segments)
// Filled segments: signalGreen with glow
// Empty segments: borderGlow color
// Animate fills with staggered AnimationController
```

#### Widget 6: `TimerWidget`
An amber countdown used during Breach Attempts (quizzes).
```dart
// Appearance: Large monospace number, amber color
// Under 10 seconds: pulse animation, color shifts to dangerRed
// Package: Use 'circular_countdown_timer' or custom AnimationController
```

### 2.5 Recommended Flutter Packages

| Package | Purpose | Priority |
|---|---|---|
| `google_fonts` | Rajdhani + JetBrains Mono typography | CRITICAL |
| `animated_text_kit` | GlitchText, typewriter effects | CRITICAL |
| `lottie` | Breach success/failure animations | HIGH |
| `flutter_animate` | Micro-interactions on every widget | HIGH |
| `go_router` | Navigation (required for clean deep links) | CRITICAL |
| `riverpod` | State management (not Provider — Riverpod is cleaner for this arch) | CRITICAL |
| `circular_countdown_timer` | Quiz timer | MEDIUM |
| `flutter_card_swiper` | Swipeable DATA CACHE theory cards | MEDIUM |
| `audioplayers` | Subtle SFX on correct/wrong answer | LOW |

**Do NOT add:** `get` (GetX), `bloc` (too verbose for hackathon), `flame` (full game engine — overkill).

### 2.6 Screen Architecture

```
lib/
├── theme/
│   ├── app_theme.dart          ← Single source of truth
│   └── netrunner_colors.dart
├── widgets/                    ← The 6 HUD widgets above
│   ├── hud_card.dart
│   ├── glitch_text.dart
│   ├── hud_button.dart
│   ├── scanline_overlay.dart
│   ├── progress_bar.dart
│   └── timer_widget.dart
├── screens/
│   ├── neural_scan/            ← Placement test
│   ├── breach_map/             ← Course map
│   ├── data_cache/             ← Theory cards (swipeable)
│   ├── breach_attempt/         ← AI Quiz
│   ├── quarantine_zone/        ← Revision module
│   └── arena/                  ← Competition
└── services/
    ├── api_service.dart        ← All Node.js calls
    └── auth_service.dart       ← Firebase Auth
```

### 2.7 Animation Strategy (The "Game Feel" Checklist)

Every screen transition must feel like entering a new system sector. Use `flutter_animate` for these patterns:

- **Screen entry:** `.animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0)`
- **Correct answer:** Lottie animation (green burst) + `ScanlineOverlay` briefly flashes green
- **Wrong answer:** Screen briefly tints red using `ColorFiltered`, `GlitchText` fires
- **Tier reveal:** Full-screen overlay with typewriter text, 2-second hold, then swipe away
- **AI generating remediation:** A pulsing spinner labeled `[PATCH_PROTOCOL GENERATING...]` using `AnimatedTextKit` repeating dots

---

## 3. Hybrid Architecture & Data Flow

### 3.1 Architecture Philosophy

The rule for a 24-hour build: **Firebase handles auth and AI inference. Node.js handles business logic and MongoDB. Flutter only talks to Node.js.** One interface, one contract.

The only exception: Flutter uses the Firebase Auth SDK directly (client-side) to get a JWT token, which it then passes to every Node.js request as a Bearer token.

### 3.2 Complete Data Flow Map

#### Flow A: Neural Scan (Placement Test)

```
Flutter                    Node.js                   Firebase Genkit         MongoDB
  │                           │                            │                    │
  ├─[Guest enters app]        │                            │                    │
  ├──POST /neural-scan/start──►                            │                    │
  │                           ├──Generate 8 logic Qs──────►                    │
  │                           │  (Genkit, structured JSON) │                    │
  │                           ◄──[{id, question, options,  │                    │
  │                           │    difficulty, type}]       │                    │
  ◄──[questions array]────────┤                            │                    │
  │                           │                            │                    │
  ├─[User answers 8 Qs]       │                            │                    │
  ├──POST /neural-scan/submit──►                           │                    │
  │   {answers[], timings[]}  ├──Score + classify──────────────────────────────►
  │                           │  (business logic, NOT AI)  │    Save tier+       │
  │                           │                            │    guestProfile     │
  ◄──{tier, message, userId}──┤                            │                    │
```

**Key decision:** Scoring is pure Node.js math. Don't waste an AI call on pass/fail logic. AI is reserved for *generation* and *explanation*.

#### Flow B: Data Cache + Breach Attempt (The Core Loop)

```
Flutter                    Node.js                   Firebase Genkit         MongoDB
  │                           │                            │                    │
  ├─[User opens Vault N]      │                            │                    │
  ├──GET /vault/{id}/cache────►                            │                    │
  │                           │                            │           Load static│
  │                           │◄──────────────────────────────────────────────── │
  ◄──{3 theory cards}─────────┤  (pre-written by content  │                    │
  │   (static content)         │   team, stored in MongoDB)│                    │
  │                           │                            │                    │
  ├─[User swipes all 3 cards] │                            │                    │
  ├──POST /breach/generate─────►                           │                    │
  │   {vaultId, tier, userId} ├──Genkit: Generate 5 Qs────►                    │
  │                           │  with structured output     │                    │
  │                           │  schema (see 3.3 below)     │                    │
  │                           ◄──{questions[]}──────────── │                    │
  ◄──{sessionId, questions[]}─┤                            │                    │
  │                           │                            │                    │
  ├─[User answers each Q]     │                            │                    │
  ├──POST /breach/answer───────►                           │                    │
  │   {sessionId, qId,        ├──Log answer + reasoning────────────────────────►
  │    selectedOption,         │  Save: {answer, wasCorrect,│    answers log      │
  │    timeSpent}              │   selectedText, correctText}│                   │
  ◄──{isCorrect, explanation}─┤  (Node.js grades it)       │                    │
```

#### Flow C: Quarantine Zone (The "Depth" Feature)

This is your vertical spike. This is what wins the hackathon.

```
Flutter                    Node.js                   Firebase Genkit         MongoDB
  │                           │                            │                    │
  ├─[User fails Vault N]      │                            │                    │
  ├──POST /quarantine/init─────►                           │                    │
  │   {sessionId}             ├──Load full answer log──────────────────────────►
  │                           │◄─────────────────────────── │       answer log   │
  │                           │                            │                    │
  │                           ├──Genkit: Analyze failure───►                    │
  │                           │  PROMPT (see 3.4):         │                    │
  │                           │  "User answered Q3 about   │                    │
  │                           │  recursion. They chose     │                    │
  │                           │  option B ('base case runs │                    │
  │                           │  last') — correct was C.   │                    │
  │                           │  Diagnose misconception    │                    │
  │                           │  and generate a 3-step     │                    │
  │                           │  remediation plan in JSON."│                    │
  │                           │                            │                    │
  │                           ◄──{patchProtocol JSON}──────┤                    │
  │                           │  (see 3.4 schema)          │                    │
  │                           ├─────────────────────────────────────────────────►
  │                           │                            │    Save patch plan │
  ◄──{patchProtocol}──────────┤                            │                    │
  │                           │                            │                    │
  ├─[Render Patch Protocol UI]│                            │                    │
  │  (diagnosed misconception,│                            │                    │
  │   3 micro-lessons,        │                            │                    │
  │   1 targeted re-quiz)     │                            │                    │
```

### 3.3 Structured JSON Output Schema (Breach Attempt)

This is critical. Use Genkit's `defineSchema` for validated output. Pass this to your Backend engineer verbatim.

```typescript
// Genkit schema — enforced at inference time
const BreachQuestionSchema = z.object({
  questions: z.array(z.object({
    id:             z.string(),
    questionText:   z.string(),
    codeSnippet:    z.string().optional(),  // Include code when relevant
    options: z.array(z.object({
      id:           z.string(),             // "A", "B", "C", "D"
      text:         z.string(),
      isCorrect:    z.boolean(),
    })),
    difficulty:     z.enum(["RECRUIT", "ROGUE", "PHANTOM"]),
    conceptTag:     z.string(),            // e.g., "recursion", "O(n) complexity"
    explanation:    z.string(),            // Shown after answer revealed
  })).length(5),
});
```

**Why this matters to judges:** Structured output is not a gimmick. It means your AI never breaks the UI. An unstructured LLM response can return anything and crash a parser. Validated schema is what "production AI" looks like. **Mention this explicitly during your demo.**

### 3.4 Quarantine Zone Prompt Template

Store this as a Genkit prompt file (`quarantine.prompt`). Your AI Prompting teammate owns and refines this.

```
You are a programming pedagogy engine for NETRUNNER, a cyberpunk coding learning platform.

A student failed the quiz on the topic: "{{vaultTopic}}".

Here is their complete answer history:
{{answerLog}}

For each wrong answer, the student's selected option text is provided alongside the correct answer.

Your task:
1. Identify the PRIMARY misconception causing their failures (be specific — not "they don't understand arrays" but "they believe array indices start at 1").
2. Generate a PATCH_PROTOCOL in the JSON schema below.

Return ONLY valid JSON matching this exact schema:

{
  "diagnosedMisconception": "string — one sentence describing the specific wrong mental model",
  "misconceptionSeverity": "surface | deep | fundamental",
  "patchSteps": [
    {
      "stepNumber": 1,
      "type": "analogy | example | counter_example | visualization_prompt",
      "title": "string — max 6 words",
      "content": "string — the actual micro-lesson content",
      "interactivePrompt": "string — one question to check understanding of THIS step"
    }
    // exactly 3 steps
  ],
  "targetedReQuizFocus": "string — a specific sub-concept for a follow-up quiz",
  "estimatedRepairTime": "string — e.g., '4 minutes'"
}
```

### 3.5 Node.js API Contract

All endpoints your Flutter app calls. Backend engineer builds to this exact spec.

```
POST   /api/auth/guest              → Create guest profile
POST   /api/neural-scan/start       → Get placement questions
POST   /api/neural-scan/submit      → Submit answers, receive tier
GET    /api/vault/:id/cache         → Get theory cards for a vault
POST   /api/breach/generate         → Generate AI quiz for vault
POST   /api/breach/answer           → Submit single answer, get feedback
POST   /api/breach/complete         → Submit session results
POST   /api/quarantine/init         → Trigger AI analysis, get Patch Protocol
GET    /api/runner/profile          → Get user stats
GET    /api/arena/challenges        → Get pending duels
POST   /api/arena/challenge         → Issue a duel
```

All responses use this envelope:
```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

---

## 4. Team Task Distribution

### 4.1 Principle: "Plug-In Ready" Work

Every non-coding task must produce a deliverable that can be pasted into the app with zero interpretation. The format is specified below. **Give each teammate a copy of their section only.**

---

### TEAMMATE A: Content & Story Lead

**Your deliverable format:** A single `content.json` file structured exactly as below. The developer will import this directly.

**Tasks:**

**Task 1 — Vault Theory Cards (DATA CACHE)**
For each of these 5 topics, write exactly 3 cards. Each card has a `title` (max 5 words) and `body` (max 50 words). Use the NETRUNNER voice — you're a hacker briefing another hacker, not a teacher.
Topics: Variables & Data Types, Functions, Loops, Arrays, Recursion.

```json
// Target format:
{
  "vaults": [
    {
      "id": "vault_001",
      "topic": "Variables & Data Types",
      "cacheCards": [
        { "cardNumber": 1, "title": "Data is just a label", "body": "A variable is a named slot in memory. Think of it as a container with a tag. The tag (name) lets you find it. The contents (value) can change. The Citadel stores everything this way." },
        { "cardNumber": 2, "title": "...", "body": "..." },
        { "cardNumber": 3, "title": "...", "body": "..." }
      ]
    }
  ]
}
```

**Task 2 — Lore Loading Screen Texts**
Write 20 lines of "intercepted Citadel transmissions." Format: plain array of strings. Each under 15 words. See section 1.4 for examples.

**Task 3 — Tier Reveal Scripts**
Write the 3 cinematic text sequences for RECRUIT, ROGUE, and PHANTOM tier reveals. Each is a sequence of 3 lines that type out one by one. Format:
```json
{ "tier": "RECRUIT", "lines": ["Line 1 text", "Line 2 text", "Line 3 text"] }
```

**Task 4 — Arena Challenge Taunts**
Write 10 "challenge issued" messages a runner sends when challenging another. Format: array of strings. E.g., *"Your uptime is about to flatline, runner."*

---

### TEAMMATE B: AI Prompting Specialist

**Your deliverable format:** Refined text files that replace the templates in Section 3.4.

**Tasks:**

**Task 1 — Master Quarantine Prompt (HIGHEST PRIORITY)**
Take the prompt template in Section 3.4 and refine it. Test it by manually calling the Gemini API (use Google AI Studio — it's free). Your metric: does the output JSON always parse? Is the `diagnosedMisconception` specific (not vague)?

Run these 3 test scenarios and tune the prompt until all 3 produce useful, specific JSON:
- Scenario A: User consistently picks "off by one" answers in loop questions
- Scenario B: User confuses pass-by-value with pass-by-reference
- Scenario C: User doesn't understand when a recursive function bottoms out

**Task 2 — Breach Generation System Prompt**
Write the system prompt that goes before every quiz generation request. It must enforce:
- Questions feel like real coding interview/challenge questions (not textbook MCQs)
- Code snippets use a consistent style (no semicolons for Python, proper indentation)
- Distractors (wrong answers) are *plausible* — common mistakes, not random

**Task 3 — Neural Scan Question Bank**
Write 16 pure-logic questions (no coding knowledge required) in this format:
```json
{ "id": "ns_001", "question": "If all Bloops are Razzles and all Razzles are Lazzles, are all Bloops definitely Lazzles?", "options": ["Yes", "No", "Cannot be determined"], "correctId": "A", "difficulty": "RECRUIT" }
```
These do NOT use AI — they're served statically. Write 6 RECRUIT, 6 ROGUE, 4 PHANTOM difficulty.

**Task 4 — Explanation Quality Review**
After the developer builds the Breach Attempt screen, manually run 20 questions and grade each AI-generated explanation on a 1-3 scale. Flag any that are too long (>40 words), too vague, or incorrect. This is your QA pass.

---

### TEAMMATE C: Visuals & Pitch Lead

**Your deliverable format:** Exported assets in the exact specs below, placed in a shared folder named `assets/`. Developer drops this folder directly into Flutter.

**Tasks:**

**Task 1 — App Icon & Splash Screen**
Design ONE icon. Concept: a circuit board in the shape of a skull, or an eye made of code characters, or a terminal cursor inside a hexagon. Export:
- `icon_1024x1024.png` (App Store)
- `splash_bg.png` (1920x1080, dark background with subtle grid pattern)

**Task 2 — Vault Node Icons (Breach Map)**
Design 3 versions of a "vault node" for the map screen:
- `node_locked.svg` — padlock + circuit lines
- `node_available.svg` — open padlock, glowing green border
- `node_breached.svg` — checkmark, "static" texture effect

**Task 3 — Lottie Animations (2 required)**
Use LottieFiles.com to find (or customize) two animations. Download as `.json`:
- `breach_success.json` — green particle burst (search "success checkmark", filter by dark bg)
- `firewall_hit.json` — red glitch/static effect (search "error glitch")

Name them exactly as above. Place in `assets/animations/`.

**Task 4 — Pitch Deck (THE MOST IMPORTANT TASK)**
Build a 7-slide deck. Structure:
1. **The Problem** — "Quiz apps don't teach. They test what you already know." (1 dramatic stat)
2. **The Vision** — One sentence, one screenshot mock
3. **The Tech** — Architecture diagram (use Section 3 as source)  
4. **The Demo Flow** — 4 screenshots showing: Neural Scan → Vault → Breach Attempt → Quarantine Zone
5. **The Depth** — Show the Quarantine Zone JSON response. This is your "look how non-shallow we are" slide.
6. **The Market** — 2 competitors (Codecademy, Brilliant), what they miss, how you win
7. **The Ask** — What you want (if applicable) + team

---

## 5. Critical Review & Market-Readiness Checklist

### 5.1 What Your Previous Judges Were Actually Saying

"Shallow" and "just a quiz app" translate to three specific technical gaps:

| Criticism | What It Actually Means | Our Fix |
|---|---|---|
| "Shallow" | AI is decorative, not functional. Remove it and the app still works the same. | Quarantine Zone: AI is the product. Without it, the feature doesn't exist. |
| "Just a quiz" | No feedback loop. Right/wrong is the whole story. | Patch Protocol explains *why* the user failed and gives a personalized path forward. |
| "Vibe-coded UI" | Inconsistent font sizes, random colors, no design system. | AppTheme singleton. Every pixel from the same source. |

### 5.2 Buzzword Traps to Avoid

These phrases will get you eye-rolls from technical judges. **Never say them without proof:**

| Say This ❌ | Say This Instead ✅ | Why |
|---|---|---|
| "AI-powered learning" | "Gemini generates personalized remediation plans based on a user's specific wrong answer, validated against a typed JSON schema" | Specificity is credibility |
| "Adaptive learning" | "The quiz difficulty dynamically adjusts based on the user's tier, which is computed from the Neural Scan scoring algorithm" | "Adaptive" means nothing without a mechanism |
| "Personalized experience" | "The Quarantine Zone identifies the user's specific misconception — not the general topic — and generates a targeted 3-step remediation plan" | Personalized ≠ individualized unless you show how |
| "Scalable architecture" | (Don't say this at all in a hackathon — nobody cares) | It's filler |
| "Full-stack application" | (Also don't say this — it's assumed) | Wasted words |

### 5.3 What's Currently Missing (Add If Time Permits)

**Priority 1 — Onboarding Friction Metric (Add this)**
Track and display: "Average time to first Breach Attempt: X seconds." This single metric proves low-friction entry to judges. Log `timestamp` when app opens and when first quiz starts. Display on the pitch deck.

**Priority 2 — The "Aha Moment" Graph**
Show judges a MongoDB query result: "Users who went through the Quarantine Zone passed their retry quiz 73% of the time." Even with synthetic data from your own testing, this proves the remediation loop works. **This is your money slide.**

**Priority 3 — Arena Demo Readiness**
The Arena (asynchronous duels) is the riskiest feature. If it's not demo-ready 3 hours before judging, **cut it entirely and say "Arena mode is in Phase 2."** A broken feature is worse than a missing one. A polished 3-feature app beats a half-broken 5-feature app every time.

**Priority 4 — Offline Fallback**
If the AI API is slow during the live demo (it happens), have 10 pre-cached quiz sessions stored in MongoDB. Your app should seamlessly fall back to these. Judges will never know. A frozen loading screen during a live demo is catastrophic.

### 5.4 The "Market-Ready" Differentiation Statement

Prepare this 30-second verbal pitch. Every team member memorizes it:

> *"Most learning apps give you a right/wrong answer and move on. We give you a diagnosis. Our Quarantine Zone uses Gemini to analyze not just that you failed, but which specific wrong mental model caused the failure — and it generates a personalized 3-step remediation plan. This isn't a quiz app. It's an adaptive tutor that learns your misconceptions."*

### 5.5 The Demo Script (Non-Negotiable)

Practice this exact flow 3 times before judging:

1. Open app → tap "GHOST PROTOCOL" (Guest Mode)
2. Neural Scan → answer 4 questions, deliberately get 2 wrong → receive ROGUE tier
3. Open Vault 1 → swipe all 3 Data Cache cards (15 seconds max)
4. Start Breach Attempt → answer 5 questions, deliberately fail 2
5. Receive "FIREWALL HIT" → enter QUARANTINE ZONE
6. Show the Patch Protocol screen — **pause here and read the diagnosed misconception aloud**
7. Show the raw JSON response from Genkit on a second screen (your Visuals teammate holds a laptop)
8. Say: *"This is a real AI response, generated in real-time, specific to the exact wrong answer this user just gave."*

---

## 6. Build Timeline — 24-Hour Sprint

### Hour 0–4: Foundation (Flutter Dev + Backend Dev)

**Flutter Dev:**
- [ ] `AppTheme` class with all colors and typography
- [ ] All 6 HUD widgets built and tested in isolation
- [ ] `go_router` navigation skeleton (all routes defined, screens are empty placeholders)
- [ ] `api_service.dart` with auth header injection

**Backend Dev:**
- [ ] Express server running on port 3000
- [ ] MongoDB connected, `Vault`, `Runner`, `BreachSession`, `AnswerLog` models defined
- [ ] Firebase Admin SDK initialized for JWT verification
- [ ] `/health` endpoint working

**Content Teammate:** Writing all Data Cache cards (Task 1)
**AI Prompting Teammate:** Testing Quarantine prompt in Google AI Studio
**Visuals Teammate:** Working on icon, node assets

### Hour 4–10: Core Loop (The Vertical Spike)

**Flutter Dev:**
- [ ] Neural Scan screen (static questions)
- [ ] Tier reveal animation screen
- [ ] Vault/Breach Map screen (even with hardcoded nodes)
- [ ] Data Cache swipe screen (plug in Content teammate's JSON)
- [ ] Breach Attempt screen (connect to backend)

**Backend Dev:**
- [ ] `/neural-scan/*` endpoints
- [ ] `/vault/:id/cache` endpoint
- [ ] `/breach/generate` endpoint with Genkit integration
- [ ] `/breach/answer` endpoint
- [ ] Structured JSON schema enforced on Genkit outputs

### Hour 10–16: The Quarantine Zone (The "Depth" Feature)

**Flutter Dev:**
- [ ] Quarantine Zone screen with Patch Protocol renderer
- [ ] Lottie animations integrated (Breach Success + Firewall Hit)
- [ ] Runner Profile screen with stats

**Backend Dev:**
- [ ] `/quarantine/init` endpoint with full Genkit prompt
- [ ] Answer log aggregation for Quarantine context
- [ ] Offline fallback: pre-cache 10 quiz sessions

**AI Prompting Teammate:** Final Quarantine prompt refinement, QA pass on explanations
**Content Teammate:** Lore texts, tier reveal scripts, arena taunts
**Visuals Teammate:** Finishing pitch deck

### Hour 16–21: Polish & Integration

- [ ] End-to-end flow tested (Neural Scan → Quarantine Zone) without breaks
- [ ] All Content teammate JSON files integrated
- [ ] Lottie files dropping into `assets/animations/`
- [ ] Arena stub screen (if time permits) OR cut entirely
- [ ] Offline fallback tested

### Hour 21–24: Demo Prep

- [ ] Full demo run x3
- [ ] MongoDB seeded with 3 "synthetic users" showing Quarantine Zone usage stats
- [ ] Pitch deck final version
- [ ] One pre-cached demo session ready as backup
- [ ] Every teammate knows the 30-second verbal pitch

---

## Appendix: MongoDB Schema Reference

```javascript
// Vault (static content)
{ _id, topicName, tier, cacheCards: [{cardNumber, title, body}], isActive }

// Runner (user profile)
{ _id, firebaseUID, tier, signalStrength, uptime, completedVaults: [], createdAt }

// BreachSession (one quiz attempt)
{ _id, runnerId, vaultId, startedAt, completedAt, score, passed }

// AnswerLog (one answer within a session)
{ _id, sessionId, questionId, questionText, selectedOptionId, selectedOptionText, 
  correctOptionText, isCorrect, timeSpentMs, conceptTag }

// PatchProtocol (AI-generated remediation plan)
{ _id, runnerId, sessionId, diagnosedMisconception, misconceptionSeverity, 
  patchSteps: [{stepNumber, type, title, content, interactivePrompt}], 
  targetedReQuizFocus, generatedAt }
```

---

*Document prepared for internal team use. Build starts now.*
*Last updated: v1.0 | Questions go to the Flutter dev lead.*
