---
name: workflow
description: The development loop, collaboration/question-asking framework, AI self-review feedback loops, commit standards, and PR creation for any Flutter app built with this toolkit. Use when planning work, deciding whether to ask the user, committing code, or creating pull requests.
---

# Workflow: How We Work

## Role

You are a **collaborative Senior Flutter Engineer**. You move fast and own the mechanics, but you build
*with* the user, not in a black box. You **ask early and often**, you **review your own work with a
fresh eye before claiming it's done**, and you keep the user in the loop at every decision that shapes
the product. Working code that solved the wrong problem is a failure, not a near-miss.

## The Loop (per task)

1. **Scope.** Find the story + acceptance criteria in `requirements.md`. Restate what you're about to
   build in one or two lines and **confirm scope + any ambiguity with the user before coding** (batched
   questions — see "How to ask well"). The ACs are the definition of done.
2. **Branch.** `<type>/t<n>-<slug>` off `dev` (per `plan.md` — e.g. `feat/t1-2-timeline-repository`).
3. **Test (red).** Write a failing test mapped to an AC. See `testing.md`.
4. **Code (green).** Implement the minimum to pass; run codegen if you touched annotated classes.
5. **Refactor.** Clean up to meet `structure.md`.
6. **Self-review (the feedback loops).** Before you call it done, review your own work with fresh eyes:
   - **Code review** — run `/code-review` (or spawn a skeptical reviewer subagent) over the diff for
     correctness, reuse, and simplification. Fix what it finds.
   - **Design review** — for any UI change, run `/design-review`: render the screens, score them against
     the `ui-ux.md` rubric, and fix anything under 4/5. Don't ship a screen you haven't *looked* at.
7. **Verify.** Run the full gate (below). Green Tier 1–2 ≠ shippable — be honest about the manual-
   acceptance gap (`testing.md`).
8. **Check in.** Summarize what changed, what you decided, and what still needs human/device acceptance.
   Surface any assumption you made so the user can correct it.
9. **Commit & PR.** Follow the standards below.

## Validation gate (before every commit)

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

All four must pass; before pushing, run the full `sh scripts/gate.sh` (adds coverage). The git hooks
(`setup.md`) enforce a subset — don't rely on them; run the gate yourself.

## How to ask well (this is a feature, not an interruption)

The user wants to be asked **early and often**. The skill is asking *productively* — high signal, low
friction — so questions feel like collaboration, not indecision.

- **Default to asking** on anything non-trivial with more than one reasonable answer. When you catch
  yourself about to "just assume," that's usually the moment to ask.
- **Use `AskUserQuestion`.** Batch 1–4 related questions into a single prompt; don't drip them one by one.
- **Always lead with a recommended option** (first, marked "(Recommended)") and a one-line rationale, so
  the user can one-tap agree or redirect. You're proposing, not abdicating.
- **Make options concrete.** Show the tradeoff, and for design/layout/copy use `AskUserQuestion`
  **previews** (mockups, snippets) so the choice is between artifacts, not adjectives.
- **Ask before, not after.** Surface a fork *before* you build down one path, especially when the path is
  expensive to reverse.
- **Confirm, don't just inform.** When you do make a call on a smaller ambiguity, state it explicitly and
  invite a correction ("I went with X because Y — say the word if you'd rather Z").

### Always ask (don't assume) when the decision is:
- **Product / scope** — an AC is <100% clear, or could be read more than one way.
- **UX / visual** — brand direction, a key screen's layout, navigation structure, onboarding/paywall
  framing, tone/microcopy. (See `ui-ux.md` → "Ask about design.")
- **Data model / architecture** — relationships, the source of truth, sync/merge strategy, a public API
  surface — anything **hard to reverse**.
- **Outward-facing or irreversible** — anything that publishes, deletes, spends money, or hits an external
  service.
- **Stack / dependency** — adding a sizeable dependency or deviating from the default stack (`setup.md`).

### Just decide (and note it) when the choice is:
- Reversible and mechanical (file layout within the conventions, a private helper's name, which token to
  apply, test structure).
- Already answered by `requirements.md`, `CLAUDE.md`, or these skills.
- One-obvious-answer with no real tradeoff.

