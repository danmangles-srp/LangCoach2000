// Widget tests for the recording detail screen (T1.6, M1 story 3). Covers:
// open -> auto-cue + play, metadata render, slider bound to the resolved
// duration, play/pause toggle through the transport seam, the not-found
// fallback for a stale id, and the indeterminate bar while duration is still
// unknown. The transport seam is faked so no device is needed.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/domain/media_item_mapper.dart';
import 'package:rivendell/features/audio/playback/platform/audio_playback_providers.dart';
import 'package:rivendell/features/audio/presentation/recording_detail_screen.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

Recording _rec({required int id, int? durationMs}) => Recording(
  id: id,
  filePath: 'content://x/rec.m4a',
  name: 'lecture-$id.m4a',
  createdAt: DateTime.utc(2026),
  sizeBytes: 4096,
  format: 'm4a',
  durationMs: durationMs,
  indexedAt: DateTime.utc(2026),
);

PlaybackState _transport({
  AudioProcessingState phase = AudioProcessingState.ready,
  bool playing = true,
}) {
  // Build via copyWith to avoid tripping avoid_redundant_argument_values on the
  // ctor's zero defaults (same trick as the controller test).
  return PlaybackState(processingState: phase, playing: playing).copyWith();
}

class _FakePlaybackService implements AudioPlaybackService {
  final StreamController<PlaybackState> _state =
      StreamController<PlaybackState>.broadcast();
  final StreamController<MediaItem?> _item =
      StreamController<MediaItem?>.broadcast();

  int? _currentId;
  final List<String> calls = <String>[];

  @override
  Stream<PlaybackState> get playbackState => _state.stream;

  @override
  Stream<MediaItem?> get mediaItem => _item.stream;

  @override
  int? get currentRecordingId => _currentId;

  @override
  Future<void> loadRecording(Recording recording) async {
    _currentId = recording.id;
    calls.add('load');
    _item.add(mediaItemFromRecording(recording));
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _state.add(_transport());
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _state.add(_transport(playing: false));
  }

  @override
  Future<void> seek(Duration position) async =>
      calls.add('seek:${position.inSeconds}');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async {
    await _state.close();
    await _item.close();
  }
}

Widget _host({
  required int id,
  required _FakePlaybackService fake,
  required Future<Recording?> Function() loader,
}) {
  return ProviderScope(
    overrides: [
      audioPlaybackServiceProvider.overrideWith(
        (ref) async => fake as AudioPlaybackService,
      ),
      recordingByIdProvider(id).overrideWith((ref) => loader()),
      // These tests exercise the transport; the review-history + word-log
      // sections are isolated from the store here (their data layers have
      // their own coverage).
      recordingReviewStatusProvider(id).overrideWith((ref) async => null),
      wordLogsForRecordingProvider(id).overrideWith((ref) async => const []),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [AppStrings.delegate],
      supportedLocales: AppStrings.supportedLocales,
      home: RecordingDetailScreen(recordingId: id),
    ),
  );
}

void main() {
  // DateFormat.yMMMd reads locale date symbols; load them once for the suite.
  setUpAll(initializeDateFormatting);

  testWidgets('auto-cues + plays on open and renders metadata + slider', (
    tester,
  ) async {
    final fake = _FakePlaybackService();
    await tester.pumpWidget(
      _host(
        id: 42,
        fake: fake,
        loader: () async => _rec(id: 42, durationMs: 100_000),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.calls, containsAll(const ['load', 'play']));
    expect(find.text('lecture-42.m4a'), findsOneWidget);
    expect(find.text('M4A'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);

    // Duration resolved from the media item -> slider is shown, maxed at it.
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 100_000);

    // Playing -> pause affordance.
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('tapping the transport toggles to pause', (tester) async {
    final fake = _FakePlaybackService();
    await tester.pumpWidget(
      _host(
        id: 42,
        fake: fake,
        loader: () async => _rec(id: 42, durationMs: 100_000),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.calls, contains('play'));

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();

    expect(fake.calls, contains('pause'));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('shows a not-found state for a stale id', (tester) async {
    final fake = _FakePlaybackService();
    await tester.pumpWidget(
      _host(id: 42, fake: fake, loader: () async => null),
    );
    await tester.pumpAndSettle();

    expect(find.text('This recording is no longer available.'), findsOneWidget);
    // No transport fired — nothing to cue.
    expect(fake.calls, isEmpty);
  });

  testWidgets('shows an indeterminate bar while duration is unknown', (
    tester,
  ) async {
    final fake = _FakePlaybackService();
    await tester.pumpWidget(
      _host(
        id: 42,
        fake: fake,
        loader: () async => _rec(id: 42), // durationMs null
      ),
    );
    await tester.pumpAndSettle();

    // Still auto-plays (the engine resolves length lazily).
    expect(fake.calls, containsAll(const ['load', 'play']));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
  });
}
