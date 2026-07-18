// Streak engine — M11 T11.3 (AC 3). Pure Dart; no device. Pins the canonical
// rules: the consecutive-day count, the asOf-1 endpoint, 1-day-gap freeze
// collapse, the >=2-day break, and the once-per-ISO-week cap-1 auto-grant.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/progress/domain/streak_engine.dart';

// 2026-07-15 (Wed) — asOf for every case. Review timestamps can carry any
// time; only the calendar day matters.
final DateTime _asOf = DateTime(2026, 7, 15);
DateTime _d(int offset) => _asOf.add(Duration(days: offset));

// 2026-01-01 (Thu) — the canonical "ISO week 1 Thursday" anchor. Month/day
// default to 1, hence the ignore; the literal Jan 1 IS the point of the test.
// ignore: avoid_redundant_argument_values
final DateTime _jan1 = DateTime(2026, 1, 1);

void main() {
  group('computeStreak', () {
    test('a 3-day run counts 3', () {
      final r = computeStreak(
        reviewDays: [_d(0), _d(-1), _d(-2)],
        asOf: _asOf,
        freezesBanked: 0,
      );
      expect(r.count, 3);
      expect(r.freezesConsumed, 0);
    });

    test(
      'today not yet reviewed: streak continues from yesterday (asOf-1)',
      () {
        final r = computeStreak(
          reviewDays: [_d(-1), _d(-2)],
          asOf: _asOf,
          freezesBanked: 0,
        );
        expect(r.count, 2);
      },
    );

    test('neither today nor yesterday reviewed -> streak 0', () {
      final r = computeStreak(
        reviewDays: [_d(-2), _d(-3)], // gap to yesterday
        asOf: _asOf,
        freezesBanked: 1,
      );
      expect(r.count, 0);
      expect(r.freezesConsumed, 0);
    });

    test('empty ledger -> streak 0', () {
      final r = computeStreak(
        reviewDays: const [],
        asOf: _asOf,
        freezesBanked: 1,
      );
      expect(r.count, 0);
    });

    test(
      'a 1-day gap with a banked freeze continues (counts the frozen day)',
      () {
        // today + (yesterday frozen) + d-2 reviewed.
        final r = computeStreak(
          reviewDays: [_d(0), _d(-2)],
          asOf: _asOf,
          freezesBanked: 1,
        );
        expect(r.count, 3);
        expect(r.freezesConsumed, 1);
      },
    );

    test('a 1-day gap with NO freeze breaks at today', () {
      final r = computeStreak(
        reviewDays: [_d(0), _d(-2)],
        asOf: _asOf,
        freezesBanked: 0,
      );
      expect(r.count, 1);
      expect(r.freezesConsumed, 0);
    });

    test('a >=2-day gap breaks even with a freeze banked', () {
      // today, then nothing for d-1 AND d-2, d-3 reviewed. Two-day gap — a
      // single freeze can't bridge it.
      final r = computeStreak(
        reviewDays: [_d(0), _d(-3)],
        asOf: _asOf,
        freezesBanked: 1,
      );
      expect(r.count, 1);
      expect(r.freezesConsumed, 0);
    });

    test('a freeze mid-streak extends it across one gap', () {
      // today, d-1, [d-2 frozen], d-3, d-4.
      final r = computeStreak(
        reviewDays: [_d(0), _d(-1), _d(-3), _d(-4)],
        asOf: _asOf,
        freezesBanked: 1,
      );
      expect(r.count, 5);
      expect(r.freezesConsumed, 1);
    });

    test(
      'consumes one freeze per collapsible gap, up to the bank (no engine cap)',
      () {
        // The engine doesn't enforce the cap — it consumes from the param.
        // The cap lives at grant time ([shouldAutoGrantFreeze]). Two banked,
        // two 1-day gaps -> both bridge. (In production the service never
        // banks > 1, so this is a determinism guard, not a real path.)
        final r = computeStreak(
          reviewDays: [_d(0), _d(-2), _d(-4), _d(-5)],
          asOf: _asOf,
          freezesBanked: 2,
        );
        // today + [d-1 frozen] + d-2 + [d-3 frozen] + d-4 + d-5.
        expect(r.count, 6);
        expect(r.freezesConsumed, 2);
      },
    );

    test('negative banked clamps to 0 (corrupt KV defends)', () {
      final r = computeStreak(
        reviewDays: [_d(0), _d(-2)],
        asOf: _asOf,
        freezesBanked: -3,
      );
      expect(r.count, 1); // gap, no freeze applied
      expect(r.freezesConsumed, 0);
    });

    test('ignores time-of-day on review timestamps (calendar day only)', () {
      final r = computeStreak(
        reviewDays: [
          DateTime(2026, 7, 15, 23, 59),
          DateTime(2026, 7, 14, 0, 1),
          DateTime(2026, 7, 13, 12),
        ],
        asOf: _asOf,
        freezesBanked: 0,
      );
      expect(r.count, 3);
    });
  });

  group('isoWeekId', () {
    test('2026-01-01 (Thursday) is ISO week 1', () {
      expect(isoWeekId(_jan1), 202601);
    });

    test('straddles New Year: 2025-12-31 shares week 1 of 2026', () {
      // Wed 2025-12-31 and Thu 2026-01-01 are the same ISO week.
      expect(isoWeekId(DateTime(2025, 12, 31)), isoWeekId(_jan1));
      expect(isoWeekId(DateTime(2025, 12, 31)), 202601);
    });

    test('all seven days of one week share an id', () {
      // Mon 2026-07-13 .. Sun 2026-07-19.
      final ids = [
        for (var i = 0; i < 7; i++)
          isoWeekId(DateTime(2026, 7, 13).add(Duration(days: i))),
      ];
      expect(ids.toSet().length, 1);
    });

    test('is monotonic across the week boundary', () {
      final thisWeek = isoWeekId(DateTime(2026, 7, 15));
      final nextWeek = isoWeekId(DateTime(2026, 7, 22));
      expect(nextWeek, greaterThan(thisWeek));
    });
  });

  group('shouldAutoGrantFreeze', () {
    test('grants when in a new ISO week and banked is below cap', () {
      expect(
        shouldAutoGrantFreeze(
          currentWeekId: 202631,
          lastGrantWeekId: 202630,
          banked: 0,
        ),
        isTrue,
      );
    });

    test('does NOT grant twice in the same ISO week', () {
      expect(
        shouldAutoGrantFreeze(
          currentWeekId: 202630,
          lastGrantWeekId: 202630,
          banked: 0,
        ),
        isFalse,
      );
    });

    test('does NOT grant when the bank is already at the cap', () {
      expect(
        shouldAutoGrantFreeze(
          currentWeekId: 202631,
          lastGrantWeekId: 202630,
          banked: maxBankedFreezes,
        ),
        isFalse,
      );
    });

    test(
      'never goes backwards: an older last-grant week still grants once',
      () {
        // A few weeks since the last grant — still just one grant now (cap-1).
        expect(
          shouldAutoGrantFreeze(
            currentWeekId: 202640,
            lastGrantWeekId: 202630,
            banked: 0,
          ),
          isTrue,
        );
      },
    );
  });
}
