# plan.md

> The ordered **HOW** for Rivendell — an offline-first Android app that turns Samsung Voice Recorder
> recordings into a GPA review pipeline with vocab logs, Anki flashcards, AI concept images, coaching
> tasks, and weekly email reports. Six milestones, executed in order; **all six = sellable v1.0**.
> Each milestone ends with a **ticket list — 1 ticket = 1 PR** off `dev`, in dependency order. Don't
> start the next ticket until the current one's gate exits `0` and its PR is open.
>
> Read **Architecture decisions** and **Reconciled dependency matrix** first — they are authoritative for
> the stack. Source of truth for *what* is `requirements.md` (FR-* / NFR-*); its ACs are the definition
> of done.

## Architecture decisions

1. **Single platform: Android.** Samsung Voice Recorder integration, AnkiDroid intents, scoped-storage
   access, and background work are all Android-specific. iOS is explicitly **out of scope for v1**
   (NFR-2.3.1 keeps the core portable, but we are not shipping iOS). Min OS **Android API 26 (8.0)**.
2. **Flutter + Riverpod + Drift.** Feature-first under
   `lib/features/<feature>/{presentation,application,data,domain}`. Drift (SQLite + SQLCipher) is the
   single source of truth — **no backend, no sync, no auth**. Repositories wrap a local datasource behind
   an abstract seam so a remote could be added later, but none exists now.
3. **Offline-first, not offline-only.** All core engines run offline. Exactly two features need network:
   **Fal.ai image generation** (FR-1.3.4) and **SMTP email reports** (FR-1.5.3). Both run behind a
   **connectivity-gated service seam** with a persistent **offline queue** drained by a
   `workmanager`-style background worker on reconnect (NFR-2.1.3).
4. **Anki via AnkiDroid intents, on-device.** Not AnkiConnect (that's HTTP-to-desktop and breaks
   offline-first). We use AnkiDroid's `com.ichi2.anki` intents to create decks, note types, and notes
   directly on the device. Requires AnkiDroid installed; we detect + gracefully degrade with a clear
   "install AnkiDroid" CTA if absent.
5. **AI images via Fal.ai.** Provider pinned. Per-word cache (an Uzbek word is generated at most once),
   connectivity-gated, skipped offline (Type 2 card shows a placeholder until generated). Key via
   `--dart-define`; no key in the repo.
6. **Weekly report via SMTP.** Background send, queued + drained on reconnect. SMTP creds + recipient
   configured via `--dart-define` / in-app settings; never in the repo. Report rendered as styled HTML.
7. **Business logic is pure Dart.** GPA interval math, vocab parsing, queue scheduling, metric
   aggregation — all testable without a device or emulator.
8. **Encrypted local DB (SQLCipher) by default** (NFR-2.4.2). Recordings are sensitive cultural content.
9. **Review completion is an append-only event log, not a flag.** A `review_events` table records one
   row per completed milestone (recording id, milestone index, completed-at). "Reviewed for milestone N",
   "last reviewed", and "review count" are all **derived** from this log — no boolean column to keep in
   sync, and the same log feeds the M6 "Completed Queue items" metric. Replaying the same milestone
   appends a new event (a user can review the same interval more than once); the *active* milestone is
   still the next-unreached one.
10. **No monetization in v1.** No IAP, no paywall, no RemoteConfig. Scope creep into billing is explicitly
   out of scope.
10. **v1 cut = all six milestones.** M1–M3 form the daily-use core; M4–M6 add automation + insight. All
    six ship before "sellable".

## Reconciled dependency matrix

Pinned at M0; versions recorded in the M0 PR. Re-pin only if a resolution fails the gate.

