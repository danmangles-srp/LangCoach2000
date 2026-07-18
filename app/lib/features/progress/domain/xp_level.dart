// XP level engine (M11, AC 1). XP is a derived view: the total is the sum of
// an append-only `xp_events` ledger, and the level is banded at a fixed
// 500-XP step. There is no hand-edited counter (decision #9) — call
// [levelFromTotalXp] / [xpIntoLevel] with the ledger sum whenever the UI
// needs to render progress. Pure Dart so the banding math is unit-testable
// without a device.

/// XP required to gain one level. Pinned by the M11 plan; changing it is a
/// product decision, not a refactor.
const int xpPerLevel = 500;

int _clampNonNegative(int total) => total < 0 ? 0 : total;

/// Level = floor(total / 500). A negative total — impossible from the ledger
/// (points are non-negative, the sum only grows) but defended against a
/// corrupt or hand-built sum — clamps to level 0 instead of going negative
/// (Dart's `~/` truncates toward zero, so -600 ~/ 500 would be -1 unclamped).
int levelFromTotalXp(int total) => _clampNonNegative(total) ~/ xpPerLevel;

/// XP earned toward the next level, in [0, 499]. Same negative clamp: Dart's
/// `%` takes the dividend's sign, so an unclamped negative total would yield a
/// negative remainder.
int xpIntoLevel(int total) => _clampNonNegative(total) % xpPerLevel;

/// The actions that earn XP (M11 AC 2 — the five awarding sites). Persisted as
/// the `source` column of an xp_events row. Stable strings so renaming a Dart
/// enum value never corrupts old rows; [fromColumn] is the read side.
enum XpSource {
  review('review'),
  wordlog('wordlog'),
  anki('anki'),
  task('task'),
  reading('reading'),
  movie('movie');

  const XpSource(this.columnValue);

  /// The string persisted in the `source` column. Stable across renames.
  final String columnValue;

  static XpSource fromColumn(String value) => XpSource.values.firstWhere(
    (s) => s.columnValue == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'unknown XpSource'),
  );
}
