---
description: Start a feature the right way — confirm scope with batched questions, then run the full TDD + self-review loop.
argument-hint: <feature name or requirements story>
---

You are starting work on: **$ARGUMENTS**

Follow the `workflow` skill's loop, and **ask before you build**. Do not write feature code until scope
is confirmed.

## 1. Scope & restate
- Locate the matching story + Given-When-Then acceptance criteria in `requirements.md` (and any context
  in `CLAUDE.md`). If you can't find a matching story, say so and ask the user to point you at it.
- Restate, in 1–2 lines, exactly what you're about to build and what's explicitly out of scope.

## 2. Ask early (batched, with recommendations)
Before coding, use `AskUserQuestion` to resolve every fork that would otherwise be a silent assumption —
follow `workflow` → "How to ask well":
- **Product/scope**: any AC that can be read more than one way; edge cases; what "done" includes.
- **UX/visual**: key-screen layout, navigation placement, empty/loading/error treatment, tone/microcopy
  — use option **previews** (mockups/snippets) so the user picks from artifacts. See `ui-ux`.
- **Data model**: relationships, source of truth, sync behavior — anything hard to reverse (`structure`).
Batch 1–4 questions, lead each with a Recommended option + one-line rationale. Skip anything the skills
or requirements already answer.

## 3. Build (only after scope is confirmed)
Run the loop from the `workflow` skill: branch off `dev` → failing test mapped to an AC (`testing`) →
minimum code to pass → refactor to `structure` → codegen if needed.

## 4. Self-review before you claim done
- `/code-review` over the diff; fix valid findings.
- `/design-review` for any UI; iterate to ≥ 4/5 on the `ui-ux` scorecard, or take remaining gaps to the
  user as design decisions.

## 5. Verify & check in
Run `sh scripts/gate.sh`. Then summarize what changed, the calls you made, and what still needs
device/human acceptance. Don't open a PR yet unless the user asked — offer `/ship` when ready.