| Concern | Package | Notes |
| --- | --- | --- |
| State + DI | `flutter_riverpod` 3.x + `riverpod_generator` | lint via `very_good_analysis` |
| Routing | `go_router` | |
| Local DB | `drift`, `drift_flutter`, `sqlcipher_flutter_libs` | encrypted SQLite |
| Models | `freezed`, `json_serializable`, `build_runner` | |
| Audio playback | `just_audio` + `audio_service` | background + media session + audio focus |
| Audio capture | `record` | saves to designated Samsung dir |
| File access | `file_picker` + `flutter_foreground_task` (for long scans) | SAF / scoped storage |
| Connectivity | `connectivity_plus` | gates the two networked services |
| Background queue | `workmanager` | drains AI + email queues on reconnect |
| Anki | AnkiDroid intents (no package — platform channel / intent) | requires AnkiDroid installed |
| AI images | `http` / Fal.ai REST client | provider pinned; key via `--dart-define` |
| Email | `mailer` (SMTP) | creds via `--dart-define` |
| Notifications | `flutter_local_notifications` + `android_alarm_manager_plus` | exact-alarms for due tasks |
| Charts | `fl_chart` | analytics dashboard |
| Logging | injected `AppLogger` | tagged: `DB/AUDIO/RECORD/ANKI/AI/MAIL/TASK/NOTIFY/CHART/CORE` |

## Milestone 0: Foundation (bootstrap)

**Objective:** A building, analyzing, test-covered Flutter app skeleton with the encrypted Drift store,
the abstract service seams, the offline queue, and the gate green — before any feature lands.

### Tickets

- **T0.1 — App bootstrap & identity.** Flutter app, package `rivendell`, bundle id
  `com.rivendell.app`, min Android 26, Material 3, `very_good_analysis`. Pin the matrix above. Record
  deviations. *Gate:* `sh scripts/gate.sh` exits 0 on an empty app. *ACs:* none (infra).
  *Deps:* none.
- **T0.2 — Encrypted Drift store + migrations.** `drift_flutter` + `sqlcipher_flutter_libs`, key derived
  per-install, migration framework, `AppLogger` (`DB`). One trivial table to prove the seam. *Gate:*
  store round-trip test green. *ACs:* NFR-2.1.2, NFR-2.4.2. *Deps:* T0.1.
- **T0.3 — Connectivity gate + offline queue.** `connectivity_plus`, an abstract `NetworkService`,
  a Drift-backed `OfflineQueue` table + `QueueWorker` (`workmanager`) that drains on reconnect. *Gate:*
  enqueue→reconnect→drain test green. *ACs:* NFR-2.1.3. *Deps:* T0.2.
- **T0.4 — AppLogger + debug surface.** Tagged logger injected via Riverpod; tags documented in CLAUDE.
  *Gate:* unit tests for tag filtering. *ACs:* none. *Deps:* T0.1.

---

## Milestone 1: Core Audio Sync & Native Playback

**Objective:** Index and play existing local recordings with zero fluff. FR-1.1.x, NFR-2.2.1/2.2.2.

### User stories
* As a learner, I want the app to scan my device for my Samsung Voice Recorder folder on first launch so
  I don't manually import historical audio.
* As a learner, I want a clean, premium list of all indexed recordings.
* As a learner, I want to tap and play any recording instantly with standard controls (play/pause/seek).

### Acceptance criteria
* On first install, the user is prompted with a native folder picker to select/confirm their Samsung Voice
  Recorder path (scoped-storage / SAF compliant).
* The app indexes all `.m4a`/`.mp3`/`.wav` in the designated directory off the main isolate without
  freezing the UI (≤1000 files in <2.0s — NFR-2.2.1).
* Playback works offline with native media-session controls and audio-focus management (FR-1.1.4).
* UI matches the premium visual bar (typography, contrast, transitions) — `/design-review` ≥4/5.

### Tickets
- **T1.1 — Storage permissions + folder picker.** Runtime perms + SAF folder selection for the Samsung
  Voice Recorder directory; persist the chosen URI. *ACs:* FR-1.1.1 (picker). *Deps:* T0.2.
- **T1.2 — Audio indexer.** Scan the designated dir, read metadata (creation date, name, size, format),
  upsert into the `recordings` table off the main isolate. *ACs:* FR-1.1.1, FR-1.1.2, NFR-2.2.1.
  *Deps:* T1.1.
