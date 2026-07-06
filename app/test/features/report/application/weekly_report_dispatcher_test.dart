// Weekly report dispatcher (T6.6, FR-1.5.3). Composes the renderer + queue
// enqueue behind pure function seams so the dispatch logic is fully testable
// without a Drift store or SMTP. The dispatcher's job: derive the just-
// completed week window, render it, enqueue the EmailMessage, stamp last-sent.

import 'package:flutter_test/flutter_test.dart';

// Tests assert exact DateTime args + explicit local types for clarity, and
// invoke the bare ReportSchedule ctor to verify the shipped default cadence.
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: omit_local_variable_types
// ignore_for_file: use_named_constants
// ignore_for_file: prefer_const_constructors

import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/report/application/weekly_report_dispatcher.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/report_schedule.dart';
import 'package:rivendell/features/report/domain/weekly_report_renderer.dart';

DashboardSnapshot _emptySnapshot(MetricsWindow window) {
  final empty = MetricSeries(const []);
  return DashboardSnapshot(
    window: window,
    granularity: MetricsGranularity.weekly,
    lessonDuration: empty,
    journalingOutput: empty,
    completedQueueItems: empty,
    flashcardsReviewed: empty,
  );
}

void main() {
  const schedule = ReportSchedule();

  test('builds last-week window aligned to schedule weekday', () async {
    MetricsWindow? captured;
    final dispatcher = WeeklyReportDispatcher(
      schedule: schedule,
      snapshotProvider: (w) async {
        captured = w;
        return _emptySnapshot(w);
      },
      recipientProvider: () async => 'user@example.com',
      renderer: const WeeklyReportRenderer(),
      enqueue: ({required type, required payload}) async => 42,
      recordLastSent: (_) async {},
    );

    // Saturday 2025-06-07 12:00 — weekStart = Sat 06-07 midnight; the
    // just-completed week is [Sat 05-31 00:00, Sat 06-07 00:00).
    await dispatcher.dispatch(now: DateTime(2025, 6, 7, 12, 0));

    expect(captured, isNotNull);
    expect(captured!.from, DateTime(2025, 5, 31));
    expect(captured!.until, DateTime(2025, 6, 7));
  });

  test('enqueues an email payload with subject + html body', () async {
    String? capturedType;
    String? capturedPayload;
    final dispatcher = WeeklyReportDispatcher(
      schedule: schedule,
      snapshotProvider: (w) async => _emptySnapshot(w),
      recipientProvider: () async => 'user@example.com',
      renderer: const WeeklyReportRenderer(),
      enqueue: ({required type, required payload}) async {
        capturedType = type;
        capturedPayload = payload;
        return 7;
      },
      recordLastSent: (_) async {},
    );

    final id = await dispatcher.dispatch(now: DateTime(2025, 6, 7, 12, 0));

    expect(id, 7);
    expect(capturedType, emailQueueType);
    expect(capturedPayload, isNotNull);
    final message = EmailMessage.fromJsonString(capturedPayload!);
    expect(message.recipient, 'user@example.com');
    expect(message.subject, contains('Rivendell'));
    expect(message.subject, contains('Week of'));
    expect(message.htmlBody, contains('<!DOCTYPE html>'));
  });

  test('returns null + does NOT enqueue when recipient is missing', () async {
    bool enqueued = false;
    bool recordedLastSent = false;
    final dispatcher = WeeklyReportDispatcher(
      schedule: schedule,
      snapshotProvider: (w) async => _emptySnapshot(w),
      recipientProvider: () async => null,
      renderer: const WeeklyReportRenderer(),
      enqueue: ({required type, required payload}) async {
        enqueued = true;
        return 1;
      },
      recordLastSent: (_) async {
        recordedLastSent = true;
      },
    );

    final id = await dispatcher.dispatch(now: DateTime(2025, 6, 7, 12, 0));

    expect(id, isNull);
    expect(enqueued, isFalse);
    expect(recordedLastSent, isFalse);
  });

  test('stamps last-sent with the dispatch instant', () async {
    DateTime? stamped;
    final dispatcher = WeeklyReportDispatcher(
      schedule: schedule,
      snapshotProvider: (w) async => _emptySnapshot(w),
      recipientProvider: () async => 'user@example.com',
      renderer: const WeeklyReportRenderer(),
      enqueue: ({required type, required payload}) async => 1,
      recordLastSent: (at) async {
        stamped = at;
      },
    );

    final now = DateTime(2025, 6, 7, 12, 0);
    await dispatcher.dispatch(now: now);

    expect(stamped, now);
  });

  test('subject names the week-of date', () async {
    String? capturedPayload;
    final dispatcher = WeeklyReportDispatcher(
      schedule: schedule,
      snapshotProvider: (w) async => _emptySnapshot(w),
      recipientProvider: () async => 'user@example.com',
      renderer: const WeeklyReportRenderer(),
      enqueue: ({required type, required payload}) async {
        capturedPayload = payload;
        return 1;
      },
      recordLastSent: (_) async {},
    );

    // Saturday 2025-06-07 → just-completed week started 2025-05-31.
    await dispatcher.dispatch(now: DateTime(2025, 6, 7, 12, 0));

    final message = EmailMessage.fromJsonString(capturedPayload!);
    expect(message.subject, contains('May 31'));
  });
}
