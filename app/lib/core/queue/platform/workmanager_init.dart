// workmanager scaffold for the offline queue (NFR-2.1.3).
//
// The in-process [QueueWorker] drains the queue whenever the app is
// foregrounded and connectivity returns — that path is unit-tested and covers
// the common case. workmanager adds a system-scheduled backstop that fires
// [drainQueueFromBackground] (T18.2) even when the app is closed, so AI-image
// generation (FR-1.3.4) progresses without a foreground session. The weekly
// email dispatch (T6.6) remains foreground-driven for now.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/platform/background_queue_drain.dart';
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
/// `queueDrainTask` runs the offline-queue drain (T18.2): it opens the
/// encrypted DB with a read-only-resolved key, registers the ai_image handler,
/// and processes pending items so AI-image generation progresses while the app
/// is closed. `reportDispatchTask` (weekly report) is still foreground-driven.
@pragma('vm:entry-point')
void callbackDispatcher() {
  final logger = AppLogger(sink: const DebugPrintSink());
  Workmanager().executeTask((task, inputData) async {
    logger.i(LogTag.task, 'workmanager task: $task');
    switch (task) {
      case queueDrainTask:
        // T18.2. Best-effort: a thrown drain returns false so workmanager
        // retries with its own backoff; the foreground resume drain + the
        // next periodic fire also cover it.
        try {
          return await drainQueueFromBackground(logger);
        } on Object catch (e) {
          logger.e(LogTag.task, 'background drain failed: $e');
          return false;
        }
      case reportDispatchTask:
        // T6.6 background dispatch is foreground-only for now (boot + resume
        // call dispatchWeeklyReportIfDue). It shares the key/handler plumbing
        // the drain now uses, so wiring it here is the natural follow-up.
        return true;
      default:
        return true;
    }
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