- **T1.3 — Startup rescan.** On app start, re-scan and reconcile (add new, keep existing, soft-mark
  missing). *ACs:* FR-1.1.1 (subsequent startups). *Deps:* T1.2.
- **T1.4 — Recordings list screen.** Premium list of indexed recordings (name, date, duration),
  empty/loading/error states, i18n strings. *ACs:* M1 story 2, NFR-2.4.1, NFR-2.5.x. *Deps:* T1.2.
- **T1.5 — Audio player + media session.** `just_audio` + `audio_service`, play/pause/seek, background
  playback, audio focus (pause on call). *ACs:* FR-1.1.4, NFR-2.2.2. *Deps:* T1.4.
- **T1.6 — Recording detail screen.** Tap a recording → detail with player + metadata. *ACs:* M1 story 3.
  *Deps:* T1.5.

---

## Milestone 2: GPA Scheduler & In-App Capturing

**Objective:** Turn static audio into a structured GPA review pipeline. FR-1.2.x.

### User stories
* As a learner, I want recordings auto-placed into a daily "Due for Review" list by the strict interval
  sequence (1, 2, 4, 7, 30, 90, 180, 365 days) so I stay on top of my listening library.
* As a learner, I want to record new audio in-app that saves into the shared Samsung folder so it's
  instantly indexed.

### Acceptance criteria
* Home screen shows a dynamic "Today's Review Queue" computed from creation dates + GPA intervals.
* A 1-day-stale recording is shown and marked stale; the stale prompt disappears on the 2nd stale day.
* Queue items are playable with one tap; crossing 80% playback appends a review event, marking that
  milestone reviewed (derived from the event log).
* The recording detail screen shows the review history: last reviewed, milestone reached, review count.
* An in-app "Record" button captures audio and exports it to the indexed folder (and it's indexed on next
  scan).

### Tickets
- **T2.1 — GPA interval engine (pure Dart).** Given creation date + now, compute due milestones over
  `1,2,4,7,30,90,180,365`. *ACs:* FR-1.2.1, FR-1.2.2. *Deps:* T0.2. (Pure-Dart, fully unit-tested.)
- **T2.2 — Review-event log.** A `review_events` table (recording id, milestone index, completed-at) +
  repository. Appending an event when playback crosses 80%. "Reviewed for milestone N" derived from the
  log, not stored as a flag. *ACs:* FR-1.2.3. *Deps:* T0.2, T1.5.
- **T2.3 — Review-history derivation.** Pure-Dart queries over `review_events`: last-reviewed date,
  milestone reached, review count, active (next-unreached) milestone per recording. *ACs:* FR-1.2.4.
  *Deps:* T2.2. (Pure-Dart, unit-tested.)
- **T2.4 — Today's queue + stale rule.** Compute today's due set (active milestone due today); mark
  1-day-stale; suppress on 2nd stale day. *ACs:* FR-1.2.5, M2 AC 1–2. *Deps:* T2.1, T2.3.
- **T2.5 — Home / queue screen.** "Today's Review Queue", one-tap play, stale badge. *ACs:* M2 AC 3,
  NFR-2.4.1. *Deps:* T2.4, T1.6.
- **T2.6 — Recording detail: review history.** On the recording detail screen, show last-reviewed
  date, milestone reached, and review count (derived from `review_events`). *ACs:* FR-1.2.4, NFR-2.4.1.
  *Deps:* T1.6, T2.3.
- **T2.7 — In-app recorder.** `record` package; save to the designated Samsung dir; trigger rescan.
  *ACs:* FR-1.1.3, M2 AC 4. *Deps:* T1.3.

---

## Milestone 3: Languaculture Word Log & Visual Attachments

**Objective:** Bridge audio with vocabulary data and visual media (GPA "Word Log"). FR-1.3.1/1.3.2.

### User stories
* As a learner, I want to attach a raw text list or a photo of my vocabulary sheet to a recording.
* As a learner, I want the associated text/image log shown contextually while that recording plays.

### Acceptance criteria
* The player screen shows a toggle panel for the associated text log or attached photo(s).
* Mapping persists offline via the local Drift store.
* Schema links one text log and/or multiple image files to one recording.

