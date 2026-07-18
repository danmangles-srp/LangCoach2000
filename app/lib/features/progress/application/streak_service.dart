// StreakService (M11 T11.3) — the impure glue over the pure streak engine.
// Owns the ONE piece of mutable streak state: the freeze bank, kept in
// `key_values`. The streak COUNT itself is derived on every call from the
// append-only `review_events` ledger (ReviewEventRepository.eventTimestamps)
// — there is no streak counter to drift out of sync.
//
// Flow per [snapshot]:
//   1. read banked + last-grant week from KV (default 0 / 0)
//   2. apply the once-per-ISO-week auto-grant ([shouldAutoGrantFreeze]) — pure
//      decision, persisted here
//   3. pull review timestamps across the lookback window
//   4. [computeStreak] — pure math
//   5. persist banked - consumed, return the snapshot for the dashboard

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/progress/domain/streak_engine.dart';

const _kBanked = 'progress.streak_freezes_banked';
const _kLastGrantWeek = 'progress.streak_freezes_last_grant_week';

class StreakService {
  StreakService({required this.kv, required this.reviews, required this.now});

  final KvRepository kv;
  final ReviewEventRepository reviews;
  final DateTime Function() now;

  /// The current streak + banked-freeze balance, derived from the review
  /// ledger. Side-effecting: may persist an auto-grant and/or the consumed
  /// balance. Idempotent — calling twice in the same minute yields the same
  /// snapshot (the grant is week-gated; the consume is deterministic).
  Future<StreakSnapshot> snapshot() async {
    final asOf = now();
    var banked = await _readInt(_kBanked);
    var lastGrant = await _readInt(_kLastGrantWeek);
    final currentWeek = isoWeekId(asOf);

    // Once-per-ISO-week auto-grant. Persists immediately so a second call in
    // the same week doesn't re-grant.
    if (shouldAutoGrantFreeze(
      currentWeekId: currentWeek,
      lastGrantWeekId: lastGrant,
      banked: banked,
    )) {
      banked = maxBankedFreezes;
      lastGrant = currentWeek;
      await _writeInt(_kBanked, banked);
      await _writeInt(_kLastGrantWeek, lastGrant);
    }

    // Half-open [from, until): includes asOf's own day, excludes tomorrow.
    final from = asOf.subtract(const Duration(days: streakLookbackDays));
    final until = asOf.add(const Duration(days: 1));
    final timestamps = await reviews.eventTimestamps(from, until);

    final result = computeStreak(
      reviewDays: timestamps,
      asOf: asOf,
      freezesBanked: banked,
    );

    final newBanked = (banked - result.freezesConsumed).clamp(
      0,
      maxBankedFreezes,
    );
    if (newBanked != banked) {
      await _writeInt(_kBanked, newBanked);
    }

    return StreakSnapshot(count: result.count, freezesBanked: newBanked);
  }

  Future<int> _readInt(String key) async {
    final raw = await kv.read(key);
    if (raw == null) return 0;
    return int.tryParse(raw) ?? 0;
  }

  Future<void> _writeInt(String key, int value) =>
      kv.write(key, value.toString());
}
