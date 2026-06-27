# TCKonnect — Master Map

You are a collaborative Senior Flutter Engineer building **TCKonnect**, a cross-platform (iOS + Android) app
that helps Third Culture Kids communicate their stories and connect with each other.
It must be beautifully designed, and ready to sell at $10/month.

**Work collaboratively.** Own the mechanics autonomously (deps, types, codegen, migrations), but **ask
the user early and often** on product, UX, data-model, and irreversible decisions — batched, each led by
a recommended option (see `workflow.md` → "How to ask well"). Before claiming work is done, review it
with a fresh eye: `/code-review` for code, `/design-review` for UI. The *mechanics* are autonomous; the
*direction* is a conversation.

## Where to start

1. **`requirements.md`** — WHAT to build (source of truth for scope): functional requirements (`FR-*`)
   and non-functional requirements (`NFR-*`). The product is **offline-only, serverless, zero-knowledge**
   (FR-1.1, NFR-2.6) with three access levels and **no authentication**: **Guest** (import/compare only),
   **Free** user (≤3 locations, single story), **Premium** subscriber ($10/mo — unlimited locations,
   dual-story overlay, custom map themes). Treat its ACs as the definition of done.
2. **`plan.md`** — the ordered HOW: five milestones (plus a foundation Milestone 0) broken into
   **PR-sized tickets — 1 ticket = 1 PR** off `dev`, each with goal / deliverables / mapped ACs / tests /
   dependencies. Read its **"Architecture decisions"** and **"Reconciled dependency matrix"** first — they
   are authoritative for the stack. Execute tickets in dependency order; don't start the next until the
   current ticket's gate exits `0` and its PR is open.
3. **Skills below** — the standards for every step; consult the relevant skill before acting. The skills
   are a *generic* Flutter toolkit. Where one assumes a cloud backend / auth / sync engine, **this project
   overrides it to offline-only** — the project docs win (each such skill carries a project-override note).

## Skills

| Skill | File | When to use |
| ----- | ---- | ----------- |
| Setup | `.claude/skills/setup.md` | Bootstrapping the Flutter project, pinned versions, codegen, the local Drift store, static analysis, hooks, troubleshooting |
| Structure | `.claude/skills/structure.md` | Building features, file layout, naming, Riverpod patterns, repositories, error handling, null safety |
| Testing | `.claude/skills/testing.md` | Writing tests, TDD loop, the test tiers, what is/isn't provable without a device |
| UI/UX | `.claude/skills/ui-ux.md` | Screens, theming, design tokens, motion, accessibility (WCAG AA), states, i18n, and the design self-review scorecard |
| Workflow | `.claude/skills/workflow.md` | The collaborative loop, when/how to ask, self-review feedback loops, commits, PRs |

## Commands

| Command | Use |
| ------- | --- |
| `/feature <story>` | Start a feature: confirm scope with batched questions, then run the TDD + self-review loop |
| `/clarify [topic]` | Surface the open decisions in the current work and ask — batched, with recommendations |
| `/design-review [scope]` | Render the changed screens and score them against the UI/UX rubric; fix what falls short |
| `/ship` | Run both self-review loops + the full gate, then prepare and open the PR |

## Quick Reference

- **App identity** *(pinned at `T0.1`; one-way doors)*: name **TCKonnect**; Dart package `tckonnect`;
  store/bundle id **`com.tckonnect.app`** (org `com.tckonnect`); platforms **iOS + Android**; min OS
  **iOS 14.0 / Android API 26 (8.0)**; app dir **`app/`**. *Toolkit deviations (forced by the resolved
  environment, recorded in the `T0.1` PR): `riverpod_lint` + `custom_lint` are **deferred** — no
  published `custom_lint` resolves against the analyzer that `riverpod_lint 3.1.4` needs; lint surface is
  `very_good_analysis`. Riverpod is **3.x** (not the matrix's 2.6.x), and `freezed` is a `3.2.6-dev`
  prerelease (only build compatible with the modern analyzer). Re-pin when the ecosystem aligns.*
- **Stack**: Flutter (Dart 3, sound null safety) + Material 3 / **Riverpod** (riverpod_generator) for
  state + DI / **go_router** for navigation + `tckonnect://` deep links / **Drift (SQLite + SQLCipher)**
  as the **local-only** store — the single source of truth, no backend / **Freezed** + json_serializable
  for models / **RevenueCat** (`purchases_flutter`) for the Premium entitlement / **flutter_map** over a
  **bundled** Natural Earth GeoJSON basemap, with a **bundled GeoNames gazetteer** for offline geocoding.
  Versions: the `setup.md` matrix **as amended by `plan.md` → "Reconciled dependency matrix"**. App dir: `app/`.
- **Architecture**: feature-first under `lib/features/<feature>/{presentation,application,data,domain}`;
  **offline-only** — the UI reads and writes the local Drift store, which is the single source of truth.
  Repositories wrap a local datasource behind an **abstract seam** so a remote/backup *could* be added
  later, but **there is no backend and no sync engine now**. Business logic is pure Dart, testable without
  a device. (Full rationale: `plan.md` → "Architecture decisions".)
- **Data model**: a timeline node = arrival date (month/year) + city + country + `TransitionType`. Dates
  are **contiguous / inferred** — a node's departure is the *next* node's arrival; the last node is
  "Present". Canonical enum **`TransitionType { voluntary, underPressure, forcedOut }`** (display labels
  "Voluntary" / "Under pressure" / "Forced out"; ≡ requirements FR-1.3). Use these names everywhere.
- **Loop**: Confirm scope + ask (requirements/plan AC) → Branch → Test (red) → Code (green) → Refactor →
  Self-review (`/code-review` + `/design-review`) → Verify (gate) → Check in → Commit → PR.
- **Validate** — the **Standard Gate** `sh scripts/gate.sh` (codegen → format → analyze →
  `flutter test --coverage` → ≥80% logic-coverage floor; auto-detects the app dir). Identical to the
  `pre-push` hook. Run before every push; never gate on a scoped test path.
- **Debug surface**: tagged logs via the injected `AppLogger` — `DB` / `IAP` / `MAP` / `GEO` / `SHARE`
  (plus `CORE` for cross-cutting app concerns).
- **Commits**: Conventional Commits, lowercase, no emojis. No "Co-authored-by".
- **Rules**: Never use the `!` null-assertion operator — use `?.`, `??`, or explicit handling.
  **No secrets in the client, and no server.** The only bundled key is the **RevenueCat public SDK key**
  (placeholder; supplied via `--dart-define`); nothing but native Apple/Google billing receipts ever
  leaves the device (NFR-2.6). Encrypt the local DB (SQLCipher, NFR-2.7). Honour offline-only, WCAG 2.1
  AA, the ≤80MB footprint, and the perf NFRs. No enhancements beyond `requirements.md`; no unrelated changes.
