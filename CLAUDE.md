# Rivendell — Master Map

Collaborative Senior Flutter Engineer building **Rivendell** �" offline-first Android app. Turns Samsung Voice Recorder recordings into structured GPA review pipeline �" vocab logs, automated Anki flashcards, AI concept images, coaching tasks, weekly email reports. Must be beautiful, fast, trustworthy with personal cultural content.

**Work collaboratively.** Own mechanics autonomous (deps, types, codegen, migrations). **Ask user early/often** on product, UX, data-model, irreversible decisions �" batched, each led by recommended option (see `workflow.md` �' "How to ask well"). Before claiming done, fresh-eye review: `/code-review` for code, `/design-review` for UI. *Mechanics* autonomous; *direction* conversation.

## Where to start

1. **`requirements.md`** �" WHAT to build (scope source of truth): functional (`FR-*`) + non-functional (`NFR-*`) requirements. Product **offline-first** (NFR-2.1.1): all core engines �" file indexing, GPA queue scheduling, task tracking, playback logs, vocab/Anki generation �" run without network. Only features needing connectivity: **AI image generation** (FR-1.3.4) + **weekly email reports** (FR-1.5.3), both **queue + fire on reconnect** (NFR-2.1.3). **No auth, no backend, no sync engine**; local SQLite store = single source of truth (NFR-2.1.2). ACs = definition of done.
2. **`plan.md`** �" ordered HOW: **six milestones** (M1 Audio Sync & Playback �' M6 Analytics & Email Reports), each with user stories + acceptance criteria. Execute in milestone order; within milestone, break work into PR-sized slices off `dev`. Don't start next milestone until current one's ACs met + PRs merged.
3. **Skills below** �" standards for every step; consult relevant skill before acting. Skills are *generic* Flutter toolkit. Where one assumes cloud backend / auth / sync engine / IAP, **this project overrides to offline-first, no-auth, no-paywall** �" project docs win.

## Skills

| Skill | File | When to use |
| ----- | ---- | ----------- |
| Setup | `.claude/skills/setup.md` | Bootstrapping Flutter project, pinned versions, codegen, local Drift store, static analysis, hooks, troubleshooting |
| Structure | `.claude/skills/structure.md` | Building features, file layout, naming, Riverpod patterns, repositories, error handling, null safety |
| Testing | `.claude/skills/testing.md` | Writing tests, TDD loop, test tiers, what is/isn't provable without device |
| UI/UX | `.claude/skills/ui-ux.md` | Screens, theming, design tokens, motion, accessibility (WCAG AA), states, i18n, design self-review scorecard |
| Workflow | `.claude/skills/workflow.md` | Collaborative loop, when/how to ask, self-review feedback loops, commits, PRs |

## Commands

| Command | Use |
| ------- | --- |
| `/feature <story>` | Start feature: confirm scope with batched questions, then run TDD + self-review loop |
| `/clarify [topic]` | Surface open decisions in current work + ask �" batched, with recommendations |
| `/design-review [scope]` | Render changed screens, score against UI/UX rubric; fix what falls short |
| `/ship` | Run both self-review loops + full gate, then prepare + open PR |

## Quick Reference

- **App identity** *(pin at bootstrap, before M1; one-way doors)*: name **Rivendell**; Dart package `rivendell`; store/bundle id **`com.rivendell.app`** (org `com.rivendell`); platform **Android-first** (Samsung Voice Recorder integration Android-specific); iOS port future goal (NFR-2.3.1), not in scope now. Min OS **Android API 26 (8.0)**. App dir pinned at **`app/`** (auto-detected by `scripts/app-dir.sh`).
  *Pinned versions + toolkit deviations (Riverpod 3.x, freezed, lint surface) recorded in bootstrap PR, following `setup.md` matrix. Re-pin when ecosystem aligns.*
