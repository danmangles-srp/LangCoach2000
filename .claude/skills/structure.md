---
name: structure
description: Architecture, file organization, naming conventions, Riverpod patterns, repository/sync design, error handling, and null safety for any Flutter app built with this toolkit. Use when building features, writing new code, or reviewing implementation patterns.
---

# Structure: How We Build

> This skill is **stack and process**, not product. The *what* (features, domain models, screens)
> always lives in the project's `requirements.md` + `CLAUDE.md`. When this skill and the project docs
> disagree about a pattern, the project docs win — but raise the conflict with the user first.

## Tech Stack (the default — keep unless the project overrides it)

- **Language**: Dart 3, sound null safety (never the `!` null-assertion operator)
- **UI**: Flutter + Material 3
- **State + DI**: Riverpod (`riverpod_generator` — `@riverpod` Notifiers/providers); no service locators
- **Navigation**: go_router (typed routes, deep links, auth redirect)
- **Backend**: Supabase (Postgres + Auth + Storage + Edge Functions) — the default; swap per project.
  *(TCKonnect: **none** — offline-only; the Drift store is the source of truth.)*
- **Local store**: Drift (SQLite) — source of truth for the UI; a sync engine reconciles with the backend
- **Models**: Freezed + json_serializable
- **Payments**: RevenueCat (`purchases_flutter`) for premium entitlements (apps that sell a subscription)
- **Charts / extras**: add domain packages (e.g. `fl_chart`) only when a feature needs them

## Architecture: offline-first, feature-first

The UI **always reads from and writes to the local store (Drift)**. A sync engine pushes queued local
writes to the backend and pulls remote changes — so the app is fully usable offline and reconciles on
reconnect (idempotent writes, last-write-wins by `id` + `updated_at`). Repositories are the only seam
that knows about both the local store and the remote backend.

```
Widget → Controller (@riverpod Notifier) → Repository → { Local DAO (Drift) , Remote (Supabase) }
                                                            ↑ Sync engine drains the write queue
```

> **When offline-first is overkill** (a read-only app, a thin client over a live API), say so and ask
> the user before dropping the local store — it's a product decision, not a silent one. See `workflow.md`.

> **TCKonnect (this project): offline-_only_.** There is **no backend and no sync engine** — the Drift
> store is the single source of truth. Keep the repository → datasource seam (so a remote could be added
> later), but implement **only** the local Drift datasource; ignore the Supabase/sync specifics in the
> diagram above and in "Repositories & sync" below. See `CLAUDE.md` + `plan.md` → decision 1.

## File Organization

Feature-first under `lib/`. Each feature owns its layers. Feature names come from `requirements.md` —
the list below is the *shape*, not a fixed set:

```
lib/
  main.dart
  app/
    app.dart                 root MaterialApp.router
    router.dart              go_router config + auth redirect
    theme.dart               Material 3 theme: color + type + spacing tokens (see ui-ux.md)
  core/
    backend/                 backend client provider (Supabase by default)
    db/                      AppDatabase (Drift), tables, DAOs
    sync/                    SyncEngine, WriteQueue, connectivity
    result/                  Result<T> / Failure types
    time/                    AppClock abstraction, timezone-aware "today"
    notifications/           notification scheduler (seam) + platform/ adapter
    logging/                 AppLogger (tagged: AUTH / SYNC / DB / IAP / …)
  features/
    auth/         { presentation, application, data, domain }
    <feature>/    one folder per product feature from requirements.md
    paywall/      premium entitlement + purchase + restore (if the app sells a subscription)
  shared/
    widgets/                 reusable widgets used across features
    formatting/              date/number/intl helpers
```

Per-feature layers:
- `presentation/` — screens + widgets (stateless, driven by state)
- `application/` — `@riverpod` controllers exposing immutable UI state
- `data/` — repositories + datasources (local DAO + remote)
- `domain/` — Freezed models + enums
- `platform/` — thin shells wrapping a device/SDK API (sign-in, payments, notifications, the backend
  client). Keep them logic-free; put `// coverage:ignore-file` atop each. **All testable logic lives in
  `domain`/`application`/`data`** — these are the coverage-counted surface. `presentation/` and
  `platform/` are verified by widget tests / device, not by the coverage %.

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

### Repositories & sync
- Repositories return `Result<T>` (or throw a typed `Failure` caught at the controller) — never leak a
  raw backend/DB exception to the UI.
- Every mutating op: write the local store first, enqueue a sync task, return immediately (optimistic).
  The `SyncEngine` is idempotent and resolves conflicts by `updated_at` (last-write-wins) keyed on row id.
- Inject an `AppClock` and the timezone so date-dependent logic is deterministic and testable.

### Premium / entitlement gating
- A single `entitlementProvider` exposes the active entitlement (e.g. from RevenueCat). Premium features
  check it and otherwise show the paywall/upsell. Gate **at the controller/repository**, not only in the
  widget.

## Code Quality

- Small, deep functions that own one thing; dartdoc for non-obvious public APIs.
- Comments explain **WHY**, not WHAT.
- Validate external input at boundaries (backend responses, deep-link params, user input).
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
- A choice is **hard to reverse** later (schema, sync/merge strategy, public API surface).
- The pattern here **conflicts** with `requirements.md` or `CLAUDE.md`.

Just decide (and note it in the PR) for reversible, mechanical, or one-obvious-answer choices. See
`workflow.md` → "How to ask well."

## What NOT to Do

- Use `!`, mutate state inside widgets, or call `print()`.
- Hit the backend directly from a widget or controller (go through a repository).
- Put any server secret (API keys, service-role keys) in the Flutter app — see `setup.md`.
- Add packages or features beyond `requirements.md`, or touch unrelated code.
