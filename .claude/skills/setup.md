---
name: setup
description: Flutter project bootstrap, pinned package versions, code generation, static analysis, test infra, and git hooks. Use when initializing a new app or troubleshooting the build.
---

# Setup: How We Start

The deterministic build foundation. A CLI agent creates these files directly (no IDE GUI required).
Bootstrap is blind-executable with the Flutter SDK on PATH.

## Before you bootstrap — ask the product questions

App identity is a set of one-way doors. **Ask the user once, up front** (one batched question, with
recommended defaults) before running `flutter create`:

- **App name** + **bundle/org identifier** (e.g. `com.acme.appname`) — painful to change after store submission.
- **Platforms** and **min OS versions**.

The remaining stack choices (backend, payments, networked services) are already decided for this
project in `CLAUDE.md` + `plan.md` → "Architecture decisions". Pin the answers there so the rest of the
build is deterministic.

## Prerequisites (verify, don't assume)

```bash
flutter --version      # Flutter stable >= 3.27, Dart >= 3.6
dart --version
flutter doctor
```

## Project location

The Flutter app lives in the **app directory named in `CLAUDE.md`** (`app/` by convention). Create once:

```bash
flutter create --org <org.identifier> --platforms=android <app_dir>
```

All `flutter`/`dart` commands below run from that app directory. Wherever this skill says `<app_dir>`,
substitute the real one.

## Pinned Version Matrix (single source of truth)

The **project's full matrix is `plan.md` → "Reconciled dependency matrix"** — that is authoritative. The
generic core below is the bootstrap baseline; add the project's domain packages (audio, Anki, Fal.ai,
SMTP, charts, notifications) per `plan.md` when each milestone needs them.

Declare everything in `pubspec.yaml`. **If a version is unavailable or incompatible in the resolved
environment, bump to the nearest compatible stable release, keep each codegen package in lockstep with
its runtime package, and record the change in the PR.**

| Package | Version | Role |
| ------- | ------- | ---- |
| `flutter_riverpod` / `riverpod_annotation` | ^3.0.0 | State management + DI |
| `riverpod_generator` | ^3.0.0 | Provider codegen (dev) |
| `go_router` | ^16.0.0 | Declarative navigation |
| `drift` / `drift_flutter` / `sqlite3_flutter_libs` | ^2.23.0 / ^0.2.0 / ^0.5.0 | Local SQLite store (source of truth) |
| `sqlcipher_flutter_libs` | ^0.6.0 | Encrypted SQLite (SQLCipher) |
| `drift_dev` | ^2.23.0 | Drift codegen (dev) |
| `freezed_annotation` / `freezed` | ^3.0.0 / ^3.0.0 | Immutable models + unions (dev: `freezed`) |
| `json_serializable` / `json_annotation` | ^6.9.0 / ^4.9.0 | DTO (de)serialization |
| `connectivity_plus` | ^6.1.0 | Online/offline detection (gates the outbound queue) |
| `flutter_local_notifications` | ^18.0.1 | Local notifications / reminders |
| `intl` | ^0.19.0 | Locale-aware date/number formatting (i18n) |
| `flutter_secure_storage` | ^9.2.0 | Stores the SQLCipher DB key per install |
| `build_runner` | ^2.4.13 | Runs all codegen (dev) |
| `mocktail` | ^1.0.4 | Test doubles (dev) |
| `very_good_analysis` | ^7.0.0 | Lint ruleset (dev) |

> **Lint surface = `very_good_analysis`.** `riverpod_lint` + `custom_lint` are **optional** — add them
> at T0.1 only if they resolve cleanly against the current analyzer; otherwise defer and record why.
> Don't block bootstrap on the Riverpod lint plugin.

> **Codegen pairs move together:** `riverpod_annotation`↔`riverpod_generator`,
> `freezed_annotation`↔`freezed`, `json_annotation`↔`json_serializable`, `drift`↔`drift_dev`.

## Code generation

Riverpod, Freezed, json_serializable, and Drift all generate `*.g.dart` / `*.freezed.dart`. Run after
any change to an annotated class:

```bash
dart run build_runner build --delete-conflicting-outputs
# during heavy iteration:
dart run build_runner watch --delete-conflicting-outputs
```

Generated files are committed (so `flutter test` works without a codegen step in CI).

## Static analysis

`analysis_options.yaml` at the app-directory root:

```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  errors:
    invalid_annotation_target: ignore   # freezed/json on fields
linter:
  rules:
    avoid_print: true                    # use AppLogger, never print()
```

Run: `flutter analyze`. (If `riverpod_lint` was added, also run `dart run custom_lint`.)

## Keys & secrets discipline (non-negotiable)

