# Changelog

All notable changes to **Rivendell** are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[SemVer](https://semver.org/). Notation `(T x.y)` references the task in
`plan.md`.

## [0.2.0] — 2026-07-19

Second beta cut. Adds the motivation layer (XP, levels, streaks, freezes) and
moves weekly email off app-password SMTP onto Google OAuth + Gmail API. Also
fixes two playback transport bugs reported in real use: auto-advance leaving
the next recording at 0:00, and the transport button not flipping to play on
completion.

### Added
- **XP + level engine (M11)** — a `xp_events` ledger drives an XP→level
  curve; five actions award XP (review-event completion, word-log attach,
  task completion, reading/movie activity log, streak daily). `(#98, #99)`
- **Streaks + freezes (M11)** — consecutive-day review streak with a
  banked-freeze safety net so one missed day doesn't reset progress. `(#100)`
- **Reading/movie activity log (M11)** — manual log of outside reading/
  watching that earns XP and feeds the streak. `(#101)`
- **Progress dashboard + global indicator (M11)** — a dashboard card
  (level + XP bar + streak + freeze badge) on Today, plus a compact
  level/streak chip in the HomeShell AppBar; both hide behind a Settings
  toggle. `(#102)`
- Background AI-image drain now opens the SQLCipher store with a key
  resolved off the main isolate (carries the single-key-owner contract
  into the background pass).

### Changed
- **Weekly email auth: Google OAuth + Gmail API** replaces the SMTP
  app-password flow. Sign in with a Google account once; reports send via
  Gmail. Removes SMTP credentials from Settings. `(#104)`
- AI-image byte-write moved off the main isolate — large image writes no
  longer cause frame drops. `(#95)`

### Fixed
- **Auto-advance showed the next recording at 0:00.** T14.3's duration seed
  read `recordings.durationMs`, a column never persisted in production, so
  the real length came only from just_audio's async `durationStream` — which
  races when the engine swaps sources straight out of a `completed` state.
  The handler now patches the authoritative duration from `setAudioSource`'s
  return value onto the media item immediately. `(#105)`
- **Transport button on completion.** With auto-advance off, finishing a
  recording now flips the button to play (it previously showed a replay
  glyph, and could read pause on just_audio edges that keep `playing=true`
  into the completed phase). Tapping still restarts from the top. `(#105)`
- Recording save routes a lapsed SAF folder grant to re-pick instead of
  throwing. `(#94)`
- SAF adapter rethrows preserve the platform stack trace across the boundary
  for diagnosable errors. `(#96)`
- Last `!` null-assertions removed from `lib/` — promotion-safe patterns
  throughout. `(#103)`

### Concessions — not-working / not-done (beta)
- iOS port: out of scope (Android-first beta).
- Network egress limited by design — AI image + weekly email are the only
  online features, both connectivity-gated.
- Google OAuth client must ship a valid `oauth_client` (Android type +
  SHA-1) in `google-services.json`, or sign-in fails silently.

## [0.1.1] — 2026-07-18

First beta cut (re-cuts the deleted 0.1.0 RC). Adds the Rivendell brand icon
and fixes three release-only issues that blocked the RC — a launch crash, a
missing INTERNET declaration, and a stale-timestamp indexer. Safe to install
on a clean device over the prior RC.

### Added
- Rivendell launcher icon — white tree-in-speech-bubble on teal `#00897B`,
  across all legacy mipmap densities + adaptive (API 26+) foreground/
  background. `(#89)`
- Repository pins LF line endings via `.gitattributes` so generated
  `*.g.dart` stops flipping CRLF↔LF on Windows checkouts. `(#91)`
- Background AI-image drain via workmanager (`T18.2`) — pending concept images
  now generate while the app is closed, not only in the foreground. The
  background isolate opens the SQLCipher store with a read-only-resolved key
  (`T0.3` single-key-owner), runs one drain pass, and closes. The custom
  prompt template (`T19.6`) is still foreground-applied; background uses the
  default pictographic prompt.

### Fixed
- Release-only launch crash — R8 minification stripped the no-arg ctor of
  `androidx.work.impl.WorkDatabase_Impl`, so `androidx.startup` threw
  `NoSuchMethodException` before Flutter loaded. ProGuard keep rules
  restore it. `(#87)`
- Release builds now declare `INTERNET` + `ACCESS_NETWORK_STATE`. Debug
  builds auto-inject INTERNET for the VM service; release did not, so the
  first AI-image GET threw `SocketException(Failed host lookup, errno 7)`
  even though the same URL loaded in the browser. `(#88)`
- SAF indexer timestamp falls back to the device `Clock` instead of a path
  that R8 stripped. `(#86)`
- Coach-note `create` / `update` no longer null-assert the freshly written
  row — explicit `StateError` if the invariant ever breaks. `(#90)`

### Concessions — not-working / not-done (beta)
- **In-app recording save** hits a SAF permission denial on some devices —
  `T19.7` deferred (native Kotlin slice).
- **Manual image attach to a word log** retired in M18. Beta uses
  AI-generated concept images via the queue only; re-add is post-beta.
- **XP / streak motivation layer** (plan M11) — not built; no gamification
  ships in this beta.
- **iOS port** — out of scope; Android-first beta (future goal, NFR-2.3.1).
- **Network egress is limited** by design — AI concept-image generation and
  weekly email reports are the only online features, both queue + connectivity
  gated. Everything else runs offline against the on-device SQLCipher store.
- **~14 internal `!` null-assertions** remain (guarded, non-crashing) —
  CLAUDE.md rule-compliance cleanup deferred.
- **Architecture health med/low tickets** (`T15.9`–`T15.16`) open —
  maintainability, not beta-blocking.

## [0.1.0] — RC

First release candidate. Offline-first GPA review pipeline: Samsung Voice
Recorder recordings → vocab logs → Anki flashcards → AI concept images →
coaching tasks → weekly email reports. Brings `main` up to `dev` (M14 tail →
M19).

### Milestone 14 — real-use feedback batch 4
- Today queue widened to a forgiving 2-week backlog, capped at 4 (so a missed
  day no longer drops recordings out of sight). `(T14.1)`
- Auto-advance seeds duration from the recording row so the next recording no
  longer shows as zero-length. `(T14.3)`
- Word-log attached images re-encoded through BitmapFactory — kills the
  long-running image-render crash. `(T14.4)`
- In-app captures published to MediaStore so they appear in Samsung Voice
  Recorder's global "All recordings" tab. `(T14.5)`
- Weekly-report SMTP controllers constructed in `initState` (settings-screen
  crash fix). `(T14.2)`

### Milestone 15 — architecture health pass
- Whole-app architecture review; coach feature brought onto the M0 pattern.
  `(T15.1, T15.5)`
- Gate fast mode + native-skip Android. `(T15.2)`
- Dead M7 queue shape deleted. `(T15.3)`
- GPA review-event append retried before surfacing a failure. `(T15.4)`
- Coach attach-picker lazy-built; Today tile stopped rebuilding on every
  position tick. `(T15.6, T15.7)`
- Folder-onboarding screen localized. `(T15.8)`

### Milestone 16 — AnkiDroid runtime-grant fix
- AnkiDroid 2.24 runtime-grant gateway + Dart export gate + one-time grant
  dialog + current-copy read. `(T16.1–T16.3)`

### Milestone 18 — AI image-gen queue hardening
- Idempotent enqueue — spamming "Send to Anki" creates one pending row per
  word, not duplicates. `(T18.1)`
- Live AI-image queue snapshot stream: the queue-review screen updates as
  items move Pending → Generated without a manual refresh. `(T18.3)`
- Pending-count link under the export action. `(T18.4)`
- Transient Pollinations failures retried in-handler with readable errors.
  `(T18.5)`
- Word-log "attach image" affordance retired (read-only viewer kept for
  anything already attached). `(T18.6)`

### Milestone 19 — reactive queue + English-prompt images + auto-advance fix
- Reactive drain: tapping Send-to-Anki generates the image **in the same
  foreground session** — no restart needed. `(T19.1, T19.2)`
- Images depict the **English** concept (Pollinations maps it cleanly); the
  Anki card back stays keyed by the Uzbek word. `(T19.3)`
- Auto-advance to the next recording actually plays it. `(T19.4)`
- Queued images link to their generated cards once they land. `(T19.5)`
- User-tunable AI image prompt template in Settings, pre-filled with the
  canonical pictographic default; persists on every change. `(T19.6)`
- Rate gate (1.2s gap between successive GETs) + 3-attempt backoff so a
  multi-word drain renders **every** image instead of only the first; the
  manual Retry button now clears stuck rows.

### Known limitations
- T19.7 (in-app recording save hitting a SAF permission denial) is deferred —
  a native Kotlin slice, not in this RC.
- T18.2 (workmanager background drain) deferred — the foreground reactive
  drain covers normal use.
- AI image generation + weekly email reports are the only network egress,
  both queued + gated on connectivity; everything else runs offline against
  the on-device SQLCipher store.
