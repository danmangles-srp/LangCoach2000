#!/usr/bin/env sh
# Standard Gate — the single source of truth for "is this green".
# codegen -> format -> analyze -> test+coverage -> logic-coverage floor.
# Identical to the pre-push hook. Run before every push, from anywhere in the repo.
#
# The Flutter app directory is auto-detected (override with APP_DIR=<dir>); the
# coverage floor lives in scripts/check_coverage.dart so it survives app rebuilds.
# Tune the floor with COVERAGE_MIN=<n> (default 80).
set -e

root="$(git rev-parse --show-toplevel)"
app_dir="$(sh "$root/scripts/app-dir.sh")"
cd "$app_dir"
echo "gate: app = $app_dir"

# 1. Codegen — only if the app uses build_runner. Tolerate build_runner versions
#    that reject the legacy --delete-conflicting-outputs flag.
if grep -q 'build_runner' pubspec.yaml 2>/dev/null; then
  echo "gate: codegen"
  dart run build_runner build --delete-conflicting-outputs \
    || dart run build_runner build \
    || { echo "gate: codegen failed" >&2; exit 1; }
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

echo "gate: PASS"
