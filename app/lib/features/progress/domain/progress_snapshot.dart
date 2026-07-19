// ProgressSnapshot (M11 T11.5, AC 1/3/4) — the derived view the dashboard card
// + AppBar chip read. Folds the XP ledger sum (XpRepository.total) and the
// streak result (StreakService.snapshot) into one value the UI can watch via a
// single provider. Pure value type: level + xpIntoLevel are banded here from
// the raw total so the widget never re-derives them. XP is informational; no
// surface gates on a snapshot field (plan M11).

import 'package:rivendell/features/progress/domain/xp_level.dart' as xp;

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.streakCount,
    required this.freezesBanked,
  });

  /// Build a snapshot from a raw XP total + a streak result. The level banding
  /// (levelFromTotalXp / xpIntoLevel) lives here so callers pass primitives.
  factory ProgressSnapshot.fromLedger({
    required int totalXp,
    required int streakCount,
    required int freezesBanked,
  }) {
    return ProgressSnapshot(
      totalXp: totalXp,
      level: xp.levelFromTotalXp(totalXp),
      xpIntoLevel: xp.xpIntoLevel(totalXp),
      streakCount: streakCount,
      freezesBanked: freezesBanked,
    );
  }

  final int totalXp;
  final int level;
  final int xpIntoLevel;
  final int streakCount;
  final int freezesBanked;

  /// Zeroed snapshot for the loading state before the ledger resolves.
  static const ProgressSnapshot empty = ProgressSnapshot(
    totalXp: 0,
    level: 0,
    xpIntoLevel: 0,
    streakCount: 0,
    freezesBanked: 0,
  );
}
