---
name: testing
description: Testing standards, TDD workflow, test tiers, golden/visual review, and validation patterns for any Flutter app built with this toolkit. Use when writing tests, debugging failures, or setting up test infrastructure.
---

# Testing: How We Break/Fix

## Frameworks

- **Runner**: `flutter_test` (`test`, `group`, `setUp`, `expect`).
- **Mocking**: `mocktail` (`when`, `thenAnswer`, `verify`, `registerFallbackValue`) — no codegen.
- **Riverpod**: `ProviderContainer` with `overrides` to inject fakes; `container.read/listen`. Use
  `addTearDown(container.dispose)`.
- **Widgets**: `testWidgets` + `WidgetTester` (`pumpWidget`, `pump`, `tester.tap`, finders).
- **Golden / visual**: `matchesGoldenFile` for pixel-stable widget snapshots (see the visual loop below).
- **Integration**: `integration_test` for the real local↔backend sync path (device/CI only).
- **Location**: `test/` mirrors `lib/` (`test/features/<f>/<x>_test.dart`). Integration tests live in
  `integration_test/`.

## TDD: Red-Green-Refactor

Hard requirement. Smallest testable chunk at a time, each mapped to a requirements AC.

1. **Red**: Write a failing test first; show the failing output before writing solution code.
2. **Green**: Implement the minimum to pass.
3. **Refactor**: Clean up while keeping tests green.

## Self-Validation Loop (no device required)

The app ships to phones, but the agent validates its own work **on the host Dart VM** — no emulator, no
live backend, no real purchases. This works because logic lives in pure Dart (controllers, repositories,
domain math) behind injectable seams (`AppClock`, repositories, datasources).

- **Tier 1 — Unit (every TDD cycle):** pure Dart with fakes/mocks via `ProviderContainer` overrides.
  Covers all domain math/rules, the sync write-queue + last-write-wins reconciliation, entitlement
  gating, debounce/throttle logic (fake `AppClock`), and validation at boundaries.
- **Tier 2 — Widget (in `flutter test`):** screens render every state of their `AsyncValue` (loading /
  error / empty / data); a tap calls the right controller method; selection highlights; the paywall
  shows for free users. Use `pumpWidget` wrapped in a `ProviderScope` with overrides.
- **Tier 3 — Integration (`integration_test`, device/CI):** drive a real local DB through a fake/staging
  backend to prove offline write → queue → sync → reconcile. Closest thing to "it works" the harness can
  run; needs a device/emulator, so it is **not** part of the per-commit gate.

`dart run build_runner build && dart format --set-exit-if-changed . && flutter analyze && flutter test`
is the complete, trustworthy self-validation loop for logic and wiring.

**What the loop canNOT prove (device + human only — NOT in the gate):** real OAuth / magic-link
redirects; real purchase + cross-device entitlement; real push/local-notification delivery; any live
third-party/LLM call; and the performance NFRs (cold start, large-list scroll at 60 fps). These are the
**manual acceptance** tier. Green Tier 1–2 means the logic is correct and wired — say so honestly in the
PR; it is **not** "shippable" proof. Pair it with the visual loop below for UI quality.

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
| Domain logic / calculations | Correct output for fixtures, including boundaries and empty input; signs/units preserved |
| Repositories | Map backend/DB rows ↔ domain models; surface failures as `Result`/`Failure`, never raw exceptions |
| Sync engine | Offline write enqueued; reconnect drains the queue once (idempotent); LWW by `updated_at` |
| Controllers | Each method transitions state correctly; optimistic write + reconcile on success/failure |
| Validation / debounce | Boundary inputs rejected; autosave debounce via fake `AppClock`; failed save re-queues, no data loss |
| Entitlement gating | Free user blocked from premium → paywall; subscriber unlocked (gate at controller/repo) |
| Auth redirect | Unauthed → sign-in; unverified → verify prompt for gated actions |
| Widget states | Every `AsyncValue` branch (loading/error/empty/data) renders; interactive widgets have Semantics labels |

> **TCKonnect is offline-only:** the **Sync engine** and **Auth redirect** rows above don't apply, and
> Tier-3 "backend integration" reduces to **local-DB** integration. Everything else holds.

Keep every collaborator injectable (`AppClock`, repositories, datasources) so widgets need no backend.

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

The **Standard Gate** is the single source of truth for "is this green" — `scripts/gate.sh` (committed
in the first milestone). It is identical to the `pre-push` hook and to every milestone's Validation
Script. Run it before every push — no exceptions:

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
