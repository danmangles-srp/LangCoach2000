---
name: structure
description: Architecture, file organization, naming conventions, Riverpod patterns, repository/outbound-queue design, error handling, and null safety. Use when building features, writing new code, or reviewing implementation patterns.
---

# Structure: How We Build

> This skill is **stack and process**, not product. The *what* (features, domain models, screens)
> always lives in the project's `requirements.md` + `CLAUDE.md` + `plan.md`. When this skill and the
> project docs disagree about a pattern, the project docs win — but raise the conflict with the user first.

## Tech Stack (the project default — see `plan.md` for the full matrix)

- **Language**: Dart 3, sound null safety (never the `!` null-assertion operator)
- **UI**: Flutter + Material 3
- **State + DI**: Riverpod (`riverpod_generator` — `@riverpod` Notifiers/providers); no service locators
- **Navigation**: go_router (typed routes)
- **Backend**: **none.** Offline-first; the Drift store is the single source of truth.
- **Local store**: Drift (SQLite + SQLCipher) — the only source of truth for the UI
- **Models**: Freezed + json_serializable
- **Outbound work**: a one-way **Task Queue** (see below) — no sync engine, no reconciliation
- **Charts / extras**: add domain packages (e.g. `fl_chart`, `just_audio`) only when a feature needs them

## Architecture: offline-first, feature-first

The UI **always reads from and writes to the local Drift store**. There is no backend and no sync
engine. The only thing that leaves the device is **outbound one-way work** to two gated services (Fal.ai
images, SMTP email): it is enqueued in a local task table and drained when connectivity returns. The
queue never feeds data *back* into the local store — there is nothing to reconcile.

```
Widget → Controller (@riverpod Notifier) → Repository → Local DAO (Drift)
                                                      ↘ TaskQueue (Drift) → OutboundService (Fal.ai / SMTP)
                                                              ↑ drained by QueueWorker on reconnect
```

> The repository → datasource seam stays abstract so a backend *could* be added later, but implement
> **only** the local Drift datasource now. Do not build a sync engine, conflict resolution, or
> last-write-wins logic — there is nothing to merge.

## File Organization

Feature-first under `lib/`. Each feature owns its layers. Feature names come from `requirements.md` —
the list below is the *shape*, not a fixed set:

```
lib/
  main.dart
  app/
    app.dart                 root MaterialApp.router
    router.dart              go_router config
    theme.dart               Material 3 theme: color + type + spacing tokens (see ui-ux.md)
  core/
    db/                      AppDatabase (Drift), tables, DAOs, migrations
    queue/                   TaskQueue (Drift table) + QueueWorker (drains on reconnect)
    connectivity/            NetworkService seam (online/offline)
    result/                  Result<T> / Failure types
    time/                    AppClock abstraction, timezone-aware "today"
    notifications/           notification scheduler (seam) + platform/ adapter
    logging/                 AppLogger (tagged — see CLAUDE.md for the tag list)
  features/
    <feature>/    one folder per product feature from requirements.md
      presentation/  screens + widgets (stateless, driven by state)
      application/   @riverpod controllers exposing immutable UI state
      data/          repositories + local datasources (Drift DAOs)
      domain/        Freezed models + enums
      platform/      thin shells wrapping a device/SDK API (audio, Anki intents, Fal.ai, SMTP,
                     notifications). Keep them logic-free; put `// coverage:ignore-file` atop each.
  shared/
    widgets/                 reusable widgets used across features
    formatting/              date/number/intl helpers
```

**Where logic lives:** `domain`/`application`/`data` are the coverage-counted surface — all testable
logic lives there in pure Dart. `presentation/` is verified by widget/golden tests; `platform/` adapters
are verified on-device. Neither is counted by the coverage floor.

## Naming Conventions

| What | Convention | Example |
| ---- | ---------- | ------- |
| Files | snake_case | `item_controller.dart`, `item_repository.dart` |
| Classes / widgets / enums | PascalCase | `ItemListScreen`, `ItemStatus`, `MoodSelector` |
| Functions / variables | camelCase | `toggleSelection`, `selectedRange` |
| Providers (generated) | camelCase | `itemListControllerProvider`, `itemRepositoryProvider` |
| Constants | lowerCamelCase | `defaultPageSize` (avoid `k`-prefix) |

Clarity over brevity: `authenticatedUser`, not `authUsr`.

## Implementation Rules

### State holding (Riverpod)
Controllers are `@riverpod` Notifiers exposing **immutable** state (Freezed). Widgets watch state and
call controller methods; never mutate state in the widget. Use `AsyncValue` for load/error/data.

```dart
@riverpod
class ItemListController extends _$ItemListController {
  @override
  Future<ItemListState> build() async {
    final items = await ref.watch(itemRepositoryProvider).all();
    return ItemListState(items: items);
  }

  Future<void> toggle(ItemId id) async {
    // optimistic local write → enqueue sync; reconcile on result
    await ref.read(itemRepositoryProvider).toggle(id);
    ref.invalidateSelf();
  }
}
```

### Models & type safety
- Freezed `data` classes for state and domain models; `sealed`/union types for finite outcomes. No
  booleans-plus-nulls where an enum says it better.
- **Never use `!`.** Use `?.`, `??`, pattern matching, or `ArgumentError`-guarded unwrap.
- Expose read-only types (`List`, not growable internals leaked).

### Repositories & the Task Queue
- Repositories return `Result<T>` (or throw a typed `Failure` caught at the controller) — never leak a
  raw DB exception to the UI.
- Mutating ops write the local store first and return immediately. If the change triggers outbound work
  (generate an image, send an email), the repository **enqueues a task** in the `TaskQueue` and returns;
  the `QueueWorker` drains it later.
- The queue is **idempotent on a task key** (e.g. an Uzbek word for image generation) so a retried task
  doesn't double-spend or duplicate. There is no inbound merge.
- Inject an `AppClock` and the timezone so date-dependent logic is deterministic and testable.

### Connectivity-gated services
- The two outbound services (`Fal.ai`, `SMTP`) sit behind abstract seams (`AIImageService`,
  `EmailService`). The `QueueWorker` checks `NetworkService` before calling them; if offline, the task
  stays enqueued for the next drain.

## Code Quality

- Small, deep functions that own one thing; dartdoc for non-obvious public APIs.
- Comments explain **WHY**, not WHAT.
- Validate external input at boundaries (user input, parsed vocab, Anki/Fal.ai responses).
- Catch only what you can handle; log via `AppLogger` with the right tag; never `print()`.
- New code should read like the code around it — match the file's existing idiom, not your preference.

```dart
/// Returns the active items for [range], or a [Failure] the UI can render.
Future<Result<List<Item>>> itemsForRange(TimeRange range);
```

## When to stop and ask (don't guess on these)

Default to a quick batched question (with a recommended option) rather than a silent assumption when:
- A **data-model / domain shape** has more than one reasonable design (relationships, enum sets, what's
  the source of truth).
- A choice is **hard to reverse** later (schema, public API surface).
- The pattern here **conflicts** with `requirements.md` or `CLAUDE.md`.

Just decide (and note it in the PR) for reversible, mechanical, or one-obvious-answer choices. See
`workflow.md` → "How to ask well."

## What NOT to Do

- Use `!`, mutate state inside widgets, or call `print()`.
- Build a sync engine, conflict resolution, or last-write-wins reconciliation — there is no backend.
- Put any key or credential in the Flutter app repo — see `setup.md`.
- Add packages or features beyond `requirements.md`, or touch unrelated code.
