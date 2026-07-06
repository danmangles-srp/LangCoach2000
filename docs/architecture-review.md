# Rivendell — Architecture Review (M15 / T15.1)

**Scope:** whole app under `app/lib/`, post-M11 accretion. Read-only audit across nine dimensions. Output is this doc plus a severity-ordered refactor list that becomes **T15.3…T15.n** (appended to `plan.md` after user picks the subset to ship).

**Method.** Five parallel read-only passes (layer purity + seams; Drift migrations + invariants; dead code + duplication; error handling + i18n; NFR-perf), each returning `file:line` findings. Highest-severity claims were then spot-checked against source before being written here. Coverage data from `flutter test --coverage` + `scripts/check_coverage.dart`.

**Severity legend.** `high` = correctness, NFR, or structural debt worth shipping now. `med` = real but tolerable. `low` = polish. `stale` = plan-vs-reality drift (doc fix, not code).

**Headline.** The app is in good shape. Migrations are clean and idempotent; the two core invariants (append-only logs, derive-don't-store) hold; no N+1 queries; the indexer offloads correctly; no orphan codegen; all providers have live consumers. The actionable debt is concentrated in: a dead M7 queue shape left behind by the M7→M10 queue churn, one silent FR-1.2.3 failure path, the `coach` feature being off the M0 pattern, two perf hotspots in list rendering, and one un-localized onboarding screen.

---

## 1. Drift migration hygiene — **clean**

- `app_database.dart:52` `schemaVersion = 9`. `onUpgrade` (`:57-90`) is a cumulative `if (from < N)` ladder covering all 8 bumps; every step is `createTable`/`addColumn`-only — **no destructive mutations** (no drop/reename/alter), and every step is range-guarded, so multi-version jumps are idempotent. v8→v9 (`metrics_events`) has its explicit `if (from < 9)` branch.
- FK pragma: not in `onConfigure` (none defined), but `beforeOpen` (`:93`) runs `PRAGMA foreign_keys = ON;` on every open including first create. Correct.
- SQLCipher: key applied in the `setup` callback (`core/database/platform/database_connection.dart:34`, `PRAGMA key = '$key';`) **before** Drift opens — the key never enters the Drift layer. Correct.
- No migration code scattered outside `app_database.dart`. No version bump without migration code.

**Finding `low`:** `onCreate` could set the FK pragma explicitly for defense-in-depth; `beforeOpen` already covers correctness. No action required.

## 2. Append-only logs + derive-don't-store invariants — **hold**

- **Append-only.** `review_events`: repo only `INSERT`s. Two `.delete()` paths (`review_event_repository.dart:277 deleteEvent`, `:293 unreviewMilestone`) are the documented, deliberate T2.6 user-initiated "undo" corrections — **not** automated counter mutations. No `.update()`/`.replace()` on this table anywhere. `metrics_events`: insert-only (`metrics_repository.dart:21 record`). No other `*_events`/`*_log` tables.
- **Derive-don't-store.** `RecordingReviewStatus` derived at `review_event_repository.dart:100 computeReviewStatus(...)` (no stored flag). GPA today queue derived at `:117 todayQueue`. GPA warmed queue derived at `:176 warmedQueue` via the pure `warmUpQueue` selector. **No gamification code exists** — there is no XP, level, streak, or freeze-bank in the app (see `stale` note in §8).

Both invariants hold. No `high`/`med` findings.

## 3. Layer purity + seam consistency

### `high`

- **`coach`: no `domain/` layer.** DTOs (`CoachNoteWithLinks`) live inside `data/coach_note_repository.dart:13`. The feature is missing a required layer.
- **`coach`: presentation reaches through to data + mutates directly.** `presentation/coach_note_dialog.dart:13` and `presentation/coach_bank_screen.dart:11` import `features/coach/data/coach_note_repository.dart`, and `coach_bank_screen.dart:66,99,160` call `ref.read(coachNoteRepositoryProvider.future)` then `repo.create/update/delete`. There is **no `application/` write orchestrator** — only read providers exist. Compare `tasks` (`TaskCommands`) and `audio` (`RecordingIndexer`), which route writes through an orchestrator. This is the feature most off the M0 pattern.

### `med`

- **Misplaced domain DTOs force `data/` imports across layers.** `audio/data/recording_repository.dart:13 ScannedFile` is also consumed by the *abstract* `application/audio_indexer_service.dart:6,9` — a domain type used by an application seam must live in `domain/`. Same shape for `gpa/data/review_event_repository.dart` (`QueueItem`, `WarmedItem`), which forces `presentation/today_queue_screen.dart:17` to import `data/`. (Resolution of the `QueueItem`/`WarmedItem` case is tangled with the dead-code delete in §4 — defer until then.)

### `low`

- **`package:flutter/foundation.dart` in 7 domain files** just for `@immutable`: `gpa/domain/{gpa_intervals.dart:11, review_status.dart:10, queue_warmup.dart:13}`, `wordlog/domain/vocab_pair.dart:5`, `anki/domain/anki_model_spec.dart:12`, `report/domain/report_schedule.dart:10`, `audio/recording/domain/recording_state.dart:5`, `audio/playback/domain/playback_snapshot.dart:12`. Use `package:meta/meta.dart` (or rely on `@freezed` which implies immutability) to keep `domain/` Flutter-SDK-free.
- **`TaskCommands` naming drift** (`tasks/application/task_commands.dart:16`): a stateless orchestrator/service named `*Commands` while M0 peers are `*Service`/`*Indexer`/`*Dispatcher`. Cosmetic.
- **`EmailService` abstract lives in `report/domain/`** — abstract service seams belong in `application/`. The SMTP concrete is correctly in `data/`.
- **`wordlog/presentation/word_log_section.dart:260,303`** does `Image.file(...)` decode directly in presentation instead of through an application service.

### Clean (seam side)

`anki` (abstract `AnkiGateway` + `AnkiExportService`, fakes + concrete in `application/`, presentation reads providers only), `ai_image` (abstract `AiImageService`, fake + Fal impl behind seam, wiring in `platform/ai_image_providers.dart`), `metrics`, `settings`, `audio` repos are concrete-but-consistent with M0.

## 4. Dead code + duplication

### `high` — dead M7 queue shape

The M7→M10 queue churn left the **old** queue shape in place alongside the live `warmedQueue`. The old shape is **dead in prod** (zero call sites in `lib/` outside its own file; exercised only by tests):

- `review_event_repository.dart:117 todayQueue`
- `review_event_repository.dart:18 QueueItem` (the gpa one)
- `review_status.dart:113 classifyQueueEntry`
- `review_status.dart:98 QueueEntryKind`

The **live** shape is `warmedQueue` / `WarmedItem` / `WarmedQueue` (`today_queue_screen.dart:26`, `warmedQueueProvider` at `review_providers.dart:68`). Deleting the four dead symbols is a clean, low-risk cleanup.

### `med`

- **`isStale` constructed, never read.** `queue_warmup.dart:44 WarmSelection.isStale` and `review_event_repository.dart:42 WarmedItem.isStale` are computed but `presentation/today_queue_screen.dart` consumes only `recording` + `status`. A comment at `queue_warmup.dart:41-43` already flags this for T15.x removal.
- **`QueueItem` name clash.** `core/queue/queue_repository.dart:9 QueueItem` (LIVE, the offline outbound queue) vs `features/gpa/.../review_event_repository.dart:18 QueueItem` (DEAD, §4 high). Two unrelated classes share a name; resolves for free once the dead one is deleted.
- **Duplicated timestamp-range selector.** `review_event_repository.dart:71 eventTimestamps` ≈ `word_log_repository.dart:64 textLogTimestamps` (~85% identical: `selectOnly` over a timestamp column, kind filter, half-open `[from, until)`, ascending, map rows → `List<DateTime>`). Extract one helper parameterized on table + column + kind.

### `low`

- Trivial `_two()` / `padLeft(2, '0')` inlined at `recording_filename.dart:14`, `recording_formatting.dart:16`, `record_sheet.dart:217`, `weekly_report_settings_section.dart:148`, `database_key.dart:24`. Not worth extracting.
- Duration formatting intentionally split: `recording_formatting.dart:10 formatDurationMs` (`h:mm:ss`) vs `weekly_report_renderer.dart:157 _formatDuration` (`1h 2m`). Different output shapes; leave as-is.

### Verified clean

No `.g.dart`/`.freezed.dart` orphans in `features/` (only `core/database/app_database.g.dart`, whose source exists). No `legacy`/`old`/`v1`/`deprecated`-named symbols. No commented-out blocks >3 lines. **All providers defined in `lib/` have ≥1 live `ref.read|watch|listen` consumer** (placeholders included — verified `reportLastSent`/`NextFire`, `imageLogClock`, `recorderClock`, `queueProcessor`).

## 5. Error-handling consistency

### `high`

- **Silent loss of an FR-1.2.3 review event.** `review_providers.dart:56-59`: the always-on 80%-crossing watcher catches `repo.recordReview(...)` failures with `on Object catch (e, st)` and only logs. The intent ("a failed append must never break playback") is correct, but the consequence is that the user sees the "reviewed" UI (the latch has fired) while the DB row is silently lost — there is **no user signal, no retry, and `reviewGenerationProvider` is only bumped on the success path** (`:55`), so the derived status never self-corrects. Fix: surface a non-blocking "couldn't save review" snackbar, and on failure reset the latch so the next upward crossing retries.

### `med`

- **Stack traces dropped across the SAF platform adapters.** `PlatformException` is caught and rethrown as a new `FileSystemException(message)` in five sites, discarding the original stack: `wordlog/platform/saf_image_writer_service.dart:28-31`; `audio/recording/platform/saf_recording_writer_service.dart:36-38` and `:51-55` (the latter is the **T14.5 `publishToMediaStore`** path just shipped); `audio/recording/platform/saf_recording_file_service.dart:30-32` and `:43-45`. Use `Error.throwWithStackTrace` (or pass `st` through) so a device-side failure is diagnosable.

### `low`

- `audio/presentation/folder_onboarding_screen.dart:103-105`: explicit empty `on Object { }` swallow on a non-fatal rescan (comment says next refresh recovers). Acceptable, but add a `w(...)` log for diagnosability.

### Verified clean

No `rethrow`-only catches, no generic `Exception(...)` wraps losing context. Non-fatal best-effort swallows are correctly used where appropriate: `queue_worker` fire-and-forget drain; `anki_export_button` surfaces `phase=error` in UI; `word_log_section:470` shows a snackbar; `saf_folder`/`audio_indexer` degrade to `null`/`[]`; `recording_management_service` best-effort file deletes + rename rollback; `recorder_controller` write-failure → `_fail('write')`; `report_providers` weekly scheduler (queued + connectivity-gated, retries next tick); `image_log_service` rethrows → caller snackbar.

## 6. i18n completeness

**Note: the project does NOT use ARB / `flutter_localizations`.** Localization is a hand-rolled `core`-style `AppStrings` (`lib/l10n/app_strings.dart`) with inline `_en` and `_uz` `_Bundle`s whose `required` constructor fields **force en/uz parity at compile time** — key drift is impossible by construction. This is a sound design; the audit is therefore "hardcoded-string sweep," not "arb key comparison."

### `high`

- **`audio/presentation/folder_onboarding_screen.dart` is entirely un-localized** — zero `AppStrings.of` calls. Six hardcoded user-facing strings: `:38` title `'Point Rivendell at your recordings'`; `:45` body `'Choose your Samsung Voice Recorder folder…'`; `:57` button `'Choose folder'`; `:76` snackbar `'No folder selected.'`; `:89` snackbar `"That isn't the usual Voice Recorder folder — indexing it anyway."`; `:117` snackbar `"Couldn't save that folder. Try again."`.

### `med`

- `report/presentation/weekly_report_settings_section.dart:84`: hardcoded snackbar `'Save failed'` — directly asymmetric with `:79`, which correctly uses `strings.settingsReportCredentialsSaved`.

### `low`

- `audio/presentation/recording_detail_screen.dart:598`: milestone label `'D+${milestone.intervalDays}'` rendered raw in a `ListTile` title. Arguably a numeric format (`D+7`) but user-visible; add `strings.reviewMilestoneLabel(n)` for parity.

All other `Text(...)` sites in `presentation/` route through `AppStrings.of(context)` / `strings.<key>`.

## 7. NFR-perf risks

### (A) N+1 queries — **none.**

All repos batch. `review_event_repository.warmedQueue` (`:176-228`) = 2 queries total (recordings + all events), grouped in Dart. `coach_note_repository.all` (`:81-103`) = 3 queries (notes + both join tables). `metrics_aggregation_service.snapshot` (`:76-97`) = 4 parallel range queries via `Future`-then-await, not a loop.

### (B) Main-isolate file/decode work

- **`med`** `ai_image/application/fal_ai_image_service.dart:135`: `file.writeAsBytes(bytes, flush: true)` for a downloaded AI image (often MB-scale) on the main isolate, no `compute()` offload.
- **`low`** `audio/application/recording_management_service.dart:91-92`: `imageDir.existsSync()` + `imageDir.deleteSync(recursive: true)` (synchronous directory walk) on the main isolate during recording delete. Bounded by per-recording image count (small), but synchronous.
- **`low`** `wordlog/presentation/word_log_section.dart:330`: `file.existsSync()` — only in the image-decode error path (diagnostic). Negligible.

The indexer is correct: `saf_audio_indexer_service.dart:49` offloads via `compute(parseScannedEntries, raw)`. Word-log image copy routes through the `rivendell/wordlog` MethodChannel to a Kotlin background thread. No `BitmapFactory.decode*` on the main isolate in Dart code.

### (C) Unbounded list builders

- **`high`** `coach/presentation/coach_note_dialog.dart:236-258`: `ListView(shrinkWrap: true, children: [for (final o in options) CheckboxListTile(...)])` where `options` is the full recordings list (up to 1000 per NFR-2.2.1). Materializes every row and `shrinkWrap` forces a measure pass over all of them when the dialog opens. Convert to `ListView.builder`.
- **`low`** `gpa/presentation/today_queue_screen.dart:72-93`: non-lazy `ListView(children: [...])`. Today is capped at 4 by `warmUpQueue`; Tomorrow strict-overflow is naturally small. Bound is tight.
- **`low`** `wordlog/presentation/word_log_section.dart:217-230`: `Wrap(children: [for (final img in images) _Thumb(...)])` — bounded by per-recording image-log count (small).
- `stats_screen.dart:79`, `settings_screen.dart:25`, `task_detail_screen.dart:95`: bounded fixed sets. Fine.

### (D) Stream/rebuild inefficiency

- **`high`** `gpa/presentation/today_queue_screen.dart:138`: `_WarmedTile.build` does `ref.watch(audioPlayerControllerProvider)` — the **full** playback snapshot, no `.select`. `RivendellAudioHandler` (`rivendell_audio_handler.dart:48`) pipes `_player.positionStream.listen((_) => _broadcast())` into `playbackState`, re-emitting at just_audio's position-tick rate (~5-8 Hz). The tile only consumes `recordingId` + `isPlaying`, so **every visible queue tile rebuilds 5-8 times/sec during playback**. The library list already filters via `.select((s) => (recordingId: s.recordingId, isPlaying: s.isPlaying))` (`recordings_screen.dart:148-152`) — this tile should mirror that pattern.
- **`low`** `recorder_controller.dart:104`: `Timer.periodic(Duration(seconds: 1))` — armed only while the record sheet is open; 1 Hz cadence. Acceptable.

## 8. Stale plan references (doc fix, not code)

The `plan.md` T15.1 spec names four things that do not match the code:

- **`WarmPlacement`** ("`WarmPlacement`-style leftovers") — does not exist anywhere in the tree. The leftover is the **`todayQueue`** shape (§4 high), not `WarmPlacement`.
- **"two parallel queue shapes … `todayQueue` vs `warmedQueue`"** — only `warmedQueue` is live; `todayQueue` is dead, not parallel-live.
- **Gamification** ("XP level, streak count", "freeze bank is the one allowed exception") — **no gamification code exists**. No XP/level/streak/freeze. The two invariants in §2 reduce to: append-only logs (hold) and derive-don't-store for review status + queue (hold). The "freeze bank" exception is moot.
- **"the three parallel queue shapes in `review_event_repository`"** / "three event repos" — there is no `xp` repo. Repos are review, metrics, coach-note, word-log, each a distinct shape; no >80% CRUD duplication, no base-class win. The one real duplication is the timestamp-range selector (§4 med).

Prune these from `plan.md` when the refactor milestone is appended.

## 9. Test-coverage holes (overall 90.8%, floor 80% — green)

`flutter test --coverage` → `check_coverage.dart` reports **90.8% (1536/1691 logic lines, 75 files)** against the 80% logic-surface floor. The floor excludes `presentation/`, `platform/`, generated, `l10n`, and the app shell by design. Holes worth noting:

- `core/database/app_database.dart` **32% (9/28)** — the migration ladder is verified idempotent by inspection (§1) but has **no migration-step tests**. A v1→v9 upgrade test (open at v1, bump, assert shape) would lock the invariant that gave this app its trustworthy-upgrade property.
- `audio/application/recording_indexer.dart` **62% (8/13)** — the index path is the NFR-2.2.1 perf-critical surface (≤1000 files <2.0s). The `compute(parseScannedEntries, ...)` offload is verified, but the parse/merge logic deserves more direct tests.
- **Provider-glue files are thin-tested**: `anki/application/anki_export_providers.dart` 20%, `wordlog/application/word_log_providers.dart` 26%, `audio/application/recording_providers.dart` 39%, `gpa/application/review_providers.dart` 63%, `coach/application/coach_providers.dart` 67%, `anki/application/anki_providers.dart` 50%. Per-line value is low (DI wiring), **but** the `review_providers` hole is exactly where the §5 `high` swallow lives — a test there would have caught it.
- `core/queue/queue_worker.dart` **82% (27/33)** — the NFR-2.1.3 connectivity-gated drain. Reasonably covered; the gap is the reconnect-retry branch.
- **Drift table declarations at 0%** (`key_values`, `offline_queue`, all `*_table.dart`, `metric_kind.dart` 5-line enum) — pure annotation/enum classes that delegate to generated code. Low value; acceptable to leave.

---

## Refactor list → T15.3…T15.n

Severity-ordered, **PR-sized** (one ticket = one PR), dependency-noted. The user selects the subset to ship before any work begins.

| Ticket | Severity | Title | Scope | Deps |
|--------|----------|-------|-------|------|
| **T15.3** | high | Delete dead M7 queue shape | Remove `todayQueue`, gpa `QueueItem`, `classifyQueueEntry`, `QueueEntryKind`; update tests. | none |
| **T15.4** | high | Stop silent FR-1.2.3 review-event loss | `review_providers.dart:56-59`: non-blocking snackbar on append failure + latch reset for retry + bump `reviewGenerationProvider`. | none |
| **T15.5** | high | Bring `coach` onto the M0 pattern | Add `coach/domain/` (move DTOs out of `data/`); add `coach/application/` write orchestrator (`CoachNoteCommands`); remove `presentation→data` imports + direct repo mutations. | none |
| **T15.6** | high | `coach_note_dialog` unbounded list | `coach_note_dialog.dart:236` `ListView(shrinkWrap, children:...)` → `ListView.builder`. | none |
| **T15.7** | high | `_WarmedTile` rebuild storm | `today_queue_screen.dart:138` `ref.watch(audioPlayerControllerProvider)` → `.select((s) => (recordingId: s.recordingId, isPlaying: s.isPlaying))`. | none |
| **T15.8** | high | Localize folder onboarding | Route the 6 hardcoded strings in `folder_onboarding_screen.dart` through `AppStrings` (en + uz). | none |
| **T15.9** | med | Preserve stack traces across SAF adapters | 5 sites: `saf_image_writer_service`, `saf_recording_writer_service` (×2, incl. T14.5 publish), `saf_recording_file_service` (×2) → `Error.throwWithStackTrace`. | none |
| **T15.10** | med | Move domain DTOs out of `data/` | `ScannedFile` → `audio/domain/` (used by abstract `AudioIndexerService`); revisit `QueueItem`/`WarmedItem` placement after T15.3. | T15.3 |
| **T15.11** | med | Offload AI image write | `fal_ai_image_service.dart:135` `writeAsBytes` → `compute()`. | none |
| **T15.12** | med | Extract shared timestamp-range selector | Merge `eventTimestamps` (review) + `textLogTimestamps` (wordlog) into one parameterized helper. | none |
| **T15.13** | med | i18n + presentation-decode polish | `weekly_report_settings_section 'Save failed'` + `recording_detail 'D+7'` → `AppStrings`; move `word_log_section` `Image.file` decode behind a service. | none |
| **T15.14** | low | `domain/` Flutter-SDK-free | 7 files: `@immutable` via `package:flutter/foundation.dart` → `package:meta` (or drop, `@freezed` implies it). | none |
| **T15.15** | low | Reconcile `plan.md` with reality | Prune stale refs: `WarmPlacement`, gamification (XP/streak/freeze), "three event repos", `todayQueue` "parallel". | T15.3 |
| **T15.16** | low (deferred) | Close coverage holes | Migration-step upgrade test (`app_database`); `recording_indexer` parse-path tests; `review_providers` append-failure test (locks T15.4). | T15.4 |

**Suggested batching if the user wants fewer PRs:** T15.3 + T15.10 + T15.12 form a coherent "queue-shape + DTO + helper" cleanup; T15.6 + T15.7 form a "list-perf" pair; T15.8 + T15.13 form an "i18n" pair. Keep T15.4, T15.5, T15.9, T15.11 standalone (independent blast radius).
