// Catch-up milestone-assignment rule (T2.2, FR-1.2.3). Pure Dart — no device.
//
// A single 80%-play satisfies the HIGHEST milestone due as of the review day
// that isn't already reached; earlier missed ones are skipped, not made up.
// Returns null when nothing is due yet (early review) or every due milestone is
// already reached (a bonus re-review) — the event is still logged with a null
// milestone index so FR-1.2.4's review count reflects real engagement.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/gpa/domain/gpa_review.dart';

// Sunday 2026-03-15 — non-Jan/non-1st base keeps Duration offsets off the
// avoid_redundant_argument_values tripwire (DateTime ctor defaults).
final DateTime created = DateTime(2026, 3, 15);

void main() {
  group('milestoneIndexForReview — catch-up rule', () {
    test('satisfies the highest milestone due on a 30-day catch-up', () {
      // Day 30 (2026-04-14): milestones D+1..D+30 (indices 0..4) are due.
      final completed = created.add(const Duration(days: 30));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: -1,
        ),
        4,
      );
    });

    test('returns null when every due milestone is already reached', () {
      final completed = created.add(const Duration(days: 30));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: 4,
        ),
        isNull,
      );
    });

    test('same-day review (before D+1) earns no milestone -> null', () {
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: created,
          reachedPrior: -1,
        ),
        isNull,
      );
    });

    test('first due day (D+1) satisfies milestone 0', () {
      final completed = created.add(const Duration(days: 1));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: -1,
        ),
        0,
      );
    });

    test('advances to the next rung when prior milestones are reached', () {
      // Day 90 (2026-06-13): D+90 (index 5) newly due, indices 0..4 reached.
      final completed = created.add(const Duration(days: 90));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: 4,
        ),
        5,
      );
    });

    test('returns null when caught up through the latest due rung', () {
      final completed = created.add(const Duration(days: 90));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: 5,
        ),
        isNull,
      );
    });

    test('on the exact D+7 due day, satisfies index 3', () {
      final completed = created.add(const Duration(days: 7));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: -1,
        ),
        3,
      );
    });

    test(
      'day boundary: 00:01 on D+1 earns milestone 0; 23:59 on day 0 does not',
      () {
        // 23:59 still on day 0 -> nothing due.
        expect(
          milestoneIndexForReview(
            createdAt: created,
            completedAt: DateTime(2026, 3, 15, 23, 59),
            reachedPrior: -1,
          ),
          isNull,
        );
        // 00:01 on day 1 -> D+1 due.
        expect(
          milestoneIndexForReview(
            createdAt: created,
            completedAt: DateTime(2026, 3, 16, 0, 1),
            reachedPrior: -1,
          ),
          0,
        );
      },
    );

    test('time-of-day within the same day does not change the result', () {
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: DateTime(2026, 4, 14),
          reachedPrior: -1,
        ),
        4,
      );
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: DateTime(2026, 4, 14, 23, 59),
          reachedPrior: -1,
        ),
        4,
      );
    });

    test('honours a custom interval ladder', () {
      // Ladder [1, 3]: D+1 due on 03-16, D+3 due on 03-18. On 03-17 only
      // D+1 is due -> index 0.
      final completed = created.add(const Duration(days: 2));
      expect(
        milestoneIndexForReview(
          createdAt: created,
          completedAt: completed,
          reachedPrior: -1,
          intervals: const [1, 3],
        ),
        0,
      );
    });
  });
}
