#!/usr/bin/env sh
# Resolve the Flutter app directory and print its absolute path on stdout.
#
# Resolution order:
#   1. $APP_DIR (relative to the repo root, or absolute) — explicit override.
#   2. The repo root itself, if it holds a pubspec.yaml (single-package repo).
#   3. The unique immediate subdirectory that holds a pubspec.yaml.
# Absence or ambiguity prints guidance to stderr and exits 1.
#
# Used by gate.sh and the pre-commit hook so the toolkit is not pinned to one
# app folder name. Override anytime:  APP_DIR=myapp sh scripts/gate.sh
set -e

root="$(git rev-parse --show-toplevel)"

# Prints the absolute path of $1 if it contains a pubspec.yaml; else returns 1.
print_if_app() {
  [ -f "$1/pubspec.yaml" ] || return 1
  ( cd "$1" && pwd )
}

# 1. Explicit override.
if [ -n "${APP_DIR:-}" ]; then
  case "$APP_DIR" in
    /*) cand="$APP_DIR" ;;
    *)  cand="$root/$APP_DIR" ;;
  esac
  if print_if_app "$cand"; then exit 0; fi
  echo "app-dir: APP_DIR='$APP_DIR' has no pubspec.yaml (looked in $cand)." >&2
  exit 1
fi

# 2. App at the repo root.
if [ -f "$root/pubspec.yaml" ]; then
  printf '%s\n' "$root"
  exit 0
fi

# 3. Unique immediate subdirectory with a pubspec.yaml.
# (Shell globbing skips dotfiles, so .dart_tool/.git/.claude are already ignored.)
found=''
count=0
for d in "$root"/*/; do
  [ -f "${d}pubspec.yaml" ] || continue
  case "$d" in */build/) continue ;; esac
  found="${d%/}"
  count=$((count + 1))
done

if [ "$count" -eq 1 ]; then
  ( cd "$found" && pwd )
  exit 0
fi

if [ "$count" -eq 0 ]; then
  echo "app-dir: no Flutter app found under $root." >&2
  echo "         Create one (see .claude/skills/setup.md) or set APP_DIR=<dir>." >&2
else
  echo "app-dir: found $count app directories; set APP_DIR=<dir> to choose one." >&2
fi
exit 1
