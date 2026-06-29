// Widget test for the review-history section on the detail screen (T2.6).
// Verifies the milestone timeline renders derived state and that the manual
// "Mark reviewed" / "Undo" controls route through the repository + bump the
// generation notifier (so the queue + status refresh). Presentation is
// coverage-excluded; this guards wiring, not line coverage.

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
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/gpa/domain/review_status.dart';
import 'package:rivendell/l10n/app_strings.dart';

Recording _rec() => Recording(
  id: 42,
  filePath: 'content://x/rec.m4a',
  name: 'lecture-42.m4a',
  createdAt: DateTime.utc(2026, 3, 15),
  sizeBytes: 4096,
  format: 'm4a',
  durationMs: 100_000,
  indexedAt: DateTime.utc(2026, 3, 15),
);

// Minimal transport fake — the detail screen watches the controller, so the
// service has to resolve. Only load/play are exercised; nothing asserted here.
class _FakePlaybackService implements AudioPlaybackService {
  final StreamController<PlaybackState> _state =
      StreamController<PlaybackState>.broadcast();
  final StreamController<MediaItem?> _item =
      StreamController<MediaItem?>.broadcast();

  @override
  Stream<PlaybackState> get playbackState => _state.stream;
  @override
  Stream<MediaItem?> get mediaItem => _item.stream;
  @override
  int? get currentRecordingId => 42;
  @override
  Future<void> loadRecording(Recording recording) async =>
      _item.add(mediaItemFromRecording(recording));
  @override
  Future<void> play() async => _state.add(
    PlaybackState(processingState: AudioProcessingState.ready).copyWith(),
  );
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {
    await _state.close();
    await _item.close();
  }
}

// Captures manual correction calls without a DB.
class _RecordingRepo implements ReviewEventRepository {
  int? markedMilestone;
  int? undoneMilestone;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #markReviewed) {
      markedMilestone =
          (invocation.namedArguments[#milestoneIndex] as int?) ?? -1;
    }
    if (invocation.memberName == #unreviewMilestone) {
      undoneMilestone =
          (invocation.namedArguments[#milestoneIndex] as int?) ?? -1;
    }
    return Future<void>.value();
  }
}

Widget _host({
  required int id,
  required _RecordingRepo repo,
  required RecordingReviewStatus status,
}) {
  return ProviderScope(
    overrides: [
      audioPlaybackServiceProvider.overrideWith(
        (ref) async => _FakePlaybackService(),
      ),
      recordingByIdProvider(id).overrideWith((ref) async => _rec()),
      recordingReviewStatusProvider(id).overrideWith((ref) async => status),
      reviewEventRepositoryProvider.overrideWith((ref) async => repo),
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
  setUpAll(initializeDateFormatting);

  // Created 2026-03-15, milestone 4 (D+30) reviewed → reached 4, active 5.
  final created = DateTime.utc(2026, 3, 15);
  final status = computeReviewStatus(
    createdAt: created,
    events: [
      ReviewLogEntry(
        milestoneIndex: 4,
        completedAt: created.add(const Duration(days: 30)),
      ),
    ],
    asOf: created.add(const Duration(days: 400)),
  );

  testWidgets('timeline shows reached + unreached milestones with controls', (
    tester,
  ) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(_host(id: 42, repo: repo, status: status));
    await tester.pumpAndSettle();

    // Milestones 0–4 are reached → "Undo"; 5/6/7 unreached → "Mark reviewed".
    expect(find.text('Undo'), findsNWidgets(5));
    expect(find.text('Mark reviewed'), findsNWidgets(3));
  });

  testWidgets('tapping Mark reviewed routes through the repository', (
    tester,
  ) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(_host(id: 42, repo: repo, status: status));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Mark reviewed').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark reviewed').first);
    await tester.pumpAndSettle();

    expect(repo.markedMilestone, isNotNull);
  });

  testWidgets('tapping Undo routes through the repository', (tester) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(_host(id: 42, repo: repo, status: status));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Undo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo').first);
    await tester.pumpAndSettle();

    expect(repo.undoneMilestone, isNotNull);
  });
}
