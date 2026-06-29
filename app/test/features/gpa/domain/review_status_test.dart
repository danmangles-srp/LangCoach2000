// Review-history derivation (T2.3, FR-1.2.4). Pure Dart over a recording's
// event log — no store, no device. Validates last-reviewed, milestone reached
// (high-water), review count, the active (next-unreached) milestone, due-ness,
// and completion. Feeds T2.4 (today's queue) and T2.6 (detail timeline).

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/gpa/domain/review_status.dart';

// 2026-03-15 — non-Jan/non-1st base keeps Duration offsets off the
// avoid_redundant_argument_values tripwire.
final DateTime created = DateTime(2026, 3, 15);

ReviewLogEntry _event({int? milestone, DateTime? at}) =>
    ReviewLogEntry(milestoneIndex: milestone, completedAt: at ?? created);

void main() {
  group('computeReviewStatus — no events', () {
    test('reached is -1, count 0, first milestone is active + not yet due', () {
      final status = computeReviewStatus(
        createdAt: created,
        events: const [],
        asOf: created,
      );
      expect(status.milestoneReached, -1);
      expect(status.reviewCount, 0);
      expect(status.lastReviewed, isNull);
      expect(status.activeMilestone?.index, 0); // D+1
      expect(status.isComplete, isFalse);
    });

    test('active first milestone is due the day after creation', () {
      final status = computeReviewStatus(
        createdAt: created,
        events: const [],
        asOf: created.add(const Duration(days: 1)),
      );
      expect(status.activeMilestone?.index, 0);
      expect(status.activeMilestoneDue, isTrue);
    });
  });

  group('computeReviewStatus — catch-up high-water', () {
    test('a milestone-4 event advances reached to 4; active becomes 5', () {
      final status = computeReviewStatus(
        createdAt: created,
        events: [
          _event(milestone: 4, at: created.add(const Duration(days: 30))),
        ],
        asOf: created.add(const Duration(days: 30)),
      );
      expect(status.milestoneReached, 4);
      expect(status.reviewCount, 1);
      expect(status.activeMilestone?.index, 5); // D+90
      expect(status.activeMilestoneDue, isFalse); // D+90 not due on day 30
      expect(status.isComplete, isFalse);
    });

    test('active milestone becomes due once its day arrives', () {
      final status = computeReviewStatus(
        createdAt: created,
        events: [
          _event(milestone: 4, at: created.add(const Duration(days: 30))),
        ],
        asOf: created.add(const Duration(days: 90)),
      );
      expect(status.activeMilestone?.index, 5);
      expect(status.activeMilestoneDue, isTrue);
    });
  });

  group('computeReviewStatus — bonus / null events', () {
    test('a null-milestone event counts but does not advance reached', () {
      final status = computeReviewStatus(
        createdAt: created,
        events: [_event(at: created.add(const Duration(days: 5)))],
        asOf: created.add(const Duration(days: 5)),
      );
      expect(status.milestoneReached, -1);
      expect(status.reviewCount, 1);
      expect(status.activeMilestone?.index, 0); // still the first
    });
  });

  group('computeReviewStatus — aggregates', () {
    test(
      'reached is the max non-null index; lastReviewed the latest completedAt',
      () {
        final day30 = created.add(const Duration(days: 30));
        final day90 = created.add(const Duration(days: 90));
        final status = computeReviewStatus(
          createdAt: created,
          events: [
            _event(milestone: 4, at: day30),
            _event(at: day90), // bonus
            _event(milestone: 5, at: day90),
          ],
          asOf: day90,
        );
        expect(status.milestoneReached, 5);
        expect(status.reviewCount, 3);
        expect(status.lastReviewed, day90);
      },
    );
  });

  group('computeReviewStatus — completion', () {
    test(
      'reaching the last milestone leaves no active milestone + isComplete',
      () {
        final status = computeReviewStatus(
          createdAt: created,
          events: [
            _event(milestone: 7, at: created.add(const Duration(days: 365))),
          ],
          asOf: created.add(const Duration(days: 365)),
        );
        expect(status.milestoneReached, 7);
        expect(status.activeMilestone, isNull);
        expect(status.activeMilestoneDue, isFalse);
        expect(status.isComplete, isTrue);
      },
    );
  });

  group('classifyQueueEntry — FR-1.2.5 stale rule', () {
    // A recording created 2026-03-15 whose active milestone is D+1 (due 03-16)
    // is the workhorse case; vary asOf to move across the stale window.
    RecordingReviewStatus freshStatus(DateTime asOf) =>
        computeReviewStatus(createdAt: created, events: const [], asOf: asOf);

    test('active milestone due today (0 days overdue) -> dueToday', () {
      // D+1 due 03-16; asOf 03-16 -> due today.
      expect(
        classifyQueueEntry(
          freshStatus(created.add(const Duration(days: 1))),
          asOf: created.add(const Duration(days: 1)),
        ),
        QueueEntryKind.dueToday,
      );
    });

    test('1 day overdue -> stale (still in queue, grace window)', () {
      // asOf 03-17 -> D+1 is 1 day overdue.
      expect(
        classifyQueueEntry(
          freshStatus(created.add(const Duration(days: 2))),
          asOf: created.add(const Duration(days: 2)),
        ),
        QueueEntryKind.stale,
      );
    });

    test('2 days overdue -> excluded (stale prompt disappears)', () {
      // asOf 03-18 -> D+1 is 2 days overdue.
      expect(
        classifyQueueEntry(
          freshStatus(created.add(const Duration(days: 3))),
          asOf: created.add(const Duration(days: 3)),
        ),
        QueueEntryKind.excluded,
      );
    });

    test('not yet due (future) -> excluded', () {
      // asOf 03-15 (creation day) -> D+1 due tomorrow, not yet due.
      expect(
        classifyQueueEntry(freshStatus(created), asOf: created),
        QueueEntryKind.excluded,
      );
    });

    test('complete (no active milestone) -> excluded', () {
      final status = computeReviewStatus(
        createdAt: created,
        events: [
          _event(milestone: 7, at: created.add(const Duration(days: 365))),
        ],
        asOf: created.add(const Duration(days: 400)),
      );
      expect(
        classifyQueueEntry(
          status,
          asOf: created.add(const Duration(days: 400)),
        ),
        QueueEntryKind.excluded,
      );
    });
  });
}
