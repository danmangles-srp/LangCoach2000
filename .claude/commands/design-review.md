---
description: Visual self-critique loop — render the changed screens, score them against the UI/UX rubric with a fresh eye, and fix what falls short.
argument-hint: [screen or feature — defaults to the current diff]
---

Run the **AI design self-review loop** from the `ui-ux` skill on: **${ARGUMENTS:-the screens touched by the current diff}**

This is a *visual* review — it complements `/code-review` (correctness/cleanup), it doesn't replace it.

## 1. Identify the screens
List the screens/widgets in scope (from the diff, or the named feature). For each, note the states that
matter: **light + dark**, **default + 200% text scale**, and **empty + populated**.

## 2. Render reality (don't review from imagination)
Get actual rendered output, in this order of preference:
1. **Run the app** (use the `/run` skill or `flutter run`) and capture screenshots of each screen/state.
2. If no device/emulator is available, generate/refresh **golden images**
   (`flutter test --update-goldens`) and review those PNGs — and say in the output that this was
   golden-based, not a live device.
If you genuinely cannot render, stop and tell the user what's blocking it rather than reviewing blind.

## 3. Score with a fresh eye
Spawn a **subagent** (Agent tool) as a *skeptical senior product designer reviewing a paid app*, and
hand it the screenshots. Have it score each screen 1–5 on every dimension of the `ui-ux` scorecard:
hierarchy & focus · spacing & alignment · typography · color & theming · consistency · states · motion &
feedback · accessibility · microcopy · **"worth paying for?"**. Using a separate context matters — it
catches what the building context rationalizes. For each row < 4, it must give a **specific, actionable**
fix (which widget, which token), not vague praise.

## 4. Fix and re-score
Apply the fixes (preferring design tokens, not magic numbers). Re-render and re-score until every
dimension is ≥ 4 — **or** the remaining gaps are genuine product/brand decisions, which you take to the
user via `AskUserQuestion` with concrete **option previews** (see `ui-ux` → "Ask about design").

## 5. Output
Post the final filled scorecard (per screen), the fixes you applied, and any design decisions you're
sending to the user. Keep this scorecard for the PR body.
