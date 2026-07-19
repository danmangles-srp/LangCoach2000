# plan.md

> The ordered **HOW** for Rivendell — an offline-first Android app that turns Samsung Voice Recorder
> recordings into a GPA review pipeline with vocab logs, Anki flashcards, AI concept images, coaching
> tasks, and weekly email reports.
>
> **Restart here:** the [Plan of Attack](#plan-of-attack-restart-here) section below is the single source
> of truth for **what is done** and **what to do next**, in order. Everything from M0 onward is reference
> detail; completed milestones are marked `COMPLETE` and can be skipped. Each ticket = 1 PR off `dev`,
> in dependency order; don't start the next until the current one's gate exits `0` and its PR is open.
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

## Plan of Attack (restart here)

> Status as of 2026-07-19. This section supersedes the per-milestone headers for "what's next." The
> milestone bodies below remain the authoritative detail for ACs, deps, and root-cause notes.

### Status board

All planned milestones are shipped. Remaining work = the M15 deferred low-priority refactors + the
`!`-sweep chore + a device-confirm parking lot.

| Milestone | State | Shipped via |
| --- | --- | --- |
| M0 Foundation | COMPLETE | bootstrap |
| M1 Core audio sync + native playback | COMPLETE | — |
| M2 GPA scheduler + in-app capture | COMPLETE | — |
| M3 Word log + image attach | COMPLETE | — |
| M4 Anki generation + AI image | COMPLETE | — |
| M5 Tasks + coach + notifications | COMPLETE | — |
| M6 Analytics dashboard + email reports | COMPLETE | #43–#47 |
| M7 UX + queue polish | COMPLETE | — |
| M8 Playback-flow + safe-area | COMPLETE | #31 |
| M9 Feedback batch 2 + AnkiDroid 2.24 | COMPLETE (T9.1 moved to M16) | #48–#50 |
| M10 Capture naming + rename/delete + queue strictness | COMPLETE | #42 |
| M11 XP + streak motivation | COMPLETE | #98–#102 |
| M14 Feedback batch 4 (queue backlog, settings crash, auto-advance duration, image attach, MediaStore) | COMPLETE | #51–#55 |
| M15 Architecture health pass (highs) | COMPLETE | #56–#63; T15.9 (#6), T15.11 |
| M16 AnkiDroid runtime-grant (T9.1, finally) | COMPLETE (pending device-confirm) | #64, #65 |
| M18 AI image queue hardening + wordlog attach retirement | COMPLETE | T18.1/3/4/5/6 + T18.2 (`drainQueueFromBackground`) |
| M19 Reactive queue + English-prompt + auto-advance fix | COMPLETE | T19.1–T19.7 |

### Next-work queue (ordered, 1 ticket = 1 PR off `dev`)

These are the only open code items. Take top-down; each is self-contained.

1. **Backlog — eliminate `!` null-asserts.** ~19 sites still use `!`, which the project rules forbid.
   Grep `!` in `lib/`, replace with `?.` / `??` / explicit handling. *Deps:* none. *Decision before
   starting:* one bundled PR vs per-feature PRs (the user leans one-bundle for a related-area sweep).
2. **T15.10 — Move domain DTOs out of `data/`.** `med`. `ScannedFile` is used by the abstract
   `AudioIndexerService` seam but lives in `audio/data/recording_repository.dart` → move to
   `audio/domain/`. *Deps:* T15.3 (shipped #58).
3. **T15.12 — Extract shared timestamp-range selector.** `med`.
   `review_event_repository.eventTimestamps` ≈ `word_log_repository.textLogTimestamps` (~85% identical).
   One parameterized helper over table + column + kind. *Deps:* none.
4. **T15.13 — i18n + presentation-decode polish.** `med`. Externalize the
   `weekly_report_settings_section` "Save failed" snackbar + the `recording_detail` "D+7" milestone
   label to `AppStrings`; move `word_log_section` `Image.file` decode behind an application service.
   *Deps:* none.
5. **T15.14 — `domain/` Flutter-SDK-free.** `low`. 7 domain files import
   `package:flutter/foundation.dart` only for `@immutable` — switch to `package:meta/meta.dart` or drop
   (`@freezed` implies immutability). Files: gpa (`gpa_intervals`, `review_status`, `queue_warmup`),
   wordlog (`vocab_pair`), anki (`anki_model_spec`), report (`report_schedule`), audio
   (`recording_state`, `playback_snapshot`). *Deps:* none.
6. **T15.16 — Close coverage holes.** `low`. v1→v9 migration-step upgrade test (`app_database.dart`
   ~32%); `recording_indexer` parse-path tests (NFR-2.2.1 surface); a `review_providers` append-failure
   test that locks T15.4. *Deps:* T15.4 (shipped #59).
7. **Dead-string cleanup (trivial).** The `wordLogAddImage` l10n key (`app_strings.dart`) is no longer
   wired after T18.6 retired the attach-image affordance — drop the en/uz entries + ctor/field/getter
   once confirmed unused. *Deps:* none.
8. **T15.15 — Reconcile `plan.md` with reality (doc).** `low`. Largely subsumed by this Plan of Attack
   rewrite; close once the stale refs flagged in the M15 body are pruned. *Deps:* none.

### Device-confirm parking lot (shipped code, pending on-device verify)

Cannot be closed from context — needs a physical device. Track separately; **do not** re-pick these up
as code work without re-verifying the device symptom first.

- **T14.4** — word-log image attach open-once fix (#54).
- **T14.5** — capture → Samsung "All recordings" via MediaStore (#55).
- **T16** — AnkiDroid runtime-grant flow (#64 / #65).
- **T19.7** — recording-save SAF permission denial + re-pick folder (#94).
- **T18.2** — workmanager background-isolate drain. `drainQueueFromBackground` is implemented; the open
  risk is background-isolate plugin init (drift + http + secure-storage). The **foreground reactive
  path is the product path** — if closed-app ~15-min drain isn't required, leave as-is.

### Decision points (ask before executing)

- **`!`-sweep shape:** one PR or per-feature? Default to one bundled PR for a related-area refactor
  unless the diff gets large.
- **T18.2 deep verify:** only shipped item with a real architectural risk flag. Confirm the user wants
  closed-app drain before investing in background-isolate plugin wiring.
- **New milestones:** none planned. If real use surfaces new defects, open a feedback-batch milestone
  (M20+) following the M14/M19 root-cause-analysis pattern.

### Execution loop (unchanged)

Branch off `dev` → 1 ticket → TDD red/green → `sh scripts/gate.sh` (codegen → format → analyze →
test → ≥80% coverage floor) → commit (Conventional Commits, lowercase, no emoji, no Co-authored-by)
→ PR targeting `dev` (never `main`; if `origin/dev` is missing, recreate it or ask — don't retarget to
`main`) → squash-merge → backfill the `plan.md` ticket marker with the PR number. Standard Gate before
every push.

---

## COMPLETE Milestone 0: Foundation (bootstrap)

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

## COMPLETE Milestone 1: Core Audio Sync & Native Playback

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

## COMPLETE Milestone 2: GPA Scheduler & In-App Capturing

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

## COMPLETE Milestone 3: Languaculture Word Log & Visual Attachments

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

## COMPLETE Milestone 4: Anki Generation & AI Image Engine

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

## COMPLETE Milestone 5: Task Management, Coaching Repository & Notifications

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

## Milestone 6: Analytics Dashboard & Automated Email Reports (T6.1–T6.6 done)

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
  FR-1.5.1. *Deps:* T6.1. (Pure-Dart, unit-tested.) ✅ PR #43
- **T6.3 — Analytics dashboard.** `fl_chart` daily/weekly/monthly views; premium styling; empty states.
  *ACs:* FR-1.5.2, M6 AC 1, NFR-2.4.1. *Deps:* T6.2. ✅ PR #44
- **T6.4 — HTML report renderer.** Render the weekly aggregate into a stylized HTML template. *ACs:*
  FR-1.5.3 (render). *Deps:* T6.2. ✅ PR #45
- **T6.5 — SMTP email service (abstract seam).** `EmailService` interface; SMTP impl via `mailer`; creds
  in encrypted local KV (user-supplied Gmail app-password); enqueue + drain on reconnect. *ACs:*
  FR-1.5.3, NFR-2.1.3, NFR-2.6.1. *Deps:* T0.3, T6.4. ✅ PR #46
- **T6.6 — Weekly report scheduler.** `workmanager` periodic worker; dispatch the rendered HTML email
  weekly; retry/backoff; in-app "last send / next send" indicator. *ACs:* FR-1.5.3, M6 AC 3. *Deps:*
  T6.5. ✅ PR #47

---

## COMPLETE Milestone 7: UX & Queue Polish (post-M4 feedback)

**Objective:** Make the app feel alive on day one and remove friction in the
recording detail flow. These are real-use findings, not new scope — they sharpen
existing M1–M3 surfaces.

### User stories
* As a new learner, I want my Today and Tomorrow queues to each show at least 3
  recordings right after my first sync, so the app is immediately useful (not an
  empty list on day 1).
* As a learner viewing a recording, I want the detail screen focused on content
  (vocab + timeline), not file metadata, and I want the vocab list above the
  review timeline.
* As a learner, I want to tap an attached image and pinch-to-zoom it full-screen.
* As a learner, tapping "mark reviewed" must NOT scroll-jump me to the top of the
  screen.

### Acceptance criteria
* After first index, the Tomorrow preview shows **≥3** recordings (topped up
  from the soonest-next-due if the strict-GPA due-tomorrow set is smaller). The
  canonical GPA intervals are NOT altered — top-ups are presented as
  reviewable-early, not rescheduled.
  *Superseded by M10 AC4:* the Today queue **no longer** has a ≥3 floor — Today
  shows only the strict due-set (active milestone due today or 1-day-stale).
  M7 AC1's "Today ≥3" wording is withdrawn; the Tomorrow ≥3 floor stands.
* The recording detail screen no longer shows duration / size / format chips;
  the GPA milestone (D+N) list renders **below** the vocab log section.
* Tapping an attached image opens a full-screen viewer with pinch-zoom
  (`InteractiveViewer`) and a dismiss affordance.
* Toggling a milestone's reviewed state preserves the current scroll position
  (no jump to top).

### Tickets
- **T7.1 — Queue warm-up top-up.** When the strict due-today queue has fewer
  than 3, top it up to 3 from the soonest-next-due recordings (reviewable early,
  badged "up next"); apply the same ≥3 floor to the Tomorrow preview. Pure-Dart
  selector over the existing GPA derivation — no schema change, no rescheduling.
  *ACs:* M7 AC 1. *Deps:* T2.4 (today queue + stale rule).
  *Superseded by T10.1:* the Today top-up half is removed (Today strict-only).
  T7.1's Tomorrow top-up logic remains in force.
- **T7.2 — Recording detail layout trim + reorder.** Remove the duration / size
  / format chips from the detail screen; move the D+N milestone list to render
  below the vocab log section. *ACs:* M7 AC 2. *Deps:* T1.6, T3.4.
- **T7.3 — Image full-screen zoom viewer.** Tap an attached word-log image →
  full-screen `InteractiveViewer` (pinch-zoom, pan, swipe/tap to dismiss).
  *ACs:* M7 AC 3. *Deps:* T3.3 (image-log attach).
- **T7.4 — No scroll-jump on mark-reviewed.** Preserve the scroll offset across
  a reviewed-state toggle on the recording detail / timeline (root-cause the
  rebuild that resets the offset; keep a stable `ScrollController` / keys).
  *ACs:* M7 AC 4. *Deps:* T2.6.

---

## Milestone 8: Playback-flow & safe-area fixes (post-M7 feedback) — T8.1/T8.2/T8.3/T8.4 done (image-render *bug* still open under T9.2)

**Objective:** Four real-use findings from the playback + library flow. The first
three tighten how the queue, the player, and attached images behave; the fourth
fixes the app drawing under Android's system navigation bar. No new scope — these
sharpen M1–M3 surfaces (and one is a platform/edge-to-edge bug).

### User stories
* As a learner in the review queue, I want tapping a recording to open its full
  detail page (not just start inline playback), and to land back on the queue
  when I leave.
* As a listener, when a recording finishes I want the next one to start
  automatically — the next item in the queue if I launched from the queue, or
  the preceding recording in my library list otherwise.
* As a learner, I want an attached notebook photo to render as the image, both
  as the thumbnail and in the full-screen viewer (today it shows a placeholder).
* As a user, I want the app's UI to stop at Android's system navigation buttons,
  not slide underneath them.

### Acceptance criteria
* Tapping a queue row pushes the recording detail route (which auto-plays); the
  inline long-press shortcut is removed. Popping the detail returns to the queue
  at the same scroll position.
* On natural playback completion the detail advances to the next recording:
  next-in-queue (today then tomorrow order) when launched from the queue, or the
  preceding library row otherwise. No advance at the end of the available list;
  manual replay still works.
* An attached word-log image renders its bytes (thumbnail + full-screen); when
  the file is missing/corrupt the tile reports a clear, diagnosable state.
* With `targetSdk` 35 forcing edge-to-edge, the home shell's bottom nav and the
  detail screen's content sit above the system navigation bar (no content drawn
  under the 3 buttons).

### Tickets
- **T8.1 — Queue tap opens detail.** `_WarmedTile.onTap` pushes the detail route
  (carrying queue peer-context — see T8.2); drop the long-press navigation and
  the inline play-on-tap (the detail auto-plays on open). *ACs:* M8 AC 1.
  *Deps:* T1.6.
- **T8.2 — Auto-advance on completion.** Carry an ordered peer-id list + a
  launch source (`queue` / `library`) to the detail route via go_router `extra`.
  The detail screen watches the player snapshot; on the transition to
  `isCompleted` it advances: queue → next id in queue order; library → preceding
  id in the list. Advance re-places the route with the same peer-context so the
  chain continues; manual replay and end-of-list are handled. *ACs:* M8 AC 2.
  *Deps:* T1.5, T1.6.
- **T8.3 — Word-log image render.** The stored app-relative path already resolves
  under the same base the DB + AI cache use (verified — those work), so the
  thumbnail/full-screen `Image.file` failure is diagnosed rather than guessed at:
  log the resolved path + existence under the `wordlog` tag, and replace the bare
  broken-image icon with a clear "couldn't load" tile. Re-attach + share the log
  to root-cause the on-device copy/decode failure. *ACs:* M8 AC 3. *Deps:* T3.3.
  ✅ PR #31 (diagnostics + tile; on-device byte fix deferred to T9.2).
- **T8.4 — Android safe-area.** Enable `SystemUiMode.edgeToEdge` in `main` so the
  system-bar insets are exposed, then ensure the home shell's `NavigationBar` and
  the detail screen's body sit above the bottom inset (`SafeArea`). *ACs:* M8 AC 4.
  *Deps:* T2.5 (home shell), T1.6.

---

## Milestone 9: Real-use feedback batch 2 + AnkiDroid 2.24 rework (post-M8)

**Objective:** Two re-opened bugs and four polish items from the latest real-use
pass. The headline: the Anki export "permission" fix (PR #41) was aimed at the
*old* AnkiDroid API model — on AnkiDroid 2.24 the v1.1.0 `READ_WRITE_DATABASE`
custom permission no longer grants content-provider access, and the user-facing
flow has changed (global "Enable AnkiDroid API" toggle + a third-party-apps
GitHub allowlist; no per-app grant screen). The image-attach render bug from
T8.3 also remains open.

### User stories
* As a learner, I want "Send to Anki" to actually work against a current
  AnkiDroid install (2.24+), not a 2020-era API model.
* As a learner, I want attached notebook photos to render (thumbnail + full
  screen), not show "couldn't load".
* As a learner, I want the library + review lists to show which recording is
  currently playing.
* As a learner, I want tasks to open in a detail view on tap and enter edit
  mode on a further tap (Todoist-style), not jump straight to editing.

### Acceptance criteria
* "Send to Anki" succeeds on AnkiDroid 2.24 without a manual permission dance,
  OR fails with a hint that matches the modern AnkiDroid UI (no stale
  "Settings → Advanced → API → allow Rivendell" copy).
* An attached image renders its bytes (thumbnail + full-screen) on first
  attach; a missing/corrupt file reports a clear, diagnosable state.
* The currently-playing recording is visually indicated in the library list
  and the review queue.
* A task row opens a detail view on tap; a further tap enters edit mode.

### Tickets
- **NOT DONE T9.1 — AnkiDroid API v2 migration.** Swap the bundled `api-1.1.0.aar` for
  the modern AnkiDroid API release that exposes `shouldRequestPermission()` /
  `requestPermission()`; drive the runtime grant intent from the export flow
  before the first content-provider call. Remove the now-stale v1.1.0
  `READ_WRITE_DATABASE` guidance. *ACs:* M9 AC 1. *Deps:* T4.1.
- **T9.2 — Word-log image render (root cause).** T8.3 added diagnostics but the
  copy still produced an unrenderable file. Root cause: the SAF `copyTo` wrote
  source bytes verbatim, so a corrupt/partial stream or a Samsung mime-mismatch
  (e.g. HEIC bytes served under `image/jpeg`) landed bytes Flutter's
  `Image.file` could not decode. Fix: re-encode the picked image through
  `BitmapFactory` (decode bounds → sample to a 2048px max edge → re-encode as
  JPEG/PNG to match the destination extension, recycle the bitmap) and throw a
  typed `IOException` on a corrupt/undecodable source so the caller surfaces
  the failure rather than writing a broken file. JPG/PNG only (FR-1.3.1).
  *ACs:* M9 AC 2. *Deps:* T3.3, T8.3.
  ✅ PR #48.
- **T9.3 — Now-playing indicator.** Surface the player snapshot's current
  recording id in the library list + review queue rows (highlight / equalizer
  glyph). The review queue already swapped its leading glyph to
  `graphic_eq_rounded` + showed a "Now playing" trailing label on the active
  row; T9.3 brings the library list to parity — `_RecordingTile` reads the
  snapshot, swaps its `_FormatBadge` glyph between `music_note_rounded` and
  `graphic_eq_rounded`, and shows the same trailing label so the two lists
  agree on what "now playing" looks like. *ACs:* M9 AC 3. *Deps:* T1.5.
  ✅ PR #49.
- **T9.4 — Tasks tap-to-detail.** Task row tap → detail view; further tap →
  edit (Todoist-style). Tap a row in the tasks list now pushes `/tasks/:id`
  (a new route + `TaskDetailScreen` reading the task by id via a
  `taskByIdProvider` family). The detail screen renders the title, completion
  toggle, optional due date (with the overdue pill), notes, and created date.
  Its AppBar Edit action opens the shared `TaskEditDialog` (lifted out of
  `tasks_screen.dart` so the list's add FAB and the detail's edit action share
  one form); Delete removes the task and pops back to the list. A stale
  deep-link falls back to the not-found view (and a non-numeric id to the home
  shell). *ACs:* M9 AC 4. *Deps:* T5.2.
  ✅ PR #50.

---

## COMPLETE Milestone 10: Real-use feedback batch 3 — capture naming, rename/delete, queue strictness (post-M9) — T10.1/T10.2/T10.3/T10.4/T10.5 done (shipped together via PR #42)

**Objective:** Four real-use findings. Two add file management the indexer-only
model lacked (in-app rename + delete, both touching the physical file in the
Samsung folder); one fixes capture so a recording is named when taken; two
tighten the queue (Today strict-only per user feedback, Tomorrow visually
de-emphasized). M10 AC4 amends M7 AC1.

### User stories
* As a learner, I want to name a recording while I'm taking it so the saved
  file reflects content, not a timestamp.
* As a learner, I want to rename a recording in-app and have the file on disk
  follow.
* As a learner, I want to delete a recording in-app — file + all its data —
  without leaving stale rows.
* As a learner, I want Today's queue to show only what's genuinely due (no early
  filler), so I trust the queue.
* As a learner, I want Tomorrow's preview clearly de-emphasized so Today stands
  out.

### Acceptance criteria
* The record sheet shows a name field while recording (pre-filled with the
  auto-generated default). The entered name becomes the saved filename **and**
  the display name; blank falls back to the default.
* Rename from a recording's detail screen renames both the DB row (display name
  + `filePath` upsert key) and the physical file in the Samsung folder
  atomically; a re-scan does not resurrect the old name.
* Delete from a recording's detail screen removes the physical file and
  cascades the DB row + its `review_events`, `word_logs`, image logs, and
  coach-bank links; a confirm dialog precedes deletion. Re-scan does not
  resurrect the row.
* **(Amends M7 AC1)** Today's queue shows only the strict due-set (active
  milestone due today or 1-day-stale); the ≥3 Today floor is revoked.
* Tomorrow's preview is **also strict-only**: it shows only active milestones
  due tomorrow exactly (overdue == -1). The ≥3 floor and "up next" filler are
  revoked for both windows. A recording appears in either queue only when on
  or past its next review date.
* Tomorrow's preview rows render de-emphasized (muted/grey, lower visual
  weight) relative to Today.

### tickets
- **T10.1 — Queue strict-only (Today + Tomorrow).** Drop ALL top-up / filler
  from `warmUpQueue` (queue_warmup.dart). Today = active milestone due today or
  1-day-stale. Tomorrow = active milestone due tomorrow exactly (overdue == -1).
  Remove `WarmPlacement` / `kWarmFloor` / `floor` param (single-value enum is
  dead weight). Amend M7 AC1 wording + queue-warmup unit tests. *ACs:*
  M10 AC4 + AC5(strict). *Deps:* T7.1.
  ✅ PR #42.
- **T10.2 — Tomorrow preview de-emphasis.** Render tomorrow-section rows in
  `today_queue_screen.dart` with muted color + reduced weight vs Today (e.g.
  `onSurfaceVariant` at reduced opacity, smaller leading badge). Today retains
  full emphasis. Pure presentation. *ACs:* M10 AC5. *Deps:* T2.5, T10.1.
  ✅ PR #42.
- **T10.3 — Name-on-capture.** Add an editable name field to the record sheet
  (visible while recording), pre-filled with `buildRecordingFileName` default.
  On stop, `RecorderController.stop` uses the entered name as both the writer's
  `displayName` and the indexed display name; blank or unchanged → default. The
  temp-path → folder-copy step preserves the file extension. *ACs:* M10 AC1.
  *Deps:* T2.7.
  ✅ PR #42.
- **T10.4 — Rename recording (DB + file).** ✅ PR #42. Detail-screen AppBar menu
  → Rename dialog. `RecordingManagementService.renameRecording` sanitizes the
  base name (shared `sanitizeRecordingBaseName`), SAF-renames the doc via
  `rivendell/record` → `renameDocument`, and writes the DB row's `name` +
  `filePath` atomically (`RecordingRepository.updateNameAndPath`). The
  authoritative new URI comes from SAF (the stem can shift on collision), so
  the next rescan keys on the new path — no re-add. Falls back to a
  timestamped base if the input sanitizes to empty; throws on SAF failure
  without mutating the DB. *ACs:* M10 AC2. *Deps:* T1.3, T10.3.
- **T10.5 — Delete recording (DB + file, cascade).** ✅ PR #42. Detail-screen
  AppBar menu → hard-confirm dialog ("Delete <name>? This removes the audio
  file and all its vocab and review data.", no undo). `RecordingManagementService.
  deleteRecording` best-effort wipes `wordlog/<id>/` (dart:io, app-private),
  best-effort SAF-deletes the audio (`deleteDocument`), then a single
  `recordings.deleteById` whose FK cascade drops `review_events`, `word_logs`,
  `coach_note_recordings`, `coach_note_word_logs`. File-op failures are logged
  but never block the DB delete. On success the detail screen pops; on failure
  a snackbar surfaces. *ACs:* M10 AC3. *Deps:* T1.2, T3.1.

---



These are deferred, not blocking M0–M1. Surface them when their milestone approaches:

1. **Fal.ai model + prompt** — which Fal.ai endpoint/model for concept images, and the prompt template
   (language-neutral pictographic vs. culturally-specific)? Decide at T4.3.
2. **SMTP provider** — a transactional SMTP (e.g. free-tier Resend/Mailgun/Brevo) vs. user-supplied Gmail
  app-password. Affects key handling at T6.5.
3. **AnkiDroid minimum version** — which AnkiDroid version's intent API do we target? Decide at T4.1.
4. **Weekly report cadence anchor** — "weekly" anchored to calendar week (Mon 00:00) vs. install
  anniversary. Decide at T6.6.
5. **Uzbek text normalization** — Latin vs. Cyrillic Uzbek; does the parser normalize both? Decide at T3.2.

---

## Milestone 11: XP & Streak Motivation Layer

**Objective:** Layer a lightweight, non-punitive progress signal on top of the existing review pipeline —
a single XP total/level and a daily streak counter. XP **itself** is a derived view (sum of an append-only
`xp_events` ledger, level banded at 500 XP — never a hand-edited counter, matching decision #9). The
**only** manual input is an optional reading/movie activity log; everything else (reviews, word-log
attaches, Anki exports, tasks) posts XP automatically as a side effect. Streaks have **1 freeze per
week** (for a day off). Nothing is ever gated on XP or streak.

### User stories
* As a learner, I want a single XP total and level that grows automatically from actions I'm already
  taking in the app, so progress feels earned without a separate logging chore.
* As a learner, I want to optionally log a reading or movie-watching session for extra XP.
* As a learner, I want a visible daily streak that survives one missed day per week.

### Acceptance criteria
* Dashboard shows a current XP total + level (derived, fixed band — **500 XP/level**), computed from an
  append-only `xp_events` ledger, never a hand-edited counter.
* XP posts automatically as a side effect of five actions: a review-event completion, a word-log attach,
  a successful Anki export, a task marked complete, **and** a logged reading/movie activity. Canonical
  point values: review **+10**, word-log attach **+5**, Anki export **+2 per card** (matches the
  `flashcards_reviewed` metric), task complete **+8**, reading/movie log **+15**.
* Streak count derives from consecutive calendar days with **≥1 review-event**; a missed day consumes
  one available streak-freeze token (auto-granted weekly, **capped at 1 banked**) before the streak
  resets to 0. Reading/movie logs feed XP only — not the streak.
* XP + level + streak are visible on **all main screens** via a shared persistent indicator, and the
  indicator can be hidden from Settings (default: shown).
* No feature is ever gated, disabled, or hidden as a consequence of a broken streak or a zero XP
  balance — streak/XP are purely informational.

### Tickets
- COMPLETE (#98) **T11.1 — XP ledger schema + engine (pure Dart).** Add an `xp_events` table
  (`features/progress/data/xp_events_table.dart`, mirroring `metrics_events_table.dart`): columns
  `id` (autoInc), `source` (text — `review`/`wordlog`/`anki`/`task`/`reading`/`movie`), `points`
  (int, non-negative), `recordingId` (int, nullable, FK→recordings), `taskId` (int, nullable,
  FK→tasks), `at` (DateTime, default now). Register in `app_database.dart` (`tables:`, bump
  `schemaVersion` to 10, add `if (from < 10) await m.createTable(xpEvents);`).
  Domain (`features/progress/domain/xp_level.dart`): `int levelFromTotalXp(int total) => total ~/ 500;`
  + `int xpIntoLevel(int total) => total % 500;` + an `XpSource` enum with stable `columnValue`
  strings (mirror `MetricKind`). Pure-Dart unit tests: level banding at 0/499/500/999/1000, negative
  total clamps to 0. *ACs:* M11 AC 1. *Deps:* T0.2.
- COMPLETE (#99) **T11.2 — XP awarding hooks.** Wire `xp_events` inserts into the five completion points — no new UI
  for four of them, XP is a side effect:
  - **review** (+10): `ReviewEventRepository.recordReview` + `markReviewed` (`features/gpa/data/review_event_repository.dart`) — insert the xp row in the same transaction.
  - **wordlog** (+5): `WordLogRepository.setTextLog` (non-empty body) + `ImageLogService.attach` success (`features/wordlog/`).
  - **anki** (+2 × cards exported): `AnkiExportService` success path (`features/anki/application/anki_export_service.dart`) — points = 2 × notes added.
  - **task** (+8): task-completion mutation in `TaskRepository`/`task_commands.dart` (`features/tasks/`).
  - **reading/movie** (+15): the T11.4 log insert.
  All inserts go through a small `XpRepository.record(source, points, {recordingId, taskId})` over the
  `xp_events` table (mirror `MetricsRepository.record`). Idempotency: review/anki hooks fire once per
  completion (the existing transaction guards double-fires); wordlog setTextLog is replace-on-edit so
  award only when the body changes from empty→non-empty (track via the prior row). Unit tests assert
  each hook writes exactly one row with the expected source+points. *ACs:* M11 AC 2. *Deps:* T11.1,
  T2.2, T3.2, T4.4, T5.2.
- COMPLETE (#100) **T11.3 — Streak + freeze engine (pure Dart).** Domain
  `features/progress/domain/streak_engine.dart`. `StreakResult computeStreak({required
  List<DateTime> reviewDays, required DateTime asOf, required int freezesBanked})` — consecutive
  calendar days with ≥1 review-event ending on `asOf` (or `asOf-1` if asOf itself has none, so "today
  not yet reviewed" doesn't read as a break); a 1-day gap consumes one banked freeze (gap collapses,
  streak continues); a longer gap or a gap with no freeze → streak 0. Source = `review_events`
  `completedAt` day-set (reuse `ReviewEventRepository.eventTimestamps`). Freeze state is the one
  mutable counter (not derivable from reviews): store `streak_freezes_banked` (int) +
  `streak_freezes_last_grant_week` (ISO week id) in `key_values` via `KvRepository`; on compute, if the
  current ISO week > last-grant week and banked < 1, set banked = 1 and stamp last-grant. Pure-Dart
  engine tests: 3-day run, gap-with-freeze continues, gap-no-freeze resets, freeze auto-grant fires
  once per ISO week, cap-1 banking. **No UI gating on reset.** *ACs:* M11 AC 3. *Deps:* T2.3, T11.1.
- COMPLETE (#101) **T11.4 — Reading/movie activity log.** New manual XP source. Schema: `activity_logs` table
  (`features/progress/data/activity_logs_table.dart`): `id`, `kind` (`reading`/`movie`), `title`
  (text), `durationMinutes` (int, nullable), `at` (DateTime). Register in `app_database.dart`
  (schemaVersion bump to 11 — fold with T11.1's bump if shipped together). Repository +
  Riverpod providers under `features/progress/`. Entry UI: an "Log activity" action (FAB on the
  progress dashboard or a menu item) opens a dialog (`AlertDialog`) with kind selector, title field,
  optional duration field; on save, insert the `activity_logs` row **and** fire the T11.2
  reading/movie XP hook (+15). List view of past logs on the dashboard (optional delete). Pure-Dart
  repo tests + a widget test for the dialog. *ACs:* M11 AC 2 (5th source). *Deps:* T11.1, T11.2.
- COMPLETE (#102) **T11.5 — XP & streak dashboard card + global indicator + settings toggle.**
  - **Dashboard card** on `today_queue_screen.dart` (above the queue list): level + `xpIntoLevel/500`
    progress bar + streak count + a freeze-available badge (frost icon when `banked > 0`).
  - **Global indicator** visible on all main screens: a compact level/streak chip in the `HomeShell`
    AppBar (read from a `progressSnapshotProvider` that fans out `xp_events` sum + streak result).
  - **Settings toggle**: add `showProgressIndicator` (bool, default true) to `AppSettings`
    (`features/settings/domain/app_settings.dart`) + `AppSettingsNotifier`
    (`features/settings/application/settings_providers.dart`) persisted via `KvRepository`
    (key `settings.show_progress`) — mirrors the existing auto-advance/theme pattern. When off, the
    global indicator hides; the dashboard card stays.
  Widget tests: card renders level/XP/streak from a faked ledger; toggle hides the chip. *ACs:*
  M11 AC 1, AC 3, AC 4. *Deps:* T2.5, T11.1, T11.3.

---

## Milestone 14: Real-use feedback batch 4 — queue backlog, capture indexing, crash + render bugs (post-M11)

**Objective:** Five findings from the latest real-use pass. One widens Today's queue back to a
forgiving 2-week backlog (the **third** Today revision: M7 ≥3 floor → M10 strict-only → M14
2-week-backlog, cap 4); one crashes the settings screen on open; one shows an auto-advanced
recording as zero-length; one re-opens the word-log image attach bug after **three** failed
attempts; one gets in-app captures into Samsung Voice Recorder's global "All recordings" tab via
MediaStore. No new scope — all sharpen existing surfaces.

### User stories
* As a learner, I want Today to surface anything I've let slip in the last two weeks (up to four),
  not just what's due today, so a missed day doesn't drop recordings out of sight.
* As a user, I want the Settings screen to open without crashing.
* As a listener, when a recording auto-advances I want the next one to show its real length, not
  "0:00".
* As a learner, I want to attach a notebook photo and actually see it attach (this has failed three
  times).
* As a learner recording in-app, I want the capture to also appear in Samsung Voice Recorder's "All
  recordings" tab, not just inside Rivendell.

### Acceptance criteria
* **(Amends M10 AC4)** Today's queue shows recordings whose active milestone became due in the last
  2 weeks (overdue 0..13 days), most-overdue first, **capped at 4**. The 1-day-stale special case +
  badge is subsumed by the backlog window (every Today row is simply "due", ordered by overdue days).
  M10's strict-only Today wording is withdrawn. **Tomorrow stays strict-only** (M10 AC5 unchanged —
  overdue == −1 exactly); the cap + 2-week window apply to Today only.
* The Settings screen opens without throwing; the SMTP-credentials block renders populated on second
  open and never throws `LateInitializationError`.
* After an auto-advance, the detail screen shows the new recording's real duration immediately (no
  transient "0:00 / 0:00"); the slider is usable as soon as the row loads.
* Attaching a JPG/PNG notebook photo produces a renderable thumbnail + full-screen image on the
  **first** attach, on device. A genuine decode failure (corrupt source, unsupported bytes) surfaces
  a precise, diagnosable error — not a silent no-op or a bare "couldn't load".
* A recording captured in-app is queryable by Samsung Voice Recorder's "All recordings" tab on
  Android 12+ (MediaStore row with `IS_RECORDING=1`, album/artist "Voice Recorder"). Captures on
  older One UI degrade gracefully (best-effort insert, never blocks the save).

### Tickets
- **COMPLETE (#51) T14.1 — Today queue: 2-week backlog, cap 4.** In `features/gpa/domain/queue_warmup.dart`, change
  the Today membership test from `overdue >= 0 && overdue < 2` to `overdue >= 0 && overdue <= 13`,
  then take the **top 4** by most-overdue (the existing `_compareByDueThenId` sorts overdue-ascending;
  slice to 4 after sort). Drop the `isStale` distinction for Today rows (every Today row is now simply
  due; the stale badge is removed from the Today path — the Tomorrow path is untouched). Update
  `features/gpa/data/review_event_repository.dart` `warmedQueue` doc + the `_WarmedTile` stale branch
  in `features/gpa/presentation/today_queue_screen.dart`. Amend M10 AC4 wording + the queue-warmup
  unit tests (new cases: overdue 0/1/5/13 in; 14+ out; exactly-4 cap; ordering most-overdue-first;
  Tomorrow still overdue==−1 only). Pure-Dart, no schema change. *ACs:* M14 AC 1. *Deps:* T10.1
  (Today strict-only — superseded).
- **COMPLETE (#52) T14.2 — Settings screen `LateInitializationError` fix.** Root cause:
  `features/report/presentation/weekly_report_settings_section.dart:29-31` declares
  `late final TextEditingController _username/_password/_recipient` but never constructs them —
  `_hydrate` only writes `.text`, and `build` reads `_username` (line ~150) before any assignment,
  throwing `LateInitializationError: field '_username' has not been initialised`. Fix: construct the
  three controllers in `initState` (empty text; `_hydrate` then sets username/recipient text after
  the KV read; password stays blank). Keep `dispose` disposing all three. Regression: a widget test
  that mounts `SettingsScreen` (faked `settingsRepositoryProvider`) asserts it builds without
  throwing and a second open re-hydrates saved values. *ACs:* M14 AC 2. *Deps:* T6.6.
- **COMPLETE (#53) T14.3 — Auto-advance shows real duration (seed only; persist-back deferred).** Root cause:
  `features/audio/presentation/recording_detail_screen.dart` `_DetailContent` computes
  `totalMs = snap.duration.inMilliseconds` (0 until the engine emits `MediaItem.duration`), so right
  after `context.replace('/recordings/$nextId')` the new row shows "0:00" + an indeterminate bar. The
  DB already carries `recordings.durationMs` (nullable, filled lazily — see `recordings_table.dart`).
  Fix: seed the controller's duration floor from the recording row — pass `durationMs` into
  `AudioPlayerController.loadAndPlay` (`features/audio/playback/application/audio_player_controller.dart`)
  so `_duration` initializes from it before the media-item stream fires. Persist the engine-resolved
  duration back to `recordings.durationMs` when it lands (in `_onMediaItem`) so later opens are
  instant. Tests: controller unit test that `loadAndPlay` with a non-null `durationMs` emits a
  snapshot with that duration before any transport event. *ACs:* M14 AC 3. *Deps:* T8.2, T1.5.
  **Shipped (#53):** seed-only — `loadAndPlay` seeds `_duration` from `recording.durationMs`,
  emits via `scheduleMicrotask` (the synchronous emit tripped Riverpod's build-phase guard since
  `loadAndPlay` runs in the detail screen's build branch). **Persist-back deferred to T15.x:**
  writing from the controller forces creation of `appDatabaseProvider`/`recordingRepositoryProvider`
  during a build frame in widget tests that don't override the DB, entangling the same guard; needs
  a cleaner injection seam (capture the repo at boot, not mid-build). The zero-length bug is fixed.
- **COMPLETE (#54, pending device confirm) T14.4 — Word-log image attach root-cause (open-once fix).** Failed three times (T8.3 diagnostics,
  T9.2 BitmapFactory re-encode). Symptom is "doesn't attach" — the `wordLogAttachFailed` snackbar
  from `word_log_section.dart _attachImage`, which fires on `isSupportedImageExt` rejection **or**
  `service.attach` throwing **or** the picker returning null (silent). Treat as unknown root cause
  and prove the fix on device — do **not** guess again. Audit (read, in order):
  `features/wordlog/platform/saf_image_log_picker_service.dart` + the Kotlin `pickImage` handler on
  `rivendell/wordlog` in `MainActivity.kt` (does the PhotoPicker launch + return a usable, persistent
  URI?); `features/wordlog/domain/supported_image_format.dart` (does it reject real-world ext like
  `.jpeg`/HEIC?); `image_log_service.attach` + `saf_image_writer_service` Kotlin (does the re-encode
  throw on a revoked / single-use PhotoPicker URI?); the `rivendell/wordlog` channel contract test.
  Instrument every hop under the `wordlog` tag (picker result, ext, channel return, bytes written,
  DB row id) so a failure leaves a precise trail. Reproduce on device, fix the actual root cause, and
  prove a **fresh** attach renders both the thumbnail + the full-screen `_FullScreenImage`. If the
  root cause is a single-use PhotoPicker URI revoked before copy, the fix is to take a persistent
  copy (or re-encoded bytes) before returning from the picker. *ACs:* M14 AC 4. *Deps:* T3.3, T9.2.
  **Shipped (#54):** audit pointed to `copyImage` reopening the picker URI twice (bounds, then decode);
  on Samsung the PickVisualMedia grant isn't reliably reusable, so the 2nd `openInputStream()` threw
  SecurityException → "could not decode image bytes" → `wordLogAttachFailed`. Fix: buffer the URI bytes
  once, decode from the buffer (2 opens → 1). Native-only; **device confirm still required** (fresh
  attach → thumbnail + `_FullScreenImage`). Secondary finding left as-is: `mimeToExt` rejects HEIC at
  the picker (FR-1.3.1 is JPG/PNG), so T9.2's HEIC re-encoder is unreachable for HEIC sources.
- **T14.5 — Capture → Samsung "All recordings" via MediaStore.** In-app captures already save to the
  Samsung folder via SAF (`saf_recording_writer_service.copyToFolder` on `rivendell/record`), but
  Samsung Voice Recorder's "All recordings" tab queries MediaStore with voice-recording flags, so a
  SAF-only file is invisible there. Add a Kotlin method `publishToMediaStore` on the `rivendell/record`
  channel: insert a `MediaStore.Audio.Media.EXTERNAL_CONTENT_URI` row with `DISPLAY_NAME`,
  `MIME_TYPE=audio/mp4`, `RELATIVE_PATH=Recordings/Voice Recorder`, `ALBUM="Voice Recorder"`,
  `ARTIST="Voice Recorder"`, and on API 31+ `IS_RECORDING=1`, `IS_MUSIC=0`; open the returned
  `OutputStream` and stream the just-written file's bytes in. Dart side: after `copyToFolder`
  succeeds in `recorder_controller.dart`, call `publishToMediaStore` with the new URI + display name.
  Best-effort — on failure log under the `RECORD` tag and continue (the recording is already saved;
  MediaStore visibility is additive). Gate the `IS_RECORDING` flag on `Build.VERSION.SDK_INT >= S`.
  *ACs:* M14 AC 5. *Deps:* T2.7, T10.3.

  **COMPLETE (#55, dev `cdf9dc7`).** Kotlin `publishToMediaStore` on `rivendell/record` inserts
  `MediaStore.Audio.Media.EXTERNAL_CONTENT_URI` (DISPLAY_NAME / `audio/mp4` /
  `Recordings/Voice Recorder` / `IS_RECORDING=1`,`IS_MUSIC=0` on API 31+) + streams the doc-URI bytes
  via `openOutputStream`. Dart: abstract port method, Saf impl (channel contract, throws
  `FileSystemException`), `recorder_controller.stop` captures the `copyToFolder` doc URI and calls
  publish best-effort (`on Object catch` → warn-log → continue). Tests: happy path asserts
  `publishCalls==1` + args; new "publish failure still reaches idle" pins non-fatal. Gate green incl.
  Android debug APK. **Note:** PR #55 squash-landed on `main` by mistake (`gh pr create` defaulted
  base `main`); dev got the change via FF from the feature branch `cdf9dc7` (parent `43ca556` = dev).
  `main`/`dev` now diverged — reconcile on next dev→main sync. **Device confirm still wanted:**
  record in-app, verify capture appears under Samsung Voice Recorder "All recordings".

---

## Milestone 15: Architecture health pass — review, refactor, gate efficiency (post-M11)

**Objective:** Two non-feature asks. (1) A critical architecture review across the whole app, then
a spawned refactor milestone for long-term maintainability. (2) Make the Standard Gate cheaper and
guarantee it's wired as a hook. No user-visible behavior change.

### User stories
* As the maintainer, I want an honest audit of how the app is structured after this much accretion,
  so the next milestones don't compound the rough edges.
* As the maintainer, I want the gate to run fast enough that I actually run it, and certainty that
  it fires on every push.

### Acceptance criteria
* A written architecture review lives at `docs/architecture-review.md`: per-feature boundary check
  (presentation/application/data/domain seams), repository/service/provider consistency, Drift
  migration + derive-don't-store invariant adherence, test-coverage gaps against the 80% floor, dead
  code, duplication, error-handling consistency, i18n completeness, and NFR-perf risks. Each finding
  is severity-tagged.
* The review **emits its own follow-up tickets** (T15.3…T15.n) appended to this milestone, ordered
  by severity — the review is not the deliverable, the refactors are. Do not start the refactors
  until the review lands and the user picks the subset to ship.
* The Standard Gate (`scripts/gate.sh`) runs materially faster on a no-op change (skips the Android
  debug build when no native/Kotlin/manifest/resource file changed; reuses the build_runner cache).
  The pre-push hook remains the canonical gate; `scripts/install-hooks.sh` is documented in the
  bootstrap step and re-runnable.

### tickets
- **T15.1 — Whole-app architecture review (read-only).** Produce `docs/architecture-review.md`.
  Cover, per feature dir under `lib/features/`: (a) layer purity (domain has no Flutter/Drift deps;
  data has no presentation deps; presentation doesn't touch the DB directly); (b) repository +
  service + provider naming/seam consistency vs the M0 pattern; (c) Drift migration hygiene
  (schemaVersion bumps, idempotent `onUpgrade` branches, FK pragmas); (d) the two invariants —
  append-only event logs (`review_events`, `metrics_events`, `xp_events`) and derive-don't-store
  (`RecordingReviewStatus`, queue, XP level, streak count) — audited for accidental mutable
  counters (freeze bank is the one allowed exception); (e) test-coverage holes against
  `scripts/check_coverage.dart`; (f) dead code + duplication across the M7–M10 queue churn (e.g.
  `WarmPlacement`-style leftovers, the two parallel queue shapes in `review_event_repository`:
  `todayQueue` vs `warmedQueue`); (g) error-handling consistency (swallowed `on Object` catches,
  missing user surfacing); (h) i18n — any hardcoded user-facing strings; (i) NFR-perf risks (N+1
  queries, main-isolate file work, unbounded list builders). Output = the doc + a severity-ordered
  refactor list that becomes T15.3+. *ACs:* M15 AC 1. *Deps:* none (read-only).

  **COMPLETE (#56).** `docs/architecture-review.md` written — 9 dimensions, severity-tagged,
  every `high`/`med` claim spot-checked against source. Headline: app is healthy; migrations
  idempotent (schemaVersion 9); both invariants hold (append-only logs, derive-don't-store); no
  N+1; indexer offloads correctly; no orphan codegen; all providers have live consumers. Actionable
  debt concentrated in: dead M7 queue shape (`todayQueue` family), one silent FR-1.2.3 swallow
  (`review_providers:56-59`), `coach` off the M0 pattern, two list-perf hotspots (`coach_note_dialog`
  unbounded `ListView`; `_WarmedTile` no-`.select` rebuild storm), one un-localized onboarding screen,
  SAF adapter stack-trace drops (incl. T14.5 publish path). Coverage 90.8% (floor 80%); holes at
  `app_database` 32% (no migration-step tests), `recording_indexer` 62%, provider-glue files.
  Emitted **T15.3–T15.16** (14 tickets, severity-ordered, appended below) — user picks subset before
  work begins. Plan-spec staleness logged for T15.15: `WarmPlacement`, gamification, "three event
  repos", `todayQueue` "parallel" all do not match the code.
- **T15.2 — Gate efficiency + hook assurance.** (a) Teach `scripts/gate.sh` to skip the Android
  debug build (step 6) when `git diff` against the merge-base shows no change under
  `app/android/**`, `**/*.kt`, `**/*.gradle*`, or `AndroidManifest.xml` — print a clear
  `gate: android skipped (no native change)` line. (b) Ensure `dart run build_runner` reuses cached
  outputs (don't blow away `.dart_tool/build` between runs). (c) Confirm the pre-push hook
  (`scripts/git-hooks/pre-push`) still `exec`s `gate.sh` verbatim and that
  `scripts/install-hooks.sh` installs pre-push + pre-commit + commit-msg; document running it in
  `setup.md` bootstrap. (d) Add a `gate --fast` mode (`SKIP_ANDROID=1` + skip codegen when no
  `.g.dart`/`.freezed.dart` source changed) for the inner-loop cycle. No change to what "green"
  means on a real push. *ACs:* M15 AC 3. *Deps:* T0.1.

  **COMPLETE (#57).** `scripts/gate.sh` rewritten:
  (a) Android debug build skipped automatically when `git diff <upstream-merge-base>..HEAD` touches
  no native file (`app/android/**`, `*.kt`, `*.gradle*`, `AndroidManifest.xml`) — prints
  `gate: android skipped (no native change)`; `GATE_FORCE_ANDROID=1` overrides.
  (b) `build_runner` already incremental (`.dart_tool/build` reused; `--delete-conflicting-outputs`
  only clears conflicting outputs, not the cache) — documented in the gate header + `setup.md`.
  (c) `pre-push` still `exec`s `gate.sh` verbatim; `install-hooks.sh` already installs all three
  hooks (commit-msg + pre-commit + pre-push) via `core.hooksPath`; `setup.md` command reference now
  documents the skip modes + `install-hooks` re-run.
  (d) `gate.sh fast` / `--fast` / `GATE_FAST=1` = `SKIP_ANDROID=1` **and** codegen skipped when no
  `.dart` declaring a generated `part` (`*.g.dart`/`*.freezed.dart`) changed vs the merge-base —
  prints `gate: codegen skipped (--fast, no codegen source changed)`.
  Verified end-to-end on this branch: full gate → `android skipped (no native change)`, 513 tests
  pass, coverage 90.8%; `--fast` → `codegen skipped (--fast, no codegen source changed)`. Safe
  default preserved: unknown merge-base → run everything.
- **T15.3 — Delete dead M7 queue shape.** `high`. Remove `todayQueue`, the gpa `QueueItem`,
  `classifyQueueEntry`, `QueueEntryKind` (all dead in prod; `warmedQueue` is the live shape). Update
  the tests that exercise them. *Deps:* none.

  **COMPLETE (#58).** Removed `ReviewEventRepository.todayQueue`, the gpa `QueueItem` class,
  `classifyQueueEntry`, `QueueEntryKind`, + the two test groups that exercised them + a stale dartdoc
  backreference. Live `core/queue QueueItem` (offline queue) + the warmed path untouched. Pure
  deletion: 4 files, +1/−271. Gate green — 499 tests (14 dead removed), coverage 90.6%, android
  auto-skipped (no native change).
- **T15.4 — Stop silent FR-1.2.3 review-event loss.** `high`. `review_providers.dart:56-59` swallows
  the `recordReview` append on the 80%-crossing watcher: user sees "reviewed" but the row is lost, no
  signal, no retry, no `reviewGenerationProvider` bump. Surface a non-blocking "couldn't save review"
  snackbar, reset the latch so the next crossing retries, bump the generator on success.
  *Deps:* none. ✅ PR #59 — added `ReviewProgressGate.rearm()`; watcher retries 3× then ticks
  `reviewSaveFailureTickProvider` → `HomeShell` snackbar. Gate + new watcher unit tests; 503 tests,
  91.1% coverage, android auto-skipped.
- **T15.5 — Bring `coach` onto the M0 pattern.** `high`. Feature is the most off-pattern: no
  `domain/` (DTOs in `data/coach_note_repository.dart`), presentation imports `data/` directly, and
  `coach_bank_screen` mutates via `repo.create/update/delete` with no `application/` orchestrator. Add
  `coach/domain/`, add a `CoachNoteCommands` write orchestrator, remove presentation→data imports.
  *Deps:* none. ✅ PR #60 — moved `CoachNoteWithLinks` to `coach/domain/`; added `CoachNoteCommands` +
  `coachNoteCommandsProvider`; presentation writes through commands, no `data/` imports. Commands
  delegation test added; 506 tests, 91.2% coverage, android auto-skipped.
- **T15.6 — `coach_note_dialog` unbounded list.** `high`. `coach_note_dialog.dart:236`
  `ListView(shrinkWrap, children:[for o in options])` materializes the full recordings list (≤1000) +
  a `shrinkWrap` measure pass on dialog open. Convert to `ListView.builder`. *Deps:* none. ✅ PR #61
  — picker sheet now `ListView.builder`; tiles build lazily on scroll instead of all-at-once on
  sheet open. Behavior-preserving; 506 tests, 91.2% coverage, android auto-skipped.
- **T15.7 — `_WarmedTile` rebuild storm.** `high`. `today_queue_screen.dart:138`
  `ref.watch(audioPlayerControllerProvider)` takes the full snapshot; just_audio's position stream
  re-emits ~5-8 Hz, so every visible tile rebuilds that fast during playback. Tile uses only
  `recordingId` + `isPlaying` → switch to `.select`, mirroring `recordings_screen.dart:148-152`.
  *Deps:* none. ✅ PR #62 — `_WarmedTile` now `ref.watch(... .select((s) => (recordingId, isPlaying,
  isError)))`; tiles rebuild on cue / play-pause / error only, not every position tick. The tile also
  reads `isError`, so it joins the tuple. Behavior-preserving; 506 tests, 91.2%, android auto-skipped.
- **T15.8 — Localize folder onboarding.** `high`. `folder_onboarding_screen.dart` has zero
  `AppStrings` calls — 6 hardcoded user-facing strings (title, body, button, 3 snackbars). Route them
  through `AppStrings` (en + uz; the `_Bundle` `required` fields enforce parity). *Deps:* none. ✅
  PR #63 — 6 strings routed through `AppStrings` (title, body parameterized on Voice Recorder folder
  name, pick, none, non-SVR warning, save failed); en + uz bundles + getter/ctor/field plumbing.
  Strings captured before async gaps so `BuildContext` is safe across awaits. Behavior-preserving;
  506 tests, 91.2%, android auto-skipped.
- **T15.9 — Preserve stack traces across SAF adapters.** `med`. Five sites catch `PlatformException`
  and rethrow a new `FileSystemException(message)`, dropping the stack: `saf_image_writer_service`
  (`:28-31`), `saf_recording_writer_service` (`:36-38` copyToFolder + `:51-55` T14.5 publishToMediaStore),
  `saf_recording_file_service` (`:30-32` rename + `:43-45` delete). Use `Error.throwWithStackTrace`.
  *Deps:* none.
  **Shipped.** All five rethrow sites now use `Error.throwWithStackTrace(fse, st)` so the
  PlatformException's own stack survives — a save/rename/delete/image-copy failure now points
  at the channel machinery that produced it, not the adapter's rethrow line. Pinned by a
  stack-preservation test at each site (the leading frame must not be the adapter file). Also
  added a new `saf_recording_file_service_test.dart` (rename + delete channel contract —
  previously had no host-side test). Gate green (567 pass, 91.4%, Android skipped — Dart-only).
  Overlaps T19.7 PR #94 in `saf_recording_writer_service.dart` (same catch block) — trivial
  merge (T19.7 adds a `FolderGrantLostException` branch ahead of this generic rethrow).
- **T15.10 — Move domain DTOs out of `data/`.** `med`. `ScannedFile` is used by the abstract
  `AudioIndexerService` seam → it must live in `audio/domain/`, not `data/recording_repository.dart`.
  Revisit gpa `QueueItem`/`WarmedItem` placement after T15.3 (the dead `QueueItem` goes; `WarmedItem`
  moves to `domain/`). *Deps:* T15.3.
- **T15.11 — Offload AI image write.** `med`. `fal_ai_image_service.dart:135` does
  `file.writeAsBytes(bytes, flush: true)` for an MB-scale download on the main isolate. Move to
  `compute()`. *Deps:* none.
  **Shipped.** The plan's `fal_ai_image_service.dart:135` path was stale (the
  service is Pollinations-keyless, not fal.ai); the real site is
  `pollinations_image_service.dart:_writeBytes` (called once per queued word
  in the foreground drain). `_writeBytes` now dispatches to a top-level
  `_writeImageBytes` via `compute()`; the path string + bytes cross the
  isolate boundary in a plain `_ImageWriteArgs` holder. Spawn cost is
  invisible — the 1.2s rate gate dwarfs it. Behavior-preserving: the existing
  bytes+path+cache-row suite stays green; added a 64KB intact-write regression
  to pin that non-trivial payloads survive the isolate transfer. Gate green
  (558 pass, 91.5% coverage, Android skipped — Dart-only). No device step:
  `compute()` is a framework primitive, and the write's observable contract
  (file at `docsDir/<relativePath>`, exact bytes, parent dir created) is
  fully unit-pinned.
- **T15.12 — Extract shared timestamp-range selector.** `med`. `review_event_repository.eventTimestamps`
  ≈ `word_log_repository.textLogTimestamps` (~85% identical). One parameterized helper over table +
  column + kind. *Deps:* none.
- **T15.13 — i18n + presentation-decode polish.** `med`. `weekly_report_settings_section 'Save failed'`
  snackbar + `recording_detail 'D+7'` milestone label → `AppStrings`; move `word_log_section`
  `Image.file` decode behind an application service. *Deps:* none.
- **T15.14 — `domain/` Flutter-SDK-free.** `low`. 7 domain files import `package:flutter/foundation.dart`
  only for `@immutable`. Switch to `package:meta/meta.dart` (or drop — `@freezed` implies immutability).
  Files: gpa (`gpa_intervals`, `review_status`, `queue_warmup`), wordlog (`vocab_pair`), anki
  (`anki_model_spec`), report (`report_schedule`), audio (`recording_state`, `playback_snapshot`).
  *Deps:* none.
- **T15.15 — Reconcile `plan.md` with reality.** `low` (doc). Prune stale refs in T15.1's spec:
  `WarmPlacement` (never existed), gamification (no XP/streak/freeze-bank code), "three event repos"
  (no xp repo), "two parallel queue shapes" (`todayQueue` is dead, not parallel). *Deps:* T15.3.
- **T15.16 — Close coverage holes.** `low` (deferred). Add a v1→v9 migration-step upgrade test
  (`app_database.dart` at 32%); `recording_indexer` parse-path tests (62%, NFR-2.2.1 surface); a
  `review_providers` append-failure test that locks T15.4. *Deps:* T15.4.

> The full severity-tagged detail, verified file:line evidence, and "clean" dimensions live in
> `docs/architecture-review.md` (T15.1). Each ticket above is one PR; do not bundle unrelated
> refactors. **The user selects the subset to ship before any T15.3+ work begins.** Suggested pairs
> if fewer PRs are wanted: T15.3+T15.10+T15.12 (queue/DTO/helper cleanup), T15.6+T15.7 (list-perf),
> T15.8+T15.13 (i18n). Keep T15.4 / T15.5 / T15.9 / T15.11 standalone.

**Milestone 15 COMPLETE.** All three ACs met: (1) `docs/architecture-review.md`
shipped (#56), severity-ordered refactor list emitted as T15.3+; (2) `gate.sh`
rewritten to skip the Android debug build on no-native-change + reuse
build_runner cache (#57), pre-push hook is canonical; (3) the user-selected
subset of refactors — the 6 `high`s, T15.3–T15.8 — shipped one PR each (#58 dead
queue shape, #59 silent FR-1.2.3 review-event loss + retry, #60 coach onto M0
pattern, #61 unbounded list builder, #62 `_WarmedTile` `.select` rebuild fix,
#63 folder-onboarding i18n). The `med`/`low` tickets (T15.9–T15.16) remain open
as backlog — out of scope for this pass.

---

## Milestone 16: AnkiDroid runtime-grant fix (T9.1, finally)

**Objective:** "Send to Anki" actually works against a current AnkiDroid install. The export throws
`Permission not granted for: CardContentProvider.query /decks (com.rivendell.app)` on the very first
content-provider call. Root cause is concrete and verified: `AnkiGateway.kt` calls
`api.deckList` / `api.modelList` (content-provider queries) **without ever driving AnkiDroid's runtime
permission grant**. On modern AnkiDroid, access requires the `READ_WRITE_PERMISSION`
(`AddContentApi.READ_WRITE_PERMISSION`) runtime grant — which Rivendell never requests. The bundled
`api-1.1.0.aar` already exports the symbols this needs (`READ_WRITE_PERMISSION`,
`getAnkiDroidPackageName`, `shouldRequestPermission` is *not* on the AAR — see T16.1); **no AAR swap
or manifest patch is the fix** — the missing piece is the runtime request flow itself. This is the
canonical flow the official `ankidroid/apisample` ships, ported to Rivendell's channel architecture.

> **Note on AnkiDroid 2.24+:** the runtime `ActivityCompat.requestPermissions({READ_WRITE_PERMISSION})`
> call is still the correct API. On 2.24 the user must additionally have AnkiDroid's global
> "Enable AnkiDroid API" toggle ON for the grant to succeed; when it's off the request returns DENIED
> and Rivendell surfaces a current-copy CTA (T16.3) — *not* the stale "Settings → Advanced → API →
> allow Rivendell" guidance PR #41 shipped.

### User stories
* As a learner, I want "Send to Anki" to succeed against my AnkiDroid install without a manual
  permission dance, or to tell me exactly what to flip if it can't.

### Acceptance criteria
* Tapping "Send to Anki" on a recording's word log, on a device with AnkiDroid installed + its API
  enabled, completes the export (Type 1 + Type 2 notes land in the Rivendell deck) with **no**
  `CardContentProvider.query /decks` SecurityException.
* On first export, if the runtime grant is missing, the user gets a one-time prompt that drives
  AnkiDroid's native grant screen; after granting, the export proceeds automatically (no second tap).
* If AnkiDroid is missing → "Install AnkiDroid" CTA (Play Store). If the grant is denied or the
  AnkiDroid API toggle is off → a clear snackbar/dialog with **current** copy: "Open AnkiDroid →
  Settings → enable the AnkiDroid API, then retry." No stale per-app-permission wording.
* Repeated exports never re-prompt once granted; the grant state is read via the API, not cached.

### Tickets
- **T16.1 — Kotlin gateway: permission API + install detection.** In
  `app/android/app/src/main/kotlin/com/rivendell/app/AnkiGateway.kt`:
  - Add `fun shouldRequestPermission(): Boolean` = API ≥ M and
    `ContextCompat.checkSelfPermission(context, AddContentApi.READ_WRITE_PERMISSION) != GRANTED`
    (this is `AnkiDroidHelper.shouldRequestPermission` from the apisample — reimplement inline; the
    `api-1.1.0.aar` does **not** ship `shouldRequestPermission` on `AddContentApi`, so don't call a
    missing method — use the `ContextCompat` check against the `READ_WRITE_PERMISSION` constant, which
    the AAR does export).
  - Switch `isInstalled()` from the `packageManager.getPackageInfo` probe to
    `AddContentApi.getAnkiDroidPackageName(context) != null` (canonical, also false when the user has
    disabled the API).
  - (No change to `ensureDeck`/`ensureModel`/`addNote`/`addMedia` — they're correct once the grant
    lands. Optional later: adopt `findDeckIdByName`/`findModelIdByName`-style rename-resilient lookup
    to cut content-provider round-trips — out of scope here.)
  - In `AndroidManifest.xml` ensure `<uses-permission android:name="<READ_WRITE_PERMISSION string>"/>`
    is declared (the permission is defined by AnkiDroid; the manifest declares that this app holds it,
    which the runtime request then grants). Use the `AddContentApi.READ_WRITE_PERMISSION` value verbatim.
  *ACs:* M16 AC 1. *Deps:* T4.1. ✅ PR #64 — `shouldRequestPermission()` reimplemented inline
  (API ≥ M + `ContextCompat.checkSelfPermission` vs `AddContentApi.READ_WRITE_PERMISSION`, verified
  via `javap` that the v1.1.0 aar exports the constant but not the method); `isInstalled()` switched
  to `getAnkiDroidPackageName(context) != null`; manifest comment refreshed (permission already
  declared by #41).
- **T16.2 — Channel + MainActivity runtime-grant flow.** In `MainActivity.kt`, add two
  `rivendell/anki` channel methods:
  - `"shouldRequestPermission"` → `result.success(ankiGateway.shouldRequestPermission())`.
  - `"requestPermission"` → register an `ActivityResultLauncher<String>` via
    `registerForActivityResult(ActivityResultContracts.RequestPermission())` (the modern, lifecycle-safe
    equivalent of `ActivityCompat.requestPermissions` + `onRequestPermissionsResult`; matches the SAF
    launcher pattern already in this file). Stash the `MethodChannel.Result` in a `pendingPermissionResult`
    field (mirror `pendingResult`/`pendingPickResult`), launch the contract with
    `READ_WRITE_PERMISSION`, and on the result callback `result.success(granted)` (and clear the
    pending field). Guard re-entry like the other launchers.
  Keep the existing `SecurityException` → `ANKI_NO_ACCESS` catch as a defensive backstop, but the
  front-door `shouldRequestPermission`/`requestPermission` is now the primary path. *ACs:* M16 AC 2.
  *Deps:* T16.1. ✅ PR #64 — `requestPermissionLauncher` via `registerForActivityResult(RequestPermission())`
  mirroring the SAF/image launchers, `pendingPermissionResult` + `REENTRY` guard, both methods handled
  on the main thread before the worker-thread content-provider block. `ANKI_NO_ACCESS` backstop retained.
  Bundled with T16.1 (one atomic native unit).
- **T16.3 — Dart export gate + one-time grant dialog + current copy.**
  - `AnkiGateway` interface (`features/anki/application/anki_gateway.dart`) +
    `AnkiDroidGatewayService` (`features/anki/platform/ankidroid_gateway_service.dart`): add
    `Future<bool> shouldRequestPermission()` + `Future<bool> requestPermission()` wrapping the two new
    channel methods. (`FakeAnkiGateway` gets no-op stubs returning `false`/`true`.)
  - Export flow (`anki_export_button.dart` + `anki_export_providers.dart`): before
    `exportType1`/`exportType2`, gate on access:
    1. `isInstalled()` false → show "Install AnkiDroid" dialog (Play Store deep link
       `market://details?id=com.ichi2.anki` with an http fallback). Return.
    2. `shouldRequestPermission()` true → show a one-time explainer dialog ("Rivendell needs AnkiDroid
       API access to add cards. Tap Continue to grant."), Continue → `requestPermission()`.
       Granted → proceed with the export. Denied → snackbar with current copy ("Open AnkiDroid →
       Settings → enable the AnkiDroid API, then retry.") and return.
    3. Else → proceed with the export (existing path).
  - Update ALL user-facing strings in `app/lib/l10n/` (en + templates) so nothing references the stale
    per-app permission screen or "Advanced → API" path. Add a `ankiEnableApiHint` string.
  - Handle the `ANKI_NO_ACCESS` typed error on existing calls as a fallback that re-runs the gate.
  Widget tests: faked gateway exercising the three branches (notInstalled / needsPermission-granted /
  needsPermission-denied) assert the right dialog/snackbar/export path. *ACs:* M16 AC 1–4. *Deps:*
  T16.2, T4.5. ✅ PR #65 — gateway/service/fake gain both methods (configurable stubs + call counter);
  `_send()` runs the 3-branch gate; `ANKI_NO_ACCESS` re-runs the gate once; stale
  `_looksLikePermissionError` text-sniff removed; l10n swapped stale `ankiPermissionHint` for
  `ankiEnableApiHint` + grant-dialog strings (en + uz). **Deviation:** the Play Store deep-link CTA was
  deferred (no `url_launcher` dep — would be a new platform channel); the existing "Install AnkiDroid
  from Google Play" dialog copy stays. Busy phase moved off the gate path into `_doExport` to stop the
  `CircularProgressIndicator` ticker deadlocking `pumpAndSettle` across the dialog await. 514 tests
  (+8), 91.2%, android auto-skipped.

**Milestone 16 COMPLETE (pending device-confirm).** All three tickets shipped (T16.1+T16.2 bundled as
PR #64, T16.3 as PR #65). The runtime-grant flow that the v1.1.0 aar exposed but Rivendell never drove
is now wired end-to-end: the export gates on `shouldRequestPermission`, drives AnkiDroid's native grant
screen via `registerForActivityResult(RequestPermission())`, and surfaces current copy on deny. The
`ankidroid_api_model` memory flagged a v2-aar migration as required; verified via `javap` that the
v1.1.0 aar already exports `READ_WRITE_PERMISSION` + `getAnkiDroidPackageName`, so no swap was needed —
the missing piece was the runtime request flow itself. **Device-confirm remains the unblockable
caveat** (mirrors T14.4/T14.5): on AnkiDroid 2.24 with the global API toggle ON, the first "Send to
Anki" should complete with no `CardContentProvider.query` SecurityException; with the toggle OFF, the
request returns DENIED and the enable-API snackbar shows current copy.
---

## Milestone 18: AI image-gen queue hardening + wordlog image-attach retirement

**Goal.** Make the AI-image → Anki Type-2 pipeline succeed autonomously, **exactly
once per word**, with visible status — product-ready. No user input, no manual
retry. Separately, retire the word-log "attach image" affordance (keep the
read-only viewer for anything already attached).

**Why now.** Real-use (post-M16) showed the pipeline flaky and opaque: spamming
"Send to Anki" created duplicate pending rows, transient Pollinations failures
stuck until the user tapped Retry, and the queue screen went stale while the app
drained in the foreground. The path-mismatch root cause was fixed in PR #71; the
remaining failures are reliability + observability, not correctness.

### Root-cause analysis (the flakiness)

- **F1 — duplicate enqueues.** `OfflineQueueItems` has *no* uniqueness (by design:
  the table comment says "replay appends; handler decides idempotency").
  `QueueRepository.enqueue` always inserts, and `enqueueGeneration` checks only
  `cache.cachedPath`, **not** the pending queue. So each "Send to Anki" tap on a
  not-yet-generated word appends a fresh row → N generations for one word, N
  `addNote` attempts, N failure cycles.
- **F2 — no real background drain.** `workmanager_init.callbackDispatcher` is a
  stub: it logs + returns `true` without ever opening the DB or draining. The
  15-min periodic task is registered but does nothing. A transient failure with
  the app backgrounded/closed never auto-retries.
- **F3 — in-process Timer dozed.** The autonomous backoff (`QueueWorker`) arms a
  Dart `Timer`; Android dozes the backgrounded process and that Timer doesn't
  fire. Effective retry is foreground-only.
- **F4 — transient upstream failures.** Pollinations keyless tier returns
  429/timeout/SSL/DNS at network handovers. `generateNow` throws on non-200 →
  item marked failed → retried only on the next *foreground* drain or resume.
- **F5 — queue UI goes stale.** `aiImageQueueSnapshotProvider` is a
  `FutureProvider` invalidated only on retry/cancel/foreground-resume. While the
  app is open and items drain, the queue screen + badges don't update → "difficult
  to know what's going on."
- **F6 — no global pending indicator.** Pending state is visible only on the
  queue screen (Settings tile) + the export button's one-shot result chip. No
  at-a-glance badge.

### Tickets

- **T18.1 — Idempotent enqueue (dedup).** Add a partial unique index on
  `offline_queue_items(type, payload) WHERE done = 0`. Migration v9→v10 first
  collapses any existing duplicate pending rows (keep min id), then creates the
  index. `enqueue` switches to `insertOrIgnore` (returns 0 rows on conflict =
  no-op). `enqueueGeneration` keeps the cache short-circuit. *ACs:* spamming
  "Send to Anki" never creates more than one pending `ai_image` row per word;
  re-enqueueing a word whose image is already cached is still a no-op. *Deps:*
  T4.3. Unit + repo test the dedup contract.
- **T18.3 — Live queue snapshot.** Expose a `Stream<int>` (pending count) from
  `QueueWorker` emitted after every drain; `aiImageQueueSnapshotProvider`
  (and any badge) `ref.watch`es it so the queue screen updates live as items
  clear — no manual refresh. *ACs:* while the app is foreground and online, a
  generated image disappears from Pending and appears under Generated within one
  drain cycle, automatically. *Deps:* T18.1 (so "pending" is meaningful).
- **T18.5 — Tolerant generation + clear per-item status.** In `generateNow`,
  retry once immediately on a transient HTTP class (429/5xx/socket/timeout)
  before throwing; keep the queue-level backoff for repeated failures. Ensure
  `lastError` is human-readable (strip the stack, keep the status/url). *ACs:* a
  single 429 self-heals without surfacing a failure; a real outage records a
  readable `lastError` and the item keeps retrying on backoff. *Deps:* T4.3.
- **T18.4 — Global pending indicator.** A compact "N images queued →" affordance
  on the recording detail (near the export button) that links to the queue
  screen; hides when 0. *ACs:* pending count is visible at a glance from the
  recording that produced it; tapping opens the queue screen. *Deps:* T18.3.
- **T18.6 — Hide word-log "attach image."** Remove the attach entry points (the
  empty-state "Add photo" button and the inline "Add photo" button in
  `_ImagesBody`). Keep the read-only viewer for any already-attached images
  (thumbnails + full-screen). The Text/Images segment toggle stays only when
  images already exist. *ACs:* the user cannot attach new images; existing
  thumbnails remain viewable. *Deps:* none. *(Independent slice — can ship
  first.)*
- **T18.2 — Real background drain via workmanager.** ⚠️ **Architectural /
  risk-flagged — confirm before executing.** Implement `callbackDispatcher` to
  open the DB (read the SQLCipher key via `SecureDatabaseKeyStore`, which is
  Android-Keystore-backed and reachable from the workmanager isolate), register
  the `ai_image` + `email` handlers, and run `QueueWorker.drain`. Keep the 15-min
  `networkType: connected` periodic task. *ACs:* a pending item with the app
  closed drains within ~15 min of regained network. *Deps:* T4.3, T0.2. *Risk:*
  background-isolate plugin initialization (flutter_secure_storage + http +
  drift) — needs the workmanager background channel wired; verify on-device.
  *Decision:* ship T18.1/3/4/5/6 first (they deliver ~90% of "works every time"
  via dedup + tolerant retry + foreground Timer + resume + start drains, since
  the queue survives process death); tackle T18.2 last and only if closed-app
  processing is required.

**Order.** T18.6 (independent, quick) → T18.1 (highest impact / lowest risk) →
T18.3 → T18.5 → T18.4 → T18.2 (heavy, gated on confirm). Each its own PR-sized
slice off `dev`, standard gate before push.

---

## Milestone 19: Reactive queue + English-prompt images + auto-advance fix

**Goal.** Close the three real-use defects that survived M18, and add the
integration test that would have caught them. After M19: tapping Send-to-Anki
generates the image **in the same foreground session** (no restart needed),
the queue-review screen updates live as it happens, the generated image
depicts the **English** concept (the card back stays Uzbek), and auto-advance
to the next recording actually plays it.

**Why now.** M18 shipped dedup (T18.1), a live snapshot stream (T18.3),
transient retry (T18.5), and a pending-count link (T18.4) — but real use
exposed that the foreground drain still never fires after enqueue, the screen
still goes stale, and the prompt feeds Pollinations an Uzbek word it can't
render. Root cause: the drain trigger and the screen-refresh signal both depend
on a network edge or a manual action, never on the **queue table changing**.
The unit suite passed because it tests `enqueue` and `generateNow` in isolation,
never the enqueue→drain→screen contract.

### Root-cause map

- **F1 (no foreground generation).** `QueueWorker.start()` subscribes to
  `NetworkService.online` only; `ConnectivityNetworkService` seeds current
  state, so the worker drains once at boot, then goes idle (pending=0 → no
  timer). `QueueRepository.enqueue()` writes the row but **nothing notifies the
  worker**. Already-online + no connectivity flap → the just-enqueued row sits
  until the next edge or app restart. Restart fires a radio edge → drains.
  This is the exact "didn't show until restart" symptom.
- **F2 (stale queue screen).** `aiImageQueueSnapshotProvider` re-fetches only
  on `QueueWorker.onDrained`. With F1, no drain fires → the screen is frozen at
  its initial fetch. Independent of F1, a row enqueued *while the screen is
  mounted* also never refreshes, because the insert doesn't surface as a drain
  event.
- **F3 (bad image).** `buildPictographPrompt(uzbekWord)` sends "concept of
  'kurbaka'" to Pollinations. Image models handle Uzbek poorly → noise. The
  pair's English gloss is known at export time (`anki_export_service.dart:121`
  has the full `pair`) but discarded. Card identity = Uzbek (cache key + Anki
  back), prompt source = English.
- **F4 (auto-advance dead).** On natural completion, `_onCompletion` does
  `context.replace('/recordings/$nextId')`; the new detail screen's
  `loadAndPlay` for the next recording showed zero length and didn't start
  playback. Root cause found in T19.4: the controller's `_lastTransport` held
  the completed state from the prior track, so the seed emit for the next
  recording reported `isCompleted=true` → the new screen's completion listener
  cascaded through the list, thrashing the engine.

### The robust fix (one mechanism for F1 + F2)

Both the worker and the snapshot provider subscribe to a **Drift reactive
stream** over the `offline_queue_items` table (`select(...).watch()`). Any
insert / markDone / markFailed emits → the worker drains (re-entry-guarded +
debounced), and the snapshot provider re-fetches. Drain trigger and screen
refresh become a function of *queue state*, not of network edges or manual
pokes. The dependency direction stays clean (repo gains one stream method;
worker + provider observe it).

### Tickets

- **T19.1 — Integration test (RED).** Boot a `ProviderContainer` with the REAL
  `AppDatabase.forTesting(NativeDatabase.memory)`, REAL `QueueWorker`,
  `QueueRepository`, `AiImageCacheRepository`, and `PollinationsImageService`
  (fake `http.Client` returning fixed PNG bytes + a temp docs dir), plus a
  `FakeNetworkService` seeded online. Override the production providers so the
  REAL graph resolves against the in-memory DB. Mount
  `AiImageQueueScreen`. Act: `service.enqueueGeneration(pair)`. Assert: screen
  shows the word under **Pending**. Pump the drain. Assert: screen shows the
  word under **Generated**, pending empty, the PNG written to the temp dir,
  cache row present. This test fails today (F1: never drains; F2: stale) and
  gates the rest of the milestone. *ACs:* the test is red on `dev` before
  T19.2/T19.3 land, green after. *Deps:* none.
- **T19.2 — Reactive drain + live snapshot.** Add
  `QueueRepository.pendingChanges(): Stream<void>` (a Drift `.watch()` over
  pending rows, mapped to void). `QueueWorker.start()` subscribes and calls
  `_drain()` on change (debounced ~50 ms; the `_draining` guard prevents
  overlap). `aiImageQueueSnapshotProvider` switches from `await for
  (worker.onDrained)` to `await for (queue.pendingChanges())` (and a cache
  change stream, or re-fetch on the queue stream since a drain that generates
  also inserts a cache row) — re-fetching on table change. Keep `onDrained` for
  external observers (badge). *ACs:* enqueue during a foreground session
  drains within ~100 ms with no network flap; the queue screen updates from
  pending→generated live. *Deps:* T19.1 (proves it).
- **T19.3 — English-prompt generation.** Payload becomes
  `{"uzbek": ..., "english": ...}`. `AiImageService.enqueueGeneration` +
  `generateNow` take the pair (or both strings). `buildPictographPrompt` runs
  on the **English** word. Cache stays keyed by **Uzbek** (card identity).
  `wordFromAiImagePayload` becomes a tolerant reader: a legacy `{"word": ...}`
  row is read as uzbek=english=word (degraded prompt, no crash) so a pending
  row from before the upgrade still drains. Anki Type-2 card unchanged
  (image:uzbek). *ACs:* `kurbaka:frog` produces an image of a frog; the card
  back is `kurbaka`. *Deps:* T19.1 (extend the test to assert the GET prompt
  contains the English word).
- **T19.4 — Auto-advance plays the next recording.** Investigate `loadAndPlay`
  on a fresh `context.replace` navigate: why duration reads zero and playback
  doesn't start. Likely the duration binding / auto-play gate mishandles the
  async `MediaItem.duration` resolve on a cold load. Fix + add a widget test
  that simulates completion → advance → asserts the next recording's
  `loadAndPlay` is called + duration resolves. *ACs:* auto-advancing to the
  next recording starts playback and shows a non-zero duration. *Deps:* none
  (independent slice).
- **T19.5 — Verify the "N images queued" link.** Confirm the T18.4
  `_AiImageQueueLink` appears in the word-log the moment a word is enqueued
  (now that F1/F2 are fixed) and that tapping it opens
  `/settings/ai-image-queue`. Covered by extending the T19.1 harness to mount
  `WordLogSection`; add an assertion if cheap. *ACs:* the link is tappable and
  routes correctly. *Deps:* T19.2.
- **T19.6 — User-tunable image prompt (Settings).** The prompt body becomes a
  user-editable template stored in the SQLCipher settings KV, with a
  `{word}` placeholder substituted at drain time. **Sensible default** = the
  current `buildPictographPrompt` body verbatim (pictographic, no-text guard) —
  pre-filled in Settings so out-of-box behavior is unchanged and a careless
  edit is recoverable. Empty/missing template falls back to the hardcoded
  default. UI: Settings → AI Image → multi-line text field. *ACs:* editing the
  template changes the next generated image's prompt; clearing it restores the
  default. *Deps:* none.
- **T19.7 — Recording save SAF permission denial.** Saving an in-app recording
  fails with `SecurityException: Permission Denial: writing
  com.android.externalstorage.ExternalStorageProvider ...
  requires android.permission.MANAGE_DOCUMENTS` at
  `MainActivity.copyToFolder(MainActivity.kt:462)`. The SAF write path goes
  through a tree-URI grant that needs `takePersistableUriPermission` (or the
  copy must write via the granted `DocumentFile` rather than a raw `File`).
  Audit the Kotlin save path, fix the permission/copy, and add a
  Robolectric/instrumentation guard if feasible. *ACs:* Save succeeds into the
  Samsung Voice Recorder folder without a SecurityException. *Deps:* none
  (native slice; Android-only).
  **Shipped (pending PR; device-confirm still required).** Root cause: the
  persistable WRITE grant taken at folder-pick can lapse (app reinstall, data
  clear, OS prune) while the URI string survives in KV, so the next
  `DocumentsContract.createDocument` / `openOutputStream` throws
  `MANAGE_DOCUMENTS` — and the old `catch (Exception)` flattened every failure
  to a generic `COPY_FAILED` with no recovery path. Fix: `MainActivity.kt`
  `copyToFolder` now `ensureWriteGrant`s first — prechecks
  `persistedUriPermissions` for WRITE, defensively re-takes
  (`takePersistableUriPermission`; no-op when held, SecurityException when
  truly gone), and the channel handler maps `SecurityException` → typed
  `NO_PERSISTED_GRANT` ahead of the generic `COPY_FAILED`. Dart:
  `FolderGrantLostException` on the writer port seam; `SafRecordingWriterService`
  maps the code; `RecorderController.stop` routes it to a distinct
  `no-folder-grant` error; the record sheet shows a "Re-pick folder" action that
  clears the stale URI + navigates to `/onboarding` (other errors still retry).
  l10n (en + uz) for the new message + action. Tests: controller routing,
  writer code-mapping, sheet affordance render. Gate green (560 tests, 91.5%
  coverage, arm64 debug APK builds). **Device-confirm still required** (mirrors
  T14.4/T14.5/T16): on a device where the grant has lapsed, verify the first
  save surfaces "Re-pick folder" instead of `MANAGE_DOCUMENTS`, and that
  re-picking + saving completes cleanly. Secondary note (out of scope): the
  startup indexer scan reads the same tree URI and also degrades silently on a
  lapsed grant — separate path, pre-existing graceful-empty behavior.

**Order.** T19.1 (red test, proves the bugs) → T19.2 (reactive fix, green) →
T19.3 (English prompt) → T19.4 (auto-advance, independent) → T19.5 (link
verify) → T19.6 (tunable prompt) → T19.7 (SAF save). Each its own PR-sized
slice off `dev`, standard gate before push. T18.2 (workmanager background
drain) remains deferred — the foreground path is the product path; background
is a fast-follow.
