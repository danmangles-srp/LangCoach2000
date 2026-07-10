// Rivendell — application entrypoint.
//
// Wires the root ProviderScope + the App widget, then boots the offline-queue
// drain on the SAME container the widget tree reads — so feature handlers
// registered later (M4 ai_image, M6 email) land in the QueueWorker that the
// connectivity edge actually drains.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/features/anki/application/anki_export_providers.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/report/platform/email_providers.dart';
import 'package:rivendell/features/report/platform/report_providers.dart';
import 'package:rivendell/features/tasks/application/task_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // T8.4: targetSdk 35 forces edge-to-edge (UI drawn behind the status + nav
  // bars). Opt in explicitly so the system-bar insets flow into MediaQuery,
  // then let SafeArea (home shell nav bar, detail body) lift content above
  // them.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  // Load every shipped locale's date symbols (uz included) so DateFormat on a
  // non-English device doesn't throw LocaleDataException. intl ships the data;
  // it just isn't registered until this runs. Cheap one-time parse; cover it
  // under the native splash. A failure degrades to en defaults, not a crash.
  await initializeDateFormatting().onError((_, __) => {});

  // One container for the widget tree and the queue — never two.
  final container = ProviderContainer();

  // Pre-warm the DB open before the first frame. The async router redirect
  // (router.dart) reads hasFolderProvider, which transitively awaits
  // appDatabaseProvider — so a cold open shows a blank native splash longer
  // than necessary. Awaiting here lets the native splash cover the open and
  // keeps the redirect's first route correct. A key/corruption failure must
  // not prevent the UI from rendering; the redirect degrades to onboarding
  // and the error surfaces downstream.
  try {
    await container.read(appDatabaseProvider.future);
  } on Object {
    // DB open failed — see comment above. Let the app render; recovery UI is
    // a follow-up.
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RivendellApp(),
    ),
  );

  // Boot after runApp so a slow DB open / workmanager init can't delay the
  // first frame (NFR-2.2). Fire-and-forget: a boot failure is non-fatal —
  // items just wait for the next app start — but surface it so it isn't
  // silently swallowed. The ai_image + email handlers are registered BEFORE
  // the worker starts so the initial online drain already sees them.
  unawaited(
    registerAiImageHandler(
          container,
          // When an image finishes generating, attach its Type 2 Anki card —
          // the first Export deferred it as pending (no image yet), and without
          // this hook nothing re-exported once the image landed. Best-effort +
          // swallowed inside the handler, so an AnkiDroid miss (not installed /
          // no grant) never fails the image-generation queue item.
          onGenerated: (word) async {
            final anki = await container.read(ankiExportServiceProvider.future);
            final res = await anki.exportType2Word(word);
            container
                .read(appLoggerProvider)
                .i(LogTag.anki, 'auto type2 re-export for "$word": $res');
          },
        )
        .then((_) => registerEmailHandler(container))
        .then((_) => bootOfflineQueue(container))
        .then((_) => dispatchWeeklyReportIfDue(container))
        .catchError(
          (Object e, StackTrace st) => FlutterError.reportError(
            FlutterErrorDetails(exception: e, stack: st),
          ),
        ),
  );

  // Init the notification plugin + request its runtime grants (FR-1.4.2,
  // T5.3). Fire-and-forget so a slow init can't delay the first frame; a
  // failure just means reminders won't fire until the next startup. The grant
  // prompts (POST_NOTIFICATIONS on 13+, exact-alarm settings on 12+) appear
  // once, over the native splash.
  unawaited(
    _initNotifications(container).catchError(
      (Object e, StackTrace st) => FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: st),
      ),
    ),
  );

  // Re-index on every startup (FR-1.1.1 — subsequent startups reconcile): new
  // files land, existing rows keep their durationMs via upsert. Fire-and-
  // forget so it can't delay the first frame; a failure leaves the stale list
  // and the manual refresh / next startup retries. No-op when no folder is
  // set (RecordingIndexer short-circuits), so this is safe pre-onboarding.
  unawaited(
    initialScan(container).catchError(
      (Object e, StackTrace st) => FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: st),
      ),
    ),
  );
}

/// Run one library scan against the chosen folder, then drop the cached
/// recordings list so the home screen re-reads. Shares the root container, so
/// invalidating here refreshes the widget tree.
Future<void> initialScan(ProviderContainer container) async {
  final indexer = await container.read(recordingIndexerProvider.future);
  await indexer.scanAndStore();
  container.invalidate(recordingsProvider);
}

/// Bootstrap the notification plugin + timezone data (FR-1.4.2, T5.3). The
/// runtime permission grant is deferred to the first scheduled reminder so the
/// prompt appears in context (after the user sets a due date), not on first
/// launch. Non-fatal on failure.
Future<void> _initNotifications(ProviderContainer container) async {
  await container.read(taskNotificationGatewayProvider).init();
}
