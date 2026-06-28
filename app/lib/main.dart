// Rivendell — application entrypoint.
//
// Wires the root ProviderScope + the App widget, then boots the offline-queue
// drain on the SAME container the widget tree reads — so feature handlers
// registered later (M4 ai_image, M6 email) land in the QueueWorker that the
// connectivity edge actually drains.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One container for the widget tree and the queue — never two.
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RivendellApp(),
    ),
  );

  // Boot after runApp so a slow DB open / workmanager init can't delay the
  // first frame (NFR-2.2). Fire-and-forget: a boot failure is non-fatal —
  // items just wait for the next app start — but surface it so it isn't
  // silently swallowed.
  unawaited(
    bootOfflineQueue(container).catchError(
      (Object e, StackTrace st) => FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: st),
      ),
    ),
  );
}
