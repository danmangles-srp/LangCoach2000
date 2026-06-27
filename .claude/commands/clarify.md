---
description: Surface the open decisions in the current work and ask the user about them — batched, with recommendations.
argument-hint: [topic — defaults to the current task/diff]
---

Find what you're about to **assume**, and ask instead. Scope: **${ARGUMENTS:-the current task / open diff / active requirements story}**

Follow `workflow` → "How to ask well."

## 1. Hunt for forks
Scan the scope for decisions that have more than one reasonable answer and aren't already settled by
`requirements.md`, `CLAUDE.md`, or the skills. Look specifically for:
- **Product/scope** — ambiguous acceptance criteria, undefined edge cases, unclear "done".
- **UX/visual** — layout, navigation, states, onboarding/paywall framing, tone/microcopy (`ui-ux`).
- **Data model / architecture** — relationships, source of truth, sync/merge, anything hard to reverse
  (`structure`).
- **Irreversible / outward-facing** — anything that publishes, deletes, spends, or calls an external
  service.

## 2. Filter
Drop anything trivial, reversible, or one-obvious-answer — don't spend the user's attention on those
(decide them yourself and note it). Keep only the decisions that actually fork the product.

## 3. Ask well
Pose the survivors via `AskUserQuestion`:
- Batch 1–4 related questions per prompt.
- Lead each with a **Recommended** option + one-line rationale.
- Make options concrete; for design/layout/copy, use **previews** (mockups, snippets) so the user
  compares artifacts, not adjectives.

If, after scanning, there are genuinely no real forks, say so plainly and state the assumptions you'll
proceed under — don't manufacture questions.
