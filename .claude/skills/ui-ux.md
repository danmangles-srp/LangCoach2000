---
name: ui-ux
description: Design system, Flutter/Material 3 styling, visual hierarchy, motion, accessibility (WCAG AA), i18n, state patterns, and the AI design self-review loop for any sellable Flutter app. Use when building screens, widgets, theming, states, or reviewing how the UI looks and feels.
---

# UI/UX: How We Look

> The bar is **sellable-grade**: every screen should look and feel worth paying for. Design is not a
> coat of paint applied at the end — it is decided per screen, reviewed with the AI design loop below,
> and gated before any UI PR. The product's specific screens live in `requirements.md`; this skill is
> *how to make any screen excellent*.

## North Star — what "good" means here

1. **Calm and confident.** Generous whitespace, few elements, one clear focal point per screen.
   Premium apps feel uncrowded. When in doubt, remove.
2. **One primary action per screen.** Make it obvious (a single filled button / FAB). Everything else is
   visually quieter.
3. **Content first, chrome last.** The user's data is the hero; navigation and controls recede.
4. **Effortless.** The core daily action is reachable in a **single tap**. Never make the user think
   about where something is.
5. **Consistent.** The same action looks and lives in the same place on every screen. Reuse components;
   don't reinvent a button.
6. **Alive but not noisy.** Motion confirms and guides; it never decorates or delays.

If a screen doesn't feel like it belongs in a paid product, it isn't done. Run the design loop.

## Design tokens — never hardcode

**Flutter + Material 3 only.** Every visual value comes from a token in `app/theme.dart` — no literal
colors, font sizes, paddings, radii, or durations in widgets. This is what makes the app consistent and
re-themeable, and it is enforced in design review.

| Token group | Source | Rule |
| ----------- | ------ | ---- |
| Color | `ColorScheme.fromSeed(seedColor: …)` | Use semantic roles (`primary`, `surface`, `error`, `onSurfaceVariant`…). Never a raw `Color(0xFF…)` in a widget. |
| Type | `TextTheme` (`displayLarge`…`labelSmall`) | Pick a role; never a literal `fontSize`. |
| Spacing | An 8-pt scale (`4, 8, 12, 16, 24, 32, 48`) | Expose as `AppSpacing` constants or `Gap` widgets. All padding/margin snaps to the scale. |
| Radius | A small radius scale (`8, 12, 16, full`) | One family of corner radii across the app. |
| Elevation / surface | M3 tonal surfaces (`surfaceContainerLow…High`) | Prefer tonal elevation over heavy shadows. |
| Motion | Duration + curve tokens (see Motion) | Standard durations and `Curves.easeInOut*`; no magic `Duration`s. |

```dart
// theme.dart — the single source of visual truth
final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: brandSeed, brightness: brightness),
  useMaterial3: true,
  textTheme: /* tuned type scale */,
);

abstract final class AppSpacing { static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0; }
```

## Visual hierarchy & layout

A user should know **where to look first** within half a second, and the scan path should be obvious.

- **One focal point.** Establish it with size, weight, color, or isolation — not all four. Everything
  else supports it.
- **Proximity = relationship.** Group related things tightly; separate unrelated things with whitespace.
  Spacing, not dividers, is the primary grouping tool.
- **Alignment.** Pick a grid and hold it. Left-align text and controls to a shared edge; ragged edges
  read as broken. Optical alignment beats mathematical when they disagree.
- **Breathe.** Screen margins ≥ 16dp (often 20–24). Don't fill the canvas — empty space signals quality.
- **Density.** Match the platform and content: roomy for consumer apps, tighter for data-dense tools.
  Be consistent within a screen.

## Typography

- **Limited scale.** Use the `TextTheme` roles; 4–6 distinct styles across the whole app, not a dozen.
- **Hierarchy by weight + size + color**, in that order — a heavier or larger or dimmer style, rarely all.
- **Body text**: ~1.4–1.5 line height; measure capped around 60–75 characters; never center long runs.
- **Numbers/labels**: use `labelLarge`/`titleMedium` deliberately; tabular figures for aligned columns.
- **Truncation**: long text uses `maxLines` + `TextOverflow.ellipsis`; layouts survive the longest
  realistic string (and translated strings — see i18n).

## Color & theming

- **Brand seed → full scheme.** One `seedColor` generates a harmonious `ColorScheme`. Don't fight it
  with ad-hoc colors.
- **Restraint.** Roughly 60% neutral surface / 30% secondary / 10% accent. One accent carries primary
  actions; if everything is colorful, nothing stands out.