This project is **offline-first with no backend, no auth, no monetization**. The only network egress is
the two gated services in `plan.md` (Fal.ai image generation, SMTP email). Their keys are injected at
build time — never committed:

```bash
flutter run \
  --dart-define=FAL_KEY=... \
  --dart-define=SMTP_USER=... \
  --dart-define=SMTP_PASS=...
```

- **Client** (`<app_dir>`): no secrets in git. Keys arrive via `--dart-define` (or a gitignored
  `env.json` for local dev). The SQLCipher DB key is generated per install and held in
  `flutter_secure_storage`.
- Any paid third-party call (Fal.ai) runs from the client by design (there is no server to proxy it);
  the key is build-injected, not committed.

## Test infrastructure (set up once in the first milestone)

`flutter_test` (SDK), `mocktail`, and Riverpod's `ProviderContainer` overrides cover the gate — no
device needed. See `testing.md`. Add a trivial passing `smoke_test.dart`, and **delete the generated
`test/widget_test.dart`** (it references the removed counter UI and won't compile), so `flutter test`
is green at the end of bootstrap.

Committed harness, all under `scripts/` and app-agnostic (see `scripts/README.md`):

- **`scripts/gate.sh`** — the **Standard Gate**, the single source of truth for "is this green". It
  auto-detects the app directory (override with `APP_DIR=<dir>`), then runs codegen → format → analyze →
  `flutter test --coverage` → the coverage floor. The `pre-push` hook calls exactly this.
- **`scripts/check_coverage.dart`** — a portable lcov parser enforcing **≥80% on the logic surface**
  (excludes generated code, `l10n/`, `main.dart`, app shells, `presentation/`, and `platform/` SDK
  adapters; tune with `COVERAGE_MIN`). It lives in `scripts/` — not inside the app — so the floor
  survives app rebuilds. Coverage MUST be measured over the full suite: `flutter test --coverage`
  instruments all of `lib/`, so a *scoped* test path reports every untouched file as 0% and fails the gate.
- **`scripts/app-dir.sh`** — resolves the app directory (`$APP_DIR` → repo root → the unique subdir
  holding a `pubspec.yaml`), so nothing is pinned to one folder name.

## Git hooks (committed, repo-local)

Scripts in `scripts/git-hooks/`, activated once with `sh scripts/install-hooks.sh` (sets
`core.hooksPath` and makes the scripts executable). Each resolves the repo root with
`git rev-parse --show-toplevel` so it works from any CWD:

| Hook | Runs |
| ---- | ---- |
| `commit-msg` | Reject non-Conventional-Commit messages (`^(feat\|fix\|refactor\|test\|docs\|chore)(\(.+\))?: .+`) |
| `pre-commit` (fast) | format check + `flutter analyze` in the auto-detected app dir |
| `pre-push` (full) | `sh scripts/gate.sh` (codegen + format + analyze + `flutter test --coverage` + coverage floor) |

## Command reference

```bash
sh scripts/gate.sh                               # THE GATE (run before every push)
flutter pub get                                  # resolve deps
dart run build_runner build --delete-conflicting-outputs  # codegen
flutter analyze                                  # static analysis
dart format .                                    # format (CI uses --set-exit-if-changed)
flutter test                                     # all unit/widget tests (no coverage gate)
flutter test test/features/<f>/<x>_test.dart     # one file — for fast iteration ONLY, not the gate
flutter build apk --debug                        # Android build
```

## Verification Checklist (end of bootstrap)

- [ ] `flutter pub get` resolves with the pinned matrix
- [ ] `dart run build_runner build` succeeds; generated files committed
- [ ] `flutter analyze` is clean
- [ ] `sh scripts/gate.sh` is green (smoke test; coverage step reports "no measurable logic lines")
- [ ] Generated `test/widget_test.dart` deleted; `smoke_test.dart` present
- [ ] No real secrets in the repo; client reads keys via `--dart-define`
- [ ] `sh scripts/install-hooks.sh` run (`core.hooksPath` set; hooks + scripts executable)
- [ ] App name, identifier, platforms, and stack choices recorded in `CLAUDE.md`

## Troubleshooting

| Problem | Fix |
| ------- | --- |
| `*.g.dart` / `*.freezed.dart` missing | Run `build_runner build --delete-conflicting-outputs` |
| build_runner conflict errors | Add `--delete-conflicting-outputs`; ensure codegen pairs are in lockstep |
| riverpod_lint not firing | Confirm it resolved at T0.1; if not, defer it (lint surface is `very_good_analysis`) |
| Drift "table not found" after schema change | Bump `schemaVersion` + add a migration; regenerate |
| SQLCipher key not persisting | Confirm `flutter_secure_storage` is initialized before opening the DB |
