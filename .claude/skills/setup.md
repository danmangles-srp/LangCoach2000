---
name: setup
description: Flutter project bootstrap, pinned package versions, code generation, backend/payments config, static analysis, test infra, and git hooks. Use when initializing a new app or troubleshooting the build.
---

# Setup: How We Start

The deterministic build foundation. A CLI agent creates these files directly (no IDE GUI required).
Bootstrap is blind-executable with the Flutter SDK on PATH.

## Before you bootstrap — ask the product questions

App identity is a set of one-way doors. **Ask the user once, up front** (one batched question, with
recommended defaults) before running `flutter create`:
- **App name** + **bundle/org identifier** (e.g. `com.acme.appname`) — painful to change after store submission.
- **Platforms** (iOS, Android, both) and **min OS versions**.
- **Backend + payments**: keep the defaults or swap? (See `structure.md`.) *(TCKonnect: **offline-only —
  no backend**; RevenueCat only. See `CLAUDE.md` + `plan.md`.)*

Pin the answers in `CLAUDE.md` so the rest of the build is deterministic.

## Prerequisites (verify, don't assume)

```bash
flutter --version      # Flutter stable >= 3.27, Dart >= 3.6
dart --version
flutter doctor         # platform toolchains; iOS build needs macOS + Xcode
```

## Project location

The Flutter app lives in the **app directory named in `CLAUDE.md`** (`app/` by convention). Create once:

```bash
flutter create --org <org.identifier> --platforms=ios,android <app_dir>
```

All `flutter`/`dart` commands below run from that app directory. Wherever this skill says `<app_dir>`,
substitute the real one.

## Pinned Version Matrix (single source of truth)

Declare these in `pubspec.yaml`. **If a version is unavailable or incompatible in the resolved
environment, bump to the nearest compatible stable release, keep each codegen package in lockstep with
its runtime package, and record the change in the PR.** Packages marked *(domain-optional)* are added
only when a feature needs them.

| Package | Version | Role |
| ------- | ------- | ---- |
| `flutter_riverpod` / `riverpod_annotation` | ^2.6.1 | State management + DI |
| `riverpod_generator` / `riverpod_lint` / `custom_lint` | ^2.6.3 / ^2.6.1 / ^0.7.0 | Provider codegen + lints (dev) |
| `go_router` | ^14.6.0 | Declarative navigation / deep links |
| `supabase_flutter` | ^2.8.0 | Auth + Postgres + Storage + Edge Functions client (default backend) |
| `drift` / `drift_flutter` / `sqlite3_flutter_libs` | ^2.23.0 / ^0.2.0 / ^0.5.0 | Local SQLite cache + write queue |
| `drift_dev` | ^2.23.0 | Drift codegen (dev) |
| `freezed_annotation` / `freezed` | ^2.5.7 / ^2.5.7 | Immutable models + unions (dev: `freezed`) |
| `json_serializable` / `json_annotation` | ^6.9.0 / ^4.9.0 | DTO (de)serialization |
| `purchases_flutter` | ^8.2.0 | RevenueCat — premium entitlements (apps that sell a subscription) |
| `google_sign_in` / `sign_in_with_apple` | ^6.2.2 / ^6.1.3 | Native OAuth (Apple required on iOS if any social login) |
| `connectivity_plus` | ^6.1.0 | Online/offline detection for the sync engine |
| `flutter_local_notifications` | ^18.0.1 | Local notifications / reminders |
| `intl` | ^0.19.0 | Locale-aware date/number formatting (i18n) |
| `build_runner` | ^2.4.13 | Runs all codegen (dev) |
| `mocktail` | ^1.0.4 | Test doubles (dev) |
| `very_good_analysis` | ^7.0.0 | Lint ruleset (dev) |
| `fl_chart` | ^0.69.0 | *(domain-optional)* charts / data viz |

> **TCKonnect override (offline-only) — canonical list in `plan.md` → "Reconciled dependency matrix".**
> **Don't add:** `supabase_flutter`, `google_sign_in`, `sign_in_with_apple`, `connectivity_plus`,
> `flutter_local_notifications`. **Do add:** `drift` / `drift_dev` / `drift_flutter` /
> `sqlite3_flutter_libs` + `sqlcipher_flutter_libs`, `flutter_secure_storage`, then per-milestone
> `flutter_map` + `latlong2`, `qr_flutter`, `mobile_scanner`, `share_plus`, `archive`.

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
  plugins:
    - custom_lint            # enables riverpod_lint
  errors:
    invalid_annotation_target: ignore   # freezed/json on fields
linter:
  rules:
    avoid_print: true                    # use AppLogger, never print()
```

Run: `flutter analyze` and `dart run custom_lint` (Riverpod-specific rules).

## Backend config — secrets discipline (non-negotiable)

> **TCKonnect ships no backend.** No Edge Functions, no Supabase, no RLS, no server secrets. The only
> bundled key is the **RevenueCat public SDK key** (via `--dart-define`); nothing but native billing
> receipts leaves the device (NFR-2.6). The rest of this section applies only if a project keeps the
> default backend.

- **Client** (`<app_dir>`): commit only **public-by-design** keys — the backend URL + anon/public key
  and the RevenueCat **public SDK key** — read from `--dart-define` (or a gitignored `env.json`).
- **Server** (Edge Functions / backend): any **secret** (third-party API keys, payment webhook secrets,
  service-role keys) lives ONLY as a server-side secret. It must NEVER appear in the Flutter app or in
  git. Any call to a paid third-party API (e.g. an LLM) is made **server-side**, never from the client.
- Database schema + Row-Level Security policies live in `migrations/` (a user can read/write only their
  own rows).

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=RC_PUBLIC_KEY=...
```

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
sh scripts/gate.sh                               # THE GATE: codegen+format+analyze+test+coverage (run before every push)
flutter pub get                                  # resolve deps
dart run build_runner build --delete-conflicting-outputs  # codegen
flutter analyze                                  # static analysis
dart format .                                    # format (CI uses --set-exit-if-changed)
flutter test                                     # all unit/widget tests (no coverage gate)
flutter test test/features/<f>/<x>_test.dart     # one file — for fast iteration ONLY, not the gate
flutter build apk --debug                        # Android build
flutter build ios --no-codesign                  # iOS build (macOS only)
```

## Verification Checklist (end of bootstrap)

- [ ] `flutter pub get` resolves with the pinned matrix
- [ ] `dart run build_runner build` succeeds; generated files committed
- [ ] `flutter analyze` + `dart run custom_lint` are clean
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
| riverpod_lint not firing | Confirm `custom_lint` plugin in `analysis_options.yaml`; run `dart run custom_lint` |
| Backend "row violates RLS" | The policy is working — query as the authed user, or fix the policy in `migrations/` |
| Apple sign-in rejected on iOS | `sign_in_with_apple` capability + entitlement required when any social login is offered (App Store 4.8) |
| Drift "table not found" after schema change | Bump `schemaVersion` + add a migration; regenerate |
