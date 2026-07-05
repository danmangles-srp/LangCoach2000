// Queue selector tests (T7.1, superseded by T10.1 / M10 AC4–5). Both windows
// strict-only. Pure — builds [RecordingReviewStatus] directly with a
// controlled active-milestone due day so the day-math is independent of the GPA
// derivation (covered in its own suite). `overdue` is the active milestone's
// daysOverdue at asOf: 0 = due today, 1 = 1-day-stale, -1 = due tomorrow,
// <= -2 = further future (excluded).

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

    test(
      'strict due-today rows render in Today, sorted stale-first then id desc',
      () {
        final q = warmUpQueue(
          all: [
            _c(id: 1, overdue: 0),
            _c(id: 2, overdue: 0),
            _c(id: 3, overdue: 0),
          ],
          asOf: asOf,
        );
        expect(q.today.map((s) => s.candidate.id), [3, 2, 1]);
        expect(q.today.every((s) => s.isStale == false), isTrue);
        expect(q.tomorrow, isEmpty);
      },
    );

    test('T10.1: Today is NEVER topped up — a single due-today item renders '
        'alone even though far-future items exist', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0),
          _c(id: 2, overdue: -3),
          _c(id: 3, overdue: -4),
          _c(id: 4, overdue: -5),
        ],
        asOf: asOf,
      );
      expect(q.today.map((s) => s.candidate.id), [1]);
      // Far-future (overdue < -1) appear in neither window.
      expect(q.tomorrow, isEmpty);
    });

    test('T10.1: Tomorrow is strict too — only overdue == -1 shown', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: -1), // due tomorrow
          _c(id: 2, overdue: -2), // day after — excluded
          _c(id: 3, overdue: -1), // due tomorrow
          _c(id: 4, overdue: -10), // far — excluded
        ],
        asOf: asOf,
      );
      // Tomorrow: only the two due-tomorrow rows, id desc (same dueOn).
      expect(q.tomorrow.map((s) => s.candidate.id), [3, 1]);
      expect(q.today, isEmpty);
    });

    test('day-one library (everything due tomorrow): Today empty, all 5 in '
        'Tomorrow', () {
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
      expect(q.today, isEmpty);
      expect(q.tomorrow.map((s) => s.candidate.id), [5, 4, 3, 2, 1]);
    });

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

    test('tomorrow ordering is soonest-due (dueOn asc) then id desc', () {
      final q = warmUpQueue(
        all: [
          _c(id: 1, overdue: 0), // today strict
          _c(id: 2, overdue: -1), // tomorrow
          _c(id: 3, overdue: -1), // tomorrow
        ],
        asOf: asOf,
      );
      expect(q.today.map((s) => s.candidate.id), [1]);
      // Same dueOn → id desc.
      expect(q.tomorrow.map((s) => s.candidate.id), [3, 2]);
    });
  });
}