- **Semantic roles, not raw colors.** `error` for errors, `primary` for the main action, `surfaceVariant`
  for quiet containers — so dark mode and re-theming "just work."
- **Light + dark parity.** Support `ThemeMode.system`; verify *both* in review. Dark mode is not an
  inverted afterthought — check contrast and elevation tonal surfaces.
- **Never encode meaning by color alone.** Pair every color signal (status, category, chart series) with
  text, an icon, a value, or a shape. This is both accessibility and clarity.

## Motion & micro-interactions

Motion's job is to **explain change and confirm action** — fast, purposeful, skippable.

- **Durations**: 150–250ms for most UI, up to ~300–400ms for full-screen transitions. Faster than you'd
  guess; sluggish animation feels cheap.
- **Easing**: ease-out for entrances, ease-in for exits, `easeInOut` for moves. Never linear for UI.
- **Navigation transitions**: use M3 patterns — container transform (tap a card → it expands into the
  detail), shared-axis (tabs/steps), fade-through (unrelated swaps). Don't ship the default platform
  slide for everything.
- **Every action gets feedback**: press states/ripples on tap, a subtle scale/opacity on press, haptics
  on meaningful confirmations, animated state changes (don't pop content in).
- **Loading**: animate skeletons, not just spinners (below).
- **Respect reduce-motion**: check `MediaQuery.disableAnimations` / accessibility settings and damp
  large motion accordingly.

## Component & screen patterns

- **Buttons** follow one hierarchy per screen: **one** filled (primary) → tonal/outlined (secondary) →
  text (tertiary). Verb labels ("Save", "Record"), never "OK/Submit" where a real verb fits.
- **Touch targets ≥ 48×48dp** even if the visual is smaller (pad the hit area).
- **Lists**: consistent row height, generous vertical padding, dividers *only* when grouping needs them;
  prefer spacing. Use cards to group a unit of related content, not to box every row.
- **Bottom sheets** for contextual actions/forms tied to an item; **dialogs** only for short, blocking
  decisions. A dialog pop must target the dialog, not the underlying shell.
- **FAB** = the single most important create action on a screen, and only that.
- **Forms**: label every field; validate inline on blur with a clear message and a path to fix; disable
  submit until valid; show progress on submit; never lose user input on error.
- **Imagery/icons**: one icon family; consistent stroke weight and size; meaningful, not decorative.

## Loading / Error / Empty / Content — design all four

Every screen renders every branch explicitly, driven from one `AsyncValue`/sealed state. A blank screen
during load, or a raw exception on error, is a bug.

| State | Design |
| ----- | ------ |
| **Loading** | **Skeleton** that mirrors the final layout (shimmering placeholders), not a centered spinner, wherever the layout is known. Spinner only for short, shape-unknown waits. |
| **Empty** | First-run guidance: a friendly line + one clear CTA (e.g. "Add your first recording"), on-brand, never a blank canvas. The empty state is a *sales* surface — make it inviting. |
| **Error** | Plain-language cause + a **Retry**. Offline → reassure ("You're offline — changes will sync"), don't alarm. Never show a stack trace or `Exception: …`. |
| **Content** | The data, as the hero. |

**Optimistic UI**: writes (toggles, edits, adds) update the screen immediately with a subtle save state;
on failure the change stays queued (offline-first) and is surfaced, never silently dropped.

## First impression & onboarding (this is where the sale happens)

- The **first screen a new user sees** must communicate the value in one glance and offer one obvious
  next step. No empty dashboards, no walls of settings.
- **Prime before you prompt.** Explain *why* before triggering an OS permission dialog (notifications,
  contacts); a denied permission is hard to recover.
- **Progressive disclosure.** Reveal complexity as needed; don't tour every feature up front.
- **Paywall / monetization**: this project ships **no paywall** in v1 (see `CLAUDE.md`). Don't add
  entitlement gates, upsell, or restore-purchase flows — they're out of scope.

## Accessibility (WCAG 2.1 AA — a requirement, not optional)

- Text contrast ≥ **4.5:1** (≥ 3:1 for large text); verify the brand palette and any status colors in
  **both** light and dark.
- Touch targets ≥ **48×48dp**; every interactive widget has a `Semantics` label conveying role + state
  (e.g. "Play recording, button"; "Due today, selected").
- Support OS **dynamic type up to 200%** without clipping — use `TextScaler`, avoid fixed heights, let
  text wrap.
- **Never color-alone** (restated because it's the most-missed): status, selection, categories, and chart
  series each need a non-color cue.
- Charts/visualizations expose a **text alternative** (a summary sentence + accessible values).
- Logical focus/reading order for screen readers; meaningful labels, not "button button button".

## Strings & i18n

All user-facing text via `flutter_localizations` + ARB files (`lib/l10n/app_en.arb`) — **no hardcoded
literals** in widgets. Dates/numbers via `intl`, locale- and timezone-aware. Ship English first, but
structure for more locales, and design layouts that survive ~30% text expansion (German/French) and the
longest realistic string.

```dart
Text(AppLocalizations.of(context).addFirstRecording);
```

## Widget testing the UI (keeps the loop deterministic)

These rules make screens host-testable without a device or a hung test (see `testing.md`):

- **Never `await tester.pumpAndSettle()` on a screen that can show a `CircularProgressIndicator`** — an
  indeterminate spinner never settles, so the call times out. Use `await tester.pump()` (one frame), or
  `pump(Duration(...))` to advance a known animation.
- Drive each `AsyncValue` branch by **overriding the controller's provider** with fixed data in a
  `ProviderScope` — don't hit a real repository. Assert the loading / error / empty / data UI per state.
- Give every interactive widget a stable `Semantics` label (also an a11y requirement) so tests find it
  by meaning, not by fragile text/position.
- Add a **golden test** per key screen state so visual regressions fail the suite (see `testing.md`).

## AI design self-review loop (do this before every UI PR)

Logic tests can't see the screen. You must **look at what you built and grade it** — this is the core
feedback loop. `/design-review` automates it; the steps:

1. **Render reality.** Run the app (or generate golden screenshots) and capture each affected screen in
   the states that matter: **light + dark**, **default + 200% text scale**, and **empty + populated**.
2. **Score against the rubric** (below). Be your own harshest critic — a senior product designer
   reviewing a paid app, not the author hoping it's fine.
3. **Fix everything under 4/5**, then re-render and re-score. Iterate until every row is ≥ 4 — or until
   the remaining gaps are genuine product/brand decisions, which you **take to the user** with options
   (see "Ask about design"). Don't silently ship a 2.
4. **Record** the final scorecard in the PR so the human reviewer sees what you checked.

### Design scorecard (fill this in — 1–5 each)

| # | Dimension | What a 5 looks like |
| - | --------- | ------------------- |
| 1 | Hierarchy & focus | One obvious focal point; scan path is immediate; secondary stuff is visually quiet |
| 2 | Spacing & alignment | Snaps to the 8-pt grid; generous margins; everything aligns to a shared edge |
| 3 | Typography | 4–6 styles, clear size/weight hierarchy, readable measure + line height |
| 4 | Color & theming | Restrained, semantic roles only, light/dark parity, contrast passes |
| 5 | Consistency | Matches the design system and sibling screens; reused components |
| 6 | States | Loading (skeleton) / empty (inviting CTA) / error (clear + retry) all designed; optimistic feedback |
| 7 | Motion & feedback | Every action acknowledged; transitions purposeful and fast; reduce-motion respected |
| 8 | Accessibility | Targets ≥ 48dp, contrast ≥ 4.5:1, Semantics labels, dynamic type, not color-alone |
| 9 | Microcopy | Clear, human, action-oriented verbs; friendly empty/error copy; no jargon |
| 10 | **Worth paying for?** | Honestly — does this screen feel like a polished, premium product? |

A screen ships when rows 1–10 are all ≥ 4 **and** row 10 is a confident yes. Otherwise: fix, or ask.

> For an independent eye, run the rubric as a **subagent** ("review these screenshots as a skeptical
> senior product designer; score each dimension and list concrete fixes") so the critique isn't graded by
> the same context that built it. `/design-review` does this for you.

## Ask about design — early and often

Visual and product-feel decisions are the user's to make, and they're expensive to redo. **Prefer
asking over assuming** whenever there's more than one reasonable direction. Ask well:

- **Show, don't describe.** Use `AskUserQuestion` with **option previews** (ASCII mockups, layout
  sketches, or alternative copy) so the user picks from concrete artifacts, not adjectives.
- **Batch** related design questions into one prompt (1–4), and lead with a **recommended** option.
- **Always ask before** committing to: brand direction (seed color / mood / personality), the layout of a
  key screen, navigation structure, onboarding/paywall framing, tone of voice, and any irreversible
  visual identity choice.
- Don't ask about things the design system already answers (which button style, what spacing) — apply the
  tokens and move on.

See `workflow.md` → "How to ask well" for the mechanics.