### tickets
- **T3.1 — Word-log schema + repository.** `word_logs` table; one text log and/or multiple images per
  recording; abstract repo seam. *ACs:* FR-1.3.1, NFR-2.1.2. *Deps:* T0.2.
- **T3.2 — Text-log attach + parsing.** Attach a text log; parse English↔Uzbek pairs via `:` / `-`
  delimiters into structured pairs. *ACs:* FR-1.3.2. *Deps:* T3.1. (Pure-Dart parser, unit-tested.)
- **T3.3 — Image-log attach.** Attach JPG/PNG notebook photos to a recording (SAF copy into app data).
  *ACs:* FR-1.3.1 (images). *Deps:* T3.1.
- **T3.4 — Word-log viewer panel.** Toggle panel on the player screen: text log or image(s).
  *ACs:* M3 AC 1, NFR-2.4.1. *Deps:* T1.6, T3.2, T3.3.

---

## Milestone 4: Anki Generation & AI Image Engine

**Objective:** Push vocab to Anki and generate concept-image cards. FR-1.3.3/1.3.4.

### User stories
* As a learner, I want the app to scan my text vocab list, extract English/Uzbek pairs, and inject them
  into Anki via a localized deck tagged with the recording name.
* As a learner, I want each card to feature a direct translation card and a separate AI-generated image
  card representing the Uzbek word.

### Acceptance criteria
* Saving a text vocab list auto-generates flashcards in AnkiDroid via its intent API, tagged with the
  recording filename. Requires AnkiDroid installed; graceful "install AnkiDroid" CTA if absent.
* Flashcard layout: Type 1 (English ↔ Uzbek) and Type 2 (AI concept image → Uzbek).
* AI image generation is **Fal.ai**, queued + drained on reconnect, cached per Uzbek word, skipped when
  offline (Type 2 shows a placeholder until ready).

### Tickets
- **T4.1 — AnkiDroid intent adapter.** Platform channel / intent to create deck, note type (Type 1 + Type
  2), and notes via `com.ichi2.anki`; detect install + degrade gracefully. *ACs:* FR-1.3.3. *Deps:* T3.2.
