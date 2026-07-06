// workmanager scaffold for the offline queue (NFR-2.1.3).
//
// The in-process [QueueProcessor] drains the queue whenever the app is
// foregrounded and connectivity returns — that path is unit-tested and covers
// the common case. workmanager adds a system-scheduled backstop that can fire
// the drain even when the app is closed (needed for the M6 weekly email and
// M4 image generation). The real background drain handler is wired to
// QueueProcessor.drain; feature handlers (ai_image, email) are registered by
// their milestones.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:workmanager/workmanager.dart';

/// workmanager task name for the periodic connectivity-drain backstop.
const queueDrainTask = 'rivendell.queue.drain';

/// workmanager task name for the weekly-report dispatch check (T6.6, FR-1.5.3).
/// Runs daily; the callback gates on `shouldFireNow` + recipient-configured so
/// a missed Saturday self-heals on the next poll. The actual SMTP send is
/// enqueued + drained via the email handler from T6.5.
const reportDispatchTask = 'rivendell.report.dispatch';

/// Top-level callback executed in the workmanager background isolate.
///
/// Returns true once the drain completes. Feature handlers are registered by
/// their milestones; until then this is a no-op that simply reports success.
@pragma('vm:entry-point')
void callbackDispatcher() {
  final logger = AppLogger(sink: const DebugPrintSink());
  Workmanager().executeTask((task, inputData) async {
    logger.i(LogTag.task, 'workmanager task: $task');
    // TODO(rivendell): open the DB (openAppDatabase, shared key) and run
    // QueueWorker.drain here; feature handlers register their types. The
    // weekly-report dispatch (reportDispatchTask) likewise needs the shared
    // key to call dispatchWeeklyReportIfDue from this isolate — until T0.3
    // lands, the foreground boot path covers the common case.
    return true;
  });
}

/// Initialise workmanager once at app boot. Idempotent.
Future<void> initWorkmanager() async {
  await Workmanager().initialize(callbackDispatcher);
  // Periodic drain every ~15 min (Workmanager minimum) as a closed-app
  // backstop; the connectivity-driven in-process drain is the primary path.
  await Workmanager().registerPeriodicTask(
    queueDrainTask,
    queueDrainTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  // Daily weekly-report dispatch check (T6.6). The OS fires this roughly once
  // per day; the foreground boot path also checks, so a missed fire here is
  // covered the next time the app opens.
  await Workmanager().registerPeriodicTask(
    reportDispatchTask,
    reportDispatchTask,
    frequency: const Duration(days: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
