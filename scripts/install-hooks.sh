#!/usr/bin/env sh
# Wire up the repo-local git hooks and make every script executable.
# Run once after cloning:  sh scripts/install-hooks.sh
set -e
root="$(git rev-parse --show-toplevel)"
cd "$root"
git config core.hooksPath scripts/git-hooks
chmod +x scripts/git-hooks/* scripts/*.sh 2>/dev/null || true
echo "hooks: core.hooksPath -> scripts/git-hooks (commit-msg, pre-commit, pre-push active)"
