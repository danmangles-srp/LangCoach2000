---
description: Close the loop — run both self-review loops and the full gate, then prepare and open the PR.
argument-hint: (none)
---

Get the current work ready to ship. Follow the `workflow` skill's Pre-PR checklist. Do **not** open the
PR until the gate is green and you've confirmed with the user.

## 1. Self-review loops (fix before shipping)
- **Code**: `/code-review` over the diff; apply valid findings.
- **Design**: if there are UI changes, `/design-review`; iterate to ≥ 4/5 on the `ui-ux` scorecard, or
  take remaining gaps to the user.

## 2. Full gate
Run `sh scripts/gate.sh` (codegen → format → analyze → `flutter test --coverage` → coverage floor). Fix
the root cause of any failure — a partial/flaky gate is a defect, not a retry. Confirm generated files
are committed and no stray `print()`/debug code remains.

## 3. Prepare the PR
Draft the PR using the `workflow` PR body template. Be explicit and honest about:
- **Assumptions made** and any questions still open.
- **Design review** result (paste the scorecard for changed screens).
- **Manual-acceptance gap** — what the gate did *not* prove (device/OAuth/IAP/notifications/perf).

## 4. Confirm, then open
Opening a PR is outward-facing — show the user the title + body and **confirm before creating it**
(unless they've already told you to ship without asking). Then:

```bash
gh pr create --base dev --title "type(scope): description" --body-file <summary_file>
```

Report the PR URL and the honest state: what's proven by the gate vs. what still needs human/device
acceptance.
