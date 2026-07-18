// Pure-Dart level engine + source enum (M11 T11.1). The level/progress math
// is the one bit of XP logic that is fully testable without a device — banding
// at 500, the into-level remainder, the negative-total clamp, and the
// source-column round trip. The xp_events table itself is declarative schema
// (coverage-excluded).

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/progress/domain/xp_level.dart';

void main() {
  group('levelFromTotalXp', () {
    test('0 xp is level 0', () {
      expect(levelFromTotalXp(0), 0);
    });

    test('499 xp is still level 0 (just under the band edge)', () {
      expect(levelFromTotalXp(499), 0);
    });

    test('500 xp crosses into level 1', () {
      expect(levelFromTotalXp(500), 1);
    });

    test('999 xp is still level 1', () {
      expect(levelFromTotalXp(999), 1);
    });

    test('1000 xp crosses into level 2', () {
      expect(levelFromTotalXp(1000), 2);
    });

    test('a negative total clamps to level 0', () {
      expect(levelFromTotalXp(-50), 0);
      // -600 ~/ 500 is -1 unclamped (truncates toward zero) — must not leak.
      expect(levelFromTotalXp(-600), 0);
    });
  });

  group('xpIntoLevel', () {
    test('0 xp has 0 into the level', () {
      expect(xpIntoLevel(0), 0);
    });

    test('499 xp is 499 into the level', () {
      expect(xpIntoLevel(499), 499);
    });

    test('500 xp wraps to 0 into the next level', () {
      expect(xpIntoLevel(500), 0);
    });

    test('750 xp is 250 into the level', () {
      expect(xpIntoLevel(750), 250);
    });

    test('a negative total clamps to 0 into the level', () {
      // Dart's % takes the dividend's sign, so -50 % 500 is -50 unclamped.
      expect(xpIntoLevel(-50), 0);
      expect(xpIntoLevel(-600), 0);
    });
  });

  group('XpSource', () {
    test('columnValue is stable for every awarding action', () {
      expect(XpSource.review.columnValue, 'review');
      expect(XpSource.wordlog.columnValue, 'wordlog');
      expect(XpSource.anki.columnValue, 'anki');
      expect(XpSource.task.columnValue, 'task');
      expect(XpSource.reading.columnValue, 'reading');
      expect(XpSource.movie.columnValue, 'movie');
    });

    test('fromColumn round-trips every source', () {
      for (final source in XpSource.values) {
        expect(XpSource.fromColumn(source.columnValue), source);
      }
    });

    test('fromColumn throws ArgumentError on an unknown string', () {
      expect(() => XpSource.fromColumn('nope'), throwsArgumentError);
    });
  });
}
