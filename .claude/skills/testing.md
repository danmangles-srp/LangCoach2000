---
name: testing
description: Testing standards, TDD workflow, test tiers, golden/visual review, and validation patterns. Use when writing tests, debugging failures, or setting up test infrastructure.
---

# Testing: How We Break/Fix

## Frameworks

- **Runner**: `flutter_test` (`test`, `group`, `setUp`, `expect`).
- **Mocking**: `mocktail` (`when`, `thenAnswer`, `verify`, `registerFallbackValue`) — no codegen.
- **Riverpod**: `ProviderContainer` with `overrides` to inject fakes; `container.read/listen`. Use
  `addTearDown(container.dispose)`.
- **Widgets**: `testWidgets` + `WidgetTester` (`pumpWidget`, `pump`, `tester.tap`, finders).
- **Golden / visual**: `matchesGoldenFile` for pixel-stable widget snapshots (see the visual loop below).
- **Integration**: `integration_test` for real device flows (audio playback, Anki intents, notifications)
  — device/CI only, not in the per-commit gate.
- **Location**: `test/` mirrors `lib/` (`test/features/<f>/<x>_test.dart`). Integration tests live in
  `integration_test/`.

## TDD: Red-Green-Refactor

Hard requirement. Smallest testable chunk at a time, each mapped to a requirements AC.

1. **Red**: Write a failing test first; show the failing output before writing solution code.
2. **Green**: Implement the minimum to pass.
3. **Refactor**: Clean up while keeping tests green.

## Self-Validation Loop (no device required)

The app ships to phones, but the agent validates its own work **on the host Dart VM** — no emulator, no
live network, no real purchases. This works because logic lives in pure Dart (controllers, repositories,
domain math) behind injectable seams (`AppClock`, repositories, datasources, `NetworkService`).

- **Tier 1 — Unit (every TDD cycle):** pure Dart with fakes/mocks via `ProviderContainer` overrides.
  Covers all domain math/rules (GPA intervals, 80% rule, stale-day logic, vocab parsing, metrics
  aggregation), the Task Queue enqueue + idempotent-drain, and validation at boundaries.
- **Tier 2 — Widget (in `flutter test`):** screens render every state of their `AsyncValue` (loading /
  error / empty / data); a tap calls the right controller method; selection highlights. Use `pumpWidget`
  wrapped in a `ProviderScope` with overrides.
- **Tier 3 — Integration (`integration_test`, device/CI):** drive real device flows — actual audio
  playback/record, AnkiDroid intent round-trip, local-notification delivery, the Fal.ai + SMTP paths
  against a test key. Closest thing to "it works" the harness can run; needs a device/emulator, so it is
  **not** part of the per-commit gate.

`dart run build_runner build && dart format --set-exact-if-changed . && flutter analyze && flutter test`
is the complete, trustworthy self-validation loop for logic and wiring.

**What the loop canNOT prove (device + human only — NOT in the gate):** real audio capture/playback
latency; the AnkiDroid intent round-trip on a real device; real local-notification delivery (exact-alarm
behavior); any live Fal.ai / SMTP call; and the performance NFRs (index ≤1000 files in <2s, playback
latency ≤250ms, 60fps scroll). These are the **manual acceptance** tier. Green Tier 1–2 means the logic
is correct and wired — say so honestly in the PR; it is **not** "shippable" proof. Pair it with the
visual loop below for UI quality.

## Visual / golden review loop (UI quality is testable too)

Logic tests prove behavior; they say nothing about whether a screen *looks* right. Close that gap:

- **Golden tests** pin a widget's rendered pixels. Add one per key screen state (empty / data / error)
  so unintended visual regressions fail the suite. Regenerate intentionally with
  `flutter test --update-goldens`, and **review the diff image before committing** — a golden you didn't
  look at proves nothing.
- **Run-and-screenshot critique** (the AI design feedback loop): launch the app, capture each affected
  screen, and grade the screenshot against the rubric in `ui-ux.md`. This is what `/design-review`
  automates — run it before every UI PR. See `ui-ux.md` → "AI design self-review loop."

## What to test (generic map — fill in from requirements.md)

| Component | Test focus |
| --------- | ---------- |
| Domain logic / calculations | Correct output for fixtures, including boundaries and empty input (GPA intervals, 80%-played, stale-day, metrics rollup) |
| Repositories | Map DB rows ↔ domain models; surface failures as `Result`/`Failure`, never raw exceptions |
| Task Queue | Offline task enqueued; reconnect drains it once (idempotent on task key); failed task retried with backoff |
| Connectivity gating | `NetworkService` offline → outbound service not called, task stays queued; online → drained |
| Controllers | Each method transitions state correctly; optimistic write + reconcile on success/failure |
| Validation / debounce | Boundary inputs rejected; autosave debounce via fake `AppClock`; failed save re-queues, no data loss |
| Widget states | Every `AsyncValue` branch (loading/error/empty/data) renders; interactive widgets have Semantics labels |

Keep every collaborator injectable (`AppClock`, repositories, datasources, `NetworkService`) so widgets
need no device.

## Example (Riverpod ProviderContainer + mocktail)

```dart
class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  test('toggling an item flips its state optimistically', () async {
    final repo = MockItemRepository();
    when(() => repo.all()).thenAnswer((_) async => [item(id: '1', done: false)]);
    when(() => repo.toggle(any())).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [itemRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(itemListControllerProvider.future);
    await container.read(itemListControllerProvider.notifier).toggle(ItemId('1'));

    verify(() => repo.toggle(ItemId('1'))).called(1);
  });
}
```

## Validation Commands

The **Standard Gate** is the single source of truth for "is this green" — `scripts/gate.sh`. It is
identical to the `pre-push` hook. Run it before every push — no exceptions:

```bash
sh scripts/gate.sh
```

which auto-detects the app directory (override with `APP_DIR=<dir>`) and runs:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage                          # FULL suite — coverage instruments all of lib/
# coverage floor (≥80% logic surface; script is at repo root, lcov is app-relative):
dart "$(git rev-parse --show-toplevel)/scripts/check_coverage.dart" coverage/lcov.info
```

**Never gate on a scoped test path.** `flutter test --coverage <one_file>` reports every file the run
didn't touch as 0% and fails the floor. Run a single file (`flutter test test/features/<f>/<x>_test.dart`)
only for fast red-green iteration; then run the full `sh scripts/gate.sh` before pushing. If any step
fails, fix the root cause before committing — a flaky/partial gate is a defect, not a retry.

> **Coverage is a floor, not a goal.** 80% line coverage of correct, behavior-focused tests is the bar;
> don't write assertion-free tests to hit a number. If you can't easily test something, that's usually a
> design smell (a missing seam) — fix the seam, or ask the user whether the surface is worth testing.
