// Queue warm-up selector tests (T7.1). Pure — builds [RecordingReviewStatus]
// directly with a controlled active-milestone due day so the day-math is
// independent of the GPA derivation (covered in its own suite). `overdue` is
// the active milestone's daysOverdue at asOf: 0 = due today, 1 = 1-day-stale,
// -1 = due tomorrow, <= -2 = further future.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/gpa/domain/gpa_intervals.dart';
import 'package:rivendell/features/gpa/domain/queue_warmup.dart';
import 'package:rivendell/features/gpa/domain/review_status.dart';

final DateTime asOf = DateTime(2026, 6, 30);

GpaMilestone _m({required int index, required int overdue}) {
  final dueOn = asOf.add(Duration(days: -overdue));
  return GpaMilestone(
    index: index,
    intervalDays: gpaIntervalsInDays[index],
    dueOn: dueOn,
  );
}

WarmCandidate _c({required int id, required int? overdue, int index = 1}) {
  final active = overdue == null ? null : _m(index: index, overdue: overdue);
  return WarmCandidate(
    id: id,
    status: RecordingReviewStatus(
      milestoneReached: active == null ? 7 : active.index - 1,
      reviewCount: 0,
      lastReviewed: null,
      activeMilestone: active,
      activeMilestoneDue: active != null && overdue! >= 0,
      isComplete: active == null,
    ),
  );
}

void main() {
  group('warmUpQueue', () {
    test('empty input yields empty today + tomorrow', () {
      final q = warmUpQueue(all: const [], asOf: asOf);
      expect(q.today, isEmpty);
      expect(q.tomorrow, isEmpty);
    });

    test('complete recordings (no active milestone) are excluded', () {
      final q = warmUpQueue(
        all: [_c(id: 1, overdue: null), _c(id: 2, overdue: null)],
        asOf: asOf,
      );
      expect(q.today, isEmpty);
      expect(q.tomorrow, isEmpty);
    });

    test('strict due-today at the floor gets no top-up', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: 0),
          _c(id: 3, overdue: 0),
        ],
        asOf: asOf,
      );
      // Same due day → id-desc tiebreak (newest-first).
      expect(q.today.map((s) => s.candidate.id), [3, 2, 1]);
      expect(q.today.every((s) => s.placement == WarmPlacement.due), isTrue);
      expect(q.tomorrow, isEmpty);
    });

    test('today below floor is topped up from the soonest upcoming', () {
      // One due today; four further-future (due in 3..6 days).
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: -3),
          _c(id: 3, overdue: -4),
          _c(id: 4, overdue: -5),
          _c(id: 5, overdue: -6),
        ],
        asOf: asOf,
      );
      // Today filled to floor=3: the one due item + the two soonest upcoming.
      expect(q.today.map((s) => s.candidate.id), [1, 2, 3]);
      expect(q.today[0].placement, WarmPlacement.due);
      expect(q.today[1].placement, WarmPlacement.upNext);
      expect(q.today[2].placement, WarmPlacement.upNext);
      // Tomorrow takes the remaining share (both further-future → up next).
      expect(q.tomorrow.map((s) => s.candidate.id), [4, 5]);
      expect(
        q.tomorrow.every((s) => s.placement == WarmPlacement.upNext),
        isTrue,
      );
    });

    test(
      'day-one library: today warmed from due-tomorrow items, rest to tomorrow',
      () {
        // Five recordings indexed today — every active milestone is D+1, due
        // tomorrow (overdue -1). Strict today is empty, so today must be warmed
        // from the upcoming set (this is the M7 AC 1 core scenario).
        final q = warmUpQueue(
          all: [
            _c(id: 1, overdue: -1),
            _c(id: 2, overdue: -1),
            _c(id: 3, overdue: -1),
            _c(id: 4, overdue: -1),
            _c(id: 5, overdue: -1),
          ],
          asOf: asOf,
        );
        // Soonest first (all same due day) → id desc; today eats the top 3.
        expect(q.today.map((s) => s.candidate.id), [5, 4, 3]);
        expect(
          q.today.every((s) => s.placement == WarmPlacement.upNext),
          isTrue,
        );
        // Remaining two are still genuinely due tomorrow → placement 'due'.
        expect(q.tomorrow.map((s) => s.candidate.id), [2, 1]);
        expect(
          q.tomorrow.every((s) => s.placement == WarmPlacement.due),
          isTrue,
        );
      },
    );

    test(
      'due-tomorrow item lands in Tomorrow (not Today) when today at floor',
      () {
        final q = warmUpQueue(
          all: [
            _c(id: 1, overdue: 0),
            _c(id: 2, overdue: 0),
            _c(id: 3, overdue: 0),
            _c(id: 4, overdue: -1),
          ],
          asOf: asOf,
        );
        // Today strict already at floor=3 (id desc) → no top-up.
        expect(q.today.map((s) => s.candidate.id), [3, 2, 1]);
        // The due-tomorrow item survives into tomorrow as a real 'due' row.
        expect(q.tomorrow.map((s) => s.candidate.id), [4]);
        expect(q.tomorrow.single.placement, WarmPlacement.due);
      },
    );

    test('a candidate is never shown in both windows', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0), // today
          _c(id: 2, overdue: -1), // tomorrow
          _c(id: 3, overdue: -3),
          _c(id: 4, overdue: -4),
          _c(id: 5, overdue: -5),
        ],
        asOf: asOf,
      );
      final todayIds = q.today.map((s) => s.candidate.id).toSet();
      final tomorrowIds = q.tomorrow.map((s) => s.candidate.id).toSet();
      expect(todayIds.intersection(tomorrowIds), isEmpty);
    });

    test('1-day-stale rows land in today and sort first', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0), // due today
          _c(id: 2, overdue: 1), // stale
          _c(id: 3, overdue: 0), // due today
        ],
        asOf: asOf,
      );
      // Stale (id 2) leads, then the two due-today by id desc (3 before 1).
      expect(q.today.map((s) => s.candidate.id), [2, 3, 1]);
      expect(q.today.first.isStale, isTrue);
      expect(q.today[1].isStale, isFalse);
    });

    test('2+ day stale recordings are excluded entirely', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 2), // too stale — dropped
          _c(id: 2, overdue: 5), // too stale — dropped
          _c(id: 3, overdue: 0), // due today
        ],
        asOf: asOf,
      );
      expect(q.today.map((s) => s.candidate.id), [3]);
      expect(q.tomorrow, isEmpty);
    });

    test('floor override changes the top-up target', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: -3),
          _c(id: 3, overdue: -4),
          _c(id: 4, overdue: -5),
          _c(id: 5, overdue: -6),
        ],
        asOf: asOf,
        floor: 4,
      );
      expect(q.today.map((s) => s.candidate.id), [1, 2, 3, 4]);
    });

    test(
      'fewer candidates than floor shows what exists without fabricating',
      () {
        final q = warmUpQueue(
          all: [_c(id: 1, overdue: 0), _c(id: 2, overdue: -3)],
          asOf: asOf,
        );
        expect(q.today.map((s) => s.candidate.id), [1, 2]);
        expect(q.tomorrow, isEmpty);
      },
    );

    test('up-next ordering is soonest-due first within upcoming', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: -10),
          _c(id: 3, overdue: -3),
          _c(id: 4, overdue: -5),
        ],
        asOf: asOf,
      );
      // Today: due item + upcoming soonest-first by dueOn asc (3, 4, 2).
      expect(q.today.map((s) => s.candidate.id), [1, 3, 4]);
    });
  });
}