- **Stack**: Flutter (Dart 3, sound null safety) + Material 3 / **Riverpod** (riverpod_generator) for state + DI / **go_router** for navigation / **Drift (SQLite)** as **local-only** store �" single source of truth, no backend / **Freezed** + json_serializable for models / **just_audio** (or equivalent) for native playback with background + audio-focus / **record** (or equivalent) for in-app capture to Samsung Voice Recorder directory / **AnkiConnect** (AnkiDroid intent API) for flashcard export / connectivity-gated **AI image** service + **email** service for FR-1.3.4 / FR-1.5.3 / charting lib (e.g. fl_chart) for FR-1.5.2 / **flutter_local_notifications** + alarm scheduling for FR-1.4.2. Versions: `setup.md` matrix, pinned at bootstrap.
- **Architecture**: feature-first under `lib/features/<feature>/{presentation,application,data,domain}`; **offline-first** �" UI reads/writes local Drift store = single source of truth. Repositories wrap local datasource behind **abstract seam** so remote/backup *could* be added later, but **no backend, no sync engine now**. Network-dependent features (AI image, email) live behind **connectivity-gated service seam** with offline **queue** draining on reconnect (NFR-2.1.3). Business logic (GPA interval math, vocab parsing, queue scheduling) = pure Dart, testable without device.
- **Data model**: **recording** = file path + name + creation date + size + format (`.m4a`/`.mp3`/`.wav`, FR-1.1.1). Each recording carries **GPA review timeline** computed from creation date over fixed intervals **D+1, D+2, D+4, D+7, D+30, D+90, D+180, D+365** (FR-1.2.2). When playback passes **80%** of duration, app appends row to **append-only `review_events` log** (recording id, milestone index, completed-at) (FR-1.2.3). "Reviewed for milestone N", **last reviewed**, **review count** all **derived** from that log �" no separate flag (FR-1.2.4). Recording links to **one text vocab log and/or multiple image logs** (FR-1.3.1); text logs parse English-definition �" Uzbek-word pairs via `:` / `-` delimiters (FR-1.3.2), feed Anki card generation tagged by recording filename (FR-1.3.3). Use these names + intervals everywhere.
- **GPA intervals** (canonical, don't change without asking): `1, 2, 4, 7, 30, 90, 180, 365` days.
- **Loop**: Confirm scope + ask (requirements/plan AC) �' Branch �' Test (red) �' Code (green) �' Refactor �' Self-review (`/code-review` + `/design-review`) �' Verify (gate) �' Check in �' Commit �' PR.
- **Validate** �" **Standard Gate** `sh scripts/gate.sh` (codegen �' format �' analyze �' `flutter test --coverage` �' ≥80% logic-coverage floor; auto-detects app dir). Identical to `pre-push` hook. Run before every push; never gate on scoped test path.
- **Debug surface**: tagged logs via injected `AppLogger` �" `DB` / `AUDIO` / `RECORD` / `ANKI` / `AI` / `MAIL` / `TASK` / `NOTIFY` / `CHART` (plus `CORE` for cross-cutting app concerns).
- **Commits**: Conventional Commits, lowercase, no emojis. No "Co-authored-by".
- **Rules**: Never use `!` null-assertion operator �" use `?.`, `??`, or explicit handling. **No secrets in client.** Keys for email/SMTP service are **runtime settings** stored in the SQLCipher-encrypted local KV store (entered via Settings, read fresh per drain so a rotation takes effect without re-queueing); never via `--dart-define`, never in the repo. AI image generation runs on the keyless Pollinations free tier (no key, no Settings entry). By design *only* network egress = user-initiated AI image generation + weekly email report �" both queued + gated on connectivity. Everything else stays on device. Given sensitive personal nature of cultural-sharing recordings (NFR-2.4.2), keep all text logs + recordings processed locally; encrypt local DB (SQLCipher) as default to satisfy NFR-2.4.2 unless user decides otherwise. Honour offline-first, perf NFRs (index ≤1000 files in <2.0s without frame drops, NFR-2.2.1; playback latency ≤250ms, NFR-2.2.2), luxury-tier UX bar (NFR-2.4.1). No enhancements beyond `requirements.md`; no unrelated changes.