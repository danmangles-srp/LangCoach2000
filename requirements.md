# requirements.md

> Source of truth for **WHAT** to build. Functional requirements (`FR-*`) and non-functional
> requirements (`NFR-*`). The Acceptance Criteria in `plan.md` are the definition of done for each.
> This is an **offline-first, serverless, no-auth** Android app. The only network egress is
> user-initiated AI image generation (FR-1.3.4) and the weekly email report (FR-1.5.3) — both queued
> and fired on reconnect (NFR-2.1.3). There is **no monetization in scope** for v1.

## Glossary

- **Recording** — an indexed audio file (`.m4a`/`.mp3`/`.wav`) from the Samsung Voice Recorder directory.
- **GPA** — Growing Participator Approach. The review schedule every recording follows.
- **GPA interval** — the day offsets `1, 2, 4, 7, 30, 90, 180, 365` after a recording's creation date.
- **Word log** — a text or image vocabulary sheet attached to a recording.
- **Type 1 card** — Anki flashcard: English text ↔ Uzbek text.
- **Type 2 card** — Anki flashcard: AI-generated concept image → Uzbek text.

## 1. Functional Requirements

### 1.1 Audio Management & System Integration
* **FR-1.1.1:** On first launch the app must prompt the user (native folder picker) to select or confirm
  their Samsung Voice Recorder directory, then dynamically index audio files (`.m4a`, `.mp3`, `.wav`)
  found there on initialization and on subsequent startups.
* **FR-1.1.2:** The app must integrate with the native Android file/storage API to pull metadata
  (creation date, name, file size) from files created by external apps like Samsung Voice Recorder.
* **FR-1.1.3:** The in-app audio recorder must save files directly to the user-designated Samsung storage
  directory so the unified audio pool stays in one place and is re-indexed on next scan.
* **FR-1.1.4:** The internal audio player must support background playback, media-session controls, and
  audio-focus management (pause on incoming call, resume/duck per Android norms).

### 1.2 GPA Spaced-Repetition Scheduler
* **FR-1.2.1:** Every indexed recording must possess a review timeline computed from its creation-date
  stamp over the GPA intervals.
* **FR-1.2.2:** The calculation engine must evaluate review status against day-intervals
  `D+1, D+2, D+4, D+7, D+30, D+90, D+180, D+365`.
* **FR-1.2.3:** When a recording is played past **80%** of its total duration, the app appends a
  **review event** to an append-only per-recording log (recording id, milestone index, completed-at
  timestamp). "Reviewed for milestone N" is **derived** from the existence of an event for that milestone
  — there is no separate flag to keep in sync.
* **FR-1.2.4:** The app must surface each recording's review history — last reviewed date, milestone
  reached, and total review count — on its detail screen, derived from the review-event log.
* **FR-1.2.5:** Today's queue must show recordings due today; a recording that became due yesterday
  (1 day stale) is still presented and marked stale, but the stale prompt disappears on the 2nd stale day.

### 1.3 Vocabulary & Flashcard Automation
* **FR-1.3.1:** Users must be able to link a text vocab log and/or one or more image logs (JPG/PNG of
  notebook pages) directly to an audio recording record. Schema: one text log and/or multiple images per
  recording.
* **FR-1.3.2:** A text-parsing engine must automatically extract English-definition ↔ Uzbek-word pairs
  from text logs via delimiter maps (e.g. lines containing `:` or `-`) to feed card generation.
* **FR-1.3.3:** The app must push flashcards to **AnkiDroid via its Android intent API** (creating the
  deck, note type, and notes), tagging each note with the source recording's filename.
* **FR-1.3.4:** An imaging pipeline must assign a concept graphic to newly generated vocab items by
  calling **Fal.ai** when the device is online. Generation is queued + drained on reconnect, cached per
  word (never regenerated for the same Uzbek word), and skipped entirely when offline.

### 1.4 Task Tracking & Coaching Utilities
* **FR-1.4.1:** A tasks engine supporting custom title, description, due date, and completion status flag.
* **FR-1.4.2:** The app must schedule local notifications/alarms via the OS to alert the user to pending
  drills or deadlines; notifications must fire accurately even when the app is fully closed.
* **FR-1.4.3:** A "Coach Bank" repository must store structured text scripts and/or map existing
  recordings or vocab words into a structured agenda for live coaching sessions.

### 1.5 Analytics & Automated Email Delivery
* **FR-1.5.1:** The app must log engagement metrics: Lesson Duration, Journaling Output (text-log entry
  count), Completed Queue items, and Flashcards reviewed.
* **FR-1.5.2:** Data-visualization components must render native charts depicting metrics against target
  weekly milestones (daily / weekly / monthly views).
* **FR-1.5.3:** A background reporting engine must aggregate weekly metrics and dispatch a custom-styled
  HTML report to the user's email address via **SMTP** (background send, queued + drained on reconnect).
  SMTP credentials are supplied via `--dart-define`, never stored in the repo.

---

## 2. Non-Functional Requirements

### 2.1 Offline Architecture (Offline-First)
* **NFR-2.1.1:** All core engines — file indexing, GPA queue scheduling, task tracking, playback logs,
  vocab/Anki generation — must execute without an active internet connection.
* **NFR-2.1.2:** All data persists in a local relational store (SQLite via Drift). There is no server and
  no sync engine; the local DB is the single source of truth.
* **NFR-2.1.3:** Features requiring connectivity (AI image generation, email dispatch) must queue
  background tasks and execute automatically upon network restoration.

### 2.2 Performance & Scalability
* **NFR-2.2.1:** Filesystem indexing must evaluate up to 1,000 files in under 2.0 seconds without frame
  drops or blocking the UI thread (run off the main isolate).
* **NFR-2.2.2:** Audio playback latency from UI touch to hardware output must not exceed 250 ms.

### 2.3 Architectural Portability
* **NFR-2.3.1:** The application core should decouple data and business logic from UI/platform layers so a
  future iOS port is feasible with minimal core-logic change (Flutter + platform-adapter seams; Android is
  the v1 target, iOS is out of scope for v1).

### 2.4 User Experience, Aesthetics & Trust
* **NFR-2.4.1:** The interface must reflect a bespoke luxury tier — clean micro-interactions, cohesive
  dark/light typography scales, smooth transitions, and no unhandled error states.
* **NFR-2.4.2:** Given the sensitive, personal nature of cultural-sharing recordings, all text logs and
  captured conversations must be securely processed locally under strict sandboxed privacy. The local DB
  is encrypted (SQLCipher) by default.

### 2.5 Accessibility & Internationalization
* **NFR-2.5.1:** UI meets WCAG 2.1 AA (contrast, touch targets ≥48dp, semantics, screen-reader labels).
* **NFR-2.5.2:** UI strings are externalized for i18n; v1 ships in English. (Learned content — Uzbek
  words — is data, not UI strings.)

### 2.6 Security & Keys
* **NFR-2.6.1:** No secrets in the client repo. The Fal.ai API key and SMTP credentials are injected via
  `--dart-define` at build time. The only network egress is the two gated services in §1.3.4 / §1.5.3.