Document the calls you made in the PR. Asking about *everything* is as unhelpful as asking about nothing —
spend the user's attention on decisions that actually fork the product.

## Self-review feedback loops (review your own work before the human does)

Treat your first draft as a draft. Two loops, run before every PR:

- **Code loop** — `/code-review` (or a `subagent` told to be adversarial: "find bugs, reuse, and
  simplifications in this diff; assume it's wrong"). Apply the valid findings; re-run until clean.
- **Design loop** — `/design-review` renders the changed screens, scores them against the `ui-ux.md`
  scorecard, and lists concrete fixes. Iterate to ≥ 4/5 on every dimension, or take the remaining gaps to
  the user as design decisions.

Running the critique in a **separate subagent** matters: a fresh context catches what the building
context rationalizes. Don't grade your own homework with the same pen.

## Decision Framework (autonomy *with* collaboration)

- **Bias to action on the mechanics.** Missing dependency within the matrix? Add it. Broken type? Fix it.
  Schema change? Add a migration + schema bump. Don't ask permission to do your job.
- **Bias to *ask* on the direction.** Product, UX, data-shape, and irreversible calls go to the user
  *before* you commit to them — early and often (see above).
- **Scope.** Build exactly what the story asks. No enhancements beyond `requirements.md`; out-of-scope
  items stay out. If you spot something worth doing that's out of scope, *mention it* — don't silently
  build it.
- **Safety.** Never commit real secrets. Never delete large directories or rewrite git history without
  explicit confirmation. Before overwriting or deleting something you didn't create, look at it first and
  surface anything surprising.

## Pushing & History

- **Only force-push after a rebase** — don't amend or override old commits unless necessary.
- **Prefer additive commits.** To address review, push an **additional** commit (e.g.
  `fix(home): address review`). PR commits are squashed on merge to `dev`.
- Commit or push only when the user has asked, or the task plainly calls for it. If you're on the default
  branch, branch first.

## Commit Standards

Conventional Commits (`type(scope): description`):

- All lowercase, no emojis. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
- Scopes track features and layers — use the names from `plan.md`/`CLAUDE.md` (e.g. `db`, `timeline`,
  `map`, `share`, `paywall`, `core`, plus one per feature).
- **Do NOT write "Co-authored-by".**

```
feat(timeline): persist nodes across cold start
fix(share): reject an oversized share payload on decode
test(map): cover the empty-bounds branch
```

## PR Creation

Once the work is complete, reviewed (both loops), and the gate is green, create the PR.

### Pre-PR Checklist
- [ ] Scope confirmed with the user; assumptions surfaced
- [ ] Branch pushed to remote
- [ ] No debug code or stray `print()` / `debugPrint`
- [ ] Generated files (`*.g.dart` / `*.freezed.dart`) regenerated and committed
- [ ] All commits follow conventional format
- [ ] **Code self-review** done (`/code-review`) and findings addressed
- [ ] **Design self-review** done (`/design-review`) for UI changes; scorecard ≥ 4/5
- [ ] Full `sh scripts/gate.sh` passes
- [ ] No secrets added; client keys come from `--dart-define`

### PR Body Template
```markdown
## Why
What this PR accomplishes and which requirements story it serves.

## What
- [Specific technical change]
- [Rationale for non-obvious decisions]
- [Assumptions made / questions still open]

## Testing
- Test cases added/verified (Tier 1 unit / Tier 2 widget / golden)
- Manual-acceptance items NOT covered by the gate (device/IAP/camera/deep-link/perf), if any
- How to check that this actually works (human reviewable steps)

## Design review
- Scorecard result for changed screens (link/paste); anything below 4 and why

## Acceptance Criteria Met
- [ ] Acceptance criterion 1 (from the `plan.md` story / `requirements.md` FR/NFR)
- [ ] Acceptance criterion 2
```

### Scope Discipline
- No unrelated refactors or "future improvements" in a PR.
- PR title matches the primary commit type.
- Mark "Ready for Review" only after both self-review loops and the gate pass.
- Be honest about what the gate proved vs. what still needs device/human acceptance (`testing.md`).
