// Recording detail auto-advance on completion (M8, T8.2). With a peer context,
// finishing a recording replaces the route with the next one (queue order);
// without context (deep link) it stays put. Drives the real GoRouter so
// `context.replace` is exercised end-to-end.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/domain/media_item_mapper.dart';
import 'package:rivendell/features/audio/playback/platform/audio_playback_providers.dart';
import 'package:rivendell/features/audio/presentation/recording_detail_screen.dart';
import 'package:rivendell/features/audio/presentation/recording_nav_context.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

Recording _rec(int id) => Recording(
  id: id,
  filePath: 'content://x/rec-$id.m4a',
  name: 'lecture-$id.m4a',
  createdAt: DateTime.utc(2026),
  sizeBytes: 4096,
  format: 'm4a',
  durationMs: 1000,
  indexedAt: DateTime.utc(2026),
);

class _FakePlaybackService implements AudioPlaybackService {
  final StreamController<PlaybackState> _state =
      StreamController<PlaybackState>.broadcast();
  final StreamController<MediaItem?> _item =
      StreamController<MediaItem?>.broadcast();

  int? _currentId;

  @override
  Stream<PlaybackState> get playbackState => _state.stream;

  @override
  Stream<MediaItem?> get mediaItem => _item.stream;

  @override
  int? get currentRecordingId => _currentId;

  @override
  Future<void> loadRecording(Recording recording) async {
    _currentId = recording.id;
    _item.add(mediaItemFromRecording(recording));
  }

  @override
  Future<void> play() async {
    _state.add(
      PlaybackState(
        processingState: AudioProcessingState.ready,
        playing: true,
      ).copyWith(),
    );
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  void emitCompleted() {
    _state.add(
      PlaybackState(processingState: AudioProcessingState.completed).copyWith(),
    );
  }

  @override
  Future<void> dispose() async {
    await _state.close();
    await _item.close();
  }
}

Widget _host({
  required _FakePlaybackService fake,
  required int startId,
  required RecordingNavContext? nav,
}) {
  final router = GoRouter(
    initialLocation: '/recordings/$startId',
    initialExtra: nav,
    routes: [
      GoRoute(
        path: '/recordings/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra;
          final ctx = extra is RecordingNavContext ? extra : null;
          return RecordingDetailScreen(recordingId: id, navContext: ctx);
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      audioPlaybackServiceProvider.overrideWith((ref) async => fake),
      for (final id in const [1, 2, 3])
        recordingByIdProvider(id).overrideWith((ref) async => _rec(id)),
      for (final id in const [1, 2, 3])
        recordingReviewStatusProvider(id).overrideWith((ref) async => null),
      for (final id in const [1, 2, 3])
        wordLogsForRecordingProvider(id).overrideWith((ref) async => const []),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [AppStrings.delegate],
      supportedLocales: AppStrings.supportedLocales,
    ),
  );
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('on completion with queue context, advances to the next id', (
    tester,
  ) async {
    final fake = _FakePlaybackService();
    await tester.pumpWidget(
      _host(
        fake: fake,
        startId: 1,
        nav: const RecordingNavContext(
          peerIds: [1, 2, 3],
          source: RecordingLaunchSource.queue,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('lecture-1.m4a'), findsOneWidget);

    // Natural completion of recording 1 → advance to 2.
    fake.emitCompleted();
    await tester.pumpAndSettle();

    expect(find.text('lecture-2.m4a'), findsOneWidget);
    expect(find.text('lecture-1.m4a'), findsNothing);
  });

  testWidgets(
    'without context (deep link) it stays on the completed recording',
    (tester) async {
      final fake = _FakePlaybackService();
      await tester.pumpWidget(_host(fake: fake, startId: 1, nav: null));
      await tester.pumpAndSettle();
      expect(find.text('lecture-1.m4a'), findsOneWidget);

      fake.emitCompleted();
      await tester.pumpAndSettle();

      // No peer list → no advance; the completed recording stays on screen.
      expect(find.text('lecture-1.m4a'), findsOneWidget);
    },
  );
}
