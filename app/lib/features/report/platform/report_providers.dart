// coverage:ignore-file — production Riverpod wiring for the weekly report
// schedule + dispatch (T6.6, FR-1.5.3). Pulls in Drift + KV + the metrics
// aggregation service, so it lives under platform/ (excluded from the coverage
// floor). The pure dispatch math + schedule arithmetic are tested directly
// without this layer.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/features/metrics/application/metrics_providers.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/report/application/weekly_report_dispatcher.dart';
import 'package:rivendell/features/report/domain/report_schedule.dart';
import 'package:rivendell/features/report/domain/weekly_report_renderer.dart';
import 'package:rivendell/features/report/platform/email_providers.dart';

const _kReportSchedule = 'report.schedule';
const _kReportLastSent = 'report.last_sent';

/// Singleton [KvRepository] for report settings (the SQLCipher-encrypted KV
/// store — NFR-2.4.2). Reads/writes JSON-encoded values.
final reportSettingsRepositoryProvider = FutureProvider<KvRepository>(
  (ref) async => KvRepository(await ref.watch(appDatabaseProvider.future)),
);

/// The current weekly-report schedule. Defaults ship synchronously on the
/// first frame; persisted values hydrate once the store resolves.
final reportScheduleProvider =
    NotifierProvider<ReportScheduleNotifier, ReportSchedule>(
      ReportScheduleNotifier.new,
    );

class ReportScheduleNotifier extends Notifier<ReportSchedule> {
  @override
  ReportSchedule build() {
    _hydrate();
    return ReportSchedule.defaults;
  }

  Future<void> _hydrate() async {
    try {
      final repo = await ref.read(reportSettingsRepositoryProvider.future);
      final raw = await repo.read(_kReportSchedule);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        state = ReportSchedule.fromJson(decoded);
      }
    } on Object {
      // Best-effort: corrupt store keeps defaults so settings never blocks.
    }
  }

  Future<void> setSchedule(ReportSchedule next) async {
    state = next;
    final repo = await ref.read(reportSettingsRepositoryProvider.future);
    await repo.write(_kReportSchedule, jsonEncode(next.toJson()));
  }
}

/// Last successful dispatch instant (for the "last sent" indicator + the
/// [shouldFireNow] gate). Null when never sent.
final reportLastSentProvider = FutureProvider<DateTime?>((ref) async {
  final repo = await ref.watch(reportSettingsRepositoryProvider.future);
  final raw = await repo.read(_kReportLastSent);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
});

/// Next scheduled fire instant given the current schedule. Re-derives whenever
/// the schedule notifier emits a new value.
final reportNextFireProvider = FutureProvider<DateTime?>((ref) async {
  final schedule = ref.watch(reportScheduleProvider);
  return nextFireFrom(schedule, DateTime.now());
});

/// Compose a [WeeklyReportDispatcher] over real deps. Reads credentials,
/// recipient, and the aggregation service fresh per call so settings changes
/// take effect immediately.
final weeklyReportDispatcherProvider = FutureProvider<WeeklyReportDispatcher>((
  ref,
) async {
  final metrics = await ref.watch(metricsAggregationServiceProvider.future);
  final queueRepo = await ref.watch(queueRepositoryProvider.future);
  final settingsRepo = await ref.watch(reportSettingsRepositoryProvider.future);
  final schedule = ref.watch(reportScheduleProvider);
  const renderer = WeeklyReportRenderer();

  return WeeklyReportDispatcher(
    schedule: schedule,
    snapshotProvider: (window) => metrics.snapshot(
      window: window,
      granularity: MetricsGranularity.weekly,
      weekStartWeekday: schedule.weekday,
    ),
    recipientProvider: () async => readReportRecipient(
      settingsRepo,
      fallback: await readSmtpUsername(settingsRepo),
    ),
    renderer: renderer,
    enqueue: queueRepo.enqueue,
    recordLastSent: (at) async {
      await settingsRepo.write(_kReportLastSent, at.toIso8601String());
      ref.invalidate(reportLastSentProvider);
    },
  );
});

/// Read the stored SMTP username (Gmail address). Mirrors the key in
/// email_providers.dart so this layer can use it as the recipient fallback
/// without coupling settings UI to the email wiring.
Future<String?> readSmtpUsername(KvRepository repo) async {
  return repo.read('smtp.username');
}

/// Dispatch this cycle's report if it's due and a recipient is configured.
/// Called from app boot (foreground path) and the workmanager dispatch task
/// (background backstop, gated on T0.3 for the isolate DB open). No-op when
/// not due or recipient missing. Non-fatal: a failure leaves the cycle "due"
/// so the next boot/poll retries.
Future<void> dispatchWeeklyReportIfDue(
  ProviderContainer container, {
  DateTime? now,
}) async {
  final logger = container.read(appLoggerProvider);
  final at = now ?? DateTime.now();
  try {
    final schedule = container.read(reportScheduleProvider);
    final lastSent = await container.read(reportLastSentProvider.future);
    if (!shouldFireNow(schedule, at, lastSent)) return;

    final dispatcher = await container.read(
      weeklyReportDispatcherProvider.future,
    );
    final id = await dispatcher.dispatch(now: at);
    if (id == null) {
      logger.i(
        LogTag.mail,
        'weekly report due but recipient unset — skipping '
        '(configure in Settings)',
      );
      return;
    }
    logger.i(LogTag.mail, 'weekly report enqueued (queue id=$id)');
  } on Object catch (e, st) {
    logger.e(LogTag.mail, 'weekly report dispatch failed: $e\n$st');
  }
}
