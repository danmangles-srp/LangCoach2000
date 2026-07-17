#!/usr/bin/env sh
# Standard Gate — the single source of truth for "is this green".
# codegen -> format -> analyze -> test+coverage -> logic-coverage floor
# -> Android debug build.
# Identical to the pre-push hook. Run before every push, from anywhere in the repo.
#
# The Flutter app directory is auto-detected (override with APP_DIR=<dir>); the
# coverage floor lives in scripts/check_coverage.dart so it survives app rebuilds.
# Tune the floor with COVERAGE_MIN=<n> (default 80).
#
# Skip the (slow) Android build with SKIP_ANDROID=1 for a fast Dart-only cycle.
# `gate.sh fast` (or `--fast`, or GATE_FAST=1) = SKIP_ANDROID=1 AND skip codegen
#   when no codegen-source (.dart with a `part '*.g.dart'` / `*.freezed.dart`)
#   changed vs the upstream merge-base — the inner-loop cycle.
# The Android build is also skipped automatically when the diff vs the upstream
#   merge-base touches no native file (app/android/**, *.kt, *.gradle*, or
#   AndroidManifest.xml); force it with GATE_FORCE_ANDROID=1.
set -e

root="$(git rev-parse --show-toplevel)"
app_dir="$(sh "$root/scripts/app-dir.sh")"

# Fast mode: `gate.sh fast` | `gate.sh --fast` | GATE_FAST=1.
FAST=
if [ "$1" = "fast" ] || [ "$1" = "--fast" ] || [ -n "${GATE_FAST:-}" ]; then
  FAST=1
  SKIP_ANDROID=1
fi

# Merge-base of HEAD and its upstream (fallback origin/dev). Empty when it can't
# be resolved — the change-detectors then fall back to the safe "run everything"
# path. Computed before the `cd` so git paths stay repo-root-relative.
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
mb_base="$(git merge-base HEAD "${upstream:-origin/dev}" 2>/dev/null || true)"

# Has any native file changed vs the merge-base? Safe default: yes (build).
native_changed() {
  if [ -z "$mb_base" ]; then return 0; fi
  git diff --name-only "$mb_base" HEAD 2>/dev/null \
    | grep -Eq '(^|/)app/android/|\.kt$|\.gradle(\.kts)?$|AndroidManifest\.xml$'
}

# Has any codegen-source changed vs the merge-base? A codegen-source is a
# non-generated .dart that declares a `part '...g.dart'` / `...freezed.dart`
# directive. Safe default: yes (run build_runner). build_runner is incremental —
# `.dart_tool/build` is reused across runs, so a no-op codegen is a fast cache hit;
# this check just skips even that when nothing relevant moved.
codegen_source_changed() {
  if [ -z "$mb_base" ]; then return 0; fi
  changed="$(git diff --name-only "$mb_base" HEAD -- '*.dart' 2>/dev/null \
    | grep -vE '\.(g|freezed)\.dart$' || true)"
  if [ -z "$changed" ]; then return 1; fi
  for f in $changed; do
    if [ -f "$root/$f" ] \
      && grep -qE "^part '[^']+\.(g|freezed)\.dart';" "$root/$f" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

cd "$app_dir"
echo "gate: app = $app_dir"

# 1. Codegen — only if the app uses build_runner. Tolerate build_runner versions
#    that reject the legacy --delete-conflicting-outputs flag. --fast skips it
#    when no codegen-source changed (build_runner's own cache makes a no-op run
#    cheap, but skipping it entirely is cheaper still).
if grep -q 'build_runner' pubspec.yaml 2>/dev/null; then
  if [ -n "$FAST" ] && ! codegen_source_changed; then
    echo "gate: codegen skipped (--fast, no codegen source changed)"
  else
    echo "gate: codegen"
    dart run build_runner build --delete-conflicting-outputs \
      || dart run build_runner build \
      || { echo "gate: codegen failed" >&2; exit 1; }
  fi
fi

# 2. Format (CI-style: fail if anything is unformatted).
echo "gate: format"
dart format --output=none --set-exit-if-changed .

# 3. Static analysis.
echo "gate: analyze"
flutter analyze

# 4. Full test suite with coverage (instruments all of lib/ — never scope this).
echo "gate: test"
flutter test --coverage

# 5. Logic-surface coverage floor.
echo "gate: coverage"
if [ -n "${COVERAGE_MIN:-}" ]; then
  dart "$root/scripts/check_coverage.dart" coverage/lcov.info --min="$COVERAGE_MIN"
else
  dart "$root/scripts/check_coverage.dart" coverage/lcov.info
fi

# 6. Android debug build. The Dart suite can't see native code, so a Kotlin /
#    manifest / resource regression ships silently without this — the
#    MainActivity base-class bug (registerForActivityResult on a plain Activity)
#    got through exactly that way. Builds a single-ABI (arm64) debug APK to keep
#    it fast while still compiling Kotlin, merging the manifest, and dexing.
#    Skipped when SKIP_ANDROID=1 (fast cycle) OR when the diff touches no native
#    file; force it with GATE_FORCE_ANDROID=1.
if [ -z "${SKIP_ANDROID:-}" ]; then
  if [ -z "${GATE_FORCE_ANDROID:-}" ] && ! native_changed; then
    echo "gate: android skipped (no native change)"
  else
    echo "gate: android (debug apk, arm64)"
    flutter build apk --debug --target-platform android-arm64 \
      || { echo "gate: android build failed" >&2; exit 1; }
  fi
fi

echo "gate: PASS"
