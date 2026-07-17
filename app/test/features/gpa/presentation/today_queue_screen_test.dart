// TodayQueueScreen widget test (T2.5 / T7.1). Presentation is coverage-excluded,
// so this guards wiring + l10n + the empty / error / populated branches rather
// than chasing coverage. The tap-opens-detail path (T8.1) is exercised
// on-device (see PR "How to verify"); the AsyncValue→widget mapping mirrors
// RecordingsScreen.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/gpa/domain/gpa_intervals.dart';
import 'package:rivendell/features/gpa/domain/review_status.dart';
import 'package:rivendell/features/gpa/presentation/today_queue_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

// Notifier that never touches the platform service — returns idle so the queue
// tiles render without a real audio engine.
class _IdleAudio extends AudioPlayerController {
  @override
  PlaybackSnapshot build() => const PlaybackSnapshot.idle();
}

Recording _rec(int id, String name) => Recording(
  id: id,
  filePath: '/svr/$name',
  name: name,
  createdAt: DateTime(2026),
  sizeBytes: 1,
  format: 'm4a',
  indexedAt: DateTime(2026),
);

RecordingReviewStatus _status() => RecordingReviewStatus(
  milestoneReached: 0,
  reviewCount: 0,
  lastReviewed: null,
  activeMilestone: GpaMilestone(
    index: 1,
    intervalDays: gpaIntervalsInDays[1],
    dueOn: DateTime(2026),
  ),
  activeMilestoneDue: true,
  isComplete: false,
);

Widget _host(Object? queue) => ProviderScope(
  overrides: [
    warmedQueueProvider.overrideWith((ref) async {
      if (queue is Exception) throw queue;
      return queue! as WarmedQueue;
    }),
    audioPlayerControllerProvider.overrideWith(_IdleAudio.new),
  ],
  child: const MaterialApp(
    localizationsDelegates: [
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: TodayQueueScreen(),
  ),
);

void main() {
  testWidgets('empty queue shows the localized empty state', (tester) async {
    await tester.pumpWidget(_host(const WarmedQueue(today: [], tomorrow: [])));
    await tester.pumpAndSettle();

    expect(find.text("Today's Review Queue"), findsOneWidget);
    expect(find.text('Nothing due today'), findsOneWidget);
  });

  testWidgets('error state offers retry', (tester) async {
    await tester.pumpWidget(_host(StateError('boom')));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load recordings"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'a strict-due today row renders the Today section + D+1 subtitle',
    (tester) async {
      await tester.pumpWidget(
        _host(
          WarmedQueue(
            today: [
              WarmedItem(
                recording: _rec(1, 'lecture-1.m4a'),
                status: _status(),
                isStale: false,
              ),
            ],
            tomorrow: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget); // section header
      expect(find.text('lecture-1.m4a'), findsOneWidget);
      expect(find.text('D+2 · Due today'), findsOneWidget); // milestone + due
    },
  );
}