- **T4.2 — Type 1 card generation.** Map parsed pairs → AnkiDroid Type 1 notes, tagged by recording
  filename; idempotent (re-saving doesn't duplicate). *ACs:* FR-1.3.3, M4 AC 2 (Type 1). *Deps:* T4.1.
- **T4.3 — Fal.ai image service (abstract seam).** `AIImageService` interface; Fal.ai impl; per-word
  cache; enqueue + drain on reconnect; placeholder when offline/pending. *ACs:* FR-1.3.4, NFR-2.1.3.
  *Deps:* T0.3.
- **T4.4 — Type 2 card generation.** For each Uzbek word with no cached image, enqueue generation, then
  attach to AnkiDroid Type 2 note. *ACs:* FR-1.3.4, M4 AC 2 (Type 2), M4 AC 3. *Deps:* T4.2, T4.3.
- **T4.5 — Anki export flow UI.** "Send to Anki" action on a recording's word log; status + retry on
  failure; offline-queue visibility. *ACs:* M4 AC 1, NFR-2.4.1. *Deps:* T4.4.

---

## Milestone 5: Task Management, Coaching Repository & Notifications

**Objective:** Actionable dashboard for learning targets + live coaching sessions. FR-1.4.x.

### User stories
* As a learner, I want to create custom exercises (e.g. "Memorize 'Yor-Yor'") with deadlines and get
  native notifications when due.
* As a learner, I want a structured bank of conversation topics, questions, and scripts for coaching
  sessions.

### Acceptance criteria
* "Exercises & Tasks" view: create, set due date, checkbox-complete.
* Local notifications fire accurately on due dates even when the app is closed.
* "Coach Bank" saves text notes and links existing recordings / vocab words as talking points.

### tickets
- **T5.1 — Tasks schema + repository.** `tasks` table (title, description, due date, completed); repo.
  *ACs:* FR-1.4.1. *Deps:* T0.2.
- **T5.2 — Tasks screen.** Create / edit / complete / delete; due-date picker; empty states.
  *ACs:* FR-1.4.1, NFR-2.4.1. *Deps:* T5.1.
- **T5.3 — Scheduled notifications.** `flutter_local_notifications` + `android_alarm_manager_plus`;
  schedule on due date; fire when app closed; exact-alarm permission flow. *ACs:* FR-1.4.2, M5 AC 2.
  *Deps:* T5.1.
- **T5.4 — Coach Bank schema + repository.** `coach_notes` table; link recordings / vocab words as talking
  points. *ACs:* FR-1.4.3. *Deps:* T0.2.
- **T5.5 — Coach Bank screen.** Create/edit notes, attach recordings/vocab, agenda view for a session.
  *ACs:* FR-1.4.3, NFR-2.4.1. *Deps:* T5.4, T1.6.

---

## Milestone 6: Analytics Dashboard & Automated Email Reports

**Objective:** Aesthetic summary of consistency. FR-1.5.x.

### User stories
* As a learner, I want a beautifully visualized dashboard: lesson hours, journaling minutes, reviews
  completed, flashcards cleared.
* As a learner, I want an automated weekly summary email of my learning trajectory.

### Acceptance criteria
* Statistics view renders native charts tracking daily/weekly/monthly metrics.
* Counters increment behind the scenes from user interaction (e.g. listening to a due recording adds to
  "Recording Reviews").
* A background worker dispatches a stylized HTML weekly email via SMTP; queued + drained on reconnect.

### tickets
- **T6.1 — Metrics schema + ingestion.** `metrics_events` table; increment Lesson Duration, Journaling
  Output, Flashcards reviewed from existing flows. "Completed Queue items" is **derived directly from
  `review_events`** (count of milestone completions in the window) — do not duplicate it into a second
  counter. *ACs:* FR-1.5.1. *Deps:* T0.2, T2.2.
- **T6.2 — Metrics aggregation (pure Dart).** Roll up events into daily/weekly/monthly series. *ACs:*
  FR-1.5.1. *Deps:* T6.1. (Pure-Dart, unit-tested.)
- **T6.3 — Analytics dashboard.** `fl_chart` daily/weekly/monthly views; premium styling; empty states.
  *ACs:* FR-1.5.2, M6 AC 1, NFR-2.4.1. *Deps:* T6.2.
- **T6.4 — HTML report renderer.** Render the weekly aggregate into a stylized HTML template. *ACs:*
  FR-1.5.3 (render). *Deps:* T6.2.
- **T6.5 — SMTP email service (abstract seam).** `EmailService` interface; SMTP impl via `mailer`; creds
  via `--dart-define`; enqueue + drain on reconnect. *ACs:* FR-1.5.3, NFR-2.1.3, NFR-2.6.1. *Deps:* T0.3,
  T6.4.
- **T6.6 — Weekly report scheduler.** `workmanager` periodic worker; dispatch the rendered HTML email
  weekly; retry/backoff; in-app "last sent / next send" indicator. *ACs:* FR-1.5.3, M6 AC 3. *Deps:* T6.5.

---

## Open questions for the user

These are deferred, not blocking M0–M1. Surface them when their milestone approaches:

1. **Fal.ai model + prompt** — which Fal.ai endpoint/model for concept images, and the prompt template
   (language-neutral pictographic vs. culturally-specific)? Decide at T4.3.
2. **SMTP provider** — a transactional SMTP (e.g. free-tier Resend/Mailgun/Brevo) vs. user-supplied Gmail
  app-password. Affects key handling at T6.5.
3. **AnkiDroid minimum version** — which AnkiDroid version's intent API do we target? Decide at T4.1.
4. **Weekly report cadence anchor** — "weekly" anchored to calendar week (Mon 00:00) vs. install
  anniversary. Decide at T6.6.
5. **Uzbek text normalization** — Latin vs. Cyrillic Uzbek; does the parser normalize both? Decide at T3.2.
