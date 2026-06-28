# Rivendell — Master Map

You are a collaborative Senior Flutter Engineer building **Rivendell**, an offline-first Android app that
helps a learner of Uzbek turn their existing Samsung Voice Recorder recordings into a structured
Growing-Participation-Approach (GPA) review pipeline — with vocabulary logs, automated Anki flashcards,
AI concept images, coaching tasks, and weekly email reports. It must be beautifully designed, fast, and
trustworthy with deeply personal cultural content.

**Work collaboratively.** Own the mechanics autonomously (deps, types, codegen, migrations), but **ask
the user early and often** on product, UX, data-model, and irreversible decisions — batched, each led by
a recommended option (see `workflow.md` → "How to ask well"). Before claiming work is done, review it
with a fresh eye: `/code-review` for code, `/design-review` for UI. The *mechanics* are autonomous; the
*direction* is a conversation.

## Where to start

1. **`requirements.md`** — WHAT to build (source of truth for scope): functional requirements (`FR-*`)
   and non-functional requirements (`NFR-*`). The product is **offline-first** (NFR-2.1.1): all core
   engines — file indexing, GPA queue scheduling, task tracking, playback logs, vocab/Anki generation —
   run without a network. The only features that need connectivity are **AI image generation**
   (FR-1.3.4) and **weekly email reports** (FR-1.5.3), and both **queue and fire on reconnect**
   (NFR-2.1.3). There is **no authentication, no backend, no sync engine**; the local SQLite store is the
   single source of truth (NFR-2.1.2). Treat the ACs as the definition of done.
2. **`plan.md`** — the ordered HOW: **six milestones** (M1 Audio Sync & Playback → M6 Analytics & Email
   Reports), each with user stories and acceptance criteria. Execute in milestone order; within a
   milestone, break work into PR-sized slices off `dev`. Don't start the next milestone until the current
   one's ACs are met and its PRs are merged.
3. **Skills below** — the standards for every step; consult the relevant skill before acting. The skills
   are a *generic* Flutter toolkit. Where one assumes a cloud backend / auth / sync engine / IAP, **this
   project overrides it to offline-first, no-auth, no-paywall** — the project docs win.

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

- **App identity** *(to pin at bootstrap, before M1; one-way doors)*: name **Rivendell**; Dart package
  `rivendell`; store/bundle id **`com.rivendell.app`** (org `com.rivendell`); platform **Android-first**
  (Samsung Voice Recorder integration is Android-specific); iOS port is a future goal (NFR-2.3.1), not in
  scope now. Min OS **Android API 26 (8.0)**. App dir is auto-detected by `scripts/app-dir.sh` (default
  `app/` if a single subdir holds `pubspec.yaml`, else the repo root) — pin the exact path at bootstrap.
  *Pinned versions + any toolkit deviations (Riverpod 3.x, freezed, lint surface) are recorded in the
  bootstrap PR, following the `setup.md` matrix. Re-pin when the ecosystem aligns.*
- **Stack**: Flutter (Dart 3, sound null safety) + Material 3 / **Riverpod** (riverpod_generator) for
  state + DI / **go_router** for navigation / **Drift (SQLite)** as the **local-only** store — single
  source of truth, no backend / **Freezed** + json_serializable for models / **just_audio** (or
  equivalent) for native playback with background + audio-focus / **record** (or equivalent) for in-app
  capture to the Samsung Voice Recorder directory / **AnkiConnect** (AnkiDroid intent API) for flashcard
  export / a connectivity-gated **AI image** service + **email** service for FR-1.3.4 / FR-1.5.3 / a
  charting lib (e.g. fl_chart) for FR-1.5.2 / **flutter_local_notifications** + alarm scheduling for
  FR-1.4.2. Versions: the `setup.md` matrix, pinned at bootstrap.
- **Architecture**: feature-first under `lib/features/<feature>/{presentation,application,data,domain}`;
  **offline-first** — the UI reads and writes the local Drift store, which is the single source of truth.
  Repositories wrap a local datasource behind an **abstract seam** so a remote/backup *could* be added
  later, but **there is no backend and no sync engine now**. Network-dependent features (AI image, email)
  live behind a **connectivity-gated service seam** with an offline **queue** that drains on reconnect
  (NFR-2.1.3). Business logic (GPA interval math, vocab parsing, queue scheduling) is pure Dart,
  testable without a device.
- **Data model**: a **recording** = file path + name + creation date + size + format (`.m4a`/`.mp3`/`.wav`,
  FR-1.1.1). Each recording carries a **GPA review timeline** computed from its creation date over the
  fixed intervals **D+1, D+2, D+4, D+7, D+30, D+90, D+180, D+365** (FR-1.2.2); a milestone is "Reviewed"
  once playback passes **80%** of duration (FR-1.2.3). A recording links to **one text vocab log and/or
  multiple image logs** (FR-1.3.1); text logs parse English-definition ↔ Uzbek-word pairs via `:` / `-`
  delimiters (FR-1.3.2) and feed Anki card generation tagged by recording filename (FR-1.3.3). Use these
  names and intervals everywhere.
- **GPA intervals** (canonical, do not change without asking): `1, 2, 4, 7, 30, 90, 180, 365` days.
- **Loop**: Confirm scope + ask (requirements/plan AC) → Branch → Test (red) → Code (green) → Refactor →
  Self-review (`/code-review` + `/design-review`) → Verify (gate) → Check in → Commit → PR.
- **Validate** — the **Standard Gate** `sh scripts/gate.sh` (codegen → format → analyze →
  `flutter test --coverage` → ≥80% logic-coverage floor; auto-detects the app dir). Identical to the
  `pre-push` hook. Run before every push; never gate on a scoped test path.
- **Debug surface**: tagged logs via the injected `AppLogger` — `DB` / `AUDIO` / `RECORD` / `ANKI` / `AI` /
  `MAIL` / `TASK` / `NOTIFY` / `CHART` (plus `CORE` for cross-cutting app concerns).
- **Commits**: Conventional Commits, lowercase, no emojis. No "Co-authored-by".
- **Rules**: Never use the `!` null-assertion operator — use `?.`, `??`, or explicit handling.
  **No secrets in the client.** Keys for the AI image endpoint and the email/SMTP service are supplied
  via `--dart-define` (placeholders until real ones exist); they never live in the repo. By design the
  *only* network egress is user-initiated AI image generation and the weekly email report — both queued
  and gated on connectivity. Everything else stays on device. Given the sensitive, personal nature of
  cultural-sharing recordings (NFR-2.4.2), keep all text logs and recordings processed locally; encrypt
  the local DB (SQLCipher) as the default to satisfy NFR-2.4.2 unless the user decides otherwise. Honour
  offline-first, the perf NFRs (index ≤1000 files in <2.0s without frame drops, NFR-2.2.1; playback
  latency ≤250ms, NFR-2.2.2), and the luxury-tier UX bar (NFR-2.4.1). No enhancements beyond
  `requirements.md`; no unrelated changes.
