// Queue selector tests (T14.1, amending M10 AC4–5). Today is a 2-week backlog:
// any recording whose active milestone became due in the last 14 days (overdue
// 0..13), most-overdue first, capped at 4. The stale distinction is gone —
// every Today row is simply "due". Tomorrow stays strict-only (overdue == -1
// exactly). Pure — builds [RecordingReviewStatus] directly with a controlled
// active-milestone due day so the day-math is independent of the GPA derivation
// (covered in its own suite). `overdue` is the active milestone's daysOverdue
// at asOf: 0 = due today, 13 = 13 days overdue (still in), 14 = dropped,
// -1 = due tomorrow, <= -2 = further future (excluded).

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
  group('warmUpQueue — Today backlog', () {
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

    test('T14.1: overdue 0, 1, 5, 13 all land in Today; 14+ excluded', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: 1),
          _c(id: 3, overdue: 5),
          _c(id: 4, overdue: 13),
          _c(id: 5, overdue: 14), // one day past the window — dropped
          _c(id: 6, overdue: 30), // well past — dropped
        ],
        asOf: asOf,
      );
      // Most-overdue first: 13, 5, 1, 0 → ids 4, 3, 2, 1.
      expect(q.today.map((s) => s.candidate.id), [4, 3, 2, 1]);
      expect(q.tomorrow, isEmpty);
    });

    test('T14.1: Today is capped at 4 (most-overdue wins)', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: 1),
          _c(id: 3, overdue: 2),
          _c(id: 4, overdue: 3),
          _c(id: 5, overdue: 4),
          _c(id: 6, overdue: 5),
        ],
        asOf: asOf,
      );
      // Most-overdue first: 5, 4, 3, 2 → ids 6, 5, 4, 3. The two least-overdue
      // (ids 2, 1) fall off the cap.
      expect(q.today.map((s) => s.candidate.id), [6, 5, 4, 3]);
      expect(q.today.length, 4);
    });

    test('T14.1: under cap — all due rows surface (no filler, no floor)', () {
      final q = warmUpQueue(
        all: [_c(id: 1, overdue: 0), _c(id: 2, overdue: 2)],
        asOf: asOf,
      );
      expect(q.today.map((s) => s.candidate.id), [2, 1]);
    });

    test(
      'T14.1: Today ordering is most-overdue first (dueOn asc) then id desc',
      () {
        final q = warmUpQueue(
          all: [
            _c(id: 10, overdue: 0),
            _c(id: 20, overdue: 0), // same dueOn as 10 → id desc: 20 before 10
            _c(id: 30, overdue: 7),
          ],
          asOf: asOf,
        );
        // overdue 7 (id 30) first, then overdue 0 tie → id desc (20, 10).
        expect(q.today.map((s) => s.candidate.id), [30, 20, 10]);
      },
    );

    test('T14.1: no stale distinction — every Today row isStale == false', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: 1), // would have been "stale" pre-T14.1
          _c(id: 3, overdue: 13),
        ],
        asOf: asOf,
      );
      expect(q.today.every((s) => s.isStale == false), isTrue);
    });

    test('T14.1: far-future rows (overdue < -1) appear in neither window', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0), // today
          _c(id: 2, overdue: -3), // neither
          _c(id: 3, overdue: -4), // neither
        ],
        asOf: asOf,
      );
      expect(q.today.map((s) => s.candidate.id), [1]);
      expect(q.tomorrow, isEmpty);
    });
  });

  group('warmUpQueue — Tomorrow (unchanged by T14.1)', () {
    test(
      'Tomorrow stays strict: only overdue == -1 shown, id desc tiebreak',
      () {
        final q = warmUpQueue(
          all: [
            _c(id: 1, overdue: -1),
            _c(id: 2, overdue: -2), // excluded
            _c(id: 3, overdue: -1),
            _c(id: 4, overdue: -10), // excluded
          ],
          asOf: asOf,
        );
        expect(q.tomorrow.map((s) => s.candidate.id), [3, 1]);
        expect(q.today, isEmpty);
      },
    );

    test(
      'day-one library (all due tomorrow): Today empty, all in Tomorrow',
      () {
        final q = warmUpQueue(
          all: [
            for (final id in [1, 2, 3, 4, 5]) _c(id: id, overdue: -1),
          ],
          asOf: asOf,
        );
        expect(q.today, isEmpty);
        expect(q.tomorrow.map((s) => s.candidate.id), [5, 4, 3, 2, 1]);
      },
    );

    test('a candidate is never shown in both windows', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0), // today
          _c(id: 2, overdue: -1), // tomorrow
          _c(id: 3, overdue: -3), // neither
        ],
        asOf: asOf,
      );
      final todayIds = q.today.map((s) => s.candidate.id).toSet();
      final tomorrowIds = q.tomorrow.map((s) => s.candidate.id).toSet();
      expect(todayIds.intersection(tomorrowIds), isEmpty);
    });

    test('Tomorrow is not capped (cap is Today-only)', () {
      final q = warmUpQueue(
        all: [
          for (final id in [1, 2, 3, 4, 5, 6]) _c(id: id, overdue: -1),
        ],
        asOf: asOf,
      );
      expect(q.tomorrow.length, 6);
    });
  });
}
