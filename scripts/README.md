# scripts/ — build toolkit

App-agnostic tooling for any Flutter app built with this repo's skills. Nothing here is pinned to a
particular app folder name — the app directory is auto-detected.

## The Standard Gate

`gate.sh` is the single source of truth for "is this green". It runs, from the app directory:

1. **codegen** — `build_runner build` (only if the app uses it; tolerant of flag changes)
2. **format** — `dart format --set-exit-if-changed`
3. **analyze** — `flutter analyze`
4. **test + coverage** — `flutter test --coverage` (full suite — never a scoped path)
5. **coverage floor** — `check_coverage.dart` enforces the logic-surface minimum

```sh
sh scripts/gate.sh            # run before every push — must exit 0
```

It is identical to the `pre-push` hook, so a clean push proves a clean gate.

## App-directory resolution

`app-dir.sh` prints the absolute path of the Flutter app. Resolution order:

1. `APP_DIR` env var (relative to repo root, or absolute)
2. the repo root, if it has a `pubspec.yaml`
3. the single immediate subdirectory with a `pubspec.yaml`

Zero config when there's one app; override anytime when there are several:

```sh
APP_DIR=myapp sh scripts/gate.sh
```

## Coverage floor

`check_coverage.dart` parses `coverage/lcov.info` and fails if line coverage over the **logic surface**
is below the floor (default **80%**). It excludes non-logic files by default — generated code (`*.g.dart`,
`*.freezed.dart`), `l10n/`, entrypoints (`main.dart`), the `app/` shell, `presentation/`, and
`platform/` adapters (verified by widget/golden tests and on-device, not by this number).

```sh
# Run from the app directory (where coverage/lcov.info is written); the script
# lives at the repo root, so resolve it absolutely:
dart "$(git rev-parse --show-toplevel)/scripts/check_coverage.dart" coverage/lcov.info
dart "$(git rev-parse --show-toplevel)/scripts/check_coverage.dart" coverage/lcov.info --min=85
COVERAGE_MIN=70 sh scripts/gate.sh    # or tune the floor via the gate (run from anywhere)
```

## Git hooks

Committed, repo-local hooks in `git-hooks/`. Install once after cloning:

```sh
sh scripts/install-hooks.sh   # sets core.hooksPath + chmod +x
```

| Hook | Runs |
| ---- | ---- |
| `commit-msg` | Rejects non-Conventional-Commit messages (`feat\|fix\|refactor\|test\|docs\|chore`) |
| `pre-commit` | Fast: format check + `flutter analyze` |
| `pre-push` | Full: `gate.sh` |

## Notes

- POSIX `sh`; runs on macOS/Linux and Git Bash on Windows.
- Every script resolves the repo root with `git rev-parse --show-toplevel`, so it works from any CWD.
