// Weekly report dispatcher (T6.6, FR-1.5.3). Composes the snapshot provider,
// the renderer, and the offline-queue enqueue seam into a single dispatch
// step. Pure coordination over injected functions — fully testable without a
// Drift store or SMTP socket.
//
// The dispatcher is invoked by the workmanager periodic task
// `rivendell.report.dispatch` (see report_workmanager.dart) gated by
// [shouldFireNow]. It only *enqueues* the EmailMessage; the existing
// connectivity-driven drain (and the queue-drain backstop task) performs the
// actual SMTP send via the email handler registered in T6.5.

import 'package:intl/intl.dart';

import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/report/domain/email_message.dart';
import 'package:rivendell/features/report/domain/report_schedule.dart';
import 'package:rivendell/features/report/domain/weekly_report_renderer.dart';

/// Build a [DashboardSnapshot] for the window the dispatcher is reporting on.
typedef SnapshotProvider =
    Future<DashboardSnapshot> Function(MetricsWindow window);

/// Append a work item to the offline queue. Mirrors
/// `QueueRepository.enqueue` so this layer stays free of Drift types.
typedef EnqueueEmail =
    Future<int> Function({required String type, required String payload});

/// The configured recipient for the report, or null if unset (which suppresses
/// dispatch without raising — the user hasn't finished configuring settings).
typedef RecipientProvider = Future<String?> Function();

/// Record the instant a dispatch succeeded, so [shouldFireNow] can suppress
/// re-sends within the same cycle.
typedef RecordLastSent = Future<void> Function(DateTime sentAt);

/// Compose one weekly-report dispatch step. Stateless apart from its injected
/// collaborators — safe to construct per invocation in the workmanager
/// isolate.
class WeeklyReportDispatcher {
  const WeeklyReportDispatcher({
    required this.schedule,
    required this.snapshotProvider,
    required this.recipientProvider,
    required this.renderer,
    required this.enqueue,
    required this.recordLastSent,
    this.labels = WeeklyReportLabels.en,
  });

  final ReportSchedule schedule;
  final SnapshotProvider snapshotProvider;
  final RecipientProvider recipientProvider;
  final WeeklyReportRenderer renderer;
  final EnqueueEmail enqueue;
  final RecordLastSent recordLastSent;
  final WeeklyReportLabels labels;

  /// Build the just-completed report week: [weekStart - 7d, weekStart) where
  /// weekStart is the most recent local midnight whose weekday matches the
  /// schedule. Half-open so adjacent weeks partition cleanly.
  MetricsWindow reportWindow(DateTime now) {
    var d = DateTime(now.year, now.month, now.day);
    while (d.weekday != schedule.weekday) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return MetricsWindow(
      from: DateTime(d.year, d.month, d.day - 7),
      until: DateTime(d.year, d.month, d.day),
    );
  }

  /// Render + enqueue this cycle's report. Returns the queue item id, or null
  /// if no recipient is configured (in which case nothing is enqueued and
  /// last-sent is not stamped — the cycle remains "due" until settings are
  /// completed).
  Future<int?> dispatch({required DateTime now}) async {
    final recipient = await recipientProvider();
    if (recipient == null || recipient.isEmpty) return null;

    final window = reportWindow(now);
    final snapshot = await snapshotProvider(window);
    final html = renderer.render(snapshot, labels: labels);
    final subject = _formatSubject(window.from);

    final message = EmailMessage(
      recipient: recipient,
      subject: subject,
      htmlBody: html,
    );

    final id = await enqueue(
      type: emailQueueType,
      payload: message.toJsonString(),
    );
    await recordLastSent(now);
    return id;
  }

  String _formatSubject(DateTime weekStart) {
    final formatted = DateFormat('MMM d, y').format(weekStart);
    return '${labels.title} — Week of $formatted';
  }
}
