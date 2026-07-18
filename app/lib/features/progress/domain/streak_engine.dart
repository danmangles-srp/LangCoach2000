// Streak + freeze engine (M11 T11.3, AC 3). Pure Dart — no IO, no
// [DateTime.now]. The streak is a DERIVED view over the append-only
// `review_events` ledger (the day-set of every review's `completedAt`); only
// the freeze bank is mutable state (lives in `key_values`, see
// [StreakService]). Keeping the math here means every edge — gaps, freezes,
// the ISO-week auto-grant — is provable without a device.
//
// Rules (canonical — don't change without asking):
//   * A streak is consecutive calendar days with >= 1 review, ending on [asOf]
//     (or [asOf] - 1 when [asOf] itself has no review, so "today not yet
//     reviewed" doesn't read as a break). If NEITHER has a review, the streak
//     is 0 — there's nothing to continue.
//   * A single missed day (a 1-day gap with a real review on the far side) is
//     collapsible: it consumes ONE banked freeze and the streak continues
//     across it (the frozen day counts as preserved).
//   * A gap of >= 2 days breaks the streak regardless of freezes — a freeze
//     preserves ONE day, not a desert.
//   * Freezes auto-grant at most one per ISO 8601 week, and only when the bank
//     is below the cap ([maxBankedFreezes] = 1). The grant DECISION is pure
//     ([shouldAutoGrantFreeze]); the write is [StreakService]'s job.

/// Compact, comparable ISO-week id: `year * 100 + week` (e.g. `202631`). The
/// year is the ISO week-numbering year (the year of the week's Thursday), so a
/// week straddling New Year keeps a single monotonic id — `202653 < 202701`.
typedef IsoWeekId = int;

/// Hard cap on banked freezes (M11): at most one stored at a time.
const int maxBankedFreezes = 1;

/// How far back StreakService should pull review timestamps. Generous — a
/// streak can run a full GPA cycle (max interval 365) plus preserved gaps, and
/// the compute stops at the first break anyway.
const int streakLookbackDays = 400;

/// The pure output of [computeStreak]: how long the run is, and how many
/// freezes the gap-collapsing ate (so the caller can persist the new bank
/// balance).
class StreakResult {
  const StreakResult({required this.count, required this.freezesConsumed});

  /// Consecutive days in the streak (frozen gap days counted as preserved).
  final int count;

  /// Freezes spent collapsing 1-day gaps this compute. Subtract from the bank.
  final int freezesConsumed;
}

/// The view the dashboard renders (T11.5): streak length + the banked freeze
/// balance AFTER this compute (grants applied, consumed subtracted).
class StreakSnapshot {
  const StreakSnapshot({required this.count, required this.freezesBanked});

  final int count;
  final int freezesBanked;
}

/// Normalize a [DateTime] to its calendar day (drops time). Used for the
/// review day-set and all comparisons, so DST wobble at midnight can't make two
/// "same day" timestamps compare unequal.
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// ISO 8601 week id for [d] (Thursday-defines-the-week algorithm). Monotonic
/// across year boundaries: week 1 of 2027 (id `202701`) sorts after week 53 of
/// 2026 (id `202653`). Pure.
IsoWeekId isoWeekId(DateTime d) {
  final weekday = d.weekday; // Mon=1 .. Sun=7
  final thursday = DateTime(
    d.year,
    d.month,
    d.day + (DateTime.thursday - weekday),
  );
  // Jan 4th is always in ISO week 1 — anchor to its week's Thursday.
  final jan4 = DateTime(thursday.year, 1, 4);
  final week1Thursday = DateTime(
    jan4.year,
    jan4.month,
    jan4.day + (DateTime.thursday - jan4.weekday),
  );
  final week = (thursday.difference(week1Thursday).inDays ~/ 7) + 1;
  return thursday.year * 100 + week;
}

/// Whether a freeze should auto-grant this week. Pure — the caller persists the
/// resulting bank/last-grant stamps. Fires at most once per ISO week (current
/// strictly greater than last-grant) and only when the bank is below the cap.
bool shouldAutoGrantFreeze({
  required IsoWeekId currentWeekId,
  required IsoWeekId lastGrantWeekId,
  required int banked,
}) {
  return currentWeekId > lastGrantWeekId && banked < maxBankedFreezes;
}

/// Compute the streak. Pure. See file header for the rules. [reviewDays] are
/// the `completedAt` timestamps of every review event in the lookback window
/// (time is ignored — only the calendar day matters). [asOf] is usually today.
/// [freezesBanked] is the bank balance AFTER any auto-grant the caller applied.
StreakResult computeStreak({
  required List<DateTime> reviewDays,
  required DateTime asOf,
  required int freezesBanked,
}) {
  final days = <DateTime>{for (final d in reviewDays) dayOf(d)};
  final today = dayOf(asOf);

  DateTime prevOf(DateTime day) => DateTime(day.year, day.month, day.day - 1);

  // Endpoint: the streak ends today, or yesterday if today has no review. If
  // neither has one, there's no live streak to extend.
  late DateTime cursor;
  if (days.contains(today)) {
    cursor = today;
  } else if (days.contains(prevOf(today))) {
    cursor = prevOf(today);
  } else {
    return const StreakResult(count: 0, freezesConsumed: 0);
  }

  var count = 1;
  var freezesConsumed = 0;
  var remaining = freezesBanked < 0 ? 0 : freezesBanked;

  while (true) {
    final gapDay = prevOf(cursor); // the day immediately before the cursor
    if (days.contains(gapDay)) {
      count++;
      cursor = gapDay;
      continue;
    }
    // gapDay is missing. Is it a collapsible 1-day gap? Only if a freeze is
    // banked AND the day beyond the gap is a real review day.
    final beyondGap = prevOf(gapDay);
    if (remaining > 0 && days.contains(beyondGap)) {
      remaining--;
      freezesConsumed++;
      count += 2; // the frozen gap day + the real day beyond it
      cursor = beyondGap;
      continue;
    }
    break;
  }

  return StreakResult(count: count, freezesConsumed: freezesConsumed);
}
