# ⚡ CodeQuest — Gamified Cyberpunk Learning Engine

[![Flutter](https://img.shields.io/badge/Frontend-Flutter_3.8+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js_v20+-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Framework-Express_5.0-000000?logo=express&logoColor=white)](https://expressjs.com)
[![MongoDB](https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb&logoColor=white)](https://mongodb.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> *"The Citadel's AI has locked humanity's collective knowledge behind encrypted vaults. You are a NETRUNNER — a rogue coder who must breach each vault, survive the QUARANTINE PROTOCOLS, and challenge rival runners in the ARENA."*

---

## 🌟 Overview

**CodeQuest** is a production-grade, adaptive programming learning platform styled as a futuristic **NETRUNNER HUD interface**. Replacing standard quiz mechanics with interactive cyber-vault breaches, neural calibration scans, and automated quarantine remediation protocols, CodeQuest delivers an immersive, gamified learning experience for computer science fundamentals.

---

## 🏗️ Architecture & Data Flow

```
                                ┌─────────────────────────────────────────┐
                                │          NETRUNNER HUD CLIENT           │
                                │           (Flutter 3.8 / Dart)          │
                                └────────────────────┬────────────────────┘
                                                     │
                                         REST API / Bearer Token
                                                     │
                                ┌────────────────────▼────────────────────┐
                                │        CODEQUEST ENGINE BACKEND         │
                                │       (Node.js / Express 5 API)         │
                                └──────┬──────────────┬──────────────┬────┘
                                       │              │              │
                    ┌──────────────────▼───┐  ┌───────▼──────┐  ┌────▼───────────────┐
                    │ JWT Auth Middleware  │  │ Neural Scan  │  │  Quarantine Zone  │
                    │  & Session Control   │  │ Engine Evaluator│ Remediation Logic │
                    └──────────────────┬───┘  └───────┬──────┘  └────┬───────────────┘
                                       │              │              │
                                ┌──────▼──────────────▼──────────────▼────┐
                                │             MONGODB CLUSTER             │
                                │   (Courses, Vaults, Quizzes, Progress)  │
                                └─────────────────────────────────────────┘
```

---

## 🎮 NETRUNNER Terminology Map

| Traditional Term | NETRUNNER Term | Cyberpunk UI Label |
|---|---|---|
| Placement Test | **NEURAL SCAN** | `[INITIALIZING NEURAL SCAN...]` |
| Novice Tier | **RECRUIT** | `RECRUIT // CLEARANCE LVL 01` |
| Intermediate Tier | **ROGUE** | `ROGUE // CLEARANCE LVL 02` |
| Advanced Tier | **PHANTOM** | `PHANTOM // CLEARANCE LVL 03` |
| Lesson / Module | **DATA CACHE** | `[CACHE DECRYPTED]` |
| Practice Quiz | **BREACH ATTEMPT** | `INITIATING BREACH //` |
| Error Revision | **QUARANTINE ZONE** | `[ENTERING QUARANTINE]` |
| XP / Points | **SIGNAL STRENGTH** | `SIG: {points}` |
| Streak | **UPTIME** | `UPTIME: {N} DAYS` |
| Leaderboard | **THREAT INDEX** | `THREAT INDEX // GLOBAL` |

---

## 🚀 Key Features

* **Adaptive Placement Engine ("Neural Scan")**: Dynamically calibrates runner proficiency (Sequential, Conditional, Loop logic) and places users into optimized clearance tiers.
* **Interactive Vault Maps**: Visual node-based breach progression map with unlocked, active, and completed state indicators.
* **Multi-Modal Interactive Mechanics**: Supports multi-choice breaches, drag-and-drop code assembly, syntax spot-the-bug challenges, and reorder sequence puzzles.
* **Quarantine Zone Remediation**: Automated tracking of failed attempt vectors generating targeted `PATCH PROTOCOL` revisions.
* **Global Threat Index Leaderboard**: Real-time ranking of runners by Signal Strength (XP) and Uptime streaks.

---

## 📡 API Endpoint Reference

### Authentication & Profile (`/api/user`)
* `POST /api/user/signup` — Register a new runner profile.
* `POST /api/user/login` — Authenticate runner & issue JWT.
* `POST /api/user/evaluate-level` — Process Neural Scan diagnostic quiz answers.
* `GET  /api/user/profile` — Fetch authenticated runner profile details.
* `POST /api/user/set-level` — Set runner clearance level (`Beginner`, `Intermediate`, `Advanced`).
* `POST /api/user/update-language` — Set active programming language track.
* `POST /api/user/sync` — Sync XP signal strength and streak uptime.
* `GET  /api/user/leaderboard` — Retrieve global threat index rankings.
* `GET  /api/user/quarantine` — Fetch flagged quarantine revision questions.

### Learning Engine (`/api/learning`)
* `GET  /api/learning/courses` — List all available learning tracks.
* `GET  /api/learning/courses/:courseId/map` — Retrieve full vault map hierarchy (Chapters, Subtopics, Quizzes).
* `GET  /api/learning/subtopics/:subtopicId/questions` — Fetch breach questions for a node.
* `POST /api/learning/quizzes/:quizId/submit` — Submit quiz answers & record user progress.

---

## 💻 Quick Start & Setup

### Prerequisites
* **Node.js**: v18+ 
* **MongoDB**: Running instance on `mongodb://127.0.0.1:27017`
* **Flutter SDK**: 3.8+

### 1. Backend Setup & Data Seeding

```bash
# Navigate to backend directory
cd codequest_backend

# Install dependencies
npm install

# Seed MongoDB with default course vaults & quizzes
npm run seed

# Run automated API test suite
npm test

# Start development server
npm run dev
```
Backend will start on `http://localhost:5050` with health check live at `http://localhost:5050/health`.

### 2. Frontend Launch

```bash
# Navigate to frontend directory
cd codequest_frontend

# Install Flutter dependencies
flutter pub get

# Launch Flutter HUD client
flutter run
```

---

## 📄 License
Distributed under the MIT License. Built with ❤️ for hackathons and production deployment.
